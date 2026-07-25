import 'dart:convert';

import 'package:dio/browser.dart';
import 'package:dio/dio.dart';

import 'api_exceptions.dart';
import 'refresh_client.dart';

class _WebRefreshClient implements RefreshClient {
  _WebRefreshClient() {
    final adapter = BrowserHttpClientAdapter();
    adapter.withCredentials = true;
    _dio.httpClientAdapter = adapter;
  }

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: const <String, String>{
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'ngrok-skip-browser-warning': 'true',
      },
      responseType: ResponseType.json,
    ),
  );

  @override
  Future<String> refresh({required String url}) async {
    try {
      final response = await _dio.post<dynamic>(url);
      final status = response.statusCode ?? 0;
      if (status < 200 || status >= 400) {
        throw ApiException(
          'Refresh failed: HTTP $status',
          statusCode: status,
          code: _refreshErrorCode(status),
        );
      }

      final root = _normalizeBody(response.data);
      final token =
          (root['access_token'] ?? root['token'] ?? root['accessToken'])
              ?.toString()
              .trim();

      if (token == null || token.isEmpty) {
        throw ApiException(
          'Invalid refresh response.',
          statusCode: status,
          code: 'REFRESH_INVALID',
        );
      }

      return token;
    } on DioException catch (error) {
      final status = error.response?.statusCode;
      throw ApiException(
        status == null
            ? 'Network error during token refresh.'
            : 'Refresh failed: HTTP $status',
        statusCode: status,
        code: status == null ? 'REFRESH_NETWORK' : _refreshErrorCode(status),
      );
    }
  }

  Map<String, dynamic> _normalizeBody(dynamic body) {
    dynamic decoded = body;
    if (decoded is String) {
      try {
        decoded = jsonDecode(decoded);
      } catch (_) {
        decoded = <String, dynamic>{};
      }
    }

    if (decoded is Map) {
      final map = decoded.cast<String, dynamic>();
      final data = map['data'];
      if (data is Map) return data.cast<String, dynamic>();
      return map;
    }

    return <String, dynamic>{};
  }

  String _refreshErrorCode(int status) {
    if (status == 401 || status == 403) return 'REFRESH_AUTH_FAILED';
    if (status >= 500) return 'REFRESH_SERVER';
    return 'REFRESH_FAILED';
  }
}

RefreshClient createRefreshClientImpl() => _WebRefreshClient();
