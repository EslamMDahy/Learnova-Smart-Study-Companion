import 'dart:developer';

import 'organizations_api.dart';
import 'dto/create_org_response.dart';
import 'dto/organization_out.dart';

class OrganizationsRepository {
  final OrganizationsApi _api;
  OrganizationsRepository(this._api);

  Future<OrganizationOut> createOrganization({
    required String name,
    required String description,
    String? logoUrl,
  }) async {
    try {
      final raw = await _api.createOrganization(
        name: name,
        description: description,
        logoUrl: logoUrl,
      );

      log('✅ createOrganization raw response: $raw');

      // Backend: { "organization": { ... } }
      final dto = CreateOrganizationResponse.fromJson(raw);
      return dto.organization;
    } catch (e, st) {
      // مهم: ده هيظهرلك في الكونسول السبب الحقيقي
      log('❌ createOrganization failed: $e', stackTrace: st);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getJoinRequests({
    required String organizationId,
    String view = 'pending',
  }) async {
    final raw = await _api.joinRequests(
      organizationId: organizationId.trim(),
      view: view,
    );

    final list = raw['users'];
    if (list is List) {
      return list
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList();
    }

    return const [];
  }

  Future<Map<String, dynamic>> acceptMember({
    required String organizationId,
    required String memberId,
  }) {
    return _api.updateMemberStatus(
      organizationId: organizationId.trim(),
      memberId: memberId.trim(),
      newStatus: 'accepted',
    );
  }

  Future<Map<String, dynamic>> declineMember({
    required String organizationId,
    required String memberId,
  }) {
    return _api.updateMemberStatus(
      organizationId: organizationId.trim(),
      memberId: memberId.trim(),
      newStatus: 'declinate',
    );
  }

  Future<Map<String, dynamic>> suspendMember({
    required String organizationId,
    required String memberId,
  }) {
    return _api.updateMemberStatus(
      organizationId: organizationId.trim(),
      memberId: memberId.trim(),
      newStatus: 'suspended',
    );
  }
}
