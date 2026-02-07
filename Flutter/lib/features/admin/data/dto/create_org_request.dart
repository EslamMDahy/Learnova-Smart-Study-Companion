class CreateOrganizationRequest {
  final String name;
  final String description;
  final String? logoUrl;

  CreateOrganizationRequest({
    required this.name,
    required this.description,
    this.logoUrl,
  });

  Map<String, dynamic> toJson() {
    final n = name.trim();
    final d = description.trim();
    final l = logoUrl?.trim();

    return {
      "name": n,
      "description": d,
      if (l != null && l.isNotEmpty) "logo_url": l, // ✅ لا تبعته لو فاضي
    };
  }
}
