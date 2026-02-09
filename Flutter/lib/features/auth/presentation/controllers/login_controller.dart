import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/error_mapper.dart';
import '../../data/auth_providers.dart';
import '../../data/auth_repository.dart';
import 'login_state.dart';

final loginControllerProvider =
    StateNotifierProvider<LoginController, LoginState>(
  (ref) => LoginController(ref),
);

class LoginController extends StateNotifier<LoginState> {
  LoginController(this.ref) : super(const LoginState());

  final Ref ref;

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  void clearError() {
    if (state.error != null) {
      state = state.copyWith(error: null);
    }
  }

  Future<bool> login(
    String email,
    String password, {
    required bool persist,
  }) async {
    // التزم بالـ pattern: امسح error فقط عبر clearError
    clearError();

    state = state.copyWith(loading: true);

    try {
      await _repo.login(
        email: email,
        password: password,
        persist: persist,
      );

      state = state.copyWith(loading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: mapApiError(e),
      );
      return false;
    }
  }
}
