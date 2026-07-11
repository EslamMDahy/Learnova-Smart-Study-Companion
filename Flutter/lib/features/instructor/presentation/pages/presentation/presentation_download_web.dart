import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

const _bridgeScriptId = 'learnova-dom-to-pptx-bridge';
const _bridgeRelativePath = 'presentation_export/learnova_dom_to_pptx.js';
const _bridgeLoadTimeout = Duration(seconds: 20);
const _exportTimeout = Duration(minutes: 5);

Future<void>? _bridgeLoadFuture;

@JS('learnovaPptx')
external _LearnovaPptxBridge? get _learnovaPptx;

extension type _LearnovaPptxBridge(JSObject _) implements JSObject {
  external JSPromise<JSAny?> exportDeck(
    JSString deckJson,
    JSString filename,
  );
}

Future<void> exportPresentationPptx({
  required String deckJson,
  required String filename,
}) async {
  if (deckJson.trim().isEmpty) {
    throw const FormatException('The presentation JSON is empty.');
  }

  try {
    await (_bridgeLoadFuture ??= _loadBridge());
  } catch (_) {
    // Permit a clean retry after a network, deployment, or CSP failure.
    _bridgeLoadFuture = null;
    rethrow;
  }

  final bridge = _learnovaPptx;
  if (bridge == null) {
    _bridgeLoadFuture = null;
    throw StateError(
      'The HTML-to-PowerPoint bridge did not initialize. '
      'Make sure web/$_bridgeRelativePath exists in the deployed build.',
    );
  }

  try {
    await bridge
        .exportDeck(deckJson.toJS, filename.toJS)
        .toDart
        .timeout(_exportTimeout);
  } on TimeoutException {
    throw TimeoutException(
      'PowerPoint export timed out after ${_exportTimeout.inMinutes} minutes.',
    );
  } catch (error) {
    throw StateError(_readJavascriptError(error));
  }
}

Future<void> _loadBridge() async {
  if (_learnovaPptx != null) return;

  final existing = web.document.getElementById(_bridgeScriptId);
  if (existing != null) {
    try {
      await _waitForBridge(timeout: const Duration(seconds: 3));
      return;
    } catch (_) {
      // A stale or failed script element must not block the retry below.
      existing.remove();
    }
  }

  final parent = web.document.head ?? web.document.body;
  if (parent == null) {
    throw StateError(
      'The browser document is not ready for PowerPoint export.',
    );
  }

  final bridgeUri = _resolveBridgeUri();
  final script = web.HTMLScriptElement()
    ..id = _bridgeScriptId
    ..type = 'text/javascript'
    ..async = true
    ..defer = true
    ..src = bridgeUri.toString();

  final completer = Completer<void>();
  StreamSubscription<web.Event>? loadSubscription;
  StreamSubscription<web.Event>? errorSubscription;
  Timer? timer;

  void cleanup() {
    timer?.cancel();
    final load = loadSubscription;
    final error = errorSubscription;
    if (load != null) unawaited(load.cancel());
    if (error != null) unawaited(error.cancel());
  }

  loadSubscription = script.onLoad.listen((_) {
    cleanup();
    if (!completer.isCompleted) completer.complete();
  });

  errorSubscription = script.onError.listen((_) {
    cleanup();
    script.remove();
    if (!completer.isCompleted) {
      completer.completeError(
        StateError(
          'Could not load $_bridgeRelativePath. '
          'Make sure the web folder from the patch is deployed and allowed '
          'by the app Content Security Policy.',
        ),
      );
    }
  });

  timer = Timer(_bridgeLoadTimeout, () {
    cleanup();
    script.remove();
    if (!completer.isCompleted) {
      completer.completeError(
        TimeoutException(
          'PowerPoint export bridge loading timed out after '
          '${_bridgeLoadTimeout.inSeconds} seconds.',
        ),
      );
    }
  });

  parent.appendChild(script);
  await completer.future;
  await _waitForBridge(timeout: const Duration(seconds: 5));
}

Uri _resolveBridgeUri() {
  final baseUri = web.document.baseURI.trim();
  if (baseUri.isEmpty) return Uri.base.resolve(_bridgeRelativePath);

  try {
    return Uri.parse(baseUri).resolve(_bridgeRelativePath);
  } on FormatException {
    return Uri.base.resolve(_bridgeRelativePath);
  }
}

Future<void> _waitForBridge({required Duration timeout}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    if (_learnovaPptx != null) return;
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }

  throw TimeoutException(
    'PowerPoint export bridge initialization timed out.',
  );
}

String _readJavascriptError(Object error) {
  final message = error.toString().trim();
  if (message.isEmpty) return 'The PowerPoint exporter failed unexpectedly.';

  return message
      .replaceFirst(RegExp(r'^StateError:\s*'), '')
      .replaceFirst(RegExp(r'^Error:\s*'), '')
      .replaceFirst(RegExp(r'^Exception:\s*'), '');
}
