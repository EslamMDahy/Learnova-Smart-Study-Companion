import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/app_error_bus.dart';
import '../../../../core/storage/token_storage.dart';
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
    clearError();

    state = state.copyWith(loading: true);

    try {
      await _repo.login(
        email: email,
        password: password,
        persist: persist,
      );

      state = state.copyWith(loading: false);
      print("TOKEN=${TokenStorage.token}");
      return true;
    } catch (e) {
      final failure = mapApiFailure(e);

      // On auth screens we keep inline error, but if a stale session exists and backend returns auth issue
      // we still trigger global handler to force re-login.
      if (TokenStorage.hasToken && failure.isAuthIssue) {
        state = state.copyWith(loading: false);
        AppErrorReporter.report(ref, failure);
        return false;
      }

      state = state.copyWith(
        loading: false,
        error: failure.message,
      );
      return false;
    }
  }
}
