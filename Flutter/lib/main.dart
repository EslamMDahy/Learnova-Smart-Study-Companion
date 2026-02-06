import 'package:flutter/material.dart';
import 'package:learnova/features/admin/dashboard/admin_dashboard_page.dart';
import 'package:learnova/features/auth/forget_password/forget_password_page.dart';
import 'package:learnova/features/auth/new%20password/set_new_password_page.dart';
import 'package:learnova/features/auth/signup/signup_page.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(const LearnovaApp());
}

class LearnovaApp extends StatelessWidget {
  const LearnovaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,

      home: AdminDashboardPage(),
    );
  }
}
