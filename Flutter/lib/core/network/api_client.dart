import 'dart:async';
import 'package:dio/dio.dart';

import '../config/env.dart';
import '../storage/token_storage.dart';
import '../ui/global_loading_bus.dart';
import 'api_exceptions.dart';
import 'endpoints.dart';

class ApiClient {
  ApiClient({Dio? dio}) : _dio = dio ?? Dio() {
    _dio.options = BaseOptions(
      baseUrl: Env.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // ✅ global loading (unless silent)
          GlobalLoadingBus.beginIfNeeded(options);

          final token = TokenStorage.token;
          if (token != null && token.trim().isNotEmpty) {
            options.headers['Authorization'] = 'Bearer ${token.trim()}';
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
              // continue mapping
            }
          }

          final status = e.response?.statusCode;

          // Refresh flow (if enabled)
          final shouldTryRefresh =
              Env.enableRefreshToken &&
              (status == 401 || status == 403) &&
              TokenStorage.isPersisted &&
              TokenStorage.hasRefresh &&
              !_isAuthPath(e.requestOptions.path) &&
              !_hasAuthRetried(e.requestOptions);

          if (shouldTryRefresh) {
            try {
              final newAccess = await _refreshAccessToken();

              TokenStorage.saveSession(
                accessToken: newAccess,
                refreshToken: TokenStorage.refreshToken,
                persist: true,
              );

              final retryResponse =
                  await _retryWithNewToken(e.requestOptions, newAccess);

              return handler.resolve(retryResponse);
            } catch (_) {
              TokenStorage.clear();
              GlobalLoadingBus.endIfNeeded(e.requestOptions);

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
          }

          // Normal mapping
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
                code: _mapCode(status, e.response?.data),
              ),
              message: msg,
            ),
          );
        },
      ),
    );
  }

  final Dio _dio;

  // -------------------- public http methods --------------------

  /// Matches Dio signature naming (queryParameters) to avoid friction across the app.
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

  // -------------------- retry helpers --------------------

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
      extra: {
        ...o.extra,
        '__getRetried': true,
      },
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

  // -------------------- refresh token (single-flight) --------------------

  Completer<String>? _refreshCompleter;

  Future<String> _refreshAccessToken() async {
    if (_refreshCompleter != null) return _refreshCompleter!.future;

    final c = Completer<String>();
    _refreshCompleter = c;

    try {
      final rt = TokenStorage.refreshToken!;
      final newToken = await _callRefreshEndpoint(rt);
      c.complete(newToken);
      return newToken;
    } catch (e) {
      c.completeError(e);
      rethrow;
    } finally {
      _refreshCompleter = null;
    }
  }

  Future<String> _callRefreshEndpoint(String refreshToken) async {
    // Separate Dio to avoid interceptor recursion
    final d = Dio(
      BaseOptions(
        baseUrl: Env.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    final res = await d.post<Map<String, dynamic>>(
      Endpoints.refresh,
      data: {'refresh_token': refreshToken},
    );

    final payload = (res.data ?? <String, dynamic>{}).cast<String, dynamic>();
    final root = (payload['data'] is Map<String, dynamic>)
        ? (payload['data'] as Map<String, dynamic>)
        : payload;

    final newToken =
        (root['access_token'] ?? root['token'] ?? root['accessToken'])?.toString();

    if (newToken == null || newToken.trim().isEmpty) {
      throw ApiException(
        'Invalid refresh response.',
        statusCode: res.statusCode,
        code: 'REFRESH_INVALID',
      );
    }

    return newToken.trim();
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
      extra: {
        ...o.extra,
        '__authRetried': true,
      },
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

  bool _isAuthPath(String path) {
    final p = path.toLowerCase();
    return p.contains('/login') ||
        p.contains('/signup') ||
        p.contains('/register') ||
        p.contains('/refresh') ||
        p.contains('/auth');
  }

  String _pickErrorMessage(DioException e) {
    final data = e.response?.data;

    final server = _extractServerMessage(data);
    if (server != null && server.trim().isNotEmpty) return server.trim();

    final friendly = _friendlyNetworkMessage(e);
    if (friendly != null && friendly.trim().isNotEmpty) return friendly.trim();

    final msg = e.message;
    if (msg != null && msg.trim().isNotEmpty) return msg.trim();

    return 'Something went wrong. Please try again.';
  }

  String? _extractServerMessage(dynamic data) {
    try {
      if (data is Map) {
        if (data['message'] is String) return data['message'] as String;
        if (data['detail'] is String) return data['detail'] as String;
        if (data['error'] is String) return data['error'] as String;

        final d = data['data'];
        if (d is Map) {
          if (d['message'] is String) return d['message'] as String;
          if (d['detail'] is String) return d['detail'] as String;
        }
      }
    } catch (_) {}
    return null;
  }

  String? _friendlyNetworkMessage(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'Network timeout. Please try again.';
      case DioExceptionType.connectionError:
        return 'No internet connection. Please check your network.';
      default:
        return null;
    }
  }

  String _mapCode(int? status, dynamic data) {
    if (status == null) return 'UNKNOWN';
    if (status == 400) return 'BAD_REQUEST';
    if (status == 401) return 'UNAUTHORIZED';
    if (status == 403) return 'FORBIDDEN';
    if (status == 404) return 'NOT_FOUND';
    if (status == 409) return 'CONFLICT';
    if (status >= 500) return 'SERVER_ERROR';

    try {
      if (data is Map && data['code'] is String) return data['code'] as String;
    } catch (_) {}
    return 'HTTP_$status';
  }
}