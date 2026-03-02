import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../error/app_error_bus.dart';
import '../network/error_mapper.dart';
import '../storage/token_storage.dart';
import '../storage/user_storage.dart';
import '../../features/auth/data/auth_providers.dart';

/// Bootstraps the session on cold start or after a storage change.
///
/// Two startup scenarios are handled:
///
/// A) **Normal tab session** – TokenStorage.hasToken is true (sessionStorage
///    still alive). Just call /me and populate UserStorage.
///
/// B) **Remember-Me cold start** – The tab was closed and re-opened.
///    sessionStorage is gone, so hasToken is false. BUT isPersisted is true
///    (localStorage flag). In this case we first attempt a silent refresh
///    (the HttpOnly refresh cookie does the heavy lifting), then call /me.
///
/// This means users who checked "Remember Me" are transparently logged back
/// in after closing and re-opening the browser — matching the backend's
/// 30-day refresh-token window.
final sessionBootstrapControllerProvider =
    NotifierProvider<SessionBootstrapController, AsyncValue<void>>(
  SessionBootstrapController.new,
);

class SessionBootstrapController extends Notifier<AsyncValue<void>> {
  CancelToken? _cancelToken;
  String? _lastToken;

  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> ensureBootstrapped() async {
    // ── Scenario B: remember-me cold start (no token in sessionStorage) ──
    if (!TokenStorage.hasToken && TokenStorage.isPersisted) {
      await _silentRefreshThenBoot();
      return;
    }

    // ── Scenario A: token exists in sessionStorage ──
    final token = TokenStorage.token?.trim() ?? '';
    if (token.isEmpty) {
      _reset();
      return;
    }

    if (UserStorage.hasMe) {
      _lastToken = token;
      state = const AsyncData(null);
      return;
    }

    if (_lastToken == token && state.isLoading) return;

    await _fetchMe(token);
  }

  // ─── silent refresh → /me ───────────────────────────────────────────────

  Future<void> _silentRefreshThenBoot() async {
    state = const AsyncLoading();

    try {
      final api = ref.read(authApiProvider);

      // This call sends the HttpOnly refresh cookie automatically (withCredentials).
      final newToken = await api.refresh();

      TokenStorage.saveSession(
        accessToken: newToken,
        persist: true, // keep remember-me alive
      );
      // Start proactive refresh timer after silent re-auth.
      ref.read(apiClientProvider).scheduleProactiveRefresh(newToken);

      await _fetchMe(newToken);
    } catch (e, st) {
      // Refresh cookie expired or server error → clear everything, go to login.
      TokenStorage.clear();
      UserStorage.clear();

      final failure = mapApiFailure(e);
      AppErrorReporter.report(ref, failure);
      state = AsyncError(e, st);
    }
  }

  // ─── /me fetch ──────────────────────────────────────────────────────────

  Future<void> _fetchMe(String token) async {
    _cancelToken?.cancel('superseded');
    final ct = CancelToken();
    _cancelToken = ct;
    _lastToken = token;

    state = const AsyncLoading();

    try {
      final api = ref.read(authApiProvider);
      final raw = await api.me(cancelToken: ct);
      if (ct.isCancelled) return;

      final persist = TokenStorage.isPersisted;
      final normalized = _normalizeMePayload(raw);
      UserStorage.saveMe(normalized, persist: persist);

      state = const AsyncData(null);
    } catch (e, st) {
      if (e is DioException && e.type == DioExceptionType.cancel) {
        state = const AsyncData(null);
        return;
      }

      final failure = mapApiFailure(e);
      AppErrorReporter.report(ref, failure);
      state = AsyncError(e, st);
    }
  }

  // ─── helpers ────────────────────────────────────────────────────────────

  Map<String, dynamic> _normalizeMePayload(Map<String, dynamic> raw) {
    Map<String, dynamic> root = raw;
    final data = root['data'];
    if (data is Map) root = data.cast<String, dynamic>();

    Map<String, dynamic> user;
    final u = root['user'];
    if (u is Map) {
      user = u.cast<String, dynamic>();
    } else {
      user = root;
    }

    final out = <String, dynamic>{'user': user};

    final orgs = root['organizations'];
    if (orgs is List) {
      out['organizations'] =
          orgs.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
    } else if (orgs is Map) {
      out['organizations'] = [orgs.cast<String, dynamic>()];
    }

    final list =
        (out['organizations'] is List) ? out['organizations'] as List : const [];
    if (list.isNotEmpty && out['selected_organization_id'] == null) {
      final first = list.first;
      if (first is Map) {
        final id = first['id'];
        if (id != null) out['selected_organization_id'] = id;
      }
    }

    return out;
  }

  void _reset() {
    _cancelToken?.cancel('reset');
    _cancelToken = null;
    _lastToken = null;
    state = const AsyncData(null);
  }
}
