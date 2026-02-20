import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

@immutable
class AppToast {
  const AppToast._();

  static Timer? _timer;

  static void show(
    BuildContext context, {
    required String title,
    required String message,
    required IconData icon,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    late final OverlayEntry entry;

    void safeRemove() {
      if (entry.mounted) entry.remove();
    }

    entry = OverlayEntry(
      builder: (_) {
        final mq = MediaQuery.of(context);
        final w = mq.size.width;

        // responsive width with safe margins
        final maxW = math.min(360.0, math.max(240.0, w - 32.0));
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
                    icon: icon,
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

    overlay.insert(entry);

    _timer?.cancel();
    _timer = Timer(duration, safeRemove);
  }
}

class _ToastCard extends StatefulWidget {
  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback onClose;

  const _ToastCard({
    required this.title,
    required this.message,
    required this.icon,
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
          boxShadow: const [
            BoxShadow(
              color: Color(0x140F172A),
              blurRadius: 18,
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
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                widget.icon,
                color: const Color(0xFF0F172A),
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
                        child: Text(widget.actionLabel!.trim()),
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
