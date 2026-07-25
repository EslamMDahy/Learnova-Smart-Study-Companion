import 'dart:typed_data';

import 'package:dio/dio.dart';

Future<void> uploadBinaryToSignedUrlImpl({
  required String uploadUrl,
  required Uint8List bodyBytes,
  required String contentType,
  Map<String, String> headers = const <String, String>{},
}) async {
  final dio = Dio();

  await dio.put<void>(
    uploadUrl,
    data: bodyBytes,
    options: Options(
      sendTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: <String, String>{
        'Content-Type': contentType,
        ...headers,
      },
    ),
  );
}
