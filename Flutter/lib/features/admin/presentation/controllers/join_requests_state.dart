import '../../data/dto/join_request_user.dart';

class JoinRequestsState {
  final bool loading;
  final String? error;
  final List<JoinRequestUser> users;
  final int count;

  const JoinRequestsState({
    this.loading = false,
    this.error,
    this.users = const [],
    this.count = 0,
  });

  bool get hasData => users.isNotEmpty;

  static const _unset = Object();

  JoinRequestsState copyWith({
    bool? loading,
    Object? error = _unset, // ✅ allows explicit null
    List<JoinRequestUser>? users,
    int? count,
  }) {
    return JoinRequestsState(
      loading: loading ?? this.loading,
      error: identical(error, _unset) ? this.error : error as String?,
      users: users ?? this.users,
      count: count ?? this.count,
    );
  }
}
