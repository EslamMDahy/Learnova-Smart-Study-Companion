import 'package:go_router/go_router.dart';

import '../../core/storage/token_storage.dart';
import '../../features/auth/presentation/pages/forget_password_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/set_new_password_page.dart';
import '../../features/auth/presentation/pages/signup_page.dart';
import '../../features/auth/presentation/pages/verify_email_page.dart';
import '../../shared/pages/home_page.dart';
import 'routes.dart';

final appRouter = GoRouter(
  initialLocation: TokenStorage.hasToken ? Routes.home : Routes.login,

  redirect: (context, state) {
    final hasToken = TokenStorage.hasToken;

    // الأضمن في التحقق من الراوت الحالي
    final path = state.uri.path;

    // ✅ لو داخل verify/reset من غير token → رجعه للوجين (أو forgot)
    if ((path == Routes.verifyEmail || path == Routes.resetPassword) &&
        (state.uri.queryParameters['token'] == null ||
            state.uri.queryParameters['token']!.trim().isEmpty)) {
      return Routes.login; // أو Routes.forgotPassword لو تحب
    }

    final isAuthRoute = _isAuthRoute(path);

    // لو مش عامل login ومش في auth → وديه login
    if (!hasToken && !isAuthRoute) return Routes.login;

    // لو عامل login وبيحاول يدخل auth routes → وديه home
    if (hasToken && isAuthRoute) return Routes.home;

    return null;
  },

  routes: [
    GoRoute(
      path: Routes.home,
      name: RouteNames.home,
      builder: (context, state) => const HomePage(),
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
  ],
);

bool _isAuthRoute(String path) {
  return path == Routes.login ||
      path == Routes.signup ||
      path == Routes.forgotPassword ||
      path == Routes.resetPassword ||
      path == Routes.verifyEmail;
}

/// ✅ خليك بعيد عن strings
class RouteNames {
  RouteNames._();

  static const home = 'home';
  static const login = 'login';
  static const signup = 'signup';
  static const forgotPassword = 'forgotPassword';
  static const verifyEmail = 'verifyEmail';
  static const resetPassword = 'resetPassword';
}
