class Endpoints {
  Endpoints._(); // يمنع عمل instance

  static const _auth = '/auth';

  // ================= AUTH =================
  static const login = '$_auth/login';
  static const signup = '$_auth/register';
  static const forgotPassword = '$_auth/forgot-password';
  static const resetPassword = '$_auth/reset-password';
  static const verifyEmail = '$_auth/verify-email';
}
