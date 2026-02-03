import 'package:flutter/material.dart';

class AuthScaffold extends StatelessWidget {
  final Widget left;
  final Widget right;

  const AuthScaffold({
    super.key,
    required this.left,
    required this.right,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, c) {
          final isDesktop = c.maxWidth >= 900;

          if (!isDesktop) {
            // موبايل/تابلت: نعرض الفورم فقط بعرض الشاشة
            return right;
          }

          // Desktop: نثبت عرض الصفحة عشان مايحصلش “3 بلوكات”
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1400),
              child: Row(
                children: [
                  Expanded(flex: 6, child: left),
                  Expanded(flex: 4, child: right),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
