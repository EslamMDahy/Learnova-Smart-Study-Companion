import 'dart:convert';

/// Small, dependency-free helpers for reading claims from an access JWT.
///
/// The app only needs the `exp` claim to avoid sending obviously expired
/// access tokens. Invalid or opaque tokens intentionally return `null` so the
/// normal reactive refresh/error flow can handle the request.
class JwtAccessToken {
  const JwtAccessToken._();

  static DateTime? expiryOf(String accessToken) {
    try {
      final parts = accessToken.split('.');
      if (parts.length != 3) return null;

      final payload = jsonDecode(
        utf8.decode(base64Url.decode(_base64UrlPad(parts[1]))),
      );
      if (payload is! Map<String, dynamic>) return null;

      final exp = payload['exp'];
      if (exp is! num) return null;

      return DateTime.fromMillisecondsSinceEpoch(
        exp.toInt() * 1000,
        isUtc: true,
      );
    } catch (_) {
      return null;
    }
  }

  static Duration? timeLeft(
    String accessToken, {
    DateTime? now,
  }) {
    final expiry = expiryOf(accessToken);
    if (expiry == null) return null;
    return expiry.difference((now ?? DateTime.now()).toUtc());
  }

  static String _base64UrlPad(String value) {
    final remainder = value.length % 4;
    return remainder == 0 ? value : value + '=' * (4 - remainder);
  }
}
