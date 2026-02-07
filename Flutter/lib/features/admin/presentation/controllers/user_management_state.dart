import '../../data/dto/join_request_user.dart';

class UserManagementState {
  final bool loading;
  final List<JoinRequestUser> users;
  final String? error;

  const UserManagementState({
    this.loading = false,
    this.users = const [],
    this.error,
  });

  UserManagementState copyWith({
    bool? loading,
    List<JoinRequestUser>? users,
    String? error,
  }) {
    return UserManagementState(
      loading: loading ?? this.loading,
      users: users ?? this.users,
      error: error,
    );
  }
}
