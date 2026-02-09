import 'package:flutter/material.dart';

class BaseDashboardShell extends StatelessWidget {
  final Widget sidebar;
  final Widget header;
  final Widget child;

  final double asideWidth;
  final double contentMaxWidth;
  final EdgeInsets contentPadding;
  final Color backgroundColor;
  final Color dividerColor;

  const BaseDashboardShell({
    super.key,
    required this.sidebar,
    required this.header,
    required this.child,
    this.asideWidth = 288,
    this.contentMaxWidth = 1400,
    this.contentPadding =
        const EdgeInsets.symmetric(horizontal: 116, vertical: 32),
    this.backgroundColor = const Color(0xFFF6F7F8),
    this.dividerColor = const Color(0xFFEDF2F7),
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ استخدم asideWidth فعلاً
          SizedBox(width: asideWidth, child: sidebar),

          Expanded(
            child: Container(
              color: backgroundColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(bottom: BorderSide(color: dividerColor)),
                    ),
                    child: header,
                  ),
                  Expanded(
                    child: Padding(
                      padding: contentPadding,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: contentMaxWidth),
                          child: child,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
