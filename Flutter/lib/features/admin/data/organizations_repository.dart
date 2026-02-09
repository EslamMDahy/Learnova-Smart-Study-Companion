import 'dart:developer';

import 'organizations_api.dart';
import 'dto/create_org_response.dart';
import 'dto/join_requests_response.dart';
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

      final dto = CreateOrganizationResponse.fromJson(raw);
      return dto.organization;
    } catch (e, st) {
      // ✅ log for debugging only (do NOT toast here)
      log('❌ createOrganization failed: $e', stackTrace: st);
      rethrow;
    }
  }

  /// ✅ Typed response (no List<Map> anymore)
  Future<JoinRequestsResponse> getJoinRequests({
    required String organizationId,
    String view = 'pending',
  }) async {
    try {
      final raw = await _api.joinRequests(
        organizationId: organizationId.trim(),
        view: view,
      );

      log('✅ getJoinRequests raw response: $raw');

      return JoinRequestsResponse.fromJson(raw);
    } catch (e, st) {
      log('❌ getJoinRequests failed: $e', stackTrace: st);
      rethrow;
    }
  }

  /// PATCH member status helpers
  Future<Map<String, dynamic>> acceptMember({
    required String organizationId,
    required String memberId,
  }) async {
    try {
      final raw = await _api.updateMemberStatus(
        organizationId: organizationId.trim(),
        memberId: memberId.trim(),
        newStatus: 'accepted',
      );

      log('✅ acceptMember raw response: $raw');
      return raw;
    } catch (e, st) {
      log('❌ acceptMember failed: $e', stackTrace: st);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> declineMember({
    required String organizationId,
    required String memberId,
  }) async {
    try {
      // ✅ IMPORTANT: "declinate" is wrong.
      // Most backends use "rejected" (or "declined"). We standardize to "rejected".
      final raw = await _api.updateMemberStatus(
        organizationId: organizationId.trim(),
        memberId: memberId.trim(),
        newStatus: 'rejected',
      );

      log('✅ declineMember raw response: $raw');
      return raw;
    } catch (e, st) {
      log('❌ declineMember failed: $e', stackTrace: st);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> suspendMember({
    required String organizationId,
    required String memberId,
  }) async {
    try {
      final raw = await _api.updateMemberStatus(
        organizationId: organizationId.trim(),
        memberId: memberId.trim(),
        newStatus: 'suspended',
      );

      log('✅ suspendMember raw response: $raw');
      return raw;
    } catch (e, st) {
      log('❌ suspendMember failed: $e', stackTrace: st);
      rethrow;
    }
  }
}
