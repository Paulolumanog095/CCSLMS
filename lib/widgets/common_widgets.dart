// lib/widgets/common_widgets.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../theme.dart';

// ============================================================
// APP TOAST  — upper-right slide-in notifications
// ============================================================
/// Usage anywhere in the widget tree:
///   AppToast.show(context, 'Saved!');
///   AppToast.show(context, 'Oops!', type: ToastType.error);
///   AppToast.show(context, 'Heads up', type: ToastType.warning);
enum ToastType { success, error, warning, info }

class AppToast {
  static OverlayEntry? _current;
  static Timer? _timer;

  static void show(
    BuildContext context,
    String message, {
    ToastType type = ToastType.success,
    Duration duration = const Duration(seconds: 3),
  }) {
    _dismiss();
    final overlay = Overlay.of(context, rootOverlay: true);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _ToastWidget(
        message: message,
        type: type,
        onDismiss: _dismiss,
      ),
    );
    _current = entry;
    overlay.insert(entry);
    _timer = Timer(duration, _dismiss);
  }

  static void _dismiss() {
    _timer?.cancel();
    _timer = null;
    _current?.remove();
    _current = null;
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final ToastType type;
  final VoidCallback onDismiss;
  const _ToastWidget({required this.message, required this.type, required this.onDismiss});
  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _slide = Tween<Offset>(begin: const Offset(1.2, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Color get _bgColor {
    switch (widget.type) {
      case ToastType.success: return AppTheme.success;
      case ToastType.error:   return AppTheme.error;
      case ToastType.warning: return AppTheme.warning;
      case ToastType.info:    return AppTheme.primaryLight;
    }
  }

  IconData get _icon {
    switch (widget.type) {
      case ToastType.success: return Icons.check_circle_rounded;
      case ToastType.error:   return Icons.error_rounded;
      case ToastType.warning: return Icons.warning_rounded;
      case ToastType.info:    return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 20,
      right: 20,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 360, minWidth: 240),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: _bgColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: _bgColor.withOpacity(0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_icon, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      widget.message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: widget.onDismiss,
                    child: const Icon(Icons.close_rounded, color: Colors.white70, size: 16),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = AppConstants.statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        AppConstants.formatStatus(status),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? buttonLabel;
  final VoidCallback? onButtonPressed;

  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.buttonLabel,
    this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, size: 40, color: AppTheme.primary),
          ),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14), textAlign: TextAlign.center),
          if (buttonLabel != null && onButtonPressed != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onButtonPressed, child: Text(buttonLabel!)),
          ],
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;

  const SectionHeader({super.key, required this.title, this.subtitle, this.action});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
            if (subtitle != null)
              Text(subtitle!, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
          ],
        ),
        const Spacer(),
        if (action != null) action!,
      ],
    );
  }
}

class LoadingOverlay extends StatelessWidget {
  final Widget child;
  final bool isLoading;

  const LoadingOverlay({super.key, required this.child, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black26,
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}

class ConfirmDialog extends StatelessWidget {
  final String title;
  final String content;
  final String confirmLabel;
  final Color confirmColor;
  final VoidCallback onConfirm;

  const ConfirmDialog({
    super.key,
    required this.title,
    required this.content,
    this.confirmLabel = 'Delete',
    this.confirmColor = AppTheme.error,
    required this.onConfirm,
  });

  static Future<void> show(BuildContext context, {
    required String title,
    required String content,
    String confirmLabel = 'Delete',
    Color confirmColor = AppTheme.error,
    required VoidCallback onConfirm,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => ConfirmDialog(
        title: title,
        content: content,
        confirmLabel: confirmLabel,
        confirmColor: confirmColor,
        onConfirm: () {
          Navigator.pop(ctx);
          onConfirm();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: onConfirm,
          style: ElevatedButton.styleFrom(backgroundColor: confirmColor),
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}