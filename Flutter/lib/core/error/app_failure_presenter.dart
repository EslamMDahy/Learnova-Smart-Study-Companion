import 'package:flutter/material.dart';
import 'app_failure.dart';

class AppFailurePresenter {
  const AppFailurePresenter._();

  static String title(AppFailure f) {
    switch (f.type) {
      case AppFailureType.network:
        return "No internet";
      case AppFailureType.timeout:
        return "Timeout";
      case AppFailureType.unauthorized:
        return "Session expired";
      case AppFailureType.forbidden:
        return "Access denied";
      case AppFailureType.validation:
        return "Invalid input";
      case AppFailureType.notFound:
        return "Not found";
      case AppFailureType.server:
        return "Server error";
      case AppFailureType.unknown:
        return "Something went wrong";
    }
  }

  static IconData icon(AppFailure f) {
    switch (f.type) {
      case AppFailureType.network:
        return Icons.wifi_off_rounded;
      case AppFailureType.timeout:
        return Icons.timer_outlined;
      case AppFailureType.unauthorized:
        return Icons.lock_outline_rounded;
      case AppFailureType.forbidden:
        return Icons.block_rounded;
      case AppFailureType.validation:
        return Icons.error_outline;
      case AppFailureType.notFound:
        return Icons.search_off_rounded;
      case AppFailureType.server:
        return Icons.cloud_off_rounded;
      case AppFailureType.unknown:
        return Icons.warning_amber_rounded;
    }
  }
}
