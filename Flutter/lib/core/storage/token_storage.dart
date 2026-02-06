import 'dart:html' as html;
import 'package:flutter/foundation.dart';

class TokenStorage {
  static const _key = 'learnova_access_token';

  static String? _memoryToken;

  // عشان GoRouter يعمل refresh لما التوكين يتغير
  static final ValueNotifier<int> _rev = ValueNotifier<int>(0);
  static Listenable get listenable => _rev;

  static String? get token =>
      _memoryToken ??
      html.window.sessionStorage[_key] ??
      html.window.localStorage[_key];

  static bool get hasToken => (token?.isNotEmpty ?? false);

  /// persist=true  -> localStorage (يفضل بعد refresh وإغلاق المتصفح)
  /// persist=false -> sessionStorage (يفضل بعد refresh داخل نفس التاب)
  static void saveToken(String token, {required bool persist}) {
    _memoryToken = token;

    if (persist) {
      html.window.sessionStorage.remove(_key);
      html.window.localStorage[_key] = token;
    } else {
      html.window.localStorage.remove(_key);
      html.window.sessionStorage[_key] = token;
    }

    _rev.value++; // notify router
  }

  static void clear() {
    _memoryToken = null;
    html.window.localStorage.remove(_key);
    html.window.sessionStorage.remove(_key);

    _rev.value++; // notify router
  }
}
