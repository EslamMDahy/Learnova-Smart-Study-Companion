import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'browser_file_picker.dart';

typedef DropZoneHitTest = bool Function(double clientX, double clientY);
typedef BrowserFilesDropped = Future<void> Function(List<PickedBrowserFile> files);

class BrowserFileDropSubscription {
  final List<_WebEventListener> _listeners;

  BrowserFileDropSubscription._(this._listeners);

  void dispose() {
    for (final listener in _listeners) {
      listener.cancel();
    }
  }
}

class _WebEventListener {
  _WebEventListener(this.target, this.type, this.listener);

  final web.EventTarget target;
  final String type;
  final JSFunction listener;

  void cancel() => target.removeEventListener(type, listener);
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

  bool isInside(web.DragEvent event) {
    return isInsideDropZone(event.clientX.toDouble(), event.clientY.toDouble());
  }

  bool isAllowed(web.File file) {
    if (acceptedExtensions.isEmpty) return true;
    final lowerName = file.name.toLowerCase();
    final lowerType = file.type.toLowerCase();
    return acceptedExtensions.any((ext) {
      final normalized = ext.trim().toLowerCase();
      if (normalized.isEmpty) return false;
      if (normalized == '*/*') return true;
      if (normalized.endsWith('/*')) {
        return lowerType.startsWith(normalized.substring(0, normalized.length - 1));
      }
      final dotExt = normalized.startsWith('.') ? normalized : '.$normalized';
      return lowerName.endsWith(dotExt) || lowerType == normalized;
    });
  }

  final listeners = <_WebEventListener>[];

  void add(String type, void Function(web.DragEvent event) handler) {
    final listener = ((web.Event event) {
      if (event is web.DragEvent) handler(event);
    }).toJS;
    web.window.addEventListener(type, listener);
    listeners.add(_WebEventListener(web.window, type, listener));
  }

  add('dragover', (event) {
    final inside = isInside(event);
    setHovering(inside);

    if (!inside) return;
    event.preventDefault();
    event.stopPropagation();
    event.dataTransfer?.dropEffect = 'copy';
  });

  add('dragleave', (event) {
    if (!isInside(event)) setHovering(false);
  });

  add('drop', (event) async {
    final inside = isInside(event);
    setHovering(false);
    if (!inside || dropping) return;

    event.preventDefault();
    event.stopPropagation();

    final files = event.dataTransfer?.files;
    if (files == null || files.length == 0) return;

    dropping = true;
    try {
      final droppedFiles = <PickedBrowserFile>[];
      for (var i = 0; i < files.length; i++) {
        final file = files.item(i);
        if (file == null || !isAllowed(file)) continue;
        droppedFiles.add(await _readDroppedFile(file));
      }
      if (droppedFiles.isNotEmpty) await onDrop(droppedFiles);
    } finally {
      dropping = false;
    }
  });

  add('dragend', (_) => setHovering(false));

  return BrowserFileDropSubscription._(listeners);
}

Future<PickedBrowserFile> _readDroppedFile(web.File file) async {
  final buffer = await file.arrayBuffer().toDart;
  final bytes = Uint8List.view(buffer.toDart);

  return PickedBrowserFile(
    name: file.name,
    mimeType: file.type,
    sizeBytes: bytes.length,
    bytes: bytes,
  );
}
