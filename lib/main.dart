// lib/main.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:local_notifier/local_notifier.dart';
import 'providers/app_provider.dart';
import 'theme.dart';
import 'widgets/sidebar.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/equipment_screen.dart';
import 'screens/borrowing_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/users_screen.dart';
import 'screens/other_screens.dart';
import 'screens/account_screen.dart';
import 'screens/lab_map_screen.dart';
import 'models/models.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // Initialize local_notifier for Windows toast notifications
  await localNotifier.setup(
    appName: 'CCSLMS',
    shortcutPolicy: ShortcutPolicy.requireCreate,
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: const LabInventoryApp(),
    ),
  );
}

class LabInventoryApp extends StatelessWidget {
  const LabInventoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CCSLMS',
      theme: AppTheme.theme,
      debugShowCheckedModeBanner: false,
      home: const AuthGate(),
    );
  }
}

/// Handles auth state: shows login or main app.
/// BUG FIX: Was calling provider.init() inside build() via addPostFrameCallback,
/// which fires on EVERY rebuild (every notifyListeners()). Now uses a StatefulWidget
/// with a dedicated _initialized flag so init() is called exactly once.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _checking = true;
  // FIX: tracks whether init() has already been called so it never fires twice.
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    await context.read<AppProvider>().checkAuth();
    if (mounted) setState(() => _checking = false);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    if (_checking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!provider.isAuthenticated) {
      // Reset so init() fires again after a fresh login.
      _initialized = false;
      return const LoginScreen();
    }

    // FIX: only call init() once per authenticated session, not on every rebuild.
    if (!_initialized && !provider.isLoading) {
      _initialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        provider.init();
      });
    }

    return const MainShell();
  }
}

