import 'browser_file_picker.dart' as browser_picker;

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
  final files = await browser_picker.pickBrowserFiles(
    acceptedExtensions: accept,
    multiple: false,
  );
  if (files.isEmpty) return null;

  final file = files.first;
  return PickedBrowserFile(
    bytes: file.bytes,
    mimeType: file.mimeType,
    name: file.name,
  );
}
