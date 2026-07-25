import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

typedef BeforeUnloadShouldBlock = bool Function();

VoidCallback registerBeforeUnload(BeforeUnloadShouldBlock shouldBlock) {
  late JSFunction listener;
  listener = ((web.Event event) {
    if (!shouldBlock()) return;

    event.preventDefault();
    if (event is web.BeforeUnloadEvent) {
      event.returnValue = '';
    }
  }).toJS;

  web.window.addEventListener('beforeunload', listener);

  return () {
    web.window.removeEventListener('beforeunload', listener);
  };
}
