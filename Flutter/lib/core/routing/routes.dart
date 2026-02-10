class Routes {
  static const home = '/';

  static const login = '/login';
  static const signup = '/signup';
  static const forgotPassword = '/forgot-password';
  static const resetPassword = '/reset-password';
  static const verifyEmail = '/verify-email';

  static const settings = '/settings';

  static const admin = '/admin';

  // ✅ Admin children
  static const adminUsers = '/admin/users';
  static const adminJoinRequests = '/admin/join-requests';
  static const adminUpgradePlans = '/admin/upgrade-plans';
  static const adminSettings = '/admin/settings';
  static const adminHelp = '/admin/help';
  static const adminNotifications = '/admin/notifications';

  static const instructor = '/instructor';

  // ✅ Instructor children
  static const instructorDashboard = '/instructor/dashboard';
  static const instructorCourse = '/instructor/course';
  static const instructorQuestionBank = '/instructor/question-bank';
  static const instructorQuizzes = '/instructor/quizzes';
  static const instructorSettings = '/instructor/settings';
  static const instructorHelp = '/instructor/help';
  static const instructorNotifications = '/instructor/notifications';
}