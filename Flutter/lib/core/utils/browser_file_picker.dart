import 'dart:typed_data';

import 'browser_file_picker_stub.dart'
    if (dart.library.html) 'browser_file_picker_web.dart' as impl;

class PickedBrowserFile {
  final String name;
  final int sizeBytes;
  final Uint8List bytes;
  final String contentType;

  const PickedBrowserFile({
    required this.name,
    required this.sizeBytes,
    required this.bytes,
    required this.contentType,
  });
}

Future<List<PickedBrowserFile>> pickBrowserFiles({
  String? accept,
  bool multiple = false,
}) {
  return impl.pickBrowserFilesImpl(accept: accept, multiple: multiple);
}
