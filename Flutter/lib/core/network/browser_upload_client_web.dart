// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:typed_data';
import 'dart:html' as html;

Future<void> uploadBinaryToSignedUrlImpl({
  required String uploadUrl,
  required Uint8List bodyBytes,
  required String contentType,
  Map<String, String> headers = const <String, String>{},
}) {
  final completer = Completer<void>();

  final xhr = html.HttpRequest()
    ..open('PUT', uploadUrl)
    ..timeout = 30000
    ..setRequestHeader('Content-Type', contentType);

  for (final entry in headers.entries) {
    xhr.setRequestHeader(entry.key, entry.value);
  }

  xhr.onLoad.listen((_) {
    if (completer.isCompleted) return;
    final status = xhr.status ?? 0;
    if (status >= 200 && status < 400) {
      completer.complete();
      return;
    }
    completer.completeError(
      Exception('Signed upload failed: HTTP $status - ${xhr.responseText}'),
    );
  });

  xhr.onError.listen((_) {
    if (completer.isCompleted) return;
    completer.completeError(Exception('Signed upload network error'));
  });

  xhr.onTimeout.listen((_) {
    if (completer.isCompleted) return;
    completer.completeError(Exception('Signed upload timed out'));
  });

  xhr.send(bodyBytes);
  return completer.future;
}
