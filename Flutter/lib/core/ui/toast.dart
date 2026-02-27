import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

enum AppToastType { success, info, warning, error }

@immutable
class AppToast {
  const AppToast._();

  static Timer? _timer;
  static OverlayEntry? _currentEntry;

  static void success(
    BuildContext context, {
    String title = 'Success',
    required String message,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    _show(
      context,
      type: AppToastType.success,
      title: title,
      message: message,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void info(
    BuildContext context, {
    String title = 'Info',
    required String message,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    _show(
      context,
      type: AppToastType.info,
      title: title,
      message: message,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void warning(
    BuildContext context, {
    String title = 'Warning',
    required String message,
    Duration duration = const Duration(seconds: 4),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    _show(
      context,
      type: AppToastType.warning,
      title: title,
      message: message,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void error(
    BuildContext context, {
    String title = 'Error',
    required String message,
    Duration duration = const Duration(seconds: 5),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    _show(
      context,
      type: AppToastType.error,
      title: title,
      message: message,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  /// Backward-compatible API: maps to info toast.
  static void show(
    BuildContext context, {
    required String title,
    required String message,
    required IconData icon,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    // Keep old signature working, but style it as "info".
    _show(
      context,
      type: AppToastType.info,
      title: title,
      message: message,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
      overrideIcon: icon,
    );
  }

  static void _show(
    BuildContext context, {
    required AppToastType type,
    required String title,
    required String message,
    required Duration duration,
    String? actionLabel,
    VoidCallback? onAction,
    IconData? overrideIcon,
  }) {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    // Always remove any previous toast immediately to avoid overlay buildup.
    _timer?.cancel();
    _currentEntry?.remove();
    _currentEntry = null;

    final style = _ToastStyle.forType(type, overrideIcon: overrideIcon);

    late final OverlayEntry entry;

    void safeRemove() {
      if (entry.mounted) entry.remove();
      if (identical(_currentEntry, entry)) {
        _currentEntry = null;
      }
    }

    entry = OverlayEntry(
      builder: (_) {
        final mq = MediaQuery.of(context);
        final w = mq.size.width;

        // responsive width with safe margins
        final maxW = math.min(380.0, math.max(260.0, w - 32.0));
        final isNarrow = w < 520;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Align(
              alignment: isNarrow ? Alignment.topCenter : Alignment.topRight,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxW),
                child: Material(
                  color: Colors.transparent,
                  child: _ToastCard(
                    title: title,
                    message: message,
                    style: style,
                    actionLabel: actionLabel,
                    onAction: onAction,
                    onClose: () {
                      _timer?.cancel();
                      safeRemove();
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    _currentEntry = entry;
    overlay.insert(entry);

    _timer = Timer(duration, safeRemove);
  }
}

class _ToastStyle {
  final Color accent;
  final Color iconBg;
  final Color iconColor;
  final IconData icon;

  const _ToastStyle({
    required this.accent,
    required this.iconBg,
    required this.iconColor,
    required this.icon,
  });

  factory _ToastStyle.forType(AppToastType type, {IconData? overrideIcon}) {
    switch (type) {
      case AppToastType.success:
        return _ToastStyle(
          accent: const Color(0xFF16A34A),
          iconBg: const Color(0xFFDCFCE7),
          iconColor: const Color(0xFF166534),
          icon: overrideIcon ?? Icons.check_circle_outline_rounded,
        );
      case AppToastType.warning:
        return _ToastStyle(
          accent: const Color(0xFFF59E0B),
          iconBg: const Color(0xFFFFF7ED),
          iconColor: const Color(0xFF9A3412),
          icon: overrideIcon ?? Icons.warning_amber_rounded,
        );
      case AppToastType.error:
        return _ToastStyle(
          accent: const Color(0xFFEF4444),
          iconBg: const Color(0xFFFEE2E2),
          iconColor: const Color(0xFF991B1B),
          icon: overrideIcon ?? Icons.error_outline_rounded,
        );
      case AppToastType.info:
        return _ToastStyle(
          accent: const Color(0xFF2563EB),
          iconBg: const Color(0xFFEAF2FF),
          iconColor: const Color(0xFF1D4ED8),
          icon: overrideIcon ?? Icons.info_outline_rounded,
        );
    }
  }
}

class _ToastCard extends StatefulWidget {
  final String title;
  final String message;
  final _ToastStyle style;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback onClose;

  const _ToastCard({
    required this.title,
    required this.message,
    required this.style,
    required this.onClose,
    this.actionLabel,
    this.onAction,
  });

  @override
  State<_ToastCard> createState() => _ToastCardState();
}

class _ToastCardState extends State<_ToastCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  )..forward();

  late final Animation<double> _fade =
      CurvedAnimation(parent: _c, curve: Curves.easeOut);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasAction = widget.actionLabel != null &&
        widget.actionLabel!.trim().isNotEmpty &&
        widget.onAction != null;

    return FadeTransition(
      opacity: _fade,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Color(0x140F172A),
              blurRadius: (kIsWeb ? 10 : 18),
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: widget.style.iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                widget.style.icon,
                color: widget.style.iconColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 13.5,
                            color: Color(0xFF0F172A),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      InkWell(
                        onTap: widget.onClose,
                        borderRadius: BorderRadius.circular(10),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            Icons.close,
                            size: 18,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.message,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF475569),
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                    maxLines: hasAction ? 2 : 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (hasAction) ...[
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () {
                          widget.onClose();
                          widget.onAction?.call();
                        },
                        child: Text(
                          widget.actionLabel!.trim(),
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: widget.style.accent,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
