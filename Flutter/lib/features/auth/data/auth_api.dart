import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/endpoints.dart';
import 'dto/login_request.dart';
import 'dto/login_response.dart';

class AuthApi {
  final ApiClient _client;
  AuthApi(this._client);

  // ─── Auth ─────────────────────────────────────────────────────────────────

  Future<LoginResponse> login(LoginRequest request) async {
    final res = await _client.post<Map<String, dynamic>>(
      Endpoints.login,
      data: request.toJson(),
    );
    final payload = (res.data ?? <String, dynamic>{}).cast<String, dynamic>();
    return LoginResponse.fromJson(payload);
  }

  Future<void> signup({
    required String fullName,
    required String email,
    required String password,
    required String systemRole,
  }) async {
    // ignore: inference_failure_on_function_invocation
    await _client.post(
      Endpoints.signup,
      data: {
        'full_name': fullName.trim(),
        'email': email.trim(),
        'password': password,
        'system_role': systemRole.trim(),
      },
    );
  }

  Future<String> verifyEmail(String token) async {
    final res = await _client.get<Map<String, dynamic>>(
      Endpoints.verifyEmail,
      queryParameters: {'token': token.trim()},
    );
    return _readMessage(res.data);
  }

  /// Resend the verification email.
  /// Backend: POST /auth/send-verification-email  { email }
  Future<String> resendVerificationEmail(String email) async {
    final res = await _client.post<Map<String, dynamic>>(
      Endpoints.resendVerification,
      data: {'email': email.trim()},
    );
    return _readMessage(res.data);
  }

  /// Check if the user's email is verified (no auth required).
  ///
  /// Backend: POST /auth/check-email-verified  { email }
  /// Expected response: { "is_verified": true/false }
  ///
  /// ⚠️  Backend constraint note:
  /// The current backend does NOT have this endpoint. A lightweight addition
  /// is required: `POST /auth/check-email-verified` that accepts { email }
  /// and returns { "is_verified": bool }. It should NOT leak whether the
  /// email exists (return false for unknown emails). Rate-limit recommended.
  /// See technical report for the minimal backend code needed.
  Future<bool> checkEmailVerified(String email) async {
    final res = await _client.post<Map<String, dynamic>>(
      Endpoints.checkEmailVerified,
      data: {'email': email.trim()},
    );
    final payload = (res.data ?? <String, dynamic>{}).cast<String, dynamic>();
    final root = (payload['data'] is Map<String, dynamic>)
        ? payload['data'] as Map<String, dynamic>
        : payload;
    return root['is_verified'] == true;
  }

  // ─── Password ─────────────────────────────────────────────────────────────

  Future<String> forgotPassword(String email) async {
    final res = await _client.post<Map<String, dynamic>>(
      Endpoints.forgotPassword,
      data: {'email': email.trim()},
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
        'token': token.trim(),
        'new_password': newPassword,
      },
    );
    return _readMessage(res.data);
  }

  // ─── Session ──────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> me({CancelToken? cancelToken}) async {
    final res = await _client.get<Map<String, dynamic>>(
      Endpoints.me,
      cancelToken: cancelToken,
    );
    return (res.data ?? <String, dynamic>{}).cast<String, dynamic>();
  }

  Future<String> refresh() async {
    final res = await _client.post<Map<String, dynamic>>(Endpoints.refresh);
    final payload = (res.data ?? <String, dynamic>{}).cast<String, dynamic>();
    final root = (payload['data'] is Map<String, dynamic>)
        ? payload['data'] as Map<String, dynamic>
        : payload;
    final newToken =
        (root['access_token'] ?? root['token'] ?? root['accessToken'])
            ?.toString();
    if (newToken == null || newToken.trim().isEmpty) {
      throw Exception('Missing access token in refresh response');
    }
    return newToken.trim();
  }

  Future<void> logout() async {
    // ignore: inference_failure_on_function_invocation
    await _client.post(Endpoints.logout);
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  String _readMessage(Map<String, dynamic>? data) {
    final v = data?['message'] ?? data?['msg'];
    return v?.toString() ?? '';
  }
}
