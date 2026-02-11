import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/storage/token_storage.dart';
import '../../core/storage/user_storage.dart';

import '../../features/auth/presentation/pages/forget_password_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/set_new_password_page.dart';
import '../../features/auth/presentation/pages/signup_page.dart';
import '../../features/auth/presentation/pages/verify_email_page.dart';

import '../../shared/pages/home_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';

// ✅ Admin shell + contents
import '../../features/admin/presentation/pages/admin_shell.dart';
import '../../features/admin/presentation/pages/admin_route_pages.dart';

// ✅ Instructor shell + contents
import '../../features/instructor/presentation/pages/instructor_shell.dart';
import '../../features/instructor/presentation/pages/instructor_route_pages.dart';

import 'routes.dart';

final appRouter = GoRouter(
  // 💡 نصيحة: غيرها لـ Routes.instructorDashboard مؤقتاً لو عايز تفتح عليها علطول للتيست
  initialLocation: _initialLocationSafe(),

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
      if (hasToken && isAuthRoute) {
        if (!UserStorage.hasMe) return null;

        if (UserStorage.isOwner) return Routes.adminUsers;
        if (UserStorage.isInstructor) return Routes.instructorDashboard;
        return Routes.home;
      }

      // ✅ Admin guard (owner-only)
      if (path.startsWith(Routes.admin)) {
        if (!UserStorage.hasMe) return null;
        if (!UserStorage.isOwner) return Routes.home;
        if (path == Routes.admin) return Routes.adminUsers;
      }

      // ✅ Instructor guard (instructor-only)
      if (path.startsWith(Routes.instructor)) {
        if (!UserStorage.hasMe) return null;

        if (!UserStorage.isInstructor) {
          if (UserStorage.isOwner) return Routes.adminUsers;
          return Routes.home;
        }

        if (path == Routes.instructor) return Routes.instructorDashboard;
      }

      return null;
    } catch (_) {
      _clearSessionSafe();
      return Routes.login;
    }
  },

  routes: [
    // --- Auth Routes ---
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

    // --- Common Routes ---
    GoRoute(
      path: Routes.settings,
      name: RouteNames.settings,
      builder: (context, state) => const SettingsPage(),
    ),

    // --- Admin Shell ---
    ShellRoute(
      builder: (context, state, child) => AdminShell(child: child),
      routes: [
        GoRoute(
          path: Routes.adminUsers,
          name: RouteNames.adminUsers,
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: AdminUsersRoutePage()),
        ),
        GoRoute(
          path: Routes.adminJoinRequests,
          name: RouteNames.adminJoinRequests,
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: AdminJoinRequestsRoutePage()),
        ),
        GoRoute(
          path: Routes.adminUpgradePlans,
          name: RouteNames.adminUpgradePlans,
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: AdminUpgradePlansRoutePage()),
        ),
        GoRoute(
          path: Routes.adminSettings,
          name: RouteNames.adminSettings,
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: AdminSettingsRoutePage()),
        ),
        GoRoute(
          path: Routes.adminHelp,
          name: RouteNames.adminHelp,
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: AdminHelpRoutePage()),
        ),
        GoRoute(
          path: Routes.adminNotifications,
          name: RouteNames.adminNotifications,
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: AdminNotificationsRoutePage()),
        ),
      ],
    ),

    // --- Instructor Shell ---
    ShellRoute(
      builder: (context, state, child) => InstructorShell(child: child),
      routes: [
        GoRoute(
          path: Routes.instructorDashboard,
          name: RouteNames.instructorDashboard,
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: InstructorDashboardRoutePage()),
        ),
        GoRoute(
          path: Routes.instructorCourse,
          name: RouteNames.instructorCourse,
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: InstructorCourseRoutePage()),
        ),
        GoRoute(
          path: Routes.instructorQuestionBank,
          name: RouteNames.instructorQuestionBank,
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: InstructorQuestionBankRoutePage()),
        ),
        GoRoute(
          path: Routes.instructorQuizzes,
          name: RouteNames.instructorQuizzes,
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: InstructorQuizzesRoutePage()),
        ),
        GoRoute(
          path: Routes.instructorSettings,
          name: RouteNames.instructorSettings,
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: InstructorSettingsRoutePage()),
        ),
        GoRoute(
          path: Routes.instructorHelp,
          name: RouteNames.instructorHelp,
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: InstructorHelpRoutePage()),
        ),
        GoRoute(
          path: Routes.instructorNotifications,
          name: RouteNames.instructorNotifications,
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: InstructorNotificationsRoutePage()),
        ),
      ],
    ),
  ],
);

// --- Helpers ---

String _initialLocationSafe() {
  
  try {
    if (!TokenStorage.hasToken) return Routes.login;
    if (UserStorage.hasMe && UserStorage.isOwner) return Routes.adminUsers;
    if (UserStorage.hasMe && UserStorage.isInstructor) {
      return Routes.instructorDashboard;
    }
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
  static const settings = 'settings';

  // instructor
  static const instructorDashboard = 'instructorDashboard';
  static const instructorCourse = 'instructorCourse';
  static const instructorQuestionBank = 'instructorQuestionBank';
  static const instructorQuizzes = 'instructorQuizzes';
  static const instructorSettings = 'instructorSettings';
  static const instructorHelp = 'instructorHelp';
  static const instructorNotifications = 'instructorNotifications';

  // admin
  static const adminUsers = 'adminUsers';
  static const adminJoinRequests = 'adminJoinRequests';
  static const adminUpgradePlans = 'adminUpgradePlans';
  static const adminSettings = 'adminSettings';
  static const adminHelp = 'adminHelp';
  static const adminNotifications = 'adminNotifications';
}
