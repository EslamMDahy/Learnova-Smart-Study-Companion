import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/error_mapper.dart';
import '../../data/auth_api.dart';
import '../../data/auth_repository.dart';

class VerifyEmailState {
  final bool loading;
  final bool success;
  final String? error;

  const VerifyEmailState({
    this.loading = false,
    this.success = false,
    this.error,
  });

  VerifyEmailState copyWith({
    bool? loading,
    bool? success,
    String? error,
  }) {
    return VerifyEmailState(
      loading: loading ?? this.loading,
      success: success ?? this.success,
      error: error ?? this.error,
    );
  }
}

// Providers
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());
final authApiProvider =
    Provider<AuthApi>((ref) => AuthApi(ref.read(apiClientProvider)));
final authRepoProvider =
    Provider<AuthRepository>((ref) => AuthRepository(ref.read(authApiProvider)));

final verifyEmailControllerProvider =
    StateNotifierProvider<VerifyEmailController, VerifyEmailState>((ref) {
  return VerifyEmailController(ref.read(authRepoProvider));
});

class VerifyEmailController extends StateNotifier<VerifyEmailState> {
  VerifyEmailController(this._repo) : super(const VerifyEmailState());

  final AuthRepository _repo;

  // ✅ دي لازم تبقى جوه الكلاس
  void setError(String msg) {
    state = state.copyWith(loading: false, success: false, error: msg);
  }

  Future<void> verify(String token) async {
    state = state.copyWith(loading: true, success: false, error: null);
    try {
      await _repo.verifyEmail(token);
      state = state.copyWith(loading: false, success: true, error: null);
    } catch (e) {
      state = state.copyWith(
        loading: false,
        success: false,
        error: mapApiError(e),
      );
    }
  }
}
