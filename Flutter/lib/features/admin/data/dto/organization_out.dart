class OrganizationOut {
  final int id;
  final String name;
  final String description;
  final String? logoUrl;
  final int ownerId;
  final int subscriptionPlanId;
  final String inviteCode;
  final String subscriptionStatus;

  OrganizationOut({
    required this.id,
    required this.name,
    required this.description,
    required this.logoUrl,
    required this.ownerId,
    required this.subscriptionPlanId,
    required this.inviteCode,
    required this.subscriptionStatus,
  });

  factory OrganizationOut.fromJson(Map<String, dynamic> json) {
    return OrganizationOut(
      id: (json["id"] ?? 0) as int,
      name: (json["name"] ?? "") as String,
      description: (json["description"] ?? "") as String,
      logoUrl: json["logo_url"] as String?,
      ownerId: (json["owner_id"] ?? 0) as int,
      subscriptionPlanId: (json["subscription_plan_id"] ?? 0) as int,
      inviteCode: (json["invite_code"] ?? "") as String,
      subscriptionStatus: (json["subscription_status"] ?? "") as String,
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "description": description,
        "logo_url": logoUrl,
        "owner_id": ownerId,
        "subscription_plan_id": subscriptionPlanId,
        "invite_code": inviteCode,
        "subscription_status": subscriptionStatus,
      };
}
