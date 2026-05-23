import 'package:flutter/material.dart';

class AppThemeRuntime {
  AppThemeRuntime._();

  static bool _isDark = false;
  static bool get isDark => _isDark;

  static void setDark(bool value) {
    _isDark = value;
  }
}

class AppColors {
  AppColors._();

  static bool get _dark => AppThemeRuntime.isDark;
  static bool get isDark => _dark;


  static const Color primary = Color(0xFF137FEC);
  static Color get primarySoft => _dark ? Color(0x24137FEC) : Color(0x0D137FEC);

  static Color get pageBg => _dark ? Color(0xFF0F172A) : Color(0xFFF6F7F8);
  static Color get bg => _dark ? Color(0xFF111827) : Color(0xFFF8FAFC);
  static Color get headerBg => _dark ? Color(0xFF1E293B) : Color(0xFFF1F5F9);
  static Color get cardBg => _dark ? Color(0xFF111827) : Colors.white;
  static Color get cardBg24 => _dark ? Color(0x3DFFFFFF) : Color(0x3D000000);
  static Color get surfaceBg => _dark ? Color(0xFF1E293B) : Color(0xFFF9FAFB);
  static Color get surfaceAlt => _dark ? Color(0xFF0F172A) : Color(0xFFFFFFFF);
  static Color get surfaceMuted => _dark ? Color(0xFF1E293B) : Color(0xFFF8FAFC);
  static Color get overlayLight => _dark ? Color(0x1AFFFFFF) : Color(0x0A000000);
  static Color get overlayStrong => _dark ? Color(0x66000000) : Color(0x1A000000);

  static Color get border => _dark ? Color(0xFF334155) : Color(0xFFE2E8F0);
  static Color get borderSoft => _dark ? Color(0xFF475569) : Color(0xFFDBE0E6);
  static Color get borderGray => _dark ? Color(0xFF334155) : Color(0xFFE5E7EB);

  static Color get textTitle => _dark ? Color(0xFFF8FAFC) : Color(0xFF111418);
  static Color get textMuted => _dark ? Color(0xFFCBD5E1) : Color(0xFF617589);
  static Color get textHint => _dark ? Color(0xFF94A3B8) : Color(0xFF9CA3AF);
  static Color get textGray => _dark ? Color(0xFFE5E7EB) : Color(0xFF374151);
  static Color get textGray500 => _dark ? Color(0xFFCBD5E1) : Color(0xFF6B7280);

  static Color get text => _dark ? Color(0xFFE5E7EB) : Color(0xFF1F2937);
  static Color get divider => _dark ? Color(0xFF334155) : Color(0xFFF3F4F6);

  static Color get title => textTitle;
  static Color get muted => textMuted;
  static Color get hint => textHint;
  static Color get card => cardBg;
  static Color get cText => textTitle;
  static Color get cMuted => textMuted;
  static Color get cBg => cardBg;
  static Color get cSurface => surfaceBg;
  static Color get cBorder => border;
  static Color get cBorderSoft => _dark ? Color(0xFF334155) : Color(0xFFF3F4F6);
  static Color get cGray700 => textGray;
  static Color get cGray500 => textGray500;

  static Color get successBg => _dark ? Color(0xFF052E16) : Color(0xFFDCFCE7);
  static const Color successDot = Color(0xFF22C55E);
  static Color get successText => _dark ? Color(0xFF86EFAC) : Color(0xFF166534);

  static Color get dangerBg => _dark ? Color(0xFF450A0A) : Color(0xFFFEF2F2);
  static Color get dangerBorder => _dark ? Color(0xFF7F1D1D) : Color(0xFFFECACA);
  static Color get dangerText => _dark ? Color(0xFFFCA5A5) : Color(0xFFDC2626);
  static Color get dangerTitle => _dark ? Color(0xFFFECACA) : Color(0xFFB91C1C);

  static const Color warningDot = Color(0xFFEAB308);
  static const Color errorDot = Color(0xFFEF4444);

