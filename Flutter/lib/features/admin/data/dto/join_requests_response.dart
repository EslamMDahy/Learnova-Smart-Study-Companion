import 'join_request_user.dart';

class JoinRequestsResponse {
  final int count;
  final List<JoinRequestUser> users;

  JoinRequestsResponse({required this.count, required this.users});

  factory JoinRequestsResponse.fromJson(Map<String, dynamic> json) {
    final rawUsers = (json["users"] as List?) ?? const [];

    final users = <JoinRequestUser>[];
    for (final item in rawUsers) {
      if (item is Map) {
        try {
          users.add(
            JoinRequestUser.fromJson(item.cast<String, dynamic>()),
          );
        } catch (_) {
          // ✅ Skip invalid entries (keeps the rest working)
        }
      }
    }

    return JoinRequestsResponse(
      count: _toInt(json["count"]) ?? users.length,
      users: users,
    );
  }

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v.trim());
    return null;
  }
}
