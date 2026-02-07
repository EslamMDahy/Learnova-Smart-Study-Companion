class MeResponse {
  final int id;
  final String email;
  final String fullName;
  final String systemRole; // "owner" / "teacher" / "student" / "assistant" ... (حسب الباك)

  MeResponse({
    required this.id,
    required this.email,
    required this.fullName,
    required this.systemRole,
  });

  bool get isOwner => systemRole.toLowerCase() == 'owner';

  factory MeResponse.fromJson(Map<String, dynamic> json) {
    return MeResponse(
      id: (json['id'] ?? 0) as int,
      email: (json['email'] ?? '') as String,
      fullName: (json['full_name'] ?? json['fullName'] ?? '') as String,
      systemRole: (json['system_role'] ?? json['systemRole'] ?? '') as String,
    );
  }
}
