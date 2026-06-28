class Env {
  Env._();

  static const bool isProd = bool.fromEnvironment('dart.vm.product');
  static const bool enableRefreshToken = true;

  /// Current FastAPI domain.
  ///
  /// You can still override it without changing code:
  ///
  ///   flutter run/build --dart-define=API_BASE_URL=https://your-api-domain
  static const String _defaultApiBaseUrl =
      'https://www.learnova-edu.com/api';

  static const String _overrideBaseUrl =
      String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    final override = _normalizeBaseUrl(_overrideBaseUrl);
    if (override.isNotEmpty) return override;

    // The project is currently using an external FastAPI/ngrok endpoint, so the
    // frontend must not fall back to localhost or same-origin in web builds.
    return _normalizeBaseUrl(_defaultApiBaseUrl);
  }

  static String _normalizeBaseUrl(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    return trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
  }
}
