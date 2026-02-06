import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ================= PRIMARY COLORS =================

  /// اللون الأساسي للمشروع (الأزرار – العناصر النشطة)
  static const Color primaryBlue = Color(0xFF137FEC);

  /// Hover أو درجات أفتح من الأساسي
  static const Color primaryLight = Color(0xFF4DA3FF);

  /// درجات أغمق (لو احتجناها)
  static const Color primaryDark = Color(0xFF0F6BD0);

  // ================= BACKGROUNDS =================

  /// خلفية الصفحات الرئيسية
  static const Color bodyBackground = Color(0xFFF6F7F8);

  /// خلفية الكروت أو الفورمز
  static const Color surface = Colors.white;

  /// خلفية الحقول
  static const Color inputBackground = Color(0xFFF1F3F5);

  // ================= TEXT COLORS =================

  /// النص الأساسي
  static const Color textPrimary = Colors.black;

  /// النص الثانوي
  static const Color textSecondary = Color(0xFF617589);

  /// نص أبيض
  static const Color textWhite = Colors.white;

  /// Placeholder / Hint
  static const Color hintText = Color(0xFF9AA6B2);

  // ================= SIDEBAR & NAV =================

  /// لون العناصر غير النشطة في الـ Sidebar
  static const Color inactiveItem = Color(0xFF617589);

  /// لون العنصر النشط
  static const Color activeItem = primaryBlue;

  // ================= DIVIDERS & BORDERS =================

  static Color divider = Colors.black.withValues(alpha: .06);
  static Color border = Colors.black.withValues(alpha: .08);

  // ================= STATUS COLORS =================

  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // ================= BUTTON COLORS =================

  static const Color buttonPrimary = primaryBlue;
  static const Color buttonText = Colors.white;

  // ================= ICON COLORS =================

  static const Color iconPrimary = Colors.black;
  static const Color iconSecondary = Color(0xFF617589);

  // ================= SHADOW =================

  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static Color? get inactiveText => null;

  static Color? get primary => null;

  static Color? get darkBackground => null;

  static Color? get lightBackground => null;

  static Color? get bodyBg => null;
}
