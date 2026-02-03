import '../../../core/network/api_client.dart';
import '../../../core/network/endpoints.dart';
import 'dto/login_request.dart';
import 'dto/login_response.dart';

class AuthApi {
  final ApiClient _client;
  AuthApi(this._client);

  Future<LoginResponse> login(LoginRequest request) async {
    final res = await _client.post<Map<String, dynamic>>(
      Endpoints.login,
      data: request.toJson(),
    );

    return LoginResponse.fromJson(res.data ?? {});
  }

  Future<void> signup({
    required String fullName,
    required String email,
    required String password,
  }) async {
    await _client.post(
      Endpoints.signup,
      data: {
        "full_name": fullName,
        "email": email,
        "password": password,
      },
    );
  }
}
