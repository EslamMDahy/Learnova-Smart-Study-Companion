import 'browser_file_picker.dart';

class BrowserFileDropSubscription {
  const BrowserFileDropSubscription();

  void dispose() {}
}

BrowserFileDropSubscription listenForBrowserFileDrops({
  required bool Function(double clientX, double clientY) isInsideDropZone,
  required Future<void> Function(List<PickedBrowserFile> files) onDrop,
  void Function(bool hovering)? onHoverChanged,
  List<String> acceptedExtensions = const ['pdf'],
}) {
  return const BrowserFileDropSubscription();
}
