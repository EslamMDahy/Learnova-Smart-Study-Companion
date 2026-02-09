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

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = TokenStorage.token;
          if (token != null && token.trim().isNotEmpty) {
            options.headers['Authorization'] = 'Bearer ${token.trim()}';
          }
          handler.next(options);
        },

        onError: (DioException e, handler) {
          final status = e.response?.statusCode;
          final data = e.response?.data;

          final serverMsg = _extractServerMessage(data);
          final friendly = _friendlyNetworkMessage(e);

          // final message priority:
          // serverMsg -> friendly -> dio message -> fallback
          final msg = (serverMsg?.trim().isNotEmpty == true)
              ? serverMsg!.trim()
              : (friendly?.trim().isNotEmpty == true)
                  ? friendly!.trim()
                  : (e.message?.trim().isNotEmpty == true)
                      ? e.message!.trim()
                      : 'Something went wrong. Please try again.';

          // OPTIONAL: لو 401 عايز تمسح التوكن
          // (لو ده متفق عليه في مشروعك)
          // if (status == 401) {
          //   TokenStorage.clear();
          // }

          // ✅ رجّع DioException لكن جوّاه error = ApiException ثابت
          handler.reject(
            DioException(
              requestOptions: e.requestOptions,
              response: e.response,
              type: e.type,
              error: ApiException(msg, statusCode: status),
              message: e.message,
            ),
          );
        },
      ),
    );

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

  /// ✅ Extract message from many backend shapes:
  /// - {"message": "..."}
  /// - {"detail": "..."}
  /// - {"detail":[{"msg":".."}]}
  /// - "plain string"
  static String? _extractServerMessage(dynamic data) {
    if (data == null) return null;

    // plain string body
    if (data is String) {
      final s = data.trim();
      return s.isEmpty ? null : s;
    }

    if (data is Map) {
      final m = data.cast<dynamic, dynamic>();

      // common keys
      final direct = m['message'] ?? m['error'] ?? m['msg'];
      if (direct != null) {
        final s = direct.toString().trim();
        if (s.isNotEmpty) return s;
      }

      // FastAPI: detail
      if (m['detail'] != null) {
        final d = m['detail'];

        if (d is String) {
          final s = d.trim();
          return s.isEmpty ? null : s;
        }

        // validation errors list
        if (d is List && d.isNotEmpty) {
          final first = d.first;

          if (first is Map && first['msg'] != null) {
            final s = first['msg'].toString().trim();
            return s.isEmpty ? null : s;
          }

          // fallback stringify
          final s = d.toString().trim();
          return s.isEmpty ? null : s;
        }

        final s = d.toString().trim();
        return s.isEmpty ? null : s;
      }

      // sometimes backend nests: {"data": {"message": "..."}}
      final inner = m['data'];
      if (inner is Map) {
        final s = _extractServerMessage(inner);
        if (s != null && s.trim().isNotEmpty) return s.trim();
      }
    }

    // fallback
    final s = data.toString().trim();
    return s.isEmpty ? null : s;
  }

  /// ✅ Friendly messages for network-level failures
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
        // غالبًا serverMsg هيمسكها
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

  Future<Response<T>> patch<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.patch<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }
}
