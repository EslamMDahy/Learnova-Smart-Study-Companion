import 'package:dio/dio.dart';
import 'api_exceptions.dart';

String mapApiError(Object e) {
  // 1) لو انت رامي ApiException جوه DioException.error
  if (e is DioException && e.error is ApiException) {
    return (e.error as ApiException).message;
  }

  if (e is DioException) {
    final status = e.response?.statusCode;
    final data = e.response?.data;

    final serverMsg = _extractServerMessage(data);
    if (serverMsg != null) return serverMsg;

    // 2) Errors by Dio type (الأوضح قبل status أحيانًا)
    switch (e.type) {
      case DioExceptionType.cancel:
        return 'Request cancelled.';
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'Connection timeout. Please try again.';
      case DioExceptionType.connectionError:
        return 'No internet connection.';
      case DioExceptionType.badCertificate:
        return 'Secure connection failed. Please try again.';
      case DioExceptionType.badResponse:
        // هنسيبها للـ status mapping تحت
        break;
      case DioExceptionType.unknown:
        // ممكن يكون SocketException أو غيره
        break;
    }

    // 3) Fallback by status code
    switch (status) {
      case 400:
        return 'Invalid request. Please check your input.';
      case 401:
        return 'Email or password is incorrect.';
      case 403:
        return 'Access denied. Please verify your email or permissions.';
      case 404:
        return 'Service not found. Please try again later.';
      case 409:
        return 'This email is already registered.';
      case 422:
        return 'Some fields are invalid. Please check your input.';
      case 429:
        return 'Too many requests. Please try again later.';
      case 500:
      case 502:
      case 503:
      case 504:
        return 'Server error. Please try again later.';
    }

    return 'Something went wrong. Please try again.';
  }

  // لو exception تانية (غير dio)
  if (e is ApiException) {
    return e.message;
  }

  return 'Unexpected error. Please try again.';
}

String? _extractServerMessage(dynamic data) {
  if (data == null) return null;

  // FastAPI sometimes returns string
  if (data is String && data.trim().isNotEmpty) {
    return data.trim();
  }

  if (data is! Map) return null;

  // FastAPI "detail" could be string or list of validation errors
  final detail = data['detail'];

  if (detail is String && detail.trim().isNotEmpty) {
    return detail.trim();
  }

  if (detail is List) {
    final msgs = <String>[];

    for (final item in detail) {
      if (item is Map) {
        final msg = item['msg']?.toString().trim();
        final loc = item['loc'];

        String? field;
        if (loc is List && loc.isNotEmpty) {
          field = loc.last?.toString();
        }

        if (msg != null && msg.isNotEmpty) {
          msgs.add((field != null && field.isNotEmpty) ? '$field: $msg' : msg);
        }
      } else if (item != null) {
        final s = item.toString().trim();
        if (s.isNotEmpty) msgs.add(s);
      }
    }

    if (msgs.isNotEmpty) return msgs.join('\n');
  }

  // Custom API message
  final message = data['message']?.toString().trim();
  if (message != null && message.isNotEmpty) return message;

  return null;
}
