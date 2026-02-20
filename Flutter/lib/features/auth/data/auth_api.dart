import 'package:dio/dio.dart';

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

    final payload = (res.data ?? <String, dynamic>{}).cast<String, dynamic>();
    return LoginResponse.fromJson(payload);
  }

  /// ✅ Now matches backend RegisterRequest:
  /// full_name, email, password, system_role
  Future<void> signup({
    required String fullName,
    required String email,
    required String password,
    required String systemRole,
  }) async {
    await _client.post(
      Endpoints.signup,
      data: {
        "full_name": fullName.trim(),
        "email": email.trim(),
        "password": password,
        "system_role": systemRole.trim(),
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
  // ✅ Added CancelToken support for Session Bootstrap (Batch 10)
  Future<Map<String, dynamic>> me({CancelToken? cancelToken}) async {
    final res = await _client.get<Map<String, dynamic>>(
      Endpoints.me,
      cancelToken: cancelToken,
    );
    final data = (res.data ?? <String, dynamic>{}).cast<String, dynamic>();
    return data;
  }

  Future<String> refresh(String refreshToken) async {
    final res = await _client.post<Map<String, dynamic>>(
      Endpoints.refresh,
      data: {"refresh_token": refreshToken},
    );

    final payload = (res.data ?? <String, dynamic>{}).cast<String, dynamic>();
    final root = (payload['data'] is Map<String, dynamic>)
        ? (payload['data'] as Map<String, dynamic>)
        : payload;

    final newToken =
        (root['access_token'] ?? root['token'] ?? root['accessToken'])
            ?.toString();

    if (newToken == null || newToken.trim().isEmpty) {
      throw Exception('Missing access token in refresh response');
    }

    return newToken.trim();
  }

  // ---------------- Helpers ----------------

  String _readMessage(Map<String, dynamic>? data) {
    final v = data?['message'] ?? data?['msg'];
    if (v == null) return '';
    return v.toString();
  }
}
