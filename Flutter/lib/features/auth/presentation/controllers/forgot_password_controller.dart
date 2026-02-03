import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'forgot_password_state.dart';

final forgotPasswordControllerProvider =
    StateNotifierProvider<ForgotPasswordController, ForgotPasswordState>(
  (ref) => ForgotPasswordController(ref),
);

class ForgotPasswordController extends StateNotifier<ForgotPasswordState> {
  ForgotPasswordController(this.ref) : super(const ForgotPasswordState());
  final Ref ref;

  Future<bool> sendResetLink(String email) async {
    state = state.copyWith(loading: true, error: null);
    try {
      // TODO: replace with real API call
      await Future.delayed(const Duration(milliseconds: 500));

      state = state.copyWith(loading: false, error: null);
      return true;
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: 'Something went wrong',
      );
      return false;
    }
  }
}
