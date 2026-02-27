import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/storage/token_storage.dart';
import '../../core/storage/user_storage.dart';
import '../../core/theme/app_theme.dart';

import '../../features/auth/presentation/pages/forget_password_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/set_new_password_page.dart';
import '../../features/auth/presentation/pages/signup_page.dart';
import '../../features/auth/presentation/pages/verify_email_page.dart';

import '../../shared/pages/home_page.dart';
import '../../shared/pages/notifications_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';

import '../../features/admin/presentation/pages/admin_shell.dart';
import '../../features/admin/presentation/pages/admin_route_pages.dart';

import '../../features/instructor/presentation/pages/instructor_shell.dart';
import '../../features/instructor/presentation/pages/instructor_route_pages.dart';
import '../../features/instructor/presentation/widgets/materials_explorer_page.dart';

import 'routes.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: _initialLocationSafe(),
  refreshListenable: Listenable.merge([
    TokenStorage.listenable,
    UserStorage.listenable,
  ]),
  redirect: (context, state) {
    try {
      final path = state.uri.path;
      final isAuthRoute = _isAuthRoute(path);

      if ((path == Routes.verifyEmail || path == Routes.resetPassword) &&
          ((state.uri.queryParameters['token'] ?? '').trim().isEmpty)) {
        return Routes.login;
      }

      final hasToken = TokenStorage.hasToken;

      if (!hasToken && !isAuthRoute) {
        return Routes.login;
      }

      if (hasToken && isAuthRoute) {
        if (!UserStorage.hasMe) return Routes.home;

        if (UserStorage.isOwner) return Routes.adminUsers;
        if (UserStorage.isInstructor) return Routes.instructorDashboard;
        return Routes.home;
      }

      if (path.startsWith(Routes.admin)) {
        if (!UserStorage.hasMe) return null;
        if (!UserStorage.isOwner) return Routes.home;
        if (path == Routes.admin) return Routes.adminUsers;
      }

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
    // --- المسارات العامة ---
    GoRoute(
      path: Routes.home,
      name: RouteNames.home,
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: Routes.settings,
      name: RouteNames.settings,
      builder: (context, state) => const SettingsPage(),
    ),

    // --- مسارات المصادقة ---
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

    // --- شيل الأدمن ---
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

    // --- شيل المدرس ---
    ShellRoute(
      builder: (context, state, child) => InstructorShell(child: child),
      routes: [
        // لوحة التحكم
        GoRoute(
          path: Routes.instructorDashboard, // /instructor/dashboard
          name: RouteNames.instructorDashboard,
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: InstructorDashboardRoutePage()),
        ),
        // قائمة الكورسات
        GoRoute(
          path: Routes.instructorCourses, // /instructor/courses
          name: RouteNames.instructorCourses,
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: InstructorCourseRoutePage()),
        ),

        // تفاصيل الكورس (مع slug)
        GoRoute(
          path: Routes.instructorCourseDetails, // /instructor/courses/:courseSlug
          name: RouteNames.instructorCourseDetails,
          pageBuilder: (context, state) {
            final slug = state.pathParameters['courseSlug']!;
            return NoTransitionPage(
              child: MaterialsExplorerPage(courseSlug: slug),
            );
          },
        ),

        // الإشعارات
        GoRoute(
          path: Routes.instructorNotifications, // /instructor/notifications
          name: RouteNames.instructorNotifications,
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: NotificationsPage()),
        ),
        // الإعدادات
        GoRoute(
          path: Routes.instructorSettings, // /instructor/settings
          name: RouteNames.instructorSettings,
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: SettingsPage()),
        ),
        // بنك الأسئلة العام
        GoRoute(
          path: Routes.instructorQuestionBank, // /instructor/question-bank
          name: RouteNames.instructorQuestionBank,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: _ComingSoonPage(title: "Question Bank"),
          ),
        ),
        // الاختبارات العامة
        GoRoute(
          path: Routes.instructorQuizzes, // /instructor/quizzes
          name: RouteNames.instructorQuizzes,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: _ComingSoonPage(title: "Quizzes"),
          ),
        ),
        // المساعدة
        GoRoute(
          path: Routes.instructorHelp, // /instructor/help
          name: RouteNames.instructorHelp,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: _ComingSoonPage(title: "Help"),
          ),
        ),
      ],
    ),
  ],
);

// --- دوال مساعدة ---
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
  static const instructorCourses = 'instructorCourses';
  static const instructorCourseDetails = 'instructorCourseDetails';
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

  // instructor course sub-pages (نحتفظ بها للتوافق)
  static const instructorCourseMaterials = 'instructorCourseMaterials';
  static const instructorCourseStudents = 'instructorCourseStudents';
  static const instructorCourseAnalytics = 'instructorCourseAnalytics';
  static const instructorCourseQuestionBank = 'instructorCourseQuestionBank';
  static const instructorCourseQuizzes = 'instructorCourseQuizzes';
}

class _ComingSoonPage extends StatelessWidget {
  final String title;
  const _ComingSoonPage({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.pageBg,
      alignment: Alignment.center,
      child: Text(
        "$title (Coming Soon)",
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
    );
  }
}