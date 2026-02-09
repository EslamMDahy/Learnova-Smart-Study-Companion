import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/app_error_bus.dart';
import '../../../../core/network/error_mapper.dart';
import '../../../../core/storage/user_storage.dart';

import '../../data/organizations_providers.dart';
import '../../data/dto/organization_out.dart';
import 'admin_dashboard_state.dart';

final adminDashboardControllerProvider =
    StateNotifierProvider<AdminDashboardController, AdminDashboardState>(
  (ref) => AdminDashboardController(ref),
);

class AdminDashboardController extends StateNotifier<AdminDashboardState> {
  AdminDashboardController(this._ref) : super(const AdminDashboardState()) {
    _hydrateFromStorage();
  }

  final Ref _ref;

  void _hydrateFromStorage() {
    final orgs = UserStorage.organizations;
    if (orgs.isEmpty) return;

    final selected =
        (UserStorage.meJson?['selected_organization_id'])?.toString().trim();

    final firstId = orgs.first['id']?.toString().trim();
    final orgId =
        (selected != null && selected.isNotEmpty) ? selected : (firstId ?? '');

    if (orgId.isNotEmpty) {
      state = state.copyWith(
        organizationId: orgId,
      );
    }
  }

  Future<void> createOrganization({
    required String name,
    required String description,
    String? logoUrl,
  }) async {
    state = state.copyWith(loading: true, error: null);

    try {
      final repo = _ref.read(organizationsRepositoryProvider);

      final OrganizationOut org = await repo.createOrganization(
        name: name,
        description: description,
        logoUrl: (logoUrl != null && logoUrl.trim().isNotEmpty)
            ? logoUrl.trim()
            : null,
      );

      final orgId = org.id.toString().trim();

      // ✅ Update controller state
      state = state.copyWith(
        loading: false,
        organizationId: orgId,
      );

      // ✅ Persist: organizations + selected_organization_id
      final current = UserStorage.meJson ?? <String, dynamic>{};
      final merged = <String, dynamic>{...current};

      final List<Map<String, dynamic>> orgs = [
        org.toJson(),
        ...UserStorage.organizations.where(
          (e) => e['id']?.toString() != orgId,
        ),
      ];

      merged['organizations'] = orgs;
      merged['selected_organization_id'] = orgId;

      // keep your existing behavior
      const persist = true;
      UserStorage.saveMe(merged, persist: persist);

      log('✅ Organization created and saved locally. orgId=$orgId');
    } catch (e, st) {
      log('❌ createOrganization error: $e', stackTrace: st);

      final failure = mapApiFailure(e);

      // ✅ Global toast (one system for the whole app)
      AppErrorReporter.report(_ref, failure);

      // ✅ Keep state.error if any UI depends on it (optional but safe)
      state = state.copyWith(
        loading: false,
        error: failure.message,
      );
    }
  }

  void clearError() {
    if (state.error != null) {
      state = state.copyWith(error: null);
    }
  }
}
