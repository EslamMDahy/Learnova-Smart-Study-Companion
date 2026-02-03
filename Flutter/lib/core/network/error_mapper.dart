import 'package:dio/dio.dart';

String mapApiError(Object e) {
  if (e is DioException) {
    final status = e.response?.statusCode;
    final data = e.response?.data;

    String? serverMsg;

    if (data is Map) {
      final detail = data['detail'];

      // ✅ detail ممكن يكون String
      if (detail is String) {
        serverMsg = detail;
      }

      // ✅ أو List (Validation errors)
      if (detail is List) {
        // نجمع رسائل الحقول بشكل مفهوم
        final msgs = <String>[];
        for (final item in detail) {
          if (item is Map) {
            final loc = item['loc'];
            final msg = item['msg']?.toString();
            String field = '';

            if (loc is List && loc.isNotEmpty) {
              field = loc.last.toString(); // email / password / invite_code ...
            }

            if (msg != null && msg.isNotEmpty) {
              msgs.add(field.isNotEmpty ? '$field: $msg' : msg);
            }
          }
        }
        if (msgs.isNotEmpty) serverMsg = msgs.join('\n');
      }

      // ✅ لو الباك بيرجع message
      serverMsg ??= data['message']?.toString();
    } else if (data is String) {
      serverMsg = data;
    }

    if (serverMsg != null && serverMsg.trim().isNotEmpty) {
      return serverMsg.trim();
    }

    switch (status) {
      case 400:
        return 'Invalid request. Please check your input.';
      case 401:
        return 'Email or password is incorrect.';
      case 403:
        return 'Please verify your email before logging in.';
      case 404:
        return 'Service not found. Please try again later.';
      case 409:
        return 'This email is already registered.';
      case 422:
        return 'Some fields are invalid. Please check your input.';
      case 500:
        return 'Server error. Please try again later.';
    }

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return 'Connection timeout. Please try again.';
    }

    if (e.type == DioExceptionType.connectionError) {
      return 'No internet connection.';
    }

    return 'Something went wrong. Please try again.';
  }

  return 'Unexpected error. Please try again.';
}
