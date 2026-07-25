import 'dart:typed_data';

import 'browser_upload_client_stub.dart' as fallback;

Future<void> uploadBinaryToSignedUrlImpl({
  required String uploadUrl,
  required Uint8List bodyBytes,
  required String contentType,
  Map<String, String> headers = const <String, String>{},
}) {
  // Keep the implementation WASM-safe. Dio's browser adapter handles web uploads
  // without importing dart:html in app code.
  return fallback.uploadBinaryToSignedUrlImpl(
    uploadUrl: uploadUrl,
    bodyBytes: bodyBytes,
    contentType: contentType,
    headers: headers,
  );
}
