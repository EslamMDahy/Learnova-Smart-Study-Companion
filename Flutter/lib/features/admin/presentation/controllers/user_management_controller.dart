import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/organizations_providers.dart';
import '../../data/dto/join_request_user.dart';
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
    state = state.copyWith(loading: true);

    try {
      final repo = ref.read(organizationsRepositoryProvider);
      final raw = await repo.getJoinRequests(
        organizationId: organizationId,
        view: view,
      );

      final users = raw.map(JoinRequestUser.fromJson).toList();

      state = state.copyWith(
        loading: false,
        users: users,
      );
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: e.toString(),
      );
    }
  }
}
