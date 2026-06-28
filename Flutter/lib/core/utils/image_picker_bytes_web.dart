// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

class PickedBrowserFile {
  final List<int> bytes;
  final String? mimeType;
  final String? name;

  const PickedBrowserFile({
    required this.bytes,
    this.mimeType,
    this.name,
  });
}

Future<PickedBrowserFile?> pickSingleImageFile({
  List<String> accept = const ['image/*'],
}) async {
  final input = html.FileUploadInputElement()
    ..accept = accept.join(',')
    ..multiple = false
    ..style.display = 'none';

  html.document.body?.append(input);

  try {
    input.click();

    await input.onChange.first;

    final file = input.files?.isNotEmpty ?? false ? input.files!.first : null;
    if (file == null) return null;

    final reader = html.FileReader();
    final completer = Completer<PickedBrowserFile?>();

    reader.onLoad.first.then((_) {
      final result = reader.result;
      final bytes = result is Uint8List ? result.toList() : <int>[];
      if (!completer.isCompleted) {
        completer.complete(
          PickedBrowserFile(
            bytes: bytes,
            mimeType: file.type,
            name: file.name,
          ),
        );
      }
    });

    reader.onError.first.then((_) {
      if (!completer.isCompleted) completer.complete(null);
    });

    reader.readAsArrayBuffer(file);
    return completer.future;
  } finally {
    input.remove();
  }
}
