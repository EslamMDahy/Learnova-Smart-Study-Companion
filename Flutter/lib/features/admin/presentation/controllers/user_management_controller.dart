import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/dto/join_requests_response.dart';
import '../../data/dto/join_request_user.dart';
import '../../data/organizations_providers.dart';
import 'user_management_state.dart';

final userManagementControllerProvider =
    StateNotifierProvider<UserManagementController, UserManagementState>(
  (ref) => UserManagementController(ref),
);

class UserManagementController extends StateNotifier<UserManagementState> {
  UserManagementController(this.ref) : super(const UserManagementState());

  final Ref ref;
  
  Future<void> loadUsers({
    required String organizationId,
    String view = 'accepted',
  }) async {
    state = state.copyWith(
      loading: true,
      clearError: true,
    );

    try {
      final repo = ref.read(organizationsRepositoryProvider);

      final res = await repo.getJoinRequests(
        organizationId: organizationId.trim(),
        view: view,
      );

      state = state.copyWith(
        loading: false,
        users: res.users,
      );
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: e.toString(),
      );
    }
  }


  void clearError() {
    state = state.copyWith(clearError: true);
  }
}
