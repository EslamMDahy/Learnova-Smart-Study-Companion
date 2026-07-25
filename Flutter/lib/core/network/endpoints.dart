class Endpoints {
  Endpoints._();

  static const _auth     = '/auth';
  static const _orgs     = '/organizations';
  static const _settings = '/settings';
  static const _courses  = '/courses';
  static const _ocr      = '/ocr';

  // ─── AUTH ────────────────────────────────────────────────────────────────
  static const login               = '$_auth/login';
  static const signup              = '$_auth/register';
  static const logout              = '$_auth/logout';
  static const forgotPassword      = '$_auth/forgot-password';
  static const resetPassword       = '$_auth/reset-password';
  static const verifyEmail         = '$_auth/verify-email';
  static const resendVerification  = '$_auth/send-verification-email';
  static const checkEmailVerified  = '$_auth/check-email-verified';
  static const me                  = '$_auth/me';
  static const refresh             = '$_auth/refresh';

  // ─── ORGANIZATIONS ───────────────────────────────────────────────────────
  static const createOrganization = _orgs;
  static String joinRequests(String organizationId) =>
      '$_orgs/$organizationId/join-requests';
  static String updateMemberStatus(String organizationId, String orgMemberId) =>
      '$_orgs/$organizationId/members/$orgMemberId/status';

  // ─── COURSES ─────────────────────────────────────────────────────────────
  static const createCourse = _courses;
  static const myCourses    = '$_courses/my';
  static String courseCoverInitiate(int courseId) =>
      '$_courses/$courseId/cover/initiate';
  static String courseCoverConfirm(int courseId) =>
      '$_courses/$courseId/cover/confirm';
  static String updateCourse(int courseId) =>
      '$_courses/$courseId';
  static String publishCourse(int courseId) =>
      '$_courses/$courseId/publish';
  static String courseEnrollmentRequests(int courseId) =>
      '$_courses/$courseId/enrollment-requests';
  static String updateCourseEnrollmentRequest(int courseId, int enrollmentId) =>
      '$_courses/$courseId/enrollment-requests/$enrollmentId';
  // The uploaded FastAPI router currently also exposes these doubled paths
  // because its router prefix is /courses and the route path starts with /courses.
  static String courseCoverInitiateLegacy(int courseId) =>
      '$_courses/courses/$courseId/cover/initiate';
  static String courseCoverConfirmLegacy(int courseId) =>
      '$_courses/courses/$courseId/cover/confirm';
  static const courseSearch = '$_courses/search';
  static const courseSearchAutocomplete = '$_courses/search/autocomplete';
  static String enrollCourse(int courseId) =>
      '$_courses/$courseId/enroll';
  static String courseInvitationsUpload(String courseId) =>
      '$_courses/$courseId/invitations/upload';
  static String courseInvitationsSend(String courseId) =>
      '$_courses/$courseId/invitations/send';
  static String courseInvitationsList(String courseId) =>
      '$_courses/$courseId/invitations';
  static const acceptCourseInvitation = '$_courses/invitations/accept';

  // ─── MODULES ─────────────────────────────────────────────────────────────
  static String courseModules(int courseId) =>
      '$_courses/$courseId/modules';
  static String createModule(int courseId) =>
      '$_courses/$courseId/modules';
  static String updateModule(int courseId, int moduleId) =>
      '$_courses/$courseId/modules/$moduleId/update';
  static String deleteModule(int courseId, int moduleId) =>
      '$_courses/$courseId/modules/$moduleId/delete';
  static String copyModule(int courseId, int moduleId) =>
      '$_courses/$courseId/modules/$moduleId/copy';
  static String reorderModules(int courseId) =>
      '$_courses/$courseId/modules/reorder';

  // ─── MATERIALS ───────────────────────────────────────────────────────────
  static String moduleMaterials(int courseId, int moduleId) =>
      '$_courses/$courseId/modules/$moduleId/materials';
  static String initMaterialUpload(int courseId, int moduleId) =>
      '$_courses/$courseId/modules/$moduleId/materials/init-upload';
  static String confirmMaterialUpload(int materialId) =>
      '/materials/$materialId/confirm-upload';
  static String materialDownloadUrl(int courseId, int moduleId, int materialId) =>
      '$_courses/$courseId/modules/$moduleId/materials/$materialId/download-url';
  static String contentStructureGenerationStream(int courseId, int materialId) =>
      '$_courses/$courseId/materials/$materialId/content-structure/stream';
  static String generatePresentation(int courseId, int materialId) =>
      '$_courses/$courseId/materials/$materialId/presentations/generate';
  static String presentationGenerationStream(int courseId, int materialId) =>
      '$_courses/$courseId/materials/$materialId/presentations/stream';
  static String presentationGenerationResult(int courseId, int materialId) =>
      '$_courses/$courseId/materials/$materialId/presentations/result';
  static String deleteMaterial(int courseId, int moduleId, int materialId) =>
      '$_courses/$courseId/modules/$moduleId/materials/$materialId';
  static String reassignMaterial(int materialId) =>
      '/$materialId/reassign';

  // ─── TOPICS ──────────────────────────────────────────────────────────────
  static String materialTopics(int courseId, int moduleId, int materialId) =>
      '$_courses/$courseId/modules/$moduleId/materials/$materialId/topics';
  static String getTopic(int courseId, int moduleId, int materialId, int topicId) =>
      '$_courses/$courseId/modules/$moduleId/materials/$materialId/topics/$topicId';
  static String updateTopic(int courseId, int moduleId, int materialId, int topicId) =>
      '$_courses/$courseId/modules/$moduleId/materials/$materialId/topics/$topicId/update';
  static String deleteTopic(int courseId, int moduleId, int materialId, int topicId) =>
      '$_courses/$courseId/modules/$moduleId/materials/$materialId/topics/$topicId/delete';
  static String reorderTopics(int courseId, int moduleId, int materialId) =>
      '$_courses/$courseId/modules/$moduleId/materials/$materialId/topics/reorder';

  // ─── LEARNING OUTCOMES ───────────────────────────────────────────────────
  // Base: /courses/{course_id}/learning-outcomes
  static String learningOutcomes(int courseId) =>
      '$_courses/$courseId/learning-outcomes';
  static String getLearningOutcome(int courseId, int outcomeId) =>
      '$_courses/$courseId/learning-outcomes/$outcomeId';
  static String updateLearningOutcome(int courseId, int outcomeId) =>
      '$_courses/$courseId/learning-outcomes/$outcomeId/update';
  static String deleteLearningOutcome(int courseId, int outcomeId) =>
      '$_courses/$courseId/learning-outcomes/$outcomeId/delete';

  // ─── QUESTIONS ───────────────────────────────────────────────────────────
  static String courseQuestions(int courseId) =>
      '$_courses/$courseId/questions';
  static String courseQuestion(int courseId, int questionId) =>
      '$_courses/$courseId/questions/$questionId';
  static String updateCourseQuestion(int courseId, int questionId) =>
      '$_courses/$courseId/questions/$questionId/update';
  static String batchCreateQuestions(int courseId, int moduleId, int materialId) =>
      '$_courses/$courseId/modules/$moduleId/materials/$materialId/questions';
  static String moduleQuestions(int courseId, int moduleId) =>
      '$_courses/$courseId/modules/$moduleId/questions';
  static String materialQuestions(int courseId, int moduleId, int materialId) =>
      '$_courses/$courseId/modules/$moduleId/materials/$materialId/questions';
  static String topicQuestions(int courseId, int moduleId, int materialId, int topicId) =>
      '$_courses/$courseId/modules/$moduleId/materials/$materialId/topics/$topicId/questions';
  static String approveTopicQuestions(
    int courseId,
    int moduleId,
    int materialId,
    int topicId,
  ) =>
      '$_courses/$courseId/modules/$moduleId/materials/$materialId/topics/$topicId/questions/approve';
  static String aiGenerateQuestions(int courseId) =>
      '$_courses/$courseId/questions/ai-generate';
  static String aiQuestionGenerationStream(int courseId) =>
      '$_courses/$courseId/questions/generation/stream';
  static String extractNativeMaterialQuestions(int courseId, int materialId) =>
      '$_courses/$courseId/materials/$materialId/questions/extract-native';
  static String extractNativeMaterialQuestionsStream(int courseId, int materialId) =>
      '$_courses/$courseId/materials/$materialId/questions/extract-native/stream';
  static String requestQuestionBankExport(int courseId) =>
      '$_courses/$courseId/questions/export';
  static String questionBankExportStream(int courseId, String jobId) =>
      '$_courses/$courseId/questions/export/$jobId/stream';
  static String questionBankExportDownload(int courseId, String jobId) =>
      '$_courses/$courseId/questions/export/$jobId/download';

  // ─── EXAMS ───────────────────────────────────────────────────────────────
  static String courseExams(int courseId) =>
      '$_courses/$courseId/exams/instructor';
  static String exam(int courseId, int examId) =>
      '$_courses/$courseId/exams/instructor/$examId';
  static String updateExam(int courseId, int examId) =>
      '$_courses/$courseId/exams/instructor/$examId';
  static String examSections(int courseId, int examId) =>
      '$_courses/$courseId/exams/instructor/$examId/sections';
  static String reorderExamSections(int courseId, int examId) =>
      '$_courses/$courseId/exams/instructor/$examId/sections/reorder';
  static String examSection(int courseId, int examId, int sectionId) =>
      '$_courses/$courseId/exams/instructor/$examId/sections/$sectionId';
  static String examSectionQuestions(int courseId, int examId, int sectionId) =>
      '$_courses/$courseId/exams/instructor/$examId/sections/$sectionId/questions';
  static String reorderExamQuestions(int courseId, int examId, int sectionId) =>
      '$_courses/$courseId/exams/instructor/$examId/sections/$sectionId/questions/reorder';
  static String examSectionQuestion(int courseId, int examId, int sectionId, int examQuestionId) =>
      '$_courses/$courseId/exams/instructor/$examId/sections/$sectionId/questions/$examQuestionId';
  static String publishExam(int courseId, int examId) =>
      '$_courses/$courseId/exams/instructor/$examId/publish';
  static String exportExamPdf(int courseId, int examId) =>
      '$_courses/$courseId/exams/instructor/$examId/export/pdf';

  // ─── STUDENT EXAMS ──────────────────────────────────────────────────────
  static String studentExams(int courseId) =>
      '$_courses/$courseId/exams/student/exams';
  static String startStudentExamAttempt(int courseId, int examId) =>
      '$_courses/$courseId/exams/student/exams/$examId/attempt';
  static String studentExamAttempts(int courseId, int examId) =>
      '$_courses/$courseId/exams/$examId/attempts';
  static String studentExamAttemptResult(int courseId, int examId, int attemptId) =>
      '$_courses/$courseId/exams/$examId/attempt/$attemptId/result';
  static String submitStudentExamAnswer(int courseId, int examId, int attemptId) =>
      '$_courses/$courseId/exams/student/exams/$examId/attempts/$attemptId/answers';
  static String submitStudentExam(int courseId, int examId, int attemptId) =>
      '$_courses/$courseId/exams/student/exams/$examId/attempts/$attemptId/submit';

  // ─── EXAM TEMPLATES ─────────────────────────────────────────────────────
  static String examTemplates(int courseId) =>
      '$_courses/$courseId/exams/instructor/templates';
  static String examTemplate(int courseId, int templateId) =>
      '$_courses/$courseId/exams/instructor/templates/$templateId';
  static String examTemplateSections(int courseId, int templateId) =>
      '$_courses/$courseId/exams/instructor/templates/$templateId/sections';
  static String examTemplateSection(int courseId, int templateId, int sectionId) =>
      '$_courses/$courseId/exams/instructor/templates/$templateId/sections/$sectionId';
  static String generateExamFromTemplate(int courseId, int templateId) =>
      '$_courses/$courseId/exams/instructor/templates/$templateId/generate-exam';



  // ─── STUDENT COURSE ASSISTANT / AI CHAT ────────────────────────────────
  static String aiChatSessions(int courseId) =>
      '$_courses/$courseId/ai-chat/sessions';
  static String aiChatSession(int courseId, int sessionId) =>
      '$_courses/$courseId/ai-chat/sessions/$sessionId';
  static String aiChatSessionMessages(int courseId, int sessionId) =>
      '$_courses/$courseId/ai-chat/sessions/$sessionId/messages';
  static String aiChatMessageStream(
    int courseId,
    int sessionId,
    int messageId,
  ) =>
      '$_courses/$courseId/ai-chat/sessions/$sessionId/messages/$messageId/stream';

  // ─── OCR / EXAM CORRECTION ─────────────────────────────────────────────
  static const examCorrection = '$_ocr/exam-correction';
  static const examScanAnalyze = '$_ocr/exam-scan/analyze';
  static const examScanSubmit = '$_ocr/exam-scan/submit';
  static String examScanAttemptResult(int attemptId) => '$_ocr/exam-scan/attempts/$attemptId/result';
  static const ocrHealth = '$_ocr/health';

  // ─── SETTINGS ────────────────────────────────────────────────────────────
  static const updateProfile     = '$_settings/profile';
  static const updatePassword    = '$_settings/password';
  static const deleteRequest     = '$_settings/delete/request';
  static const deleteConfirm     = '$_settings/delete/confirm';
  static const getPreferences    = '$_settings/preferences';
  static const updatePreferences = '$_settings/preferences';
  static const avatarUploadUrl   = '$_settings/avatar/upload-url';
  static const avatarConfirm     = '$_settings/avatar/confirm';
}
