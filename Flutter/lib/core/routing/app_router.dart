import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/signup_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/forget_password_page.dart';
import '../../features/auth/presentation/pages/verify_email_page.dart';

import '../../core/storage/token_storage.dart';
import '../../shared/pages/home_page.dart';
import 'routes.dart';


final appRouter = GoRouter(
  initialLocation: Routes.login,
  redirect: (context, state) {
    final hasToken = TokenStorage.hasToken;

    final loc = state.matchedLocation;

    final isAuthRoute = loc == Routes.login ||
        loc == Routes.signup ||
        loc == Routes.forgotPassword ||
        loc == Routes.resetPassword ||
        loc == Routes.verifyEmail; // ✅ مهم

    if (!hasToken && !isAuthRoute) return Routes.login;
    if (hasToken && isAuthRoute) return Routes.home;

    return null;
  },
  routes: [
    GoRoute(
      path: Routes.home,
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: Routes.login,
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: Routes.signup,
      builder: (context, state) => const SignUpPage(),
    ),
    GoRoute(
      path: Routes.forgotPassword,
      builder: (context, state) => const ForgetPasswordPage(),
    ),

    // ✅ Verify Email route
    GoRoute(
      path: Routes.verifyEmail,
      builder: (context, state) {
        final token = state.uri.queryParameters['token'];
        return VerifyEmailPage(token: token);
      },
    ),

    GoRoute(
      path: Routes.resetPassword,
      builder: (context, state) {
        final token = state.uri.queryParameters['token'];
        return Scaffold(
          body: Center(child: Text('Reset Password token: $token')),
        );
      },
    ),
  ],
);
