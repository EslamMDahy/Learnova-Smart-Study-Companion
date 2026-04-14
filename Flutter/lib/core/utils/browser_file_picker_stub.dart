import 'package:flutter/foundation.dart';

import 'browser_file_picker.dart';

Future<List<PickedBrowserFile>> pickBrowserFilesImpl({
  String? accept,
  bool multiple = false,
}) async {
  if (kIsWeb) {
    throw UnsupportedError('Browser file picker is unavailable on this platform.');
  }
  return const <PickedBrowserFile>[];
}
