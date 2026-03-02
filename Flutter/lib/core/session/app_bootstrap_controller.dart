import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/token_storage.dart';
import '../storage/user_storage.dart';
import '../../features/auth/data/auth_providers.dart';

/// The global bootstrap state.
///
/// The splash screen is shown exactly while [AppBootstrapState.inProgress].
/// It transitions to [done] once (per full app load), never again.
enum AppBootstrapState { inProgress, done }

final appBootstrapControllerProvider =
    NotifierProvider<AppBootstrapController, AppBootstrapState>(
  AppBootstrapController.new,
);

class AppBootstrapController extends Notifier<AppBootstrapState> {
  @override
  AppBootstrapState build() => AppBootstrapState.inProgress;

  /// Called once from the root widget's initState.
  /// Determines auth state, loads user if needed, then marks done.
  Future<void> bootstrap() async {
    // Already done — never run twice in the same app lifecycle.
    if (state == AppBootstrapState.done) return;

    try {
      final hasToken   = TokenStorage.hasToken;
      final isPersisted = TokenStorage.isPersisted;

      if (!hasToken && !isPersisted) {
        // Guest — nothing to load.
        state = AppBootstrapState.done;
        return;
      }

      if (UserStorage.hasMe) {
        // Session already hydrated (shouldn't happen on cold start, but safe).
        state = AppBootstrapState.done;
        return;
      }

      final api = ref.read(authApiProvider);

      // Remember-Me cold start: sessionStorage token is gone, but the
      // HttpOnly refresh cookie is alive. Silently re-mint the access token.
      if (!hasToken && isPersisted) {
        final newToken = await api.refresh();
        TokenStorage.saveSession(accessToken: newToken, persist: true);
      }

      // Load user profile.
      final raw = await api.me();
      final normalized = _normalize(raw);
      UserStorage.saveMe(normalized, persist: TokenStorage.isPersisted);
    } catch (_) {
      // Any failure → treat as guest. Clear stale session.
      TokenStorage.clear();
      UserStorage.clear();
    } finally {
      state = AppBootstrapState.done;
    }
  }

  // ── Normalize /me response shape ─────────────────────────────────────────

  static Map<String, dynamic> _normalize(Map<String, dynamic> raw) {
    Map<String, dynamic> root = raw;
    final data = root['data'];
    if (data is Map) root = data.cast<String, dynamic>();

    final u = root['user'];
    final user = (u is Map) ? u.cast<String, dynamic>() : root;
    final out  = <String, dynamic>{'user': user};

    final orgs = root['organizations'];
    if (orgs is List) {
      out['organizations'] =
          orgs.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
    } else if (orgs is Map) {
      out['organizations'] = [orgs.cast<String, dynamic>()];
    }

    final list = (out['organizations'] is List)
        ? out['organizations'] as List
        : const [];
    if (list.isNotEmpty && out['selected_organization_id'] == null) {
      final first = list.first;
      if (first is Map) {
        final id = first['id'];
        if (id != null) out['selected_organization_id'] = id;
      }
    }

    return out;
  }
}