  static Color get badgeBlueBg => _dark ? Color(0xFF172554) : Color(0xFFDBEAFE);
  static Color get badgeBlueBorder => _dark ? Color(0xFF1E3A8A) : Color(0xFFBFDBFE);
  static Color get badgeBlueFg => _dark ? Color(0xFF93C5FD) : Color(0xFF1E40AF);

  static Color get badgePurpleBg => _dark ? Color(0xFF3B0764) : Color(0xFFF3E8FF);
  static Color get badgePurpleBorder => _dark ? Color(0xFF581C87) : Color(0xFFE9D5FF);
  static Color get badgePurpleFg => _dark ? Color(0xFFD8B4FE) : Color(0xFF6B21A8);

  static Color get badgeIndigoBg => _dark ? Color(0xFF1E1B4B) : Color(0xFFE0E7FF);
  static Color get badgeIndigoBorder => _dark ? Color(0xFF312E81) : Color(0xFFC7D2FE);
  static Color get badgeIndigoFg => _dark ? Color(0xFFA5B4FC) : Color(0xFF4338CA);

  static Color get shadowSoft => _dark ? Color(0x66000000) : Color(0x14000000);
  static Color get shadowThin => _dark ? Color(0x52000000) : Color(0x0D000000);
  static Color get shadowBlue => _dark ? Color(0x66137FEC) : Color(0xFFBFDBFE);

  static Color get sidebarBg => _dark ? Color(0xFF0B1220) : Colors.white;
  static Color get sidebarBorder => _dark ? Color(0xFF1E293B) : Color(0xFFE8ECF0);
  static Color get sidebarLabel => _dark ? Color(0xFF94A3B8) : Color(0xFFB0BAC8);
  static Color get sidebarSelectedBg => _dark ? Color(0xFF082F49) : Color(0xFFEBF4FE);
  static Color get sidebarHoverBg => _dark ? Color(0xFF111827) : Colors.transparent;
  static Color get sidebarHoverFg => _dark ? Color(0xFFE2E8F0) : Color(0xFF1E293B);

  static Color get appChromeBg => _dark ? Color(0xFF0B1220) : Colors.white;
  static Color get panelBg => _dark ? Color(0xFF111827) : Colors.white;
  static Color get panelMutedBg => _dark ? Color(0xFF0F172A) : Color(0xFFF8FAFC);
  static Color get rowBg => _dark ? Color(0xFF111827) : Colors.white;
  static Color get rowAltBg => _dark ? Color(0xFF1E293B) : Color(0xFFF9FAFB);

  static Color get hoverBg => _dark ? Color(0xFF1E293B) : Color(0xFFFAFBFC);
  static Color get selectedBg => _dark ? Color(0xFF172554) : Color(0xFFEBF4FE);
  static Color get fieldBg => _dark ? Color(0xFF0F172A) : Colors.white;
  static Color get fieldDisabledBg => _dark ? Color(0xFF1E293B) : Color(0xFFF3F4F6);
  static Color get lightPanelBg => _dark ? Color(0xFF111827) : Color(0xFFF9FAFB);

  static Color get documentStageBg => _dark ? Color(0xFF0B1220) : Colors.white;
  static Color get documentStageHeaderStart => _dark ? Color(0xFF101827) : Color(0xFFF8FAFC);
  static Color get documentStageHeaderEnd => _dark ? Color(0xFF151F32) : Color(0xFFEFF6FF);
  static Color get documentCanvasBg => _dark ? Color(0xFF0F172A) : Color(0xFFF8FAFC);
  static Color get documentCanvasRadial => _dark ? Color(0xFF1A2332) : Color(0xFFEFF6FF);
  static Color get canvasBg => _dark ? Color(0xFF0F172A) : Color(0xFFF6F7F8);

  static Color get infoBg => _dark ? Color(0xFF082F49) : Color(0xFFDBEAFE);
  static Color get infoBorder => _dark ? Color(0xFF075985) : Color(0xFFBFDBFE);
  static Color get infoText => _dark ? Color(0xFF93C5FD) : Color(0xFF1D4ED8);

