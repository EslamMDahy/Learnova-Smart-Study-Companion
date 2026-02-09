import 'package:dio/dio.dart';

import '../error/app_failure.dart';
import 'api_exceptions.dart';

AppFailure mapApiFailure(Object e) {
  // 1) لو ApiClient لفّها في ApiException جوه DioException.error
  if (e is DioException && e.error is ApiException) {
    final ex = e.error as ApiException;
    return _fromStatus(
      statusCode: ex.statusCode,
      message: ex.message,
      debug: ex.toString(),
    );
  }

  // 2) DioException مباشر
  if (e is DioException) {
    final status = e.response?.statusCode;
    final data = e.response?.data;

    final serverMsg = _extractServerMessage(data);
    if (serverMsg != null && serverMsg.trim().isNotEmpty) {
      return _fromStatus(
        statusCode: status,
        message: serverMsg.trim(),
        debug: e.toString(),
      );
    }

    // type-first mapping
    switch (e.type) {
      case DioExceptionType.cancel:
        return const AppFailure(
          type: AppFailureType.unknown,
          message: 'Request cancelled.',
        );
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return const AppFailure(
          type: AppFailureType.timeout,
          message: 'Connection timeout. Please try again.',
        );
      case DioExceptionType.connectionError:
        return const AppFailure(
          type: AppFailureType.network,
          message: 'No internet connection.',
        );
      case DioExceptionType.badCertificate:
        return const AppFailure(
          type: AppFailureType.unknown,
          message: 'Secure connection failed. Please try again.',
        );
      case DioExceptionType.badResponse:
        // continue to status mapping
        break;
      case DioExceptionType.unknown:
        break;
    }

    return _fromStatus(
      statusCode: status,
      message: 'Something went wrong. Please try again.',
      debug: e.toString(),
    );
  }

  // 3) ApiException (غير Dio)
  if (e is ApiException) {
    return _fromStatus(
      statusCode: e.statusCode,
      message: e.message,
      debug: e.toString(),
    );
  }

  // 4) fallback
  return AppFailure(
    type: AppFailureType.unknown,
    message: 'Unexpected error. Please try again.',
    debugMessage: e.toString(),
  );
}

// Backward compatibility (لو أي Controller/Widget لسه بيستخدم String)
String mapApiError(Object e) => mapApiFailure(e).message;

AppFailure _fromStatus({
  required int? statusCode,
  required String message,
  required String debug,
}) {
  final sc = statusCode;

  if (sc == null) {
    return AppFailure(
      type: AppFailureType.unknown,
      message: message.isNotEmpty ? message : 'Something went wrong. Please try again.',
      debugMessage: debug,
      statusCode: sc,
    );
  }

  switch (sc) {
    case 400:
      return AppFailure(
        type: AppFailureType.validation,
        message: message.isNotEmpty ? message : 'Invalid request. Please check your input.',
        debugMessage: debug,
        statusCode: sc,
      );
    case 401:
      return AppFailure(
        type: AppFailureType.unauthorized,
        message: message.isNotEmpty ? message : 'Your session expired. Please login again.',
        debugMessage: debug,
        statusCode: sc,
      );
    case 403:
      return AppFailure(
        type: AppFailureType.forbidden,
        message: message.isNotEmpty ? message : 'Access denied.',
        debugMessage: debug,
        statusCode: sc,
      );
    case 404:
      return AppFailure(
        type: AppFailureType.notFound,
        message: message.isNotEmpty ? message : 'Service not found.',
        debugMessage: debug,
        statusCode: sc,
      );
    case 409:
      return AppFailure(
        type: AppFailureType.validation,
        message: message.isNotEmpty ? message : 'Conflict. Please try again.',
        debugMessage: debug,
        statusCode: sc,
      );
    case 422:
      return AppFailure(
        type: AppFailureType.validation,
        message: message.isNotEmpty ? message : 'Some fields are invalid. Please check your input.',
        debugMessage: debug,
        statusCode: sc,
      );
    case 429:
      return AppFailure(
        type: AppFailureType.server,
        message: message.isNotEmpty ? message : 'Too many requests. Please try again later.',
        debugMessage: debug,
        statusCode: sc,
      );
    case 500:
    case 502:
    case 503:
    case 504:
      return AppFailure(
        type: AppFailureType.server,
        message: message.isNotEmpty ? message : 'Server error. Please try again later.',
        debugMessage: debug,
        statusCode: sc,
      );
    default:
      return AppFailure(
        type: AppFailureType.unknown,
        message: message.isNotEmpty ? message : 'Something went wrong. Please try again.',
        debugMessage: debug,
        statusCode: sc,
      );
  }
}

String? _extractServerMessage(dynamic data) {
  if (data == null) return null;

  if (data is String && data.trim().isNotEmpty) {
    return data.trim();
  }

  if (data is! Map) return null;

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

  final message = data['message']?.toString().trim();
  if (message != null && message.isNotEmpty) return message;

  return null;
}
