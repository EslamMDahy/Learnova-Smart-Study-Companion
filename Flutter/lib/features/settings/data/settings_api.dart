import 'dart:typed_data';
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
    final data = (root['user'] ?? root) as Map<String, dynamic>;
    return UserProfile.fromJson(data);
  }


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
        'full_name': fullName.trim(),
        'phone': phoneNumber?.trim(),
        'bio': bio?.trim(),
        'language_preference': languagePreference.trim(),
      },
      cancelToken: cancelToken,
    );
    return UserProfile.fromJson((res.data ?? {}).cast<String, dynamic>());
  }

  // ──────────── Avatar Upload (2-step) ────────────

  /// Step 1: Get a Supabase signed upload URL from the backend
  Future<Map<String, dynamic>> getAvatarUploadUrl({
    required String contentType,
    required int fileSizeBytes,
    CancelToken? cancelToken,
  }) async {
    final res = await _client.post<Map<String, dynamic>>(
      Endpoints.avatarUploadUrl,
      data: {
        'content_type': contentType,
        'file_size_bytes': fileSizeBytes,
      },
      cancelToken: cancelToken,
    );
    return (res.data ?? {}).cast<String, dynamic>();
  }

  /// Step 2: Upload the file bytes directly to Supabase using the signed URL.
  ///
  /// Keep this request outside [ApiClient]. Signed storage URLs should not inherit
  /// the app API base URL, auth interceptor, JSON content-type, or global loading
  /// behavior. This keeps the upload path compatible with both the normal JS
  /// web build and the wasm web build.
  Future<void> uploadAvatarToSupabase({
    required String uploadUrl,
    required List<int> bytes,
    required String contentType,
    CancelToken? cancelToken,
  }) async {
    final bodyBytes = Uint8List.fromList(bytes);

    final response = await Dio().put<void>(
      uploadUrl,
      data: bodyBytes,
      cancelToken: cancelToken,
      options: Options(
        contentType: contentType,
        responseType: ResponseType.plain,
        sendTimeout: const Duration(minutes: 2),
        receiveTimeout: const Duration(minutes: 2),
        headers: const <String, dynamic>{
          'x-upsert': 'true',
        },
        validateStatus: (status) =>
            status != null && status >= 200 && status < 400,
      ),
    );

    final status = response.statusCode ?? 0;
    if (status < 200 || status >= 400) {
      throw Exception('Supabase upload failed: HTTP $status');
    }
  }

  /// Step 3: Confirm the upload to the backend so it bumps updated_at
  Future<String> confirmAvatarUpload({CancelToken? cancelToken}) async {
    final res = await _client.post<Map<String, dynamic>>(
      Endpoints.avatarConfirm,
      data: {'uploaded': true},
      cancelToken: cancelToken,
    );
    final data = (res.data ?? {}).cast<String, dynamic>();
    return data['avatar_url']?.toString() ?? '';
  }

  Future<String> updatePassword({
    required String currentPassword,
    required String newPassword,
    CancelToken? cancelToken,
  }) async {
    final res = await _client.patch<Map<String, dynamic>>(
      Endpoints.updatePassword,
      data: {
        'current_password': currentPassword,
        'new_password': newPassword,
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
      data: {'current_password': currentPassword},
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
      data: {'otp': otp.trim()},
      cancelToken: cancelToken,
    );
    return _msg(res.data);
  }


  Future<UserPreferences> getPreferences({CancelToken? cancelToken}) async {
    final res = await _client.get<Map<String, dynamic>>(
      Endpoints.getPreferences,
      cancelToken: cancelToken,
    );
    return UserPreferences.fromJson(_extractPreferences(res.data));
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
    return UserPreferences.fromJson(_extractPreferences(res.data));
  }

  Map<String, dynamic> _extractPreferences(Map<String, dynamic>? raw) {
    final root = (raw ?? {}).cast<String, dynamic>();
    final data = root['preferences'] ?? root['data'] ?? root['user_preferences'] ?? root;
    if (data is Map) return data.cast<String, dynamic>();
    return root;
  }

  String _msg(Map<String, dynamic>? data) {
    final v = data?['message'] ?? data?['msg'] ?? data?['detail'];
    return (v ?? '').toString();
  }
}
