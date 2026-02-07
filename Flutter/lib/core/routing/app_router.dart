import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../../core/storage/token_storage.dart';
import '../../core/storage/user_storage.dart';

import '../../features/auth/presentation/pages/forget_password_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/set_new_password_page.dart';
import '../../features/auth/presentation/pages/signup_page.dart';
import '../../features/auth/presentation/pages/verify_email_page.dart';

import '../../features/admin/presentation/pages/admin_dashboard_page.dart';
import '../../shared/pages/home_page.dart';

import 'routes.dart';

final appRouter = GoRouter(
  initialLocation: _initialLocation(),

  // ✅ Re-evaluate when token or stored session changes
  refreshListenable: Listenable.merge([
    TokenStorage.listenable,
    UserStorage.listenable,
  ]),

  redirect: (context, state) {
    final hasToken = TokenStorage.hasToken;
    final path = state.uri.path;

    // ✅ protect verify/reset: token query param required
    if ((path == Routes.verifyEmail || path == Routes.resetPassword) &&
        (state.uri.queryParameters['token'] == null ||
            state.uri.queryParameters['token']!.trim().isEmpty)) {
      return Routes.login;
    }

    final isAuthRoute = _isAuthRoute(path);

    // ❌ not logged in
    if (!hasToken && !isAuthRoute) {
      return Routes.login;
    }

    // ❌ logged in and trying to access auth pages
    // IMPORTANT: don't redirect away from /login until we have loaded `me`.
    // Otherwise token save triggers a router refresh while role is still empty,
    // and the user gets pushed to normal home.
    if (hasToken && isAuthRoute) {
      if (!UserStorage.hasMe) return null;
      return UserStorage.isOwner ? Routes.admin : Routes.home;
    }

    // ✅ Admin guard (owner-only)
    if (path == Routes.admin) {
      if (!UserStorage.hasMe) return null;
      if (!UserStorage.isOwner) return Routes.home;
    }

    return null;
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
  ],
);

String _initialLocation() {
  if (!TokenStorage.hasToken) return Routes.login;

  // لو user data موجودة بالفعل (local/session) نحدد البداية صح.
  if (UserStorage.hasMe && UserStorage.isOwner) return Routes.admin;

  return Routes.home;
}

bool _isAuthRoute(String path) {
  return path == Routes.login ||
      path == Routes.signup ||
      path == Routes.forgotPassword ||
      path == Routes.resetPassword ||
      path == Routes.verifyEmail;
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
}
