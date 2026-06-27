import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';

import '../config/env.dart';
import '../log/app_logger.dart';
import '../storage/token_storage.dart';
import '../ui/global_loading_bus.dart';
import 'api_exceptions.dart';
import 'dio_adapter_config.dart';
import 'endpoints.dart';
import 'i_token_refresh_scheduler.dart';
import 'jwt_access_token.dart';
import 'refresh_client.dart';


class SseEvent {
  final String event;
  final String data;
  final Map<String, dynamic>? jsonData;

  const SseEvent({
    required this.event,
    this.data = '',
    this.jsonData,
  });

  bool get isReady => event == 'ready';
  bool get isTimeout => event == 'timeout';
  bool get isError => event == 'error';

  String? get detail {
    final raw = jsonData?['detail'] ?? jsonData?['message'] ?? jsonData?['error'];
    final text = raw?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }
}

/// HTTP client built on Dio.
/// Also implements [ITokenRefreshScheduler] so the repository layer can depend
/// on the narrow interface rather than the full ApiClient.
class ApiClient implements ITokenRefreshScheduler {
  ApiClient({Dio? dio, RefreshClient? refreshClient})
      : _dio = dio ?? Dio(),
        _refreshClient = refreshClient ?? createRefreshClient() {
        _dio.options = BaseOptions(
          baseUrl: Env.baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          sendTimeout: const Duration(seconds: 15),
          headers: const {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'ngrok-skip-browser-warning': 'true',
          },
        );
    configureDioAdapter(_dio);

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          GlobalLoadingBus.beginIfNeeded(options);

          options.headers['ngrok-skip-browser-warning'] = 'true';

          var token = TokenStorage.token?.trim();

          // Web timers can be throttled when the tab is inactive, so relying
          // only on a proactive Timer is not enough. Before every protected
          // request, silently refresh if the access JWT is already close to
          // expiry. This prevents the app from sending an expired Bearer token
          // and then being redirected out of the dashboard.
          if (Env.enableRefreshToken &&
              token != null &&
              token.isNotEmpty &&
              !_isAuthPath(options.path) &&
              _shouldRefreshBeforeRequest(token)) {
            try {
              final fresh = await _refreshAccessTokenWithRecovery(
                logFailure: false,
              );
              TokenStorage.saveSession(
                accessToken: fresh,
                persist: TokenStorage.isPersisted,
              );
              scheduleProactiveRefresh(fresh);
              token = fresh.trim();
            } catch (_) {
              // Keep the current token on the request. If it really is expired,
              // the 401 interceptor below will perform the normal reactive
              // refresh flow and show a session-expired state only after the
              // refresh cookie is confirmed invalid.
            }
          }

          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          handler.next(options);
        },
        onResponse: (response, handler) {
          GlobalLoadingBus.endIfNeeded(response.requestOptions);
          handler.next(response);
        },
        onError: (DioException e, handler) async {
          // Optional: retry GET once on transient network errors
          if (_shouldRetryGetOnce(e)) {
            try {
              final res = await _retryOnce(e.requestOptions);
              return handler.resolve(res);
            } catch (_) {
              // continue to normal error handling
            }
          }

          final status = e.response?.statusCode;

          // Conditions to attempt a token refresh:
          // – refresh feature enabled in env
          // – 401 response
          // – we have a token (otherwise the user is already logged out)
          // – not an auth endpoint (avoid refresh-loops)
          // – not already retried for this request
          final shouldTryRefresh = Env.enableRefreshToken &&
              status == 401 &&
              _canAttemptRefresh() &&
              !_isAuthPath(e.requestOptions.path) &&
              !_hasAuthRetried(e.requestOptions);

          if (shouldTryRefresh) {
            String newAccess;
            try {
              newAccess = await _refreshAccessTokenWithRecovery();
            } catch (refreshError) {
              GlobalLoadingBus.endIfNeeded(e.requestOptions);

              // Only destroy the local session when the refresh endpoint
              // explicitly says the refresh credential is invalid/expired.
              // Network errors, timeouts, server restarts, or 5xx responses are
              // transient infrastructure failures; clearing tokens here creates
              // a fake logout while the user may still have a valid refresh
              // cookie once the backend is reachable again.
              if (_isRefreshAuthFailure(refreshError)) {
                TokenStorage.clear();

                return handler.reject(
                  DioException(
                    requestOptions: e.requestOptions,
                    response: e.response,
                    type: e.type,
                    error: ApiException(
                      'Your session expired. Please login again.',
                      statusCode: status,
                      code: 'TOKEN_EXPIRED',
                    ),
                    message: e.message,
                  ),
                );
              }

              final refreshUnavailable =
                  _mapRefreshUnavailableError(e.requestOptions, refreshError);
              return handler.reject(refreshUnavailable);
            }

            TokenStorage.saveSession(
              accessToken: newAccess,
              persist: TokenStorage.isPersisted,
            );

            // Reschedule proactive refresh for the new token lifetime.
            scheduleProactiveRefresh(newAccess);

            try {
              final retryResponse =
                  await _retryWithNewToken(e.requestOptions, newAccess);
              return handler.resolve(retryResponse);
            } on DioException catch (retryError) {
              GlobalLoadingBus.endIfNeeded(e.requestOptions);
              return handler.reject(_mapRetryAfterRefreshError(retryError));
            } catch (retryError) {
              GlobalLoadingBus.endIfNeeded(e.requestOptions);
              return handler.reject(
                DioException(
                  requestOptions: e.requestOptions,
                  response: e.response,
                  error: ApiException(
                    'Request could not be completed. Please try again.',
                    code: 'AUTH_RETRY_FAILED',
                  ),
                  message: retryError.toString(),
                ),
              );
            }
          }

          // Normal error mapping
          GlobalLoadingBus.endIfNeeded(e.requestOptions);

          final msg = _pickErrorMessage(e);

          return handler.reject(
            DioException(
              requestOptions: e.requestOptions,
              response: e.response,
              type: e.type,
              error: ApiException(
                msg,
                statusCode: status,
                code: _mapCode(status, e.response?.data, requestOptions: e.requestOptions),
              ),
              message: msg,
            ),
          );
        },
      ),
    );
  }

  final Dio _dio;
  final RefreshClient _refreshClient;

  // ── Proactive refresh timer (ITokenRefreshScheduler) ───────────────────────
  //
  // Fires 2 minutes before the JWT expires so the user never hits a 401 mid-
  // session. After every successful refresh (reactive or proactive) we cancel
  // the old timer and schedule a new one for the replacement token.

  Timer? _proactiveTimer;

  @override
  void scheduleProactiveRefresh(String accessToken) {
    _proactiveTimer?.cancel();
    _proactiveTimer = null;

    final expiry = JwtAccessToken.expiryOf(accessToken);
    if (expiry == null) return;

    final now = DateTime.now().toUtc();
    if (expiry.isBefore(now)) return;

    final fireAt = expiry.subtract(const Duration(minutes: 2));
    final delay = fireAt.isAfter(now)
        ? fireAt.difference(now)
        : const Duration(seconds: 30);

    _proactiveTimer = Timer(delay, _proactiveRefresh);
  }

  @override
  void cancelProactiveRefresh() {
    _proactiveTimer?.cancel();
    _proactiveTimer = null;
  }

  void dispose() {
    cancelProactiveRefresh();
  }

  Future<void> _proactiveRefresh() async {
    if (!TokenStorage.hasToken) return;

    try {
      final newToken = await _refreshAccessTokenWithRecovery();

      TokenStorage.saveSession(
        accessToken: newToken,
        persist: TokenStorage.isPersisted,
      );

      scheduleProactiveRefresh(newToken);
    } catch (_) {
      // Proactive refresh failed. Reactive 401 interceptor will handle it.
    }
  }

  // ── Public HTTP methods ────────────────────────────────────────────────────


  Future<SseEvent> waitForSseEvent(
    String path, {
    CancelToken? cancelToken,
    Duration receiveTimeout = const Duration(minutes: 5),
    Set<String> terminalEvents = const <String>{'ready', 'timeout', 'error'},
  }) async {
    final response = await _dio.get<ResponseBody>(
      path,
      options: Options(
        responseType: ResponseType.stream,
        receiveTimeout: receiveTimeout,
        headers: const <String, dynamic>{
          'Accept': 'text/event-stream',
          'Cache-Control': 'no-cache',
        },
        extra: const <String, dynamic>{'silent': true},
      ),
      cancelToken: cancelToken,
    );

    final stream = response.data?.stream;
    if (stream == null) {
      throw const FormatException('Invalid SSE response stream');
    }

    String eventName = 'message';
    final dataLines = <String>[];

    SseEvent dispatchEvent() {
      final rawData = dataLines.join('\n').trim();
      Map<String, dynamic>? jsonData;
      if (rawData.isNotEmpty) {
        try {
          final decoded = jsonDecode(rawData);
          if (decoded is Map) {
            jsonData = Map<String, dynamic>.from(decoded);
          }
        } catch (_) {
          jsonData = null;
        }
      }
      final emitted = SseEvent(
        event: eventName.trim().isEmpty ? 'message' : eventName.trim(),
        data: rawData,
        jsonData: jsonData,
      );
      eventName = 'message';
      dataLines.clear();
      return emitted;
    }

    final lineStream = stream
        .map<List<int>>((chunk) => chunk)
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    await for (final line in lineStream) {
      if (line.trim().isEmpty) {
        if (dataLines.isEmpty && eventName == 'message') continue;
        final emitted = dispatchEvent();
        if (terminalEvents.contains(emitted.event)) return emitted;
        continue;
      }

      if (line.startsWith(':')) continue;
      if (line.startsWith('event:')) {
        eventName = line.substring('event:'.length).trim();
        continue;
      }
      if (line.startsWith('data:')) {
        dataLines.add(line.substring('data:'.length).trimLeft());
        continue;
      }
    }

    if (dataLines.isNotEmpty || eventName != 'message') {
      return dispatchEvent();
    }

    return const SseEvent(
      event: 'closed',
      data: 'The server closed the event stream before sending a terminal event.',
    );
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) =>
      _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) =>
      _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) =>
      _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) =>
      _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) =>
      _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );

  // ── Retry helpers ────────────────────────────────────────────────────────────

  bool _shouldRetryGetOnce(DioException e) {
    if (e.requestOptions.method.toUpperCase() != 'GET') return false;
    if (e.requestOptions.extra['__getRetried'] == true) return false;

    return e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError;
  }

  Future<Response<dynamic>> _retryOnce(RequestOptions o) async {
    final opts = Options(
      method: o.method,
      headers: o.headers,
      responseType: o.responseType,
      contentType: o.contentType,
      followRedirects: o.followRedirects,
      validateStatus: o.validateStatus,
      receiveDataWhenStatusError: o.receiveDataWhenStatusError,
      extra: {...o.extra, '__getRetried': true},
    );

    return _dio.request<dynamic>(
      o.path,
      data: o.data,
      queryParameters: o.queryParameters,
      options: opts,
      cancelToken: o.cancelToken,
      onReceiveProgress: o.onReceiveProgress,
      onSendProgress: o.onSendProgress,
    );
  }

  // ── Refresh token (single-flight) ──────────────────────────────────────────

  Future<String>? _refreshFuture;

  Future<String> _refreshAccessToken({bool logFailure = true}) {
    final inFlight = _refreshFuture;
    if (inFlight != null) return inFlight;

    final future = _callRefreshEndpoint(logFailure: logFailure).whenComplete(() {
      _refreshFuture = null;
    });

    _refreshFuture = future;
    return future;
  }

  Future<String> refreshAccessToken({bool logFailure = true}) =>
      _refreshAccessTokenWithRecovery(logFailure: logFailure);

  Future<String> _refreshAccessTokenWithRecovery({bool logFailure = true}) async {
    try {
      return await _refreshAccessToken(logFailure: logFailure);
    } catch (error) {
      if (!_isRefreshAuthFailure(error)) rethrow;

      // A refresh cookie can be rotated by another in-flight request or tab.
      // Give the browser a short moment to apply the newest Set-Cookie, then
      // retry once before deciding the session is actually expired.
      await Future<void>.delayed(const Duration(milliseconds: 450));
      return _refreshAccessToken(logFailure: logFailure);
    }
  }

  Future<String> _callRefreshEndpoint({bool logFailure = true}) async {
    final url = '${Env.baseUrl}${Endpoints.refresh}';
    try {
      return await _refreshClient.refresh(url: url);
    } catch (e, st) {
      // 401/403 from /auth/refresh is an expected auth state, not an
      // infrastructure error. During app startup this simply means there is no
      // valid HttpOnly refresh cookie, especially after manually clearing
      // cookies/storage in DevTools. Do not spam the console with a warning.
      if (logFailure && !_isRefreshAuthFailure(e)) {
        AppLogger.log(
          'Refresh token call failed.',
          level: LogLevel.warn,
          error: e,
          stackTrace: st,
        );
      }
      rethrow;
    }
  }

  bool _isRefreshAuthFailure(Object error) {
    final ex = _extractApiException(error);
    final status = ex?.statusCode;
    final code = ex?.cleanCode;

    return status == 401 ||
        status == 403 ||
        code == 'REFRESH_AUTH_FAILED' ||
        code == 'REFRESH_EXPIRED' ||
        code == 'REFRESH_REVOKED';
  }

  ApiException? _extractApiException(Object error) {
    if (error is ApiException) return error;
    if (error is DioException && error.error is ApiException) {
      return error.error as ApiException;
    }
    return null;
  }

  DioException _mapRefreshUnavailableError(
    RequestOptions originalRequest,
    Object refreshError,
  ) {
    final ex = _extractApiException(refreshError);
    final code = ex?.cleanCode;
    final status = ex?.statusCode;

    final isTimeout = code == 'REFRESH_TIMEOUT';
    final message = isTimeout
        ? 'Could not refresh your session because the server timed out. Please try again.'
        : 'Could not refresh your session because the server is unavailable. Please try again.';

    return DioException(
      requestOptions: originalRequest,
      type: isTimeout
          ? DioExceptionType.receiveTimeout
          : DioExceptionType.connectionError,
      error: ApiException(
        message,
        statusCode: status,
        code: code ?? 'REFRESH_UNAVAILABLE',
      ),
      message: message,
    );
  }


  DioException _mapRetryAfterRefreshError(DioException e) {
    final status = e.response?.statusCode;
    if (status == 401) {
      return DioException(
        requestOptions: e.requestOptions,
        response: e.response,
        type: e.type,
        error: ApiException(
          'Request could not be completed. Please try again.',
          statusCode: status,
          code: 'AUTH_RETRY_FAILED',
        ),
        message: 'auth_retry_failed',
      );
    }
    return e;
  }

  bool _hasAuthRetried(RequestOptions o) => o.extra['__authRetried'] == true;

  Future<Response<dynamic>> _retryWithNewToken(
    RequestOptions o,
    String accessToken,
  ) async {
    final opts = Options(
      method: o.method,
      headers: {
        ...o.headers,
        'Authorization': 'Bearer ${accessToken.trim()}',
      },
      responseType: o.responseType,
      contentType: o.contentType,
      followRedirects: o.followRedirects,
      validateStatus: o.validateStatus,
      receiveDataWhenStatusError: o.receiveDataWhenStatusError,
      extra: {...o.extra, '__authRetried': true},
    );

    return _dio.request<dynamic>(
      o.path,
      data: o.data,
      queryParameters: o.queryParameters,
      options: opts,
      cancelToken: o.cancelToken,
      onReceiveProgress: o.onReceiveProgress,
      onSendProgress: o.onSendProgress,
    );
  }


  bool _shouldRefreshBeforeRequest(String accessToken) {
    final timeLeft = _accessTokenTimeLeft(accessToken);
    if (timeLeft == null) return false;
    return timeLeft <= const Duration(seconds: 90);
  }

  Duration? _accessTokenTimeLeft(String accessToken) =>
      JwtAccessToken.timeLeft(accessToken);

  bool _canAttemptRefresh() {
    return TokenStorage.hasToken || TokenStorage.isPersisted;
  }

  bool _isAuthPath(String path) {
    return path.contains(Endpoints.login) ||
        path.contains(Endpoints.signup) ||
        path.contains(Endpoints.refresh);
  }

  String _pickErrorMessage(DioException e) {
    final status = e.response?.statusCode;
    if (status == 401) {
      return _hasAuthRetried(e.requestOptions)
          ? 'Request could not be completed. Please try again.'
          : 'Your session expired. Please login again.';
    }
    if (status == 403) {
      return 'Access denied.';
    }

    final data = e.response?.data;

    try {
      if (data is Map) {
        final m = data.cast<String, dynamic>();
        final directRaw = m['detail'] ?? m['message'] ?? m['error'];
        if (directRaw is String && directRaw.trim().isNotEmpty) {
          return directRaw.trim();
        }

        final detail = m['detail'];
        if (detail is List && detail.isNotEmpty) {
          final messages = <String>[];
          for (final item in detail) {
            if (item is Map) {
              final loc = item['loc'];
              final msg = item['msg']?.toString();
              if (msg != null && msg.trim().isNotEmpty) {
                if (loc is List && loc.isNotEmpty) {
                  messages.add('${loc.join('.')}: ${msg.trim()}');
                } else {
                  messages.add(msg.trim());
                }
              } else {
                final text = item.toString().trim();
                if (text.isNotEmpty) messages.add(text);
              }
            } else {
              final text = item.toString().trim();
              if (text.isNotEmpty) messages.add(text);
            }
          }
          if (messages.isNotEmpty) return messages.join('\n');
        }

        final inner = m['data'];
        if (inner is Map) {
          final innerMsg = (inner['message'] ?? inner['error'])?.toString();
          if (innerMsg != null && innerMsg.trim().isNotEmpty) {
            return innerMsg.trim();
          }
        }

        final errs = m['errors'];
        if (errs is List && errs.isNotEmpty) {
          final first = errs.first;
          if (first is Map) {
            final msg = first['message']?.toString();
            if (msg != null && msg.trim().isNotEmpty) return msg.trim();
          }
        }
      }
    } catch (_) {}

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return 'Request timed out. Please try again.';
    }

    if (e.type == DioExceptionType.connectionError) {
      return 'Network error. Check your connection and try again.';
    }

    return e.message?.trim().isNotEmpty ?? false
        ? e.message!.trim()
        : 'Something went wrong. Please try again.';
  }

  String _mapCode(int? status, dynamic data, {RequestOptions? requestOptions}) {
    if (status == null) return 'UNKNOWN';
    if (status == 400) return 'BAD_REQUEST';
    if (status == 401) {
      return requestOptions != null && _hasAuthRetried(requestOptions)
          ? 'AUTH_RETRY_FAILED'
          : 'UNAUTHORIZED';
    }
    if (status == 403) return 'FORBIDDEN';
    if (status == 404) return 'NOT_FOUND';
    if (status >= 500) return 'SERVER_ERROR';

    try {
      if (data is Map) {
        final m = data.cast<String, dynamic>();
        final code = m['code']?.toString();
        if (code != null && code.trim().isNotEmpty) return code.trim();
      }
    } catch (_) {}
    return 'HTTP_$status';
  }
}
