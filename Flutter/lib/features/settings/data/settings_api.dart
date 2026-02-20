import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/endpoints.dart';
import 'dto/user_profile.dart';
import 'dto/user_preferences.dart';

class SettingsApi {
  final ApiClient _client;
  SettingsApi(this._client);

  // profile source
  Future<UserProfile> me({CancelToken? cancelToken}) async {
    final res = await _client.get<Map<String, dynamic>>(
      Endpoints.me,
      cancelToken: cancelToken,
    );
    final root = (res.data ?? {}).cast<String, dynamic>();
    final data = (root['user'] ?? root).cast<String, dynamic>();
    return UserProfile.fromJson(data);
  }

  // backend expects full_name + phone (مش phone_number)
  Future<UserProfile> updateProfile({
    required String fullName,
    String? phoneNumber,
    String? bio,
    String? studentId,
    String? universityEmail,
    required String languagePreference,
    CancelToken? cancelToken,
  }) async {
    final res = await _client.patch<Map<String, dynamic>>(
      Endpoints.updateProfile,
      data: {
        "full_name": fullName.trim(),
        "phone": phoneNumber?.trim(),
        "bio": bio?.trim(),
        "student_id": studentId?.trim(),
        "university_email": universityEmail?.trim(),
        "language_preference": languagePreference.trim(),
      },
      cancelToken: cancelToken,
    );
    return UserProfile.fromJson((res.data ?? {}).cast<String, dynamic>());
  }

  Future<String> updatePassword({
    required String currentPassword,
    required String newPassword,
    CancelToken? cancelToken,
  }) async {
    final res = await _client.patch<Map<String, dynamic>>(
      Endpoints.updatePassword,
      data: {
        "current_password": currentPassword,
        "new_password": newPassword,
      },
      cancelToken: cancelToken,
    );
    return _msg(res.data);
  }

  Future<String> requestAccountDelete({
    required String currentPassword,
    CancelToken? cancelToken,
  }) async {
    final res = await _client.post<Map<String, dynamic>>(
      Endpoints.deleteRequest,
      data: {"current_password": currentPassword},
      cancelToken: cancelToken,
    );
    return _msg(res.data);
  }

  Future<String> confirmDeleteAccount({
    required String otp,
    CancelToken? cancelToken,
  }) async {
    final res = await _client.delete<Map<String, dynamic>>(
      Endpoints.deleteConfirm,
      data: {"otp": otp.trim()},
      cancelToken: cancelToken,
    );
    return _msg(res.data);
  }

  // ===== user_preferences (لازم تبقى موجودة في الباك)
  Future<UserPreferences> getPreferences({CancelToken? cancelToken}) async {
    final res = await _client.get<Map<String, dynamic>>(
      Endpoints.getPreferences,
      cancelToken: cancelToken,
    );
    return UserPreferences.fromJson((res.data ?? {}).cast<String, dynamic>());
  }

  Future<UserPreferences> updatePreferences(
    UserPreferences prefs, {
    CancelToken? cancelToken,
  }) async {
    final res = await _client.patch<Map<String, dynamic>>(
      Endpoints.updatePreferences,
      data: prefs.toJson(),
      cancelToken: cancelToken,
    );
    return UserPreferences.fromJson((res.data ?? {}).cast<String, dynamic>());
  }

  String _msg(Map<String, dynamic>? data) {
    final v = data?['message'] ?? data?['msg'] ?? data?['detail'];
    return (v ?? '').toString();
  }
}