  static Color get warningBg => _dark ? Color(0xFF451A03) : Color(0xFFFFF7ED);
  static Color get warningSoftBg => _dark ? Color(0xFF422006) : Color(0xFFFFFBEB);
  static Color get warningBorder => _dark ? Color(0xFF92400E) : Color(0xFFFED7AA);
  static Color get warningText => _dark ? Color(0xFFFCD34D) : Color(0xFFEA580C);

  static Color get purpleBg => _dark ? Color(0xFF2E1065) : Color(0xFFF5F3FF);
  static Color get purpleBorder => _dark ? Color(0xFF6D28D9) : Color(0xFFDDD6FE);
  static Color get purpleText => _dark ? Color(0xFFD8B4FE) : Color(0xFF7C3AED);

  static Color get greenBg => successBg;
  static Color get greenBorder => _dark ? Color(0xFF166534) : Color(0xFFBBF7D0);
  static Color get greenText => successText;
}

class AppTextStyles {
  AppTextStyles._();

  static const String _font = 'Inter';

  static TextStyle get h1 => TextStyle(
        fontFamily: _font,
        fontSize: 36,
        fontWeight: FontWeight.w800,
        height: 40 / 36,
        letterSpacing: -0.9,
        color: AppColors.textTitle,
      );

  static TextStyle get h3 => TextStyle(
        fontFamily: _font,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.textTitle,
      );

  static TextStyle get subtitle => TextStyle(
        fontFamily: _font,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 24 / 16,
        color: AppColors.textMuted,
      );

  static TextStyle get sectionTitle => TextStyle(
        fontFamily: _font,
        fontWeight: FontWeight.w700,
        fontSize: 18,
        height: 28 / 18,
        color: AppColors.textTitle,
      );

  static TextStyle get sectionSubtitle => TextStyle(
        fontFamily: _font,
        fontWeight: FontWeight.w400,
        fontSize: 14,
        height: 20 / 14,
        color: AppColors.textMuted,
      );

  static TextStyle get button => TextStyle(
        fontFamily: _font,
        fontWeight: FontWeight.w700,
        fontSize: 14,
        height: 21 / 14,
      );

  static TextStyle get label => TextStyle(
        fontFamily: _font,
        fontWeight: FontWeight.w700,
        fontSize: 14,
        height: 20 / 14,
        color: AppColors.textTitle,
      );

  static TextStyle get input => TextStyle(
        fontFamily: _font,
        fontWeight: FontWeight.w400,
        fontSize: 14,
        height: 19 / 14,
        color: AppColors.textTitle,
      );

  static TextStyle get hint => TextStyle(
        fontFamily: _font,
        fontWeight: FontWeight.w400,
        fontSize: 14,
        height: 19 / 14,
        color: AppColors.textHint,
      );

  static TextStyle get muted => TextStyle(
        fontFamily: _font,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textMuted,
      );

  static TextStyle get mutedSmall => TextStyle(
        fontFamily: _font,
        fontWeight: FontWeight.w400,
        fontSize: 12,
        height: 16 / 12,
        color: AppColors.textMuted,
      );
}

class AppText {
  AppText._();

  static TextStyle get h1 => AppTextStyles.h1;
  static TextStyle get h3 => AppTextStyles.h3;
  static TextStyle get subtitle => AppTextStyles.subtitle;
  static TextStyle get sectionTitle => AppTextStyles.sectionTitle;
  static TextStyle get sectionSubtitle => AppTextStyles.sectionSubtitle;
  static TextStyle get button => AppTextStyles.button;
  static TextStyle get label => AppTextStyles.label;
  static TextStyle get input => AppTextStyles.input;
  static TextStyle get hint => AppTextStyles.hint;
  static TextStyle get muted => AppTextStyles.muted;
  static TextStyle get mutedSmall => AppTextStyles.mutedSmall;
}

class AppSpacing {
  AppSpacing._();

  static const EdgeInsets pagePadding = EdgeInsets.fromLTRB(24, 40, 24, 40);
  static const EdgeInsets notificationsPage = EdgeInsets.fromLTRB(32, 32, 32, 24);
  static const EdgeInsets cardPadding = EdgeInsets.all(32);
  static const EdgeInsets page = pagePadding;

