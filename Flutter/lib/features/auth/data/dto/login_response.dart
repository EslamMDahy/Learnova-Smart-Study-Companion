class LoginResponse {
  final String accessToken;

  LoginResponse({required this.accessToken});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final token = (json['access_token'] ?? json['token'] ?? json['accessToken'])?.toString();
    if (token == null || token.isEmpty) {
      throw Exception('Missing access token in response');
    }
    return LoginResponse(accessToken: token);
  }
}
