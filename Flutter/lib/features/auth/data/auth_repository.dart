import '../../../core/storage/token_storage.dart';
import '../../../core/storage/user_storage.dart';
import 'auth_api.dart';
import 'dto/login_request.dart';

class AuthRepository {
  final AuthApi _api;
  AuthRepository(this._api);

  // ---------------- Auth ----------------

  Future<void> login({
    required String email,
    required String password,
    required bool persist,
  }) async {
    final res = await _api.login(
      LoginRequest(
        email: email.trim(),
        password: password,
        rememberMe: persist, // ✅ NEW: map persist -> remember_me (backend)
      ),
    );

    // Ensure we store a valid user shape (avoid persisting null id).
    final userId = res.user?.id;
    if (userId == null || userId.trim().isEmpty) {
      throw Exception('Missing user in login response');
    }

    // ✅ Store full user payload (expanded) from login response
    final meToStore = <String, dynamic>{
      'user': res.user!.toJson(),
      'organizations': res.organizations
          .map((o) => {
                'id': _toIntOrString(o.id),
                'name': o.name,
                'description': o.description,
                'logo_url': o.logoUrl,
                'invite_code': o.inviteCode,
                'subscription_status': o.subscriptionStatus,
              })
          .toList(),
    };

    // OPTIONAL (Front-only): store selected org id if owner has orgs
    if (res.organizations.isNotEmpty) {
      meToStore['selected_organization_id'] =
          _toIntOrString(res.organizations.first.id);
    }

    UserStorage.saveMe(meToStore, persist: persist);

    // save token (backend: access_token)
    TokenStorage.saveSession(
      accessToken: res.accessToken,
      refreshToken: res.refreshToken,
      persist: persist,
    );
  }

  dynamic _toIntOrString(String id) {
    final n = int.tryParse(id);
    return n ?? id;
  }

  /// ✅ matches backend register (no account_type, no invite_code)
  Future<void> signup({
    required String fullName,
    required String email,
    required String password,
    required String systemRole,
  }) async {
    await _api.signup(
      fullName: fullName.trim(),
      email: email.trim(),
      password: password,
      systemRole: systemRole,
    );
  }

  Future<String> verifyEmail(String token) {
    return _api.verifyEmail(token);
  }

  // ---------------- Password ----------------

  Future<String> forgotPassword(String email) {
    return _api.forgotPassword(email.trim());
  }

  Future<String> resetPassword({
    required String token,
    required String newPassword,
  }) {
    return _api.resetPassword(
      token: token,
      newPassword: newPassword,
    );
  }

  // ---------------- Session ----------------

  void logout() {
    TokenStorage.clear();
    UserStorage.clear();
  }
}