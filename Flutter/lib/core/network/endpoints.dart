class Endpoints {
  Endpoints._();

  static const _auth = '/auth';
  static const _orgs = '/organizations';

  // ================= AUTH =================
  static const login = '$_auth/login';
  static const signup = '$_auth/register';
  static const forgotPassword = '$_auth/forgot-password';
  static const resetPassword = '$_auth/reset-password';
  static const verifyEmail = '$_auth/verify-email';
  static const me = '$_auth/me';

  // ============== ORGANIZATIONS ===========
  static const createOrganization = _orgs; // POST /organizations

  static String joinRequests(String organizationId) =>
      '$_orgs/$organizationId/join-requests'; // GET

  static String updateMemberStatus(
    String organizationId,
    String orgMemberId,
  ) =>
      '$_orgs/$organizationId/members/$orgMemberId/status'; // PATCH
}
