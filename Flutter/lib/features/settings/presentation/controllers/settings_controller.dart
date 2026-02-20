import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/app_error_bus.dart';
import '../../../../core/network/error_mapper.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../core/storage/user_storage.dart';
import '../../data/dto/user_preferences.dart';
import '../../data/dto/user_profile.dart';
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

  CancelToken? _loadCancel;
  CancelToken? _saveCancel;

  SettingsRepository get _repo => ref.read(settingsRepositoryProvider);

  void clearMessages() {
    if (state.error != null || state.success != null) {
      state = state.copyWith(error: null, success: null);
    }
  }

  void _resetLoadCancel() {
    _loadCancel?.cancel('superseded');
    _loadCancel = CancelToken();
  }

  void _resetSaveCancel() {
    _saveCancel?.cancel('superseded');
    _saveCancel = CancelToken();
  }

  void _handleError(Object e, {bool stopLoading = true}) {
    final failure = mapApiFailure(e);

    // لو عنده session ودي auth issue -> global handler
    if (TokenStorage.hasToken && failure.isAuthIssue) {
      if (stopLoading) state = state.copyWith(loading: false);
      AppErrorReporter.report(ref, failure);
      return;
    }

    state = state.copyWith(
      loading: false,
      error: failure.message,
    );
  }

  void _hydrateProfileFromStorageIfPossible() {
    // لو profile مش موجود، حاول هيدرِيت من التخزين فورًا (قبل الـAPI)
    if (state.profile != null) return;

    final cachedUser = UserStorage.userMap;
    if (cachedUser == null) return;

    try {
      final profile = UserProfile.fromJson(cachedUser);
      state = state.copyWith(profile: profile);
    } catch (_) {
      // ignore
    }
  }

  Future<void> load() async {
    // لو بالفعل بيعمل load متكرر
    if (state.loading) return;

    clearMessages();

    _hydrateProfileFromStorageIfPossible();

    _resetLoadCancel();

    // ✅ Soft-load: لو عندنا داتا بالفعل متعملش loading true (عشان مفيش فلاش فاضي)
    final hasData = state.profile != null && state.preferences != null;
    state = state.copyWith(loading: !hasData);

    try {
      // 1) profile (repo نفسه cached-first)
      final profile = await _repo.me(cancelToken: _loadCancel);

      // 2) preferences
      UserPreferences prefs;
      try {
        prefs = await _repo.getPreferences(cancelToken: _loadCancel);
      } catch (_) {
        // ✅ حافظ على الموجود بدل ما ترجع defaults لو عندنا بيانات
        prefs = state.preferences ?? UserPreferences.defaults();
      }

      state = state.copyWith(
        loading: false,
        profile: profile,
        preferences: prefs,
      );
    } catch (e) {
      _handleError(e);
    }
  }

  Future<bool> saveProfile({
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String bio,
    required String language,
    required bool assignmentAlerts,

    // Preferences (اختياري)
    bool? emailNotifications,
    bool? courseUpdates,
    bool? announcementNotifications,
    bool? gradingNotifications,
    bool? deadlineReminders,
    String? themeMode,
    String? profileVisibility,
    bool? showOnlineStatus,
  }) async {
    clearMessages();
    _resetSaveCancel();
    state = state.copyWith(savingProfile: true);

    try {
      final fullName = _mergeName(firstName, lastName);
      final langCode = _mapLanguageToCode(language);

      final updatedProfile = await _repo.updateProfile(
        fullName: fullName,
        phoneNumber: phoneNumber,
        bio: bio,
        studentId: state.profile?.studentId,
        universityEmail: state.profile?.universityEmail,
        languagePreference: langCode,
        cancelToken: _saveCancel,
      );

      // ✅ merge محافظ عالحقول اللي ممكن الباك ما يرجعهاش
      final old = state.profile;

      final mergedProfile = UserProfile(
        id: updatedProfile.id,
        fullName: updatedProfile.fullName,
        email: updatedProfile.email,
        avatarUrl: updatedProfile.avatarUrl ?? old?.avatarUrl,
        phoneNumber: updatedProfile.phoneNumber ?? old?.phoneNumber,
        bio: updatedProfile.bio ?? old?.bio,
        studentId: updatedProfile.studentId ?? old?.studentId,
        universityEmail: updatedProfile.universityEmail ?? old?.universityEmail,
        languagePreference: updatedProfile.languagePreference,
        systemRole: updatedProfile.systemRole,
        isEmailVerified: updatedProfile.isEmailVerified,
        accountStatus: updatedProfile.accountStatus,
        createdAt: updatedProfile.createdAt ?? old?.createdAt,
        lastLoginAt: updatedProfile.lastLoginAt ?? old?.lastLoginAt,
      );

      // ✅ حدّث UserStorage (شكل backend: { user: {...}, organizations: [...] })
      final currentMe = UserStorage.meJson ?? <String, dynamic>{};
      UserStorage.saveMe(
        {
          ...currentMe,
          'user': mergedProfile.toJson(),
        },
        persist: true,
      );

      // preferences
      final currentPrefs = state.preferences ?? UserPreferences.defaults();
      final nextPrefs = UserPreferences(
        emailNotifications: emailNotifications ?? currentPrefs.emailNotifications,
        assignmentAlerts: assignmentAlerts,
        courseUpdates: courseUpdates ?? currentPrefs.courseUpdates,
        announcementNotifications:
            announcementNotifications ?? currentPrefs.announcementNotifications,
        gradingNotifications:
            gradingNotifications ?? currentPrefs.gradingNotifications,
        deadlineReminders: deadlineReminders ?? currentPrefs.deadlineReminders,
        themeMode: themeMode ?? currentPrefs.themeMode,
        profileVisibility: profileVisibility ?? currentPrefs.profileVisibility,
        showOnlineStatus: showOnlineStatus ?? currentPrefs.showOnlineStatus,
      );

      UserPreferences savedPrefs = nextPrefs;
      // لو endpoint مش موجود في الباك مش هنكسر
      try {
        state = state.copyWith(savingPreferences: true);
        savedPrefs = await _repo.updatePreferences(
          nextPrefs,
          cancelToken: _saveCancel,
        );
      } catch (_) {
        savedPrefs = nextPrefs;
      } finally {
        state = state.copyWith(savingPreferences: false);
      }

      state = state.copyWith(
        savingProfile: false,
        profile: mergedProfile,
        preferences: savedPrefs,
        success: "Saved",
      );

      return true;
    } catch (e) {
      final failure = mapApiFailure(e);

      if (TokenStorage.hasToken && failure.isAuthIssue) {
        state = state.copyWith(savingProfile: false);
        AppErrorReporter.report(ref, failure);
        return false;
      }

      state = state.copyWith(
        savingProfile: false,
        error: failure.message,
      );
      return false;
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    clearMessages();
    _resetSaveCancel();
    state = state.copyWith(updatingPassword: true);

    try {
      final msg = await _repo.updatePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        cancelToken: _saveCancel,
      );

      state = state.copyWith(
        updatingPassword: false,
        success: msg.isEmpty ? "Password updated" : msg,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        updatingPassword: false,
        error: mapApiFailure(e).message,
      );
      return false;
    }
  }

  Future<bool> requestDelete({required String currentPassword}) async {
    clearMessages();
    _resetSaveCancel();
    state = state.copyWith(deleting: true);

    try {
      final msg = await _repo.requestAccountDelete(
        currentPassword: currentPassword,
        cancelToken: _saveCancel,
      );

      state = state.copyWith(
        deleting: false,
        success: msg.isEmpty ? "OTP sent" : msg,
      );
      return true;
    } catch (e) {
      state = state.copyWith(deleting: false, error: mapApiFailure(e).message);
      return false;
    }
  }

  Future<bool> confirmDelete({required String otp}) async {
    clearMessages();
    _resetSaveCancel();
    state = state.copyWith(deleting: true);

    try {
      final msg = await _repo.confirmDeleteAccount(
        otp: otp,
        cancelToken: _saveCancel,
      );

      state = state.copyWith(
        deleting: false,
        success: msg.isEmpty ? "Account deleted" : msg,
      );
      return true;
    } catch (e) {
      state = state.copyWith(deleting: false, error: mapApiFailure(e).message);
      return false;
    }
  }

  String _mergeName(String first, String last) {
    final f = first.trim();
    final l = last.trim();
    if (f.isEmpty) return l;
    if (l.isEmpty) return f;
    return "$f $l";
  }

  String _mapLanguageToCode(String ui) {
    switch (ui) {
      case "English (US)":
      case "English (UK)":
        return "en";
      case "Arabic":
        return "ar";
      default:
        return "en";
    }
  }

  @override
  void dispose() {
    _loadCancel?.cancel('disposed');
    _saveCancel?.cancel('disposed');
    super.dispose();
  }
}
