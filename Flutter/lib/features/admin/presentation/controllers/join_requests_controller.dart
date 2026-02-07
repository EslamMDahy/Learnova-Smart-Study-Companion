import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/user_storage.dart';
import '../../data/dto/join_request_user.dart';
import '../../data/organizations_providers.dart';
import 'join_requests_state.dart';

final joinRequestsControllerProvider =
    StateNotifierProvider.autoDispose<JoinRequestsController, JoinRequestsState>(
  (ref) => JoinRequestsController(ref),
);

class JoinRequestsController extends StateNotifier<JoinRequestsState> {
  JoinRequestsController(this._ref) : super(const JoinRequestsState());

  final Ref _ref;

  String _resolveOrgId(String? organizationId) {
    final orgId = (organizationId != null && organizationId.trim().isNotEmpty)
        ? organizationId.trim()
        : (UserStorage.organizationId ?? '').trim();

    if (orgId.isEmpty) {
      throw Exception('Missing organizationId');
    }
    return orgId;
  }

  Future<void> load({
    String? organizationId,
    String view = 'pending',
  }) async {
    state = state.copyWith(loading: true, error: null);

    try {
      final repo = _ref.read(organizationsRepositoryProvider);
      final orgId = _resolveOrgId(organizationId);

      final rawUsers = await repo.getJoinRequests(
        organizationId: orgId,
        view: view,
      );

      final users = rawUsers
          .map((e) => JoinRequestUser.fromJson(e))
          .toList(growable: false);

      state = state.copyWith(loading: false, users: users);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> accept({
    String? organizationId,
    required String orgMemberId,
  }) async {
    try {
      final repo = _ref.read(organizationsRepositoryProvider);
      final orgId = _resolveOrgId(organizationId);

      await repo.acceptMember(
        organizationId: orgId,
        memberId: orgMemberId.trim(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> decline({
    String? organizationId,
    required String orgMemberId,
  }) async {
    try {
      final repo = _ref.read(organizationsRepositoryProvider);
      final orgId = _resolveOrgId(organizationId);

      await repo.declineMember(
        organizationId: orgId,
        memberId: orgMemberId.trim(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  void clearError() {
    if (state.error != null) state = state.copyWith(error: null);
  }
}
