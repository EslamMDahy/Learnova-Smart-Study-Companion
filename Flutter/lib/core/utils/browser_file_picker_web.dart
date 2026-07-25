import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

class PickedBrowserFile {
  final String name;
  final String mimeType;
  final int sizeBytes;
  final Uint8List bytes;

  const PickedBrowserFile({
    required this.name,
    required this.mimeType,
    required this.sizeBytes,
    required this.bytes,
  });
}

Future<List<PickedBrowserFile>> pickBrowserFiles({
  required List<String> acceptedExtensions,
  bool multiple = true,
}) async {
  final completer = Completer<List<PickedBrowserFile>>();
  final input = web.document.createElement('input') as web.HTMLInputElement;

  input.type = 'file';
  input.accept = acceptedExtensions.join(',');
  input.multiple = multiple;
  input.style.display = 'none';

  late JSFunction changeListener;
  late JSFunction cancelListener;

  Future<void> cleanup() async {
    input.removeEventListener('change', changeListener);
    input.removeEventListener('cancel', cancelListener);
    input.remove();
  }

  changeListener = ((web.Event _) {
    () async {
      try {
        final selected = input.files;
        if (selected == null || selected.length == 0) {
          if (!completer.isCompleted) completer.complete(const []);
          await cleanup();
          return;
        }

        final files = <PickedBrowserFile>[];
        for (var i = 0; i < selected.length; i++) {
          final file = selected.item(i);
          if (file == null) continue;
          files.add(await _readFile(file));
        }

        if (!completer.isCompleted) completer.complete(files);
      } catch (error, stackTrace) {
        if (!completer.isCompleted) {
          completer.completeError(error, stackTrace);
        }
      } finally {
        await cleanup();
      }
    }();
  }).toJS;

  cancelListener = ((web.Event _) {
    if (!completer.isCompleted) completer.complete(const []);
    cleanup();
  }).toJS;

  input.addEventListener('change', changeListener);
  input.addEventListener('cancel', cancelListener);
  web.document.body?.appendChild(input);
  input.click();

  return completer.future;
}

Future<PickedBrowserFile> _readFile(web.File file) async {
  final buffer = await file.arrayBuffer().toDart;
  final bytes = Uint8List.view(buffer.toDart);

  return PickedBrowserFile(
    name: file.name,
    mimeType: file.type,
    sizeBytes: bytes.length,
    bytes: bytes,
  );
}
