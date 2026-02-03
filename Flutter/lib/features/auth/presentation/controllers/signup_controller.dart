import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/error_mapper.dart';
import '../../data/auth_api.dart';
import '../../data/auth_repository.dart';

class SignupState {
  final bool loading;
  final String? error;

  const SignupState({this.loading = false, this.error});

  SignupState copyWith({bool? loading, String? error}) =>
      SignupState(loading: loading ?? this.loading, error: error);
}

// Providers
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());
final authApiProvider =
    Provider<AuthApi>((ref) => AuthApi(ref.read(apiClientProvider)));
final authRepoProvider =
    Provider<AuthRepository>((ref) => AuthRepository(ref.read(authApiProvider)));

final signupControllerProvider =
    StateNotifierProvider<SignupController, SignupState>((ref) {
  return SignupController(ref.read(authRepoProvider));
});

class SignupController extends StateNotifier<SignupState> {
  SignupController(this._repo) : super(const SignupState());

  final AuthRepository _repo;

  /// لو عايز تمسح الايرور من الـ UI لما اليوزر يكتب
  void clearError() {
    if (state.error != null) {
      state = state.copyWith(error: null);
    }
  }

  Future<bool> signup({
    required String fullName,
    required String email,
    required String password,
    required String accountType,
    required String systemRole, // ✅ student / instructor / assistant
    String? inviteCode,         // ✅ required only for user
  }) async {
    // لو فيه error قديم امسحه وابدأ لودينج
    state = state.copyWith(loading: true, error: null);

    try {
      await _repo.signup(
        fullName: fullName,
        email: email,
        password: password,
        accountType: accountType,
        systemRole: systemRole,
        inviteCode: inviteCode,
      );

      state = state.copyWith(loading: false, error: null);
      return true;
    } catch (e) {
      state = state.copyWith(loading: false, error: mapApiError(e));
      return false;
    }
  }
}
