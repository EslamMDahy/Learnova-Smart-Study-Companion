import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/error_mapper.dart';
import '../../data/settings_providers.dart';
import '../../data/settings_repository.dart';
import 'settings_state.dart';

final settingsControllerProvider =
    StateNotifierProvider<SettingsController, SettingsState>(
  (ref) => SettingsController(ref),
);

class SettingsController extends StateNotifier<SettingsState> {
  SettingsController(this.ref) : super(const SettingsState());

  final Ref ref;

  SettingsRepository get _repo => ref.read(settingsRepositoryProvider);

  void clearMessages() {
    if (state.error != null || state.success != null) {
      state = state.copyWith(error: null, success: null);
    }
  }

  Future<bool> saveProfile({
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String bio,
    required String language,
    required bool assignmentAlerts,
  }) async {
    clearMessages();
    state = state.copyWith(savingProfile: true);

    try {
      final msg = await _repo.updateProfile(
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
        bio: bio,
        language: language,
        assignmentAlerts: assignmentAlerts,
      );

      state = state.copyWith(savingProfile: false, success: msg.isEmpty ? "Saved" : msg);
      return true;
    } catch (e) {
      state = state.copyWith(savingProfile: false, error: mapApiError(e));
      return false;
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    clearMessages();
    state = state.copyWith(updatingPassword: true);

    try {
      final msg = await _repo.updatePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      state = state.copyWith(
        updatingPassword: false,
        success: msg.isEmpty ? "Password updated" : msg,
      );
      return true;
    } catch (e) {
      state = state.copyWith(updatingPassword: false, error: mapApiError(e));
      return false;
    }
  }

  Future<bool> requestDelete() async {
    clearMessages();
    state = state.copyWith(deleting: true);

    try {
      final msg = await _repo.requestAccountDelete();
      state = state.copyWith(deleting: false, success: msg.isEmpty ? "Delete request sent" : msg);
      return true;
    } catch (e) {
      state = state.copyWith(deleting: false, error: mapApiError(e));
      return false;
    }
  }
}
