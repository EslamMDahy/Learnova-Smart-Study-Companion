import 'dart:async';
import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'browser_file_picker.dart';

Future<List<PickedBrowserFile>> pickBrowserFilesImpl({
  String? accept,
  bool multiple = false,
}) async {
  final input = html.FileUploadInputElement()
    ..multiple = multiple;
  if (accept != null && accept.trim().isNotEmpty) {
    input.accept = accept;
  }

  final completer = Completer<List<PickedBrowserFile>>();

  input.onChange.listen((_) async {
    try {
      final files = input.files;
      if (files == null || files.isEmpty) {
        completer.complete(const <PickedBrowserFile>[]);
        return;
      }

      final picked = <PickedBrowserFile>[];
      for (int i = 0; i < files.length; i++) {
        final file = files[i];
        final bytes = await _readBytes(file);
        picked.add(
          PickedBrowserFile(
            name: file.name,
            sizeBytes: bytes.length,
            bytes: bytes,
            contentType: file.type,
          ),
        );
      }
      completer.complete(picked);
    } catch (e, st) {
      completer.completeError(e, st);
    }
  });

  input.click();
  return completer.future;
}

Future<Uint8List> _readBytes(html.File file) {
  final completer = Completer<Uint8List>();
  final reader = html.FileReader();

  reader.onLoad.listen((_) {
    final result = reader.result;
    if (result is Uint8List) {
      completer.complete(result);
      return;
    }
    if (result is ByteBuffer) {
      completer.complete(Uint8List.view(result));
      return;
    }
    completer.completeError(
      StateError('Unsupported file reader result for ${file.name}.'),
    );
  });

  reader.onError.listen((_) {
    completer.completeError(
      StateError('Failed to read ${file.name} from the browser picker.'),
    );
  });

  reader.readAsArrayBuffer(file);
  return completer.future;
}
