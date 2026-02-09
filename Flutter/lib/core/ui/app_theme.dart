import 'package:flutter/material.dart';

class AppColors {
  static const bg = Color(0xFFF8FAFC);
  static const card = Colors.white;
  static const border = Color(0xFFE2E8F0);
  static const muted = Color(0xFF64748B);
  static const title = Color(0xFF0F172A);
  static const primary = Color(0xFF2563EB);
  static const headerBg = Color(0xFFF1F5F9);
}

class AppSpacing {
  static const page = EdgeInsets.all(32);
  static const card = EdgeInsets.all(20);
  static const gap12 = SizedBox(width: 12, height: 12);
  static const gap16 = SizedBox(width: 16, height: 16);
  static const gap24 = SizedBox(width: 24, height: 24);
  static const gap32 = SizedBox(width: 32, height: 32);
}

class AppText {
  static const h1 = TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.title);
  static const body = TextStyle(fontSize: 13, color: AppColors.title);
  static const muted = TextStyle(fontSize: 12, color: AppColors.muted);
  static const label = TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.muted, letterSpacing: 0.6);
}
