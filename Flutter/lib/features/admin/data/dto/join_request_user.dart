class JoinRequestUser {
  /// User id (may come as id/_id/user_id)
  final String id;

  /// Organization member id used in:
  /// PATCH /organizations/{orgId}/members/{memberId}/status
  /// (may come as org_member_id / member_id / memberId / organization_member_id)
  final String orgMemberId;

  final String fullName;
  final String email;
  final String? avatarUrl;
  final String systemRole;
  final String status;

  JoinRequestUser({
    required this.id,
    required this.orgMemberId,
    required this.fullName,
    required this.email,
    required this.avatarUrl,
    required this.systemRole,
    required this.status,
  });

  factory JoinRequestUser.fromJson(Map<String, dynamic> json) {
    final id = (json["id"] ??
            json["_id"] ??
            json["user_id"] ??
            json["userId"])
        ?.toString()
        .trim();

    final memberId = (json["org_member_id"] ??
            json["orgMemberId"] ??
            json["member_id"] ??
            json["memberId"] ??
            json["organization_member_id"])
        ?.toString()
        .trim();

    final fallbackId =
        (json["id"] ?? json["_id"])?.toString().trim() ?? '0';

    return JoinRequestUser(
      id: (id == null || id.isEmpty) ? fallbackId : id,
      orgMemberId:
          (memberId == null || memberId.isEmpty) ? fallbackId : memberId,
      fullName: (json["full_name"] ??
              json["fullName"] ??
              json["name"] ??
              "")
          .toString()
          .trim(),
      email: (json["email"] ?? "").toString().trim(),
      avatarUrl: (json["avatar_url"] ?? json["avatarUrl"])?.toString(),
      systemRole:
          (json["system_role"] ?? json["systemRole"] ?? "").toString().toLowerCase(),
      status: (json["status"] ?? "").toString().toLowerCase(),
    );
  }
}
