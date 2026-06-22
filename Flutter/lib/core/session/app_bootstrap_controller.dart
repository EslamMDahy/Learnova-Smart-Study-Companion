import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../network/api_exceptions.dart';
import '../storage/token_storage.dart';
import '../storage/user_storage.dart';
import '../../features/auth/data/auth_providers.dart';

enum AppBootstrapState { inProgress, done }

final appBootstrapControllerProvider =
    NotifierProvider<AppBootstrapController, AppBootstrapState>(
  AppBootstrapController.new,
);

class AppBootstrapController extends Notifier<AppBootstrapState> {
  @override
  AppBootstrapState build() => AppBootstrapState.inProgress;

  Future<void> bootstrap() async {
    if (state == AppBootstrapState.done) return;

    try {
      final hasToken = TokenStorage.hasToken;
      final isPersisted = TokenStorage.isPersisted;

      if (!hasToken && !isPersisted) {
        state = AppBootstrapState.done;
        return;
      }

      final currentToken = TokenStorage.token?.trim();
      final needsRefresh = currentToken == null ||
          currentToken.isEmpty ||
          _shouldRefreshAccessToken(currentToken);

      if (!needsRefresh && UserStorage.hasMe && hasToken) {
        ref.read(apiClientProvider).scheduleProactiveRefresh(currentToken);
        state = AppBootstrapState.done;
        return;
      }

      final api = ref.read(authApiProvider);

      if (needsRefresh) {
        try {
          final newToken = await api.refresh(logFailure: false);
          TokenStorage.saveSession(
            accessToken: newToken,
            persist: isPersisted,
          );
          ref.read(apiClientProvider).scheduleProactiveRefresh(newToken);
        } catch (e) {
          // Refresh auth failure means the cookie/token is invalid, so logout.
          // Infrastructure failure (server down/restarting/timeout) must not
          // destroy the saved session; the user can recover when the backend
          // is available again.
          if (_isRefreshAuthFailure(e)) {
            TokenStorage.clear();
            UserStorage.clear();
          }
          state = AppBootstrapState.done;
          return;
        }
      } else {
        ref.read(apiClientProvider).scheduleProactiveRefresh(currentToken);
      }

      final raw = await api.me();
      final normalized = _normalize(raw);

      final existing = UserStorage.meJson;
      final Map<String, dynamic> merged;

      if (existing != null) {
        final existingUser = (existing['user'] is Map)
            ? (existing['user'] as Map).cast<String, dynamic>()
            : <String, dynamic>{};

        final newUser = (normalized['user'] is Map)
            ? (normalized['user'] as Map).cast<String, dynamic>()
            : <String, dynamic>{};

        final mergedUser = <String, dynamic>{...existingUser};
        newUser.forEach((k, v) {
          if (v != null) mergedUser[k] = v;
        });

        merged = {
          ...existing,
          ...normalized,
          'user': mergedUser,
        };
      } else {
        merged = normalized;
      }

      UserStorage.saveMe(merged, persist: TokenStorage.isPersisted);
    } catch (e) {
      // Do not log the user out just because /auth/me could not be reached
      // during startup. Only explicit 401/403 auth responses should clear the
      // local session.
      if (_isAuthFailure(e)) {
        TokenStorage.clear();
        UserStorage.clear();
      }
    } finally {
      state = AppBootstrapState.done;
    }
  }

  static bool _isRefreshAuthFailure(Object error) {
    final ex = _extractApiException(error);
    final status = ex?.statusCode;
    final code = ex?.cleanCode;

    return status == 401 ||
        status == 403 ||
        code == 'REFRESH_AUTH_FAILED' ||
        code == 'REFRESH_EXPIRED' ||
        code == 'REFRESH_REVOKED';
  }

  static bool _isAuthFailure(Object error) {
    final ex = _extractApiException(error);
    final status = ex?.statusCode;
    return status == 401 || status == 403;
  }

  static ApiException? _extractApiException(Object error) {
    if (error is ApiException) return error;
    if (error is DioException && error.error is ApiException) {
      return error.error as ApiException;
    }
    if (error is DioException) {
      final status = error.response?.statusCode;
      if (status != null) {
        return ApiException(
          error.message ?? 'Request failed.',
          statusCode: status,
        );
      }
    }
    return null;
  }

  static bool _shouldRefreshAccessToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;

      String pad(String s) {
        final rem = s.length % 4;
        return rem == 0 ? s : s + '=' * (4 - rem);
      }

      final payload = jsonDecode(
        utf8.decode(base64Url.decode(pad(parts[1]))),
      ) as Map<String, dynamic>;

      final exp = payload['exp'];
      if (exp is! num) return true;

      final expiry = DateTime.fromMillisecondsSinceEpoch(
        exp.toInt() * 1000,
        isUtc: true,
      );

      final refreshBefore = DateTime.now()
          .toUtc()
          .add(const Duration(minutes: 2));

      return !expiry.isAfter(refreshBefore);
    } catch (_) {
      return true;
    }
  }

  static Map<String, dynamic> _normalize(Map<String, dynamic> raw) {
    Map<String, dynamic> root = raw;
    final data = root['data'];
    if (data is Map) {
      root = data.cast<String, dynamic>();
    }

    final u = root['user'];
    final user = (u is Map) ? u.cast<String, dynamic>() : root;

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
        if (id != null) {
          out['selected_organization_id'] = id;
        }
      }
    }

    return out;
  }
}
