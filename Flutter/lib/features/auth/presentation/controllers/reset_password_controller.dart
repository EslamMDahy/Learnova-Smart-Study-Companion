import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/error_mapper.dart';
import '../../data/auth_providers.dart';
import '../../data/auth_repository.dart';
import 'reset_password_state.dart';

final resetPasswordControllerProvider =
    StateNotifierProvider<ResetPasswordController, ResetPasswordState>(
  (ref) => ResetPasswordController(ref),
);

class ResetPasswordController extends StateNotifier<ResetPasswordState> {
  ResetPasswordController(this.ref) : super(const ResetPasswordState());

  final Ref ref;

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  void reset() {
    // لا نمسح error مباشرة
    clearError();
    state = const ResetPasswordState();
  }

  void clearError() {
    if (state.error != null) {
      state = state.copyWith(error: null);
    }
  }

  Future<bool> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    final t = token.trim();

    // امسح error فقط عبر clearError
    clearError();

    state = state.copyWith(
      loading: true,
      success: false,
      message: null,
    );

    if (t.isEmpty) {
      state = state.copyWith(
        loading: false,
        success: false,
        message: null,
        error: "Invalid reset link. Please request a new one.",
      );
      return false;
    }

    try {
      final msg = await _repo.resetPassword(
        token: t,
        newPassword: newPassword,
      );

      state = state.copyWith(
        loading: false,
        success: true,
        message: msg.trim().isNotEmpty
            ? msg.trim()
            : "Password reset successfully. You can now log in.",
      );

      return true;
    } catch (err) {
      state = state.copyWith(
        loading: false,
        success: false,
        message: null,
        error: mapApiError(err),
      );
      return false;
    }
  }
}
