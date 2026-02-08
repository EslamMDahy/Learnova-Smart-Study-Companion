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
      ),
    );

    // 1) Save EXACT backend login shape parts we rely on:
    // - user (with system_role)
    // - organizations (only when owner, else empty)
    //
    // IMPORTANT: save user/session BEFORE saving token.
    // TokenStorage.saveToken triggers GoRouter refresh immediately,
    // so we must ensure UserStorage.isOwner is already correct.
    final meToStore = <String, dynamic>{
      'user': {
        'id': res.user?.id,
        // backend uses full_name
        'full_name': res.user?.name,
        'email': res.user?.email,
        'system_role': res.user?.role,
      },
      'organizations': res.organizations
          .map((o) => {
                'id': _toIntOrString(o.id),
                'name': o.name,
              })
          .toList(),
    };

    // 2) OPTIONAL (Front-only): store selected org id if owner has orgs
    // This is NOT from backend; it's just UI convenience.
    if (res.organizations.isNotEmpty) {
      meToStore['selected_organization_id'] =
          _toIntOrString(res.organizations.first.id);
    }

    UserStorage.saveMe(meToStore, persist: persist);

    // 3) save token (backend: access_token)
    TokenStorage.saveToken(
      res.accessToken,
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
