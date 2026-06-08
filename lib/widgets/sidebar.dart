// lib/widgets/sidebar.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme.dart';
import '../models/models.dart';

class AppSidebar extends StatelessWidget {
  const AppSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final user = provider.currentUser;

    final navItems = [
      _NavItem(0, Icons.dashboard_rounded, 'Dashboard'),
      _NavItem(1, Icons.inventory_2_rounded, 'Equipment'),
      _NavItem(2, Icons.meeting_room_rounded, 'Laboratories'),
      _NavItem(3, Icons.category_rounded, 'Categories'),
      _NavItem(4, Icons.swap_horiz_rounded, 'Borrowing'),
      _NavItem(5, Icons.build_rounded, 'Maintenance'),
      _NavItem(6, Icons.bar_chart_rounded, 'Reports'),
      if (user?.role == UserRole.departmentHead)
        _NavItem(7, Icons.group_rounded, 'Users'),
      _NavItem(8, Icons.manage_accounts_rounded, 'My Account'),
    ];

    return Container(
      width: 220,
  decoration: const BoxDecoration(
    color: Colors.white,
    border: Border(right: BorderSide(color: AppTheme.border)),
  ),
      child: Column(
        children: [
          // Logo
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppTheme.border))),
            child: Row(
  children: [
    Image.asset(
      'assets/images/CCS LOGO.png',
      width: 40,
      height: 40,
      fit: BoxFit.contain,
    ),
    const SizedBox(width: 10),
Expanded(
  child: Column(
    mainAxisSize: MainAxisSize.min, // Keeps the column tight around the text
    crossAxisAlignment: CrossAxisAlignment.start, // Aligns text to the left
    children: [
      const Text(
        'CCSLMS',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: AppTheme.textSecondary,
          fontSize: 18, // Slightly reduced to fit the subtext better
          fontFamily: 'monospace',
        ),
        overflow: TextOverflow.ellipsis,
      ),
      Text(
        'CCS Laboratory Management System',
        style: TextStyle(
          fontWeight: FontWeight.normal,
          color: AppTheme.textSecondary.withOpacity(0.7), // Dimmed for hierarchy
          fontSize: 10, // Small subtext size
          fontFamily: 'Poppins',
        ),
        maxLines: 2, // Allows it to wrap if the sidebar is narrow
        overflow: TextOverflow.ellipsis,
      ),
    ],
  ),
),
  ],
),
          ),

          // Nav items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
              children: navItems.map((item) => _SidebarItem(
                icon: item.icon,
                label: item.label,
                index: item.index,
                selected: provider.selectedIndex == item.index,
                onTap: () => provider.setSelectedIndex(item.index),
              )).toList(),
            ),
          ),

          // User footer
          if (user != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppTheme.border)),
                color: Colors.white,
              ),
              child: Row(
                children: [
                  _UserAvatar(user: user),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.fullName,
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis),
                        Text(user.role.label,
                          style: const TextStyle(color: Color(0xFF64748B), fontSize: 10),
                          overflow: TextOverflow.ellipsis),
                      ],
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

class _NavItem {
  final int index;
  final IconData icon;
  final String label;
  _NavItem(this.index, this.icon, this.label);
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final bool selected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppTheme.sidebarActive : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, color: selected ? Colors.white : const Color(0xFF94A3B8), size: 18),
              const SizedBox(width: 10),
              Text(label,
                style: TextStyle(
                  color: selected ? Colors.white : const Color(0xFF94A3B8),
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                )),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sidebar footer avatar — shows photo if available, falls back to initial ──
class _UserAvatar extends StatefulWidget {
  final UserProfile user;
  const _UserAvatar({required this.user});

  @override
  State<_UserAvatar> createState() => _UserAvatarState();
}

class _UserAvatarState extends State<_UserAvatar> {
  bool _failed = false;

  @override
  void didUpdateWidget(_UserAvatar oldWidget) {
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
      radius: 16,
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
                  color: user.role.color,
                  fontWeight: FontWeight.w700,
                  fontSize: 13),
            )
          : null,
    );
  }
}