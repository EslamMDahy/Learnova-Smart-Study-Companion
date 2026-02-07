import 'join_request_user.dart';

class JoinRequestsResponse {
  final int count;
  final List<JoinRequestUser> users;

  JoinRequestsResponse({required this.count, required this.users});

  factory JoinRequestsResponse.fromJson(Map<String, dynamic> json) {
    final list = (json["users"] as List? ?? const [])
        .whereType<Map>()
        .map((e) => JoinRequestUser.fromJson(e.cast<String, dynamic>()))
        .toList();

    return JoinRequestsResponse(
      count: (json["count"] ?? list.length) as int,
      users: list,
    );
  }
}
