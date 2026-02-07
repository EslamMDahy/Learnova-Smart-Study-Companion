class LoginResponse {
  final String accessToken;
  final String? tokenType;

  /// User object
  final LoginUser? user;

  /// Organizations list
  final List<LoginOrganization> organizations;

  /// Convenience: first valid organization id
  String? get organizationId {
    for (final o in organizations) {
      if (o.id.trim().isNotEmpty) return o.id;
    }
    return null;
  }

  LoginResponse({
    required this.accessToken,
    this.tokenType,
    this.user,
    this.organizations = const [],
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    // support wrapped payloads
    final root = (json['data'] is Map<String, dynamic>)
        ? json['data'] as Map<String, dynamic>
        : (json['result'] is Map<String, dynamic>)
            ? json['result'] as Map<String, dynamic>
            : json;

    final token = (root['access_token'] ??
            root['token'] ??
            root['accessToken'])
        ?.toString();

    if (token == null || token.trim().isEmpty) {
      throw Exception('Missing access token in response');
    }

    final tokenType = (root['token_type'] ?? root['tokenType'])?.toString();

    // user
    LoginUser? parsedUser;
    final userJson = root['user'];
    if (userJson is Map<String, dynamic>) {
      parsedUser = LoginUser.fromJson(userJson);
    }

    // organizations (support: organizations | orgs | organization)
    final orgsRaw =
        root['organizations'] ?? root['orgs'] ?? root['organization'];

    final parsedOrgs = <LoginOrganization>[];

    if (orgsRaw is List) {
      for (final item in orgsRaw) {
        if (item is Map<String, dynamic>) {
          parsedOrgs.add(LoginOrganization.fromJson(item));
        }
      }
    } else if (orgsRaw is Map<String, dynamic>) {
      parsedOrgs.add(LoginOrganization.fromJson(orgsRaw));
    }

    return LoginResponse(
      accessToken: token,
      tokenType: tokenType,
      user: parsedUser,
      organizations: parsedOrgs,
    );
  }
}

class LoginUser {
  final String id;
  final String? name; // هنحط فيها full_name أو name
  final String? email;
  final String? role;
  final String? avatarUrl;

  LoginUser({
    required this.id,
    this.name,
    this.email,
    this.role,
    this.avatarUrl,
  });

  factory LoginUser.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] ?? json['_id'] ?? json['userId'])?.toString();

    if (id == null || id.trim().isEmpty) {
      throw Exception('Missing user id in login response user object');
    }

    return LoginUser(
      id: id,
      name: (json['full_name'] ?? json['name'])?.toString(),
      email: json['email']?.toString(),
      avatarUrl: (json['avatar_url'] ?? json['avatarUrl'])?.toString(),
      role: (json['system_role'] ?? json['role'] ?? json['type'])?.toString(),
    );
  }
}

class LoginOrganization {
  final String id;
  final String? name;

  // اختياري لو محتاجهم لاحقاً
  final String? description;
  final String? logoUrl;
  final String? inviteCode;
  final String? subscriptionStatus;

  LoginOrganization({
    required this.id,
    this.name,
    this.description,
    this.logoUrl,
    this.inviteCode,
    this.subscriptionStatus,
  });

  factory LoginOrganization.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] ??
            json['_id'] ??
            json['organizationId'] ??
            json['orgId'])
        ?.toString();

    if (id == null || id.trim().isEmpty) {
      throw Exception('Missing organization id in login response org object');
    }

    return LoginOrganization(
      id: id,
      name: (json['name'] ?? json['title'])?.toString(),
      description: json['description']?.toString(),
      logoUrl: (json['logo_url'] ?? json['logoUrl'])?.toString(),
      inviteCode: (json['invite_code'] ?? json['inviteCode'])?.toString(),
      subscriptionStatus:
          (json['subscription_status'] ?? json['subscriptionStatus'])
              ?.toString(),
    );
  }
}
