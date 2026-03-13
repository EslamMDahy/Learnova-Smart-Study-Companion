import 'dart:html' as html;
import 'package:flutter/foundation.dart';

class TokenStorage {
  static const _accessKey = 'learnova_access_token';
  static const _refreshKey = 'learnova_refresh_token';

  static String? _memoryAccess;
  static String? _memoryRefresh;

  // عشان GoRouter يعمل refresh لما التوكين يتغير
  static final ValueNotifier<int> _rev = ValueNotifier<int>(0);
  static Listenable get listenable => _rev;

  static String? get token =>
      _memoryAccess ??
      html.window.sessionStorage[_accessKey] ??
      html.window.localStorage[_accessKey];

  static String? get refreshToken =>
      _memoryRefresh ??
      html.window.sessionStorage[_refreshKey] ??
      html.window.localStorage[_refreshKey];

  static bool get hasToken => (token?.isNotEmpty ?? false);
  static bool get hasRefresh => (refreshToken?.isNotEmpty ?? false);

  /// detect remember-me (persist) from storage location
  static bool get isPersisted =>
      html.window.localStorage.containsKey(_accessKey);

  /// persist=true  -> localStorage
  /// persist=false -> sessionStorage
  static void saveSession({
    required String accessToken,
    String? refreshToken,
    required bool persist,
  }) {
    _memoryAccess = accessToken;
    _memoryRefresh = refreshToken;

    if (persist) {
      html.window.sessionStorage.remove(_accessKey);
      html.window.sessionStorage.remove(_refreshKey);

      html.window.localStorage[_accessKey] = accessToken;
      if (refreshToken != null && refreshToken.trim().isNotEmpty) {
        html.window.localStorage[_refreshKey] = refreshToken.trim();
      } else {
        html.window.localStorage.remove(_refreshKey);
      }
    } else {
      html.window.localStorage.remove(_accessKey);
      html.window.localStorage.remove(_refreshKey);

      html.window.sessionStorage[_accessKey] = accessToken;
      if (refreshToken != null && refreshToken.trim().isNotEmpty) {
        html.window.sessionStorage[_refreshKey] = refreshToken.trim();
      } else {
        html.window.sessionStorage.remove(_refreshKey);
      }
    }

    _rev.value++;
  }

  /// Backward compat: old callers
  static void saveToken(String token, {required bool persist}) {
    saveSession(accessToken: token, refreshToken: refreshToken, persist: persist);
  }

  static void clear() {
    _memoryAccess = null;
    _memoryRefresh = null;

    html.window.localStorage.remove(_accessKey);
    html.window.localStorage.remove(_refreshKey);

    html.window.sessionStorage.remove(_accessKey);
    html.window.sessionStorage.remove(_refreshKey);

    _rev.value++;
  }
}
