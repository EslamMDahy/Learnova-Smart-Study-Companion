import '../../data/dto/join_request_user.dart';

class JoinRequestsState {
  final bool loading;
  final String? error;
  final List<JoinRequestUser> users;

  const JoinRequestsState({
    this.loading = false,
    this.error,
    this.users = const [],
  });

  JoinRequestsState copyWith({
    bool? loading,
    String? error,
    List<JoinRequestUser>? users,
  }) {
    return JoinRequestsState(
      loading: loading ?? this.loading,
      error: error,
      users: users ?? this.users,
    );
  }
}
