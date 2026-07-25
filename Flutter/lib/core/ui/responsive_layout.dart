import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Shared responsive breakpoints used by the Flutter web UI.
///
/// Keep feature pages using the same thresholds so the app does not switch
/// layouts at different widths on mobile/tablet.
class LearnovaBreakpoints {
  static const double phone = 600;
  static const double tablet = 900;
  static const double desktop = 1200;

  const LearnovaBreakpoints._();
}

extension LearnovaResponsiveContext on BuildContext {
  Size get viewportSize => MediaQuery.sizeOf(this);
  double get viewportWidth => viewportSize.width;
  bool get isPhone => viewportWidth < LearnovaBreakpoints.phone;
  bool get isTabletOrBelow => viewportWidth < LearnovaBreakpoints.tablet;
}

EdgeInsets learnovaPagePaddingForWidth(double width) {
  if (width < 380) return const EdgeInsets.symmetric(horizontal: 12, vertical: 16);
  if (width < LearnovaBreakpoints.phone) {
    return const EdgeInsets.symmetric(horizontal: 16, vertical: 18);
  }
  if (width < LearnovaBreakpoints.tablet) {
    return const EdgeInsets.symmetric(horizontal: 20, vertical: 24);
  }
  return const EdgeInsets.symmetric(horizontal: 32, vertical: 32);
}

int learnovaGridColumns({
  required double width,
  double minTileWidth = 280,
  int maxColumns = 4,
}) {
  final safeWidth = math.max(1, width);
  final count = (safeWidth / minTileWidth).floor();
  return count.clamp(1, maxColumns).toInt();
}

Widget learnovaMaybeScrollableRow({
  required Widget child,
  bool enabled = true,
}) {
  if (!enabled) return child;
  return SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    physics: const BouncingScrollPhysics(),
    child: child,
  );
}
