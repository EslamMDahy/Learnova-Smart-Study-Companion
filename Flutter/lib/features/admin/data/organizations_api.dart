import '../../../core/network/api_client.dart';
import '../../../core/network/endpoints.dart';

class OrganizationsApi {
  final ApiClient _client;
  OrganizationsApi(this._client);

  /// POST /organizations
  /// Backend response: { "organization": { ... } }
  Future<Map<String, dynamic>> createOrganization({
    required String name,
    required String description,
    String? logoUrl,
  }) async {
    final n = name.trim();
    final d = description.trim();
    final l = logoUrl?.trim();

    final payload = <String, dynamic>{
      "name": n,
      "description": d,
      if (l != null && l.isNotEmpty) "logo_url": l, // ✅
    };

    final res = await _client.post<Map<String, dynamic>>(
      Endpoints.createOrganization,
      data: payload,
    );

    return (res.data ?? const <String, dynamic>{}).cast<String, dynamic>();
  }

  /// GET /organizations/{id}/join-requests?view=pending|accepted
  Future<Map<String, dynamic>> joinRequests({
    required String organizationId,
    String view = 'pending',
  }) async {
    final safeView = (view == 'accepted') ? 'accepted' : 'pending';

    final res = await _client.get<Map<String, dynamic>>(
      Endpoints.joinRequests(organizationId.trim()),
      queryParameters: {"view": safeView},
    );

    return (res.data ?? const <String, dynamic>{}).cast<String, dynamic>();
  }

  /// PATCH /organizations/{id}/members/{org_member_id}/status
  Future<Map<String, dynamic>> updateMemberStatus({
    required String organizationId,
    required String memberId,
    required String newStatus,
  }) async {
    final res = await _client.patch<Map<String, dynamic>>(
      Endpoints.updateMemberStatus(
        organizationId.trim(),
        memberId.trim(),
      ),
      data: {
        "new_status": newStatus,
      },
    );

    return (res.data ?? const <String, dynamic>{}).cast<String, dynamic>();
  }
}
