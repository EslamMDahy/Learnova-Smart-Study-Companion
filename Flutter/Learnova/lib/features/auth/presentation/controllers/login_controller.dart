import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../data/auth_api.dart';
import '../../data/auth_repository.dart';

class LoginState {
  final bool loading;
  final String? error;

  const LoginState({this.loading = false, this.error});

  LoginState copyWith({bool? loading, String? error}) =>
      LoginState(loading: loading ?? this.loading, error: error);
}

// Providers
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());
final authApiProvider = Provider<AuthApi>((ref) => AuthApi(ref.read(apiClientProvider)));
final authRepoProvider = Provider<AuthRepository>((ref) => AuthRepository(ref.read(authApiProvider)));

final loginControllerProvider =
    StateNotifierProvider<LoginController, LoginState>((ref) {
  return LoginController(ref.read(authRepoProvider));
});

class LoginController extends StateNotifier<LoginState> {
  LoginController(this._repo) : super(const LoginState());

  final AuthRepository _repo;

    Future<bool> login(String email, String password, {required bool persist}) async {
    state = state.copyWith(loading: true, error: null);
    try {
        await _repo.login(email: email, password: password, persist: persist);
        state = state.copyWith(loading: false);
        return true;
    } catch (e) {
        state = state.copyWith(loading: false, error: e.toString());
        return false;
    }
    }
}