// =================== MAIN SHELL WITH REALTIME ===================
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  RealtimeChannel? _notifChannel;

  @override
  void initState() {
    super.initState();
    // Start listening after first frame so provider is ready
    WidgetsBinding.instance.addPostFrameCallback((_) => _subscribeToNotifications());
  }

  void _subscribeToNotifications() {
    final provider = context.read<AppProvider>();
    final userId = provider.currentUser?.id;
    if (userId == null) return;

    // Listen to INSERT events on the notifications table for this user
    _notifChannel = Supabase.instance.client
        .channel('notifications:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) async {
            // Reload notifications in provider
            await provider.loadNotifications();

            // Show Windows toast for the new notification
            final row = payload.newRecord;
            final title   = row['title']   as String? ?? 'CCSLMS';
            final message = row['message'] as String? ?? '';
            _showToast(title, message);
          },
        )
        .subscribe();
  }

  void _showToast(String title, String body) {
    // Strip emoji from title for cleaner Windows toast
    final cleanTitle = title.replaceAll(RegExp(r'[^\x00-\x7F]'), '').trim();

    final notification = LocalNotification(
      title: cleanTitle.isEmpty ? 'CCSLMS' : cleanTitle,
      body: body,
    );
    notification.show();
  }

  @override
  void dispose() {
    _notifChannel?.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    final screens = [
      const DashboardScreen(),
      const EquipmentScreen(),
      const LaboratoriesScreen(),
      const CategoriesScreen(),
      const BorrowingScreen(),
      const MaintenanceScreen(),
      const ReportsScreen(),
      const UsersScreen(),
      const AccountScreen(),
    ];

    return Scaffold(
      body: Row(
        children: [
          const AppSidebar(),
          Expanded(
            child: Column(
              children: [
                // Top bar
                Container(
                  height: 60,
                  decoration: const BoxDecoration(
                    color: AppTheme.surface,
                    border: Border(bottom: BorderSide(color: AppTheme.border)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      const Spacer(),
                      if (provider.isLoading)
                        const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      const SizedBox(width: 16),

                      // Current user chip
                      if (provider.currentUser != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: provider.currentUser!.role.color.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: provider.currentUser!.role.color.withOpacity(0.2)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _TopBarAvatar(user: provider.currentUser!),
                              const SizedBox(width: 8),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(provider.currentUser!.fullName,
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: provider.currentUser!.role.color)),
                                  Text(provider.currentUser!.role.label,
                                    style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(width: 8),

                      IconButton(
                        icon: const Icon(Icons.refresh_rounded, color: AppTheme.textSecondary),
                        onPressed: () => provider.init(),
                        tooltip: 'Refresh',
                      ),
                      const NotificationBell(),
                      IconButton(
                        icon: const Icon(Icons.logout_rounded, color: AppTheme.textSecondary),
                        onPressed: () async { await provider.signOut(); },
                        tooltip: 'Sign Out',
                      ),
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: screens[provider.selectedIndex.clamp(0, screens.length - 1)],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =================== NOTIFICATION BELL ===================
class NotificationBell extends StatefulWidget {
  const NotificationBell({super.key});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  bool _open = false;
  OverlayEntry? _overlayEntry;
  final _bellKey = GlobalKey();

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _togglePanel(AppProvider provider) {
    if (_open) {
      _removeOverlay();
      setState(() => _open = false);
      return;
    }

    final renderBox = _bellKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (ctx) {
        final p = ctx.watch<AppProvider>();
        return Stack(
          children: [
            // Tap outside to close
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  _removeOverlay();
                  if (mounted) setState(() => _open = false);
                },
              ),
            ),
            // Panel anchored below the bell button
            Positioned(
              top: offset.dy + size.height + 4,
              right: MediaQuery.of(ctx).size.width - offset.dx - size.width,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                shadowColor: Colors.black26,
                child: Container(
                  width: 340,
                  constraints: const BoxConstraints(maxHeight: 440),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: _NotificationPanel(
                    notifications: p.notifications,
                    provider: p,
                    unread: p.unreadNotificationCount,
                    onClose: () {
                      _removeOverlay();
                      if (mounted) setState(() => _open = false);
                    },
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context, rootOverlay: true).insert(_overlayEntry!);
    setState(() => _open = true);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final unread = provider.unreadNotificationCount;

    if (_open) {
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => _overlayEntry?.markNeedsBuild());
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          key: _bellKey,
          icon: Icon(
            _open ? Icons.notifications_rounded : Icons.notifications_outlined,
            color: _open ? AppTheme.primary : AppTheme.textSecondary,
          ),
          onPressed: () => _togglePanel(provider),
          tooltip: 'Notifications',
        ),
        if (unread > 0)
          Positioned(
            right: 6,
            top: 6,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: AppTheme.error,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  unread > 9 ? '9+' : '$unread',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _NotificationPanel extends StatelessWidget {
  final List<AppNotification> notifications;
  final AppProvider provider;
  final int unread;
  final VoidCallback onClose;

  const _NotificationPanel({
    required this.notifications,
    required this.provider,
    required this.unread,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              const Text('Notifications',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
              if (unread > 0)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.error,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                ),
              const Spacer(),
              if (unread > 0)
                TextButton(
                  onPressed: () => provider.markAllNotificationsRead(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                  ),
                  child: const Text('Mark all read',
                    style: TextStyle(fontSize: 11, color: AppTheme.primary)),
                ),
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close, size: 16, color: AppTheme.textSecondary),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),

        // List
        if (notifications.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Column(children: [
              Icon(Icons.notifications_none_rounded, size: 40, color: AppTheme.textSecondary),
              SizedBox(height: 8),
              Text('No notifications', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            ]),
          )
        else
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: AppTheme.border),
              itemBuilder: (_, i) => _NotificationTile(
                notification: notifications[i],
                onRead:   () => provider.markNotificationRead(notifications[i].id),
                onDelete: () => provider.deleteNotification(notifications[i].id),
                onClose:  onClose,
              ),
            ),
          ),
      ],
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onRead;
  final VoidCallback onDelete;
  final VoidCallback onClose;

  const _NotificationTile({
    required this.notification,
    required this.onRead,
    required this.onDelete,
    required this.onClose,
  });

  Color get _typeColor {
    switch (notification.type) {
      case 'under_repair':    return AppTheme.warning;
      case 'equipment_fixed': return AppTheme.success;
      default:                return AppTheme.primary;
    }
  }

  IconData get _typeIcon {
    switch (notification.type) {
      case 'under_repair':    return Icons.build_rounded;
      case 'equipment_fixed': return Icons.check_circle_rounded;
      default:                return Icons.info_outline_rounded;
    }
  }

  /// Extract seat label from message e.g. "at seat PC-01 in" or "Seat PC-01 in"
  String? _extractSeatLabel() {
    final regex = RegExp(r'[Ss]eat ([A-Z0-9\-]+)');
    final match = regex.firstMatch(notification.message);
    return match?.group(1);
  }

  Future<void> _handleTap(BuildContext context) async {
    onRead();
    onClose();

    if (notification.type != 'under_repair') return;
    final laboratoryId = notification.referenceId;
    if (laboratoryId == null) return;

    final provider = context.read<AppProvider>();
    Laboratory? lab;
    try {
      lab = provider.laboratories.firstWhere((l) => l.id == laboratoryId);
    } catch (_) { return; }

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider.value(
            value: provider,
            child: LabMapScreen(
              laboratory: lab!,
              highlightSeatLabel: _extractSeatLabel(),
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _handleTap(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        color: notification.isRead ? Colors.transparent : _typeColor.withOpacity(0.04),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: _typeColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(_typeIcon, size: 15, color: _typeColor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(notification.title,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w700,
                          color: AppTheme.textPrimary,
                        )),
                    ),
                    if (!notification.isRead)
                      Container(
                        width: 7, height: 7,
                        decoration: const BoxDecoration(color: AppTheme.error, shape: BoxShape.circle),
                      ),
                  ]),
                  const SizedBox(height: 3),
                  Text(notification.message,
                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, height: 1.4)),
                  const SizedBox(height: 4),
                  Row(children: [
                    Text(_timeAgo(notification.createdAt),
                      style: TextStyle(fontSize: 10, color: AppTheme.textSecondary.withOpacity(0.6))),
                    if (notification.type == 'under_repair' && notification.referenceId != null) ...[
                      const SizedBox(width: 6),
                      Text('Tap to view lab →',
                        style: TextStyle(fontSize: 10, color: AppTheme.primary.withOpacity(0.7),
                            fontWeight: FontWeight.w600)),
                    ],
                  ]),
                ],
              ),
            ),
            InkWell(
              onTap: onDelete,
              borderRadius: BorderRadius.circular(4),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.close_rounded, size: 13, color: AppTheme.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1)  return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)   return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ── Top-bar user chip avatar — shows photo with safe error fallback ──
class _TopBarAvatar extends StatefulWidget {
  final UserProfile user;
  const _TopBarAvatar({required this.user});

  @override
  State<_TopBarAvatar> createState() => _TopBarAvatarState();
}

class _TopBarAvatarState extends State<_TopBarAvatar> {
  bool _failed = false;

  @override
  void didUpdateWidget(_TopBarAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.avatarUrl != widget.user.avatarUrl) {
      _failed = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final hasAvatar = user.avatarUrl != null &&
        user.avatarUrl!.isNotEmpty &&
        !_failed;

    return CircleAvatar(
      radius: 12,
      backgroundColor: user.role.color.withOpacity(0.2),
      backgroundImage: hasAvatar ? NetworkImage(user.avatarUrl!) : null,
      onBackgroundImageError: hasAvatar
          ? (_, __) {
              if (mounted) setState(() => _failed = true);
            }
          : null,
      child: !hasAvatar
          ? Text(
              user.fullName.substring(0, 1).toUpperCase(),
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: user.role.color),
            )
          : null,
    );
  }
}