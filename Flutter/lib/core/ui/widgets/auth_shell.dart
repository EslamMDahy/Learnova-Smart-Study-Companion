import 'package:flutter/material.dart';

class AuthShell extends StatelessWidget {
  const AuthShell({
    super.key,
    required this.form,
    required this.left,
    this.formMaxWidth = 420,
  });

  final Widget form;
  final AuthLeftPanel left;
  final double formMaxWidth;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final isCompact = w < 980; // responsive للويب

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F14),
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1300),
            margin: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: isCompact
                  ? _CompactLayout(left: left, form: form, formMaxWidth: formMaxWidth)
                  : _WideLayout(left: left, form: form, formMaxWidth: formMaxWidth),
            ),
          ),
        ),
      ),
    );
  }
}

class AuthLeftPanel {
  final String? backgroundAsset; // صورة الخلفية
  final Gradient? overlayGradient; // overlay
  final Widget? topLogo; // لوجو/علامة
  final String title;
  final String subtitle;
  final List<String> bullets; // optional
  final Color textColor;

  const AuthLeftPanel({
    this.backgroundAsset,
    this.overlayGradient,
    this.topLogo,
    required this.title,
    required this.subtitle,
    this.bullets = const [],
    this.textColor = Colors.white,
  });
}

class _WideLayout extends StatelessWidget {
  const _WideLayout({
    required this.left,
    required this.form,
    required this.formMaxWidth,
  });

  final AuthLeftPanel left;
  final Widget form;
  final double formMaxWidth;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _LeftPanel(left: left)),
        Expanded(
          child: Container(
            color: Colors.white,
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: formMaxWidth),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                  child: form,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CompactLayout extends StatelessWidget {
  const _CompactLayout({
    required this.left,
    required this.form,
    required this.formMaxWidth,
  });

  final AuthLeftPanel left;
  final Widget form;
  final double formMaxWidth;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        SizedBox(height: 320, child: _LeftPanel(left: left)),
        Container(
          color: Colors.white,
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: formMaxWidth),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: form,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LeftPanel extends StatelessWidget {
  const _LeftPanel({required this.left});

  final AuthLeftPanel left;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (left.backgroundAsset != null)
          Image.asset(left.backgroundAsset!, fit: BoxFit.cover)
        else
          Container(color: const Color(0xFF0A1630)),
        if (left.overlayGradient != null)
          Container(decoration: BoxDecoration(gradient: left.overlayGradient)),
        Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              left.topLogo ?? const SizedBox(height: 24),
              const Spacer(),
              Text(
                left.title,
                style: TextStyle(
                  color: left.textColor,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                left.subtitle,
                style: TextStyle(
                  color: left.textColor.withOpacity(0.85),
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
              if (left.bullets.isNotEmpty) ...[
                const SizedBox(height: 18),
                ...left.bullets.map(
                  (b) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: left.textColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(Icons.check, size: 14, color: left.textColor.withOpacity(0.9)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            b,
                            style: TextStyle(
                              color: left.textColor.withOpacity(0.85),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 18),
            ],
          ),
        ),
      ],
    );
  }
}
