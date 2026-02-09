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

  const LoginResponse({
    required this.accessToken,
    this.tokenType,
    this.user,
    this.organizations = const [],
  });

  LoginResponse copyWith({
    String? accessToken,
    String? tokenType,
    LoginUser? user,
    List<LoginOrganization>? organizations,
  }) {
    return LoginResponse(
      accessToken: accessToken ?? this.accessToken,
      tokenType: tokenType ?? this.tokenType,
      user: user ?? this.user,
      organizations: organizations ?? this.organizations,
    );
  }

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    // support wrapped payloads
    final root = (json['data'] is Map<String, dynamic>)
        ? json['data'] as Map<String, dynamic>
        : (json['result'] is Map<String, dynamic>)
            ? json['result'] as Map<String, dynamic>
            : json;

    final token =
        (root['access_token'] ?? root['token'] ?? root['accessToken'])
            ?.toString();

    if (token == null || token.trim().isEmpty) {
      throw Exception('Missing access token in response');
    }

    final parsedTokenType =
        (root['token_type'] ?? root['tokenType'])?.toString();

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
      tokenType: parsedTokenType,
      user: parsedUser,
      organizations: parsedOrgs,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LoginResponse &&
        other.accessToken == accessToken &&
        other.tokenType == tokenType &&
        other.user == user &&
        _listEquals(other.organizations, organizations);
  }

  @override
  int get hashCode => Object.hash(
        accessToken,
        tokenType,
        user,
        Object.hashAll(organizations),
      );
}

class LoginUser {
  final String id;
  final String? name; // full_name أو name
  final String? email;
  final String? role;
  final String? avatarUrl;

  const LoginUser({
    required this.id,
    this.name,
    this.email,
    this.role,
    this.avatarUrl,
  });

  LoginUser copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? avatarUrl,
  }) {
    return LoginUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LoginUser &&
        other.id == id &&
        other.name == name &&
        other.email == email &&
        other.role == role &&
        other.avatarUrl == avatarUrl;
  }

  @override
  int get hashCode => Object.hash(id, name, email, role, avatarUrl);
}

class LoginOrganization {
  final String id;
  final String? name;

  final String? description;
  final String? logoUrl;
  final String? inviteCode;
  final String? subscriptionStatus;

  const LoginOrganization({
    required this.id,
    this.name,
    this.description,
    this.logoUrl,
    this.inviteCode,
    this.subscriptionStatus,
  });

  LoginOrganization copyWith({
    String? id,
    String? name,
    String? description,
    String? logoUrl,
    String? inviteCode,
    String? subscriptionStatus,
  }) {
    return LoginOrganization(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      logoUrl: logoUrl ?? this.logoUrl,
      inviteCode: inviteCode ?? this.inviteCode,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
    );
  }

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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LoginOrganization &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.logoUrl == logoUrl &&
        other.inviteCode == inviteCode &&
        other.subscriptionStatus == subscriptionStatus;
  }

  @override
  int get hashCode =>
      Object.hash(id, name, description, logoUrl, inviteCode, subscriptionStatus);
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
