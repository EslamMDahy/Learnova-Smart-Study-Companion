class SettingsState {
  final bool savingProfile;
  final bool updatingPassword;
  final bool deleting;
  final String? error;
  final String? success;

  const SettingsState({
    this.savingProfile = false,
    this.updatingPassword = false,
    this.deleting = false,
    this.error,
    this.success,
  });

  SettingsState copyWith({
    bool? savingProfile,
    bool? updatingPassword,
    bool? deleting,
    String? error,
    String? success,
  }) {
    return SettingsState(
      savingProfile: savingProfile ?? this.savingProfile,
      updatingPassword: updatingPassword ?? this.updatingPassword,
      deleting: deleting ?? this.deleting,
      error: error,
      success: success,
    );
  }
}
