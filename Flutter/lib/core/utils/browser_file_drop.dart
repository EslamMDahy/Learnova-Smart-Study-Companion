export 'browser_file_drop_stub.dart'
    if (dart.library.js_interop) 'browser_file_drop_web.dart'
    if (dart.library.html) 'browser_file_drop_web.dart';
