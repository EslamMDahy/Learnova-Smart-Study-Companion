import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../error/app_error_bus.dart';
import '../error/app_failure.dart';
import '../error/app_failure_presenter.dart';
import 'toast.dart';

class GlobalErrorToastListener extends ConsumerStatefulWidget {
  final Widget child;
  const GlobalErrorToastListener({super.key, required this.child});

  @override
  ConsumerState<GlobalErrorToastListener> createState() =>
      _GlobalErrorToastListenerState();
}

class _GlobalErrorToastListenerState
    extends ConsumerState<GlobalErrorToastListener> {
  String? _lastKey;

  @override
  Widget build(BuildContext context) {
    ref.listen<AppFailure?>(appErrorProvider, (prev, next) {
      if (next == null) return;

      final key = "${next.type}:${next.message}:${next.statusCode ?? ''}";
      if (_lastKey == key) return;
      _lastKey = key;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        AppToast.show(
          context,
          title: AppFailurePresenter.title(next),
          message: next.message,
          icon: AppFailurePresenter.icon(next),
        );

        AppErrorReporter.clear(ref); // ✅ دلوقتي صح
      });
    });

    return widget.child;
  }
}
