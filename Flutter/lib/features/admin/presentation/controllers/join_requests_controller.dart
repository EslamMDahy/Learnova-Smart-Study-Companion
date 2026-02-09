import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/app_error_bus.dart';
import '../../../../core/network/error_mapper.dart';
import '../../../../core/storage/user_storage.dart';

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
      // ✅ validation-style error (not generic Exception)
      throw ArgumentError('Missing organizationId.');
    }
    return orgId;
  }

  Future<void> load({
    String? organizationId,
    String view = 'pending',
  }) async {
    // ✅ if your JoinRequestsState has sentinel like AdminDashboardState, this will clear error
    state = state.copyWith(loading: true, error: null);

    try {
      final repo = _ref.read(organizationsRepositoryProvider);
      final orgId = _resolveOrgId(organizationId);

      final res = await repo.getJoinRequests(
        organizationId: orgId,
        view: view,
      );

      // ✅ res.users already parsed DTOs
      state = state.copyWith(
        loading: false,
        users: res.users,
        count: res.count,
      );
    } catch (e) {
      final failure = mapApiFailure(e);
      AppErrorReporter.report(_ref, failure);

      state = state.copyWith(
        loading: false,
        error: failure.message,
      );
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
      final failure = mapApiFailure(e);
      AppErrorReporter.report(_ref, failure);

      state = state.copyWith(error: failure.message);
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
      final failure = mapApiFailure(e);
      AppErrorReporter.report(_ref, failure);

      state = state.copyWith(error: failure.message);
      rethrow;
    }
  }

  void clearError() {
    if (state.error != null) state = state.copyWith(error: null);
  }
}
