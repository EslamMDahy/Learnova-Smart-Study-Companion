import '../../../core/network/api_client.dart';
import '../../../core/network/endpoints.dart';
import 'dto/login_request.dart';
import 'dto/login_response.dart';

class AuthApi {
  final ApiClient _client;
  AuthApi(this._client);

  Future<LoginResponse> login(LoginRequest request) async {
    // ✅ لما الـ endpoint يجهز: فك التعليق
    // final res = await _client.post<Map<String, dynamic>>(
    //   Endpoints.login,
    //   data: request.toJson(),
    // );
    // return LoginResponse.fromJson(res.data ?? {});

    await Future.delayed(const Duration(milliseconds: 800));
    return LoginResponse(accessToken: 'fake-token-from-stub');
  }

    Future<void> signup({
    required String fullName,
    required String email,
    required String password,
    }) async {
    // لما endpoint يجهز هنفك تعليق request الحقيقي
    // await _client.post(Endpoints.signup, data: {...});

    await Future.delayed(const Duration(milliseconds: 800));
    }

}
