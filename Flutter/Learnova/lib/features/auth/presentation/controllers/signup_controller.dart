import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../data/auth_api.dart';
import '../../data/auth_repository.dart';

class SignupState {
  final bool loading;
  final String? error;

  const SignupState({this.loading = false, this.error});

  SignupState copyWith({bool? loading, String? error}) =>
      SignupState(loading: loading ?? this.loading, error: error);
}

// Providers (نفس فكرة اللوجين)
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());
final authApiProvider = Provider<AuthApi>((ref) => AuthApi(ref.read(apiClientProvider)));
final authRepoProvider = Provider<AuthRepository>((ref) => AuthRepository(ref.read(authApiProvider)));

final signupControllerProvider =
    StateNotifierProvider<SignupController, SignupState>((ref) {
  return SignupController(ref.read(authRepoProvider));
});

class SignupController extends StateNotifier<SignupState> {
  SignupController(this._repo) : super(const SignupState());

  final AuthRepository _repo;

  Future<bool> signup({
    required String fullName,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(loading: true, error: null);
    try {
      await _repo.signup(fullName: fullName, email: email, password: password);
      state = state.copyWith(loading: false);
      return true;
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
      return false;
    }
  }
}
