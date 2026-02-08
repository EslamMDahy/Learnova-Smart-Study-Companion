import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/error_mapper.dart';
import '../../data/auth_providers.dart';
import '../../data/auth_repository.dart';
import 'signup_state.dart';

final signupControllerProvider =
    StateNotifierProvider<SignupController, SignupState>(
  (ref) => SignupController(ref.read(authRepositoryProvider)),
);

class SignupController extends StateNotifier<SignupState> {
  SignupController(this._repo) : super(const SignupState());

  final AuthRepository _repo;

  void clearError() {
    if (state.error != null) {
      state = state.copyWith(error: null);
    }
  }

  void reset() => state = const SignupState();

  bool _looksLikeEmail(String v) {
    final s = v.trim();
    return s.isNotEmpty && s.contains('@') && s.contains('.');
  }

  /// ✅ Now matches backend:
  /// full_name, email, password, system_role
  Future<bool> signup({
    required String fullName,
    required String email,
    required String password,
    required String systemRole,
  }) async {
    state = state.copyWith(loading: true, error: null);

    final cleanFullName = fullName.trim();
    final cleanEmail = email.trim();
    final cleanSystemRole = systemRole.trim().toLowerCase();

    // ✅ Local validation (خفيف واحترافي)
    if (cleanFullName.isEmpty) {
      state = state.copyWith(loading: false, error: 'Full name is required.');
      return false;
    }

    if (!_looksLikeEmail(cleanEmail)) {
      state = state.copyWith(loading: false, error: 'Please enter a valid email.');
      return false;
    }

    if (password.trim().length < 8) {
      state = state.copyWith(
        loading: false,
        error: 'Password must be at least 8 characters.',
      );
      return false;
    }

    // (اختياري) نعمل guard بسيط يوازي الباك
    const allowed = {'student', 'instructor', 'assistant', 'owner'};
    if (!allowed.contains(cleanSystemRole)) {
      state = state.copyWith(
        loading: false,
        error: 'Invalid System Role.',
      );
      return false;
    }

    try {
      await _repo.signup(
        fullName: cleanFullName,
        email: cleanEmail,
        password: password,
        systemRole: cleanSystemRole,
      );

      state = state.copyWith(loading: false, error: null);
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
