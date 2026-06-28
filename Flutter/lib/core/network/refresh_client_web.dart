// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;

import 'api_exceptions.dart';
import 'refresh_client.dart';

class _XhrRefreshClient implements RefreshClient {
  @override
  Future<String> refresh({required String url}) {
    final completer = Completer<String>();

    final xhr = html.HttpRequest()
      ..open('POST', url)
      ..timeout = 15000
      ..setRequestHeader('Content-Type', 'application/json')
      ..setRequestHeader('Accept', 'application/json')
      ..setRequestHeader('ngrok-skip-browser-warning', 'true')
      ..withCredentials = true; // sends HttpOnly cookie cross-origin

    xhr.onLoad.listen((_) {
      if (completer.isCompleted) return;
      try {
        final status = xhr.status ?? 0;
        if (status < 200 || status >= 400) {
          completer.completeError(
            ApiException(
              'Refresh failed: HTTP $status',
              statusCode: status,
              code: _refreshErrorCode(status),
            ),
          );
          return;
        }

        final body = xhr.responseText ?? '';
        final decoded = _parseJsonBody(body);
        final root = (decoded['data'] is Map)
            ? (decoded['data'] as Map).cast<String, dynamic>()
            : decoded;

        final token =
            (root['access_token'] ?? root['token'] ?? root['accessToken'])
                ?.toString();

        if (token == null || token.trim().isEmpty) {
          completer.completeError(
            ApiException(
              'Invalid refresh response.',
              statusCode: status,
              code: 'REFRESH_INVALID',
            ),
          );
          return;
        }

        completer.complete(token.trim());
      } catch (e) {
        completer.completeError(e);
      }
    });

    xhr.onError.listen((_) {
      if (completer.isCompleted) return;
      completer.completeError(
        ApiException(
          'Network error during token refresh.',
          code: 'REFRESH_NETWORK',
        ),
      );
    });

    xhr.onTimeout.listen((_) {
      if (completer.isCompleted) return;
      completer.completeError(
        ApiException(
          'Token refresh timed out.',
          code: 'REFRESH_TIMEOUT',
        ),
      );
    });

    xhr.send(); // no body needed — cookie is sent automatically
    return completer.future;
  }

  String _refreshErrorCode(int status) {
    if (status == 401 || status == 403) return 'REFRESH_AUTH_FAILED';
    if (status >= 500) return 'REFRESH_SERVER';
    return 'REFRESH_FAILED';
  }

  Map<String, dynamic> _parseJsonBody(String body) {
    try {
      return (jsonDecode(body) as Map).cast<String, dynamic>();
    } catch (_) {
      return <String, dynamic>{};
    }
  }
}

/// Used by conditional import factory.
RefreshClient createRefreshClientImpl() => _XhrRefreshClient();
