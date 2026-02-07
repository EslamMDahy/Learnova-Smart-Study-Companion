import '../../../core/network/api_client.dart';
import '../../../core/network/endpoints.dart';
import 'dto/login_request.dart';
import 'dto/login_response.dart';

class AuthApi {
  final ApiClient _client;
  AuthApi(this._client);

  // ---------------- Auth ----------------

  Future<LoginResponse> login(LoginRequest request) async {
    final res = await _client.post<Map<String, dynamic>>(
      Endpoints.login,
      data: request.toJson(),
    );

    final payload = (res.data ?? const {}).cast<String, dynamic>();
    return LoginResponse.fromJson(payload);
  }

  Future<void> signup({
    required String fullName,
    required String email,
    required String password,
    required String accountType,
    required String systemRole,
    String? inviteCode,
  }) async {
    await _client.post(
      Endpoints.signup,
      data: {
        "full_name": fullName.trim(),
        "email": email.trim(),
        "password": password,
        "account_type": accountType.trim(),
        "system_role": systemRole.trim(),
        if (inviteCode != null && inviteCode.trim().isNotEmpty)
          "invite_code": inviteCode.trim(),
      },
    );
  }

  Future<String> verifyEmail(String token) async {
    final res = await _client.get<Map<String, dynamic>>(
      Endpoints.verifyEmail,
      queryParameters: {"token": token.trim()},
    );
    return _readMessage(res.data);
  }

  // ---------------- Password ----------------

  Future<String> forgotPassword(String email) async {
    final res = await _client.post<Map<String, dynamic>>(
      Endpoints.forgotPassword,
      data: {"email": email.trim()},
    );
    return _readMessage(res.data);
  }

  Future<String> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    final res = await _client.post<Map<String, dynamic>>(
      Endpoints.resetPassword,
      data: {
        "token": token.trim(),
        "new_password": newPassword,
      },
    );
    return _readMessage(res.data);
  }

  // keep /me for later usage if you want, but DON'T use it in login flow
  Future<Map<String, dynamic>> me() async {
    final res = await _client.get<Map<String, dynamic>>(Endpoints.me);
    final data = (res.data ?? const {}).cast<String, dynamic>();
    return data;
  }

  // ---------------- Helpers ----------------

  String _readMessage(Map<String, dynamic>? data) {
    final v = data?['message'] ?? data?['msg'];
    if (v == null) return '';
    return v.toString();
  }
}
