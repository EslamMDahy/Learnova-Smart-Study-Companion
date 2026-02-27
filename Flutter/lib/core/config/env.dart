// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class Env {
  Env._();

  static const bool isProd = bool.fromEnvironment('dart.vm.product');
  static const bool enableRefreshToken = true;

  /// IMPORTANT (web dev):
  /// To make HttpOnly refresh cookies work, frontend and backend must share the SAME host.
  /// We therefore build the API URL using the current page hostname (localhost vs 127.0.0.1).
  static String get baseUrl {
    if (isProd) return 'https://api.learnova.app';

    final proto = html.window.location.protocol; // http: / https:
    final host = html.window.location.hostname;  // localhost / 127.0.0.1 / ...
    return '$proto//$host:8000';
  }
}
