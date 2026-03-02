class Endpoints {
  Endpoints._();

  static const _auth     = '/auth';
  static const _orgs     = '/organizations';
  static const _settings = '/settings';
  static const _courses  = '/courses';

  // ─── AUTH ────────────────────────────────────────────────────────────────
  static const login               = '$_auth/login';
  static const signup              = '$_auth/register';
  static const logout              = '$_auth/logout';
  static const forgotPassword      = '$_auth/forgot-password';
  static const resetPassword       = '$_auth/reset-password';
  static const verifyEmail         = '$_auth/verify-email';
  static const resendVerification  = '$_auth/send-verification-email'; // existing backend
  static const checkEmailVerified  = '$_auth/check-email-verified';   // NEW — see backend note
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
  static String courseInvitationsUpload(String courseId) =>
      '$_courses/$courseId/invitations/upload';
  static String courseInvitationsSend(String courseId) =>
      '$_courses/$courseId/invitations/send';
  static String courseInvitationsList(String courseId) =>
      '$_courses/$courseId/invitations';

  // ─── MODULES ─────────────────────────────────────────────────────────────
  static String courseModules(int courseId) =>
      '$_courses/$courseId/modules';
  static String createModule(int courseId) =>
      '$_courses/$courseId/modules';

  // ─── MATERIALS ───────────────────────────────────────────────────────────
  static String moduleMaterials(int courseId, int moduleId) =>
      '$_courses/$courseId/modules/$moduleId/materials';
  static String initMaterialUpload(int courseId, int moduleId) =>
      '$_courses/$courseId/modules/$moduleId/materials/init-upload';
  static String confirmMaterialUpload(int materialId) =>
      '/materials/$materialId/confirm-upload';
  static String materialDownloadUrl(int courseId, int moduleId, int materialId) =>
      '$_courses/$courseId/modules/$moduleId/materials/$materialId/download-url';

  // ─── TOPICS ──────────────────────────────────────────────────────────────
  static String moduleTopics(int courseId, int moduleId) =>
      '$_courses/$courseId/modules/$moduleId/topics';

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
