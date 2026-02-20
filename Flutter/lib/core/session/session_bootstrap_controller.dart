import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../error/app_error_bus.dart';
import '../network/error_mapper.dart';
import '../storage/token_storage.dart';
import '../storage/user_storage.dart';
import '../../features/auth/data/auth_providers.dart';

/// Bootstraps /me once after a valid token exists.
/// Goal: prevent role-based flicker & make router guards deterministic.
///
/// - Runs only when TokenStorage.hasToken && !UserStorage.hasMe
/// - Cancels previous request if re-triggered (reload / route refresh)
/// - Persists in the same storage location as the token (session vs local)
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
    final token = TokenStorage.token?.trim();
    final hasToken = token != null && token.isNotEmpty;

    if (!hasToken) {
      _reset();
      return;
    }

    if (UserStorage.hasMe) {
      _lastToken = token;
      state = const AsyncData(null);
      return;
    }

    // Guard: if we already tried with the same token and still loading, skip.
    if (_lastToken == token && state.isLoading) return;

    // Cancel previous in-flight attempt.
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
      // Silent on cancellation.
      if (e is DioException && e.type == DioExceptionType.cancel) {
        state = const AsyncData(null);
        return;
      }

      final failure = mapApiFailure(e);

      // Report globally (includes 401/403 dialog + logout + redirect).
      AppErrorReporter.report(ref, failure);

      // Keep state for a local retry UI (optional).
      state = AsyncError(e, st);
    }
  }

  Map<String, dynamic> _normalizeMePayload(Map<String, dynamic> raw) {
    // Expected shapes:
    // A) { user: {...}, organizations: [...] }
    // B) { id, email, system_role, ... }  -> treat as user
    // C) nested { data: {...} }          -> unwrap if exists
    Map<String, dynamic> root = raw;

    final data = root['data'];
    if (data is Map) {
      root = data.cast<String, dynamic>();
    }

    Map<String, dynamic> user;
    final u = root['user'];
    if (u is Map) {
      user = u.cast<String, dynamic>();
    } else {
      user = root;
    }

    final out = <String, dynamic>{
      'user': user,
    };

    // organizations (optional)
    final orgs = root['organizations'];
    if (orgs is List) {
      out['organizations'] =
          orgs.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
    } else if (orgs is Map) {
      out['organizations'] = [orgs.cast<String, dynamic>()];
    }

    // selected org (front-only convenience)
    final list = (out['organizations'] is List) ? out['organizations'] as List : const [];
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
