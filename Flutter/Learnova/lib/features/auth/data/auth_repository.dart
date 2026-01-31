import '../../../core/storage/token_storage.dart';
import 'auth_api.dart';
import 'dto/login_request.dart';

class AuthRepository {
  final AuthApi _api;
  AuthRepository(this._api);

    Future<void> login({required String email, required String password, required bool persist}) async {
    final res = await _api.login(LoginRequest(email: email, password: password));
    TokenStorage.saveToken(res.accessToken, persist: persist);
    }

    Future<void> signup({
    required String fullName,
    required String email,
    required String password,
    }) async {
    await _api.signup(fullName: fullName, email: email, password: password);
    }


    

  void logout() => TokenStorage.clear();
}
