import 'package:flutter/material.dart';

/// Design tokens (colors/spacing/text).

class AppColors {
  // page backgrounds
  static const pageBg = Color(0xFFF6F7F8);
  static const bg = Color(0xFFF8FAFC);
  static const headerBg = Color(0xFFF1F5F9);


  // surfaces
  static const card = Colors.white;
  static const border = Color(0xFFE2E8F0);
  static const borderSoft = Color(0xFFDBE0E6);

  // text
  static const title = Color(0xFF111418);
  static const muted = Color(0xFF617589);
  static const hint = Color(0xFF9CA3AF);

  // brand
  static const primary = Color(0xFF137FEC);
  static const primarySoft = Color(0x0D137FEC); // rgba(primary, 0.05 تقريبًا)

  // status: success
  static const successBg = Color(0xFFDCFCE7);
  static const successDot = Color(0xFF22C55E);
  static const successText = Color(0xFF166534);

  // status: danger
  static const dangerBg = Color(0xFFFEF2F2);
  static const dangerBorder = Color(0xFFFECACA);
  static const dangerText = Color(0xFFDC2626);
  static const dangerTitle = Color(0xFFB91C1C);

  // shadows
  static const shadowSoft = Color(0x14000000);
  static const shadowThin = Color(0x0D000000);
  static const shadowBlue = Color(0xFFBFDBFE);

  static const cText = Color(0xFF111418);
  static const cMuted = Color(0xFF617589);
  static const cGray700 = Color(0xFF374151);
  static const cGray500 = Color(0xFF6B7280);
  static const cBorder = Color(0xFFE5E7EB);
  static const cBorderSoft = Color(0xFFF3F4F6);
  static const cBg = Color(0xFFFFFFFF);
  static const cSurface = Color(0xFFF9FAFB);
}

class AppSpacing {
  // page padding in Settings
  static const page = EdgeInsets.fromLTRB(24, 40, 24, 40);
  static const notificationsPage = EdgeInsets.fromLTRB(32, 32, 32, 24);
  // cards
  static const cardPadding = EdgeInsets.all(32);

  // gaps
  static const gap4 = SizedBox(height: 4);
  static const gap6 = SizedBox(height: 6);
  static const gap8 = SizedBox(height: 8);
  static const gap12 = SizedBox(height: 12);
  static const gap16 = SizedBox(height: 16);
  static const gap20 = SizedBox(height: 20);
  static const gap24 = SizedBox(height: 24);
  static const gap32 = SizedBox(height: 32);
}

class AppText {
  static const h1 = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w800,
    height: 40 / 36,
    letterSpacing: -0.9,
    color: AppColors.title,
  );

  static const subtitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 24 / 16,
    color: AppColors.muted,
  );

  static const sectionTitle = TextStyle(
    fontWeight: FontWeight.w700,
    fontSize: 18,
    height: 28 / 18,
    color: AppColors.title,
  );

  static const sectionSubtitle = TextStyle(
    fontWeight: FontWeight.w400,
    fontSize: 14,
    height: 20 / 14,
    color: AppColors.muted,
  );

  static const button = TextStyle(
    fontWeight: FontWeight.w700,
    fontSize: 14,
    height: 21 / 14,
  );

  static const label = TextStyle(
    fontWeight: FontWeight.w700,
    fontSize: 14,
    height: 20 / 14,
    color: AppColors.title,
  );

  static const input = TextStyle(
    fontWeight: FontWeight.w400,
    fontSize: 14,
    height: 19 / 14,
    color: AppColors.title,
  );

  static const hint = TextStyle(
    fontWeight: FontWeight.w400,
    fontSize: 14,
    height: 19 / 14,
    color: AppColors.hint,
  );

  static const mutedSmall = TextStyle(
    fontWeight: FontWeight.w400,
    fontSize: 12,
    height: 16 / 12,
    color: AppColors.muted,
  );
}

/// ------------------------------------------------------------
/// Unified Modern Components (canonical)
/// ------------------------------------------------------------
