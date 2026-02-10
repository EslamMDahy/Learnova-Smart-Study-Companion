import '../../../core/network/api_client.dart';
import '../../../core/network/endpoints.dart';

class SettingsApi {
  final ApiClient _client;
  SettingsApi(this._client);

  Future<String> updateProfile({
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String bio,
    required String language,
    required bool assignmentAlerts,
  }) async {
    final res = await _client.patch<Map<String, dynamic>>(
      Endpoints.updateProfile,
      data: {
        "first_name": firstName.trim(),
        "last_name": lastName.trim(),
        "phone_number": phoneNumber.trim(),
        "bio": bio.trim(),
        "language": language.trim(),
        "assignment_alerts": assignmentAlerts,
      },
    );

    return _readMessage(res.data);
  }

  Future<String> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final res = await _client.patch<Map<String, dynamic>>(
      Endpoints.updatePassword,
      data: {
        "current_password": currentPassword,
        "new_password": newPassword,
      },
    );

    return _readMessage(res.data);
  }

  Future<String> requestAccountDelete() async {
    final res = await _client.post<Map<String, dynamic>>(
      Endpoints.deleteRequest,
      data: const {}, // لو الباك مش محتاج body
    );
    return _readMessage(res.data);
  }

  String _readMessage(Map<String, dynamic>? data) {
    final v = data?['message'] ?? data?['msg'] ?? data?['detail'];
    if (v == null) return '';
    return v.toString();
  }
}