  static const double xs = 4;
  static const double sm = 6;
  static const double md = 8;
  static const double lg = 12;
  static const double xl = 16;
  static const double xl2 = 20;
  static const double xl3 = 24;
  static const double xl4 = 32;

  static const SizedBox gap4 = SizedBox(height: xs);
  static const SizedBox gap6 = SizedBox(height: sm);
  static const SizedBox gap8 = SizedBox(height: md);
  static const SizedBox gap12 = SizedBox(height: lg);
  static const SizedBox gap16 = SizedBox(height: xl);
  static const SizedBox gap20 = SizedBox(height: xl2);
  static const SizedBox gap24 = SizedBox(height: xl3);
  static const SizedBox gap32 = SizedBox(height: xl4);
}

class AppTheme {
  AppTheme._();

  static ThemeData get light => _buildScoped(Brightness.light);
  static ThemeData get dark => _buildScoped(Brightness.dark);

  static ThemeData _buildScoped(Brightness brightness) {
    final previous = AppThemeRuntime.isDark;
    AppThemeRuntime.setDark(brightness == Brightness.dark);
    try {
      return _build(brightness);
    } finally {
      AppThemeRuntime.setDark(previous);
    }
  }

  static ThemeData _build(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;

    final ColorScheme colorScheme = isDark
        ? ColorScheme.dark(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            secondary: Color(0xFF60A5FA),
            surface: Color(0xFF111827),
            onSurface: Color(0xFFF8FAFC),
            outline: Color(0xFF334155),
            error: Color(0xFFFCA5A5),
          )
        : ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            secondary: Color(0xFF2563EB),
            surface: Colors.white,
            onSurface: Color(0xFF111418),
            outline: Color(0xFFE2E8F0),
            error: Color(0xFFDC2626),
          );

    final surface = isDark ? Color(0xFF111827) : Colors.white;
    final elevatedSurface = isDark ? Color(0xFF1E293B) : Colors.white;
    final overlay = isDark ? Colors.white : Colors.black;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      fontFamily: 'Inter',
      scaffoldBackgroundColor: isDark ? Color(0xFF0F172A) : Color(0xFFF6F7F8),
      canvasColor: isDark ? Color(0xFF0F172A) : Color(0xFFF6F7F8),
      cardColor: surface,
      dividerColor: isDark ? Color(0xFF334155) : Color(0xFFE2E8F0),
      disabledColor: isDark ? Color(0xFF64748B) : Color(0xFF9CA3AF),

