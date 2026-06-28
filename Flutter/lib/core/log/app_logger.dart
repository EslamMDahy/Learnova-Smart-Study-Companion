import 'package:flutter/foundation.dart';

enum LogLevel { debug, info, warn, error }

/// Minimal logging abstraction.
///
/// Logging is intentionally disabled in release builds to avoid leaking
/// sensitive payloads and to prevent heavy console serialization from slowing
/// the web app down.
class AppLogger {
  AppLogger._();

  static void log(
    String message, {
    LogLevel level = LogLevel.info,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (kReleaseMode) return;

    final prefix = switch (level) {
      LogLevel.debug => '[D]',
      LogLevel.info => '[I]',
      LogLevel.warn => '[W]',
      LogLevel.error => '[E]',
    };

    debugPrint('$prefix $message');

    if (error != null) {
      debugPrint('$prefix error=$error');
    }

    if (stackTrace != null) {
      debugPrint('$prefix stackTrace=\n$stackTrace');
    }
  }
}
