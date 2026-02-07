import 'dart:async';
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
  }) {
    // maybeOf بيرجع OverlayState? فمش هيعمل dead code
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    late final OverlayEntry entry;

    void safeRemove() {
      if (entry.mounted) entry.remove();
    }

    entry = OverlayEntry(
      builder: (_) => Positioned(
        top: 18,
        right: 18,
        child: Material(
          color: Colors.transparent,
          child: _ToastCard(
            title: title,
            message: message,
            icon: icon,
            onClose: () {
              _timer?.cancel();
              safeRemove();
            },
          ),
        ),
      ),
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
  final VoidCallback onClose;

  const _ToastCard({
    required this.title,
    required this.message,
    required this.icon,
    required this.onClose,
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
    return FadeTransition(
      opacity: _fade,
      child: Container(
        width: 360,
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
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
