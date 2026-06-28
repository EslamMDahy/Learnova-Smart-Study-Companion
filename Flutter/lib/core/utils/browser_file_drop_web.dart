// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

import 'browser_file_picker.dart';

typedef DropZoneHitTest = bool Function(double clientX, double clientY);
typedef BrowserFilesDropped = Future<void> Function(List<PickedBrowserFile> files);

class BrowserFileDropSubscription {
  final List<StreamSubscription<dynamic>> _subscriptions;

  BrowserFileDropSubscription._(this._subscriptions);

  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
  }
}

BrowserFileDropSubscription listenForBrowserFileDrops({
  required DropZoneHitTest isInsideDropZone,
  required BrowserFilesDropped onDrop,
  void Function(bool hovering)? onHoverChanged,
  List<String> acceptedExtensions = const ['pdf'],
}) {
  var hovering = false;
  var dropping = false;

  void setHovering(bool value) {
    if (hovering == value) return;
    hovering = value;
    onHoverChanged?.call(value);
  }

  bool isFileDrag(html.MouseEvent event) {
    final types = event.dataTransfer.types;
    return types?.contains('Files') == true ||
        types?.contains('application/x-moz-file') == true;
  }

  bool isInside(html.MouseEvent event) {
    return isInsideDropZone(event.client.x.toDouble(), event.client.y.toDouble());
  }

  final subscriptions = <StreamSubscription<dynamic>>[];

  subscriptions.add(html.window.onDragOver.listen((mouseEvent) {
    if (!isFileDrag(mouseEvent)) return;

    final inside = isInside(mouseEvent);
    setHovering(inside);

    if (!inside) return;
    mouseEvent.preventDefault();
    mouseEvent.stopPropagation();
    mouseEvent.dataTransfer.dropEffect = 'copy';
  }));

  subscriptions.add(html.window.onDragLeave.listen((mouseEvent) {
    if (!isFileDrag(mouseEvent)) return;
    if (!isInside(mouseEvent)) setHovering(false);
  }));

  subscriptions.add(html.window.onDrop.listen((mouseEvent) async {
    if (!isFileDrag(mouseEvent)) return;

    final inside = isInside(mouseEvent);
    setHovering(false);
    if (!inside || dropping) return;

    mouseEvent.preventDefault();
    mouseEvent.stopPropagation();

    final files = mouseEvent.dataTransfer.files;
    if (files == null || files.isEmpty) return;

    dropping = true;
    try {
      final droppedFiles = <PickedBrowserFile>[];
      for (final file in files) {
        droppedFiles.add(await _readDroppedFile(file));
      }
      await onDrop(droppedFiles);
    } finally {
      dropping = false;
    }
  }));

  subscriptions.add(html.window.onDragEnd.listen((_) => setHovering(false)));

  return BrowserFileDropSubscription._(subscriptions);
}

Future<PickedBrowserFile> _readDroppedFile(html.File file) async {
  final completer = Completer<PickedBrowserFile>();
  final reader = html.FileReader();

  reader.onError.listen((_) {
    if (!completer.isCompleted) {
      completer.completeError(reader.error ?? StateError('Could not read dropped file.'));
    }
  });

  reader.onLoad.listen((_) {
    if (completer.isCompleted) return;
    final result = reader.result;
    final bytes = result is Uint8List
        ? result
        : Uint8List.view(result as ByteBuffer);
    completer.complete(PickedBrowserFile(
      name: file.name,
      mimeType: file.type,
      sizeBytes: bytes.length,
      bytes: bytes,
    ));
  });

  reader.readAsArrayBuffer(file);
  return completer.future;
}
