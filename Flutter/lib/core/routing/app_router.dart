import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';


import '../../core/storage/token_storage.dart';
import '../../core/storage/user_storage.dart';

import '../../features/auth/presentation/pages/forget_password_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/set_new_password_page.dart';
import '../../features/auth/presentation/pages/signup_page.dart';
import '../../features/auth/presentation/pages/verify_email_page.dart';

import '../../features/admin/presentation/pages/admin_dashboard_page.dart';
import '../../features/instructor/presentation/pages/instructor_dashboard_page.dart';
import '../../shared/pages/home_page.dart';

import 'routes.dart';

final appRouter = GoRouter(
  initialLocation: _initialLocationSafe(),

  // ✅ Re-evaluate when token or stored session changes
  refreshListenable: Listenable.merge([
    TokenStorage.listenable,
    UserStorage.listenable,
  ]),

  redirect: (context, state) {
    try {
      final path = state.uri.path;
      final isAuthRoute = _isAuthRoute(path);

      // ✅ protect verify/reset: token query param required
      if ((path == Routes.verifyEmail || path == Routes.resetPassword) &&
          ((state.uri.queryParameters['token'] ?? '').trim().isEmpty)) {
        return Routes.login;
      }

      final hasToken = TokenStorage.hasToken;

      // ❌ not logged in
      if (!hasToken && !isAuthRoute) {
        return Routes.login;
      }

      // ❌ logged in and trying to access auth pages
      // IMPORTANT: don't redirect away from /login until we have loaded `me`.
      if (hasToken && isAuthRoute) {
        if (!UserStorage.hasMe) return null;

        if (UserStorage.isOwner) return Routes.admin;
        if (UserStorage.isInstructor) return Routes.instructor;
        return Routes.home;
      }

      // ✅ Admin guard (owner-only)
      if (path == Routes.admin) {
        if (!UserStorage.hasMe) return null;
        if (!UserStorage.isOwner) return Routes.home;
      }

      // ✅ Instructor guard (instructor-only)
      if (path == Routes.instructor) {
        if (!UserStorage.hasMe) return null;

        if (!UserStorage.isInstructor) {
          // Owners go to admin, others go home
          if (UserStorage.isOwner) return Routes.admin;
          return Routes.home;
        }
      }

      return null;
    } catch (_) {
      // ✅ if storage parsing/reading failed -> treat as invalid session
      _clearSessionSafe();
      return Routes.login;
    }
  },

  routes: [
    GoRoute(
      path: Routes.home,
      name: RouteNames.home,
      builder: (context, state) {
        // ✅ Decide landing based on stored login payload (no /me needed)
        if (UserStorage.isOwner) {
          return const AdminDashboardPage();
        }
        if (UserStorage.isInstructor) {
          return const InstructorDashboardPage();
        }
        return const HomePage();
      },
    ),

    GoRoute(
      path: Routes.login,
      name: RouteNames.login,
      builder: (context, state) => const LoginPage(),
    ),

    GoRoute(
      path: Routes.signup,
      name: RouteNames.signup,
      builder: (context, state) => const SignUpPage(),
    ),

    GoRoute(
      path: Routes.forgotPassword,
      name: RouteNames.forgotPassword,
      builder: (context, state) => const ForgetPasswordPage(),
    ),

    GoRoute(
      path: Routes.verifyEmail,
      name: RouteNames.verifyEmail,
      builder: (context, state) {
        final token = state.uri.queryParameters['token'];
        return VerifyEmailPage(token: token);
      },
    ),

    GoRoute(
      path: Routes.resetPassword,
      name: RouteNames.resetPassword,
      builder: (context, state) {
        final token = state.uri.queryParameters['token'];
        return SetNewPasswordPage(token: token);
      },
    ),

    GoRoute(
      path: Routes.admin,
      name: RouteNames.admin,
      builder: (context, state) => const AdminDashboardPage(),
    ),

    GoRoute(
      path: Routes.instructor,
      name: RouteNames.instructor,
      builder: (context, state) => const InstructorDashboardPage(),
    ),
  ],
);

String _initialLocationSafe() {
  try {
    if (!TokenStorage.hasToken) return Routes.login;

    // لو user data موجودة بالفعل (local/session) نحدد البداية صح.
    if (UserStorage.hasMe && UserStorage.isOwner) return Routes.admin;
    if (UserStorage.hasMe && UserStorage.isInstructor) return Routes.instructor;

    return Routes.home;
  } catch (_) {
    _clearSessionSafe();
    return Routes.login;
  }
}

bool _isAuthRoute(String path) {
  return path == Routes.login ||
      path == Routes.signup ||
      path == Routes.forgotPassword ||
      path == Routes.resetPassword ||
      path == Routes.verifyEmail;
}

void _clearSessionSafe() {
  try {
    TokenStorage.clear();
  } catch (_) {}
  try {
    UserStorage.clear();
  } catch (_) {}
}

class RouteNames {
  RouteNames._();

  static const home = 'home';
  static const login = 'login';
  static const signup = 'signup';
  static const forgotPassword = 'forgotPassword';
  static const verifyEmail = 'verifyEmail';
  static const resetPassword = 'resetPassword';
  static const admin = 'admin';
  static const instructor = 'instructor';
}