      appBarTheme: AppBarTheme(
        backgroundColor: elevatedSurface,
        foregroundColor: isDark ? Color(0xFFF8FAFC) : Color(0xFF111418),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Color(0xFFF8FAFC) : Color(0xFF111418)),
        actionsIconTheme: IconThemeData(color: isDark ? Color(0xFFF8FAFC) : Color(0xFF111418)),
        titleTextStyle: AppTextStyles.h3.copyWith(fontSize: 18),
      ),

      iconTheme: IconThemeData(color: isDark ? Color(0xFFCBD5E1) : Color(0xFF617589)),
      primaryIconTheme: IconThemeData(color: isDark ? Color(0xFFF8FAFC) : Color(0xFF111418)),

      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: isDark ? Color(0xFF334155) : Color(0xFFE2E8F0)),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: AppTextStyles.sectionTitle,
        contentTextStyle: AppTextStyles.muted,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: elevatedSurface,
        surfaceTintColor: Colors.transparent,
        textStyle: AppTextStyles.input,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStateProperty.all(elevatedSurface),
          surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
        ),
      ),

      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: AppTextStyles.input,
        inputDecorationTheme: _inputDecorationTheme(isDark),
        menuStyle: MenuStyle(
          backgroundColor: WidgetStateProperty.all(elevatedSurface),
          surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
        ),
      ),

      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: isDark ? Color(0xFF334155) : Color(0xFFE5E7EB),
          disabledForegroundColor: isDark ? Color(0xFF94A3B8) : Color(0xFF9CA3AF),
          textStyle: AppTextStyles.button,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          minimumSize: Size(0, 40),
          elevation: 0,
          splashFactory: NoSplash.splashFactory,
        ).copyWith(
          mouseCursor: WidgetStateProperty.all(SystemMouseCursors.click),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) return overlay.withOpacity(0.08);
            if (states.contains(WidgetState.pressed)) return overlay.withOpacity(0.14);
            return Colors.transparent;
          }),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: isDark ? Color(0xFFF8FAFC) : Color(0xFF111418),
          disabledForegroundColor: isDark ? Color(0xFF94A3B8) : Color(0xFF9CA3AF),
          backgroundColor: surface,
          textStyle: AppTextStyles.button,
          side: BorderSide(color: isDark ? Color(0xFF475569) : Color(0xFFDBE0E6)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          minimumSize: Size(0, 40),
          splashFactory: NoSplash.splashFactory,
        ).copyWith(
          mouseCursor: WidgetStateProperty.all(SystemMouseCursors.click),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) return overlay.withOpacity(0.05);
            return Colors.transparent;
          }),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          disabledForegroundColor: isDark ? Color(0xFF94A3B8) : Color(0xFF9CA3AF),
          splashFactory: NoSplash.splashFactory,
        ).copyWith(
          mouseCursor: WidgetStateProperty.all(SystemMouseCursors.click),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) return AppColors.primary.withOpacity(0.08);
            return Colors.transparent;
          }),
        ),
      ),

      inputDecorationTheme: _inputDecorationTheme(isDark),

      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.primary,
        selectionColor: AppColors.primary.withOpacity(0.28),
        selectionHandleColor: AppColors.primary,
      ),

      textTheme: TextTheme(
        displayLarge: AppTextStyles.h1,
        headlineMedium: AppTextStyles.h3,
        bodyLarge: AppTextStyles.input,
        bodyMedium: AppTextStyles.muted,
        bodySmall: AppTextStyles.mutedSmall,
        labelLarge: AppTextStyles.button,
        labelMedium: AppTextStyles.label,
        titleMedium: AppTextStyles.sectionTitle,
        titleSmall: AppTextStyles.sectionSubtitle,
      ),

      dividerTheme: DividerThemeData(
        color: isDark ? Color(0xFF334155) : Color(0xFFE2E8F0),
        thickness: 1,
        space: 1,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return isDark ? Color(0xFFCBD5E1) : Color(0xFF9CA3AF);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return isDark ? Color(0xFF334155) : Color(0xFFE5E7EB);
        }),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: BorderSide(color: isDark ? Color(0xFF475569) : Color(0xFFDBE0E6)),
      ),

      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return isDark ? Color(0xFF94A3B8) : Color(0xFF9CA3AF);
        }),
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: isDark ? Color(0xFFCBD5E1) : Color(0xFF617589),
        indicatorColor: AppColors.primary,
        dividerColor: isDark ? Color(0xFF334155) : Color(0xFFE2E8F0),
      ),

      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        iconColor: isDark ? Color(0xFFCBD5E1) : Color(0xFF617589),
        textColor: isDark ? Color(0xFFF8FAFC) : Color(0xFF111418),
        subtitleTextStyle: AppTextStyles.muted,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? Color(0xFF1E293B) : Color(0xFF111827),
        contentTextStyle: TextStyle(color: Colors.white),
        actionTextColor: Color(0xFF93C5FD),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static InputDecorationTheme _inputDecorationTheme(bool isDark) {
    return InputDecorationTheme(
      filled: true,
      fillColor: isDark ? Color(0xFF0F172A) : Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      labelStyle: AppTextStyles.label,
      hintStyle: AppTextStyles.hint,
      helperStyle: AppTextStyles.mutedSmall,
      errorStyle: TextStyle(color: AppColors.dangerText, fontSize: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: isDark ? Color(0xFF475569) : Color(0xFFDBE0E6)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: isDark ? Color(0xFF475569) : Color(0xFFDBE0E6)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.dangerText),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.dangerText, width: 1.5),
      ),
    );
  }
}
