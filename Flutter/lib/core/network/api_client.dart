import 'package:dio/dio.dart';

import '../config/env.dart';
import '../storage/token_storage.dart';
import 'api_exceptions.dart';

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

    // ✅ Interceptors (Request + Error) in one place
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = TokenStorage.token;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (DioException e, handler) {
          final status = e.response?.statusCode;
          final data = e.response?.data;

          // ✅ FastAPI commonly uses "detail"
          String? serverMsg;
          if (data is Map) {
            if (data['message'] != null) serverMsg = data['message'].toString();
            if (serverMsg == null && data['detail'] != null) {
              final d = data['detail'];
              if (d is String) {
                serverMsg = d;
              } else if (d is List && d.isNotEmpty) {
                // validation errors: [{"loc":..,"msg":".."}]
                final first = d.first;
                if (first is Map && first['msg'] != null) {
                  serverMsg = first['msg'].toString();
                } else {
                  serverMsg = d.toString();
                }
              } else {
                serverMsg = d.toString();
              }
            }
          }

          final friendly = _friendlyNetworkMessage(e);

          final msg = serverMsg ??
              friendly ??
              e.message ??
              'Something went wrong. Please try again.';

          handler.reject(
            DioException(
              requestOptions: e.requestOptions,
              response: e.response,
              type: e.type,
              error: ApiException(msg, statusCode: status),
            ),
          );
        },
      ),
    );

    // ✅ Optional: logging in dev only
    if (!Env.isProd) {
      _dio.interceptors.add(
        LogInterceptor(
          requestHeader: true,
          requestBody: true,
          responseHeader: false,
          responseBody: true,
          error: true,
        ),
      );
    }
  }

  final Dio _dio;

  // ✅ Helper: map Dio types to friendly messages
  String? _friendlyNetworkMessage(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timed out. Please try again.';
      case DioExceptionType.connectionError:
        return 'No internet connection. Please check your network.';
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      case DioExceptionType.badCertificate:
        return 'Bad certificate. Please contact support.';
      case DioExceptionType.badResponse:
        // handled by serverMsg mostly
        return null;
      case DioExceptionType.unknown:
        return null;
    }
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> put<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> delete<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }
}
