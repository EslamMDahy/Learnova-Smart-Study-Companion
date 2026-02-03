import 'dart:html' as html;

class TokenStorage {
  static const _key = 'learnova_access_token';
  static String? _token;

  static String? get token => _token ?? html.window.localStorage[_key];

  static bool get hasToken => token != null;

  static void saveToken(String token, {bool persist = false}) {
    _token = token;
    if (persist) {
      html.window.localStorage[_key] = token;
    } else {
      html.window.localStorage.remove(_key);
    }
  }

  static void clear() {
    _token = null;
    html.window.localStorage.remove(_key);
  }
}
