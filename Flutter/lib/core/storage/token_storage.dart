// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/foundation.dart';

/// Manages access-token storage across the session lifetime.
///
/// Design:
/// - Access token lives in sessionStorage (tab-scoped, cleared on close).
/// - A lightweight `_persistKey` flag is written to localStorage whenever the
///   user chooses "Remember Me". It survives browser/tab close.
/// - On cold start, SessionBootstrapper checks [isPersisted]. If true it fires
///   a silent refresh call so the HttpOnly refresh cookie re-mints a fresh
///   access token — restoring the session transparently.
/// - The actual refresh secret is in an HttpOnly cookie managed by the backend.
///   This class never stores or reads the refresh token value directly.
///
/// Edge-case — unverified login:
/// - When a 403 "Email not verified" error occurs on login, the email is stored
///   in [pendingVerificationEmail] (localStorage so it survives browser close).
///   On next cold start the router checks this flag and redirects to the
///   verify-email-sent screen so the user always has a way forward.
class TokenStorage {
  TokenStorage._();

  static const _accessKey   = 'learnova_access_token';
  static const _persistKey  = 'learnova_persist';       // remember-me flag
  static const _pendingKey  = 'learnova_pending_verify'; // unverified email

  static String? _memoryAccess;

  static final ValueNotifier<int> _rev = ValueNotifier<int>(0);
  static Listenable get listenable => _rev;

  // ─── getters ──────────────────────────────────────────────────────────────

  static String? get token =>
      _memoryAccess ??
      html.window.sessionStorage[_accessKey] ??
      html.window.localStorage[_accessKey];

  static bool get hasToken => (token ?? '').trim().isNotEmpty;

  /// True when the user last logged in with "Remember Me" checked.
  static bool get isPersisted =>
      html.window.localStorage.containsKey(_persistKey);

  /// Email that is pending verification (user tried to login but isn't verified).
  /// Stored in localStorage so it survives browser close.
  static String? get pendingVerificationEmail {
    final v = html.window.localStorage[_pendingKey];
    return (v != null && v.trim().isNotEmpty) ? v.trim() : null;
  }

  // ─── save ─────────────────────────────────────────────────────────────────

  static void saveSession({
    required String accessToken,
    required bool persist,
  }) {
    final trimmed = accessToken.trim();
    _memoryAccess = trimmed;

    html.window.sessionStorage[_accessKey] = trimmed;

    if (persist) {
      html.window.localStorage[_accessKey] = trimmed;
      html.window.localStorage[_persistKey] = '1';
    } else {
      html.window.localStorage.remove(_accessKey);
      html.window.localStorage.remove(_persistKey);
    }

    // Clear any pending verification state on successful login.
    html.window.localStorage.remove(_pendingKey);

    _rev.value++;
  }

  /// Store an email that is awaiting verification.
  /// Call this when the backend returns 403 "Email not verified" during login.
  static void setPendingVerificationEmail(String email) {
    final trimmed = email.trim();
    if (trimmed.isNotEmpty) {
      html.window.localStorage[_pendingKey] = trimmed;
    }
    _rev.value++;
  }

  /// Remove the pending verification email (e.g. on successful verification
  /// or on explicit logout from the verify screen).
  static void clearPendingVerificationEmail() {
    html.window.localStorage.remove(_pendingKey);
    _rev.value++;
  }

  /// Backward-compat wrapper.
  static void saveToken(String token, {required bool persist}) {
    saveSession(accessToken: token, persist: persist);
  }

  // ─── clear ────────────────────────────────────────────────────────────────

  static void clear() {
    _memoryAccess = null;
    html.window.sessionStorage.remove(_accessKey);
    html.window.localStorage.remove(_accessKey);
    html.window.localStorage.remove(_persistKey);
    html.window.localStorage.remove(_pendingKey);
    _rev.value++;
  }
}
