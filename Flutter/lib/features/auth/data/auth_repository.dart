import '../../../core/storage/token_storage.dart';
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

    TokenStorage.saveToken(
      res.accessToken,
      persist: persist,
    );
  }

  Future<void> signup({
    required String fullName,
    required String email,
    required String password,
    required String accountType,
    required String systemRole,
    String? inviteCode,
  }) async {
    await _api.signup(
      fullName: fullName.trim(),
      email: email.trim(),
      password: password,
      accountType: accountType,
      systemRole: systemRole,
      inviteCode: inviteCode,
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
  }
}
