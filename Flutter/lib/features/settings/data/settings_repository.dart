import 'settings_api.dart';

class SettingsRepository {
  final SettingsApi _api;
  SettingsRepository(this._api);

  Future<String> updateProfile({
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String bio,
    required String language,
    required bool assignmentAlerts,
  }) {
    return _api.updateProfile(
      firstName: firstName,
      lastName: lastName,
      phoneNumber: phoneNumber,
      bio: bio,
      language: language,
      assignmentAlerts: assignmentAlerts,
    );
  }

  Future<String> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    return _api.updatePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  Future<String> requestAccountDelete() {
    return _api.requestAccountDelete();
  }
}
