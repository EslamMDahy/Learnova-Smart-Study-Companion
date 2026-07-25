class Routes {
  Routes._();

  static const landing = '/';       // Guest entry point (unauthenticated)
  static const home    = '/home';   // Authenticated hub (students / general)

  static const login          = '/login';
  static const signup         = '/signup';
  static const forgotPassword = '/forgot-password';
  static const resetPassword  = '/reset-password';
  static const verifyEmail    = '/verify-email';
  static const verifyEmailSent = '/verify-email-sent';
  static const error          = '/error';
  static const courseInvite   = '/course-invite';

  static const settings = '/settings';

  static const student = '/student';
  static const studentDashboard = '/student/dashboard';
  static const studentCourses = '/student/courses';
  static const studentDiscoverCourses = '/student/discover-courses';
  static const studentCourseDetails = '/student/courses/details';
  static const studentQuestionBank = '/student/question-bank';
  static const studentQuizHistory = '/student/quiz-history';
  static const studentExamAttempt = '/student/exams/attempt';
  static const studentExamResult = '/student/exams/result';
  static const studentRecommendations = '/student/recommendations';
  static const studentSettings = '/student/settings';
  static const studentHelp = '/student/help';
  static const studentNotifications = '/student/notifications';

  static const admin = '/admin';
  static const adminUsers          = '/admin/users';
  static const adminJoinRequests   = '/admin/join-requests';
  static const adminUpgradePlans   = '/admin/upgrade-plans';
  static const adminSettings       = '/admin/settings';
  static const adminHelp           = '/admin/help';
  static const adminNotifications  = '/admin/notifications';

  static const instructor = '/instructor';
  static const instructorDashboard  = '/instructor/dashboard';
  static const instructorCourses    = '/instructor/courses';
  static const instructorCourseDetails  = '/instructor/courses/:courseSlug';
  static const instructorCourseMaterials    = '/instructor/courses/:courseSlug/materials';
  static const instructorCourseOutcomes     = '/instructor/courses/:courseSlug/outcomes';
  static const instructorCourseStudents     = '/instructor/courses/:courseSlug/students';
  static const instructorCourseAnalytics    = '/instructor/courses/:courseSlug/analytics';
  static const instructorCourseQuestionBank = '/instructor/courses/:courseSlug/question-bank';
  static const instructorCourseTemplates    = '/instructor/courses/:courseSlug/templates';
  static const instructorCourseQuizzes      = '/instructor/courses/:courseSlug/exams';
  static const instructorCoursePresentation = '/instructor/courses/:courseSlug/presentation';
  static const instructorQuestionBank  = '/instructor/question-bank';
  static const instructorExamCorrection = '/instructor/exam-correction';
  static const instructorPresentation = '/instructor/presentation';
  static const instructorQuizzesLegacy = '/instructor/quizzes';
  static const instructorQuizzes       = '/instructor/exams';
  static const instructorSettings      = '/instructor/settings';
  static const instructorHelp          = '/instructor/help';
  static const instructorNotifications = '/instructor/notifications';

  // ── Helpers ───────────────────────────────────────────────────────────────
  static const courseMaterialsSegment    = 'materials';
  static const courseOutcomesSegment     = 'outcomes';
  static const courseStudentsSegment     = 'students';
  static const courseAnalyticsSegment    = 'analytics';
  static const courseQuestionBankSegment = 'question-bank';
  static const courseTemplatesSegment    = 'templates';
  static const courseQuizzesSegment      = 'exams';

  static String courseDetails(String slug)      => '/instructor/courses/$slug';
  static String courseMaterials(String slug)    => '/instructor/courses/$slug/materials';
  static String courseOutcomes(String slug)     => '/instructor/courses/$slug/outcomes';
  static String courseStudents(String slug)     => '/instructor/courses/$slug/students';
  static String courseAnalytics(String slug)    => '/instructor/courses/$slug/analytics';
  static String courseQuestionBank(String slug) => '/instructor/courses/$slug/question-bank';
  static String courseTemplates(String slug)    => '/instructor/courses/$slug/templates';
  static String courseQuizzes(String slug)      => '/instructor/courses/$slug/exams';
  static String coursePresentation(
    String slug, {
    required int moduleId,
    required int materialId,
    required Iterable<int> topicIds,
    String? courseTitle,
    String? materialTitle,
    int? materialPageCount,
  }) {
    final query = <String, String>{
      'moduleId': moduleId.toString(),
      'materialId': materialId.toString(),
      'topicIds': topicIds.join(','),
      if (courseTitle != null && courseTitle.trim().isNotEmpty)
        'courseTitle': courseTitle.trim(),
      if (materialTitle != null && materialTitle.trim().isNotEmpty)
        'materialTitle': materialTitle.trim(),
      if (materialPageCount != null && materialPageCount > 0)
        'pageCount': materialPageCount.toString(),
    };
    return Uri(
      path: '/instructor/courses/$slug/presentation',
      queryParameters: query,
    ).toString();
  }

  static String courseInviteFor(String token) =>
      '$courseInvite?token=${Uri.encodeQueryComponent(token)}';

  static String studentExamAttemptFor({
    required int courseId,
    required int examId,
  }) =>
      '$studentExamAttempt?courseId=$courseId&examId=$examId';

  static String studentExamResultFor({
    required int courseId,
    required int examId,
    required int attemptId,
  }) =>
      '$studentExamResult?courseId=$courseId&examId=$examId&attemptId=$attemptId';

  /// Navigate to the "check your email" screen after signup or unverified login.
  static String verifyEmailSentFor(String email) =>
      '$verifyEmailSent?email=${Uri.encodeQueryComponent(email)}';

  /// Navigate to the global error page.
  static String errorPage({
    String type = 'server',
    String? message,
    String? errorId,
  }) {
    final params = <String, String>{'type': type};
    if (message != null) params['msg'] = message;
    if (errorId != null) params['id'] = errorId;
    final query = params.entries
        .map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');
    return '$error?$query';
  }
}
