import 'dart:convert';

import 'package:web/web.dart' as web;

void downloadTextFile({
  required String filename,
  required String content,
  String mimeType = 'text/plain',
}) {
  final uri = 'data:$mimeType;charset=utf-8,${Uri.encodeComponent(content)}';
  _downloadDataUri(filename: filename, uri: uri);
}

void downloadBytesFile({
  required String filename,
  required List<int> bytes,
  String mimeType = 'application/octet-stream',
}) {
  final uri = 'data:$mimeType;base64,${base64Encode(bytes)}';
  _downloadDataUri(filename: filename, uri: uri);
}

void _downloadDataUri({required String filename, required String uri}) {
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
  anchor.href = uri;
  anchor.download = filename;
  anchor.style.display = 'none';

  web.document.body?.appendChild(anchor);
  anchor.click();
  anchor.remove();
}
