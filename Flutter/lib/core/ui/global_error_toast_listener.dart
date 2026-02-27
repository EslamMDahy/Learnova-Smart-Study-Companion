import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../error/app_error_bus.dart';
import '../error/app_failure.dart';
import '../error/app_failure_presenter.dart';
import '../routing/app_router.dart';
import '../routing/routes.dart';
import '../storage/token_storage.dart';
import '../storage/user_storage.dart';
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
  bool _authDialogOpen = false;

  @override
  Widget build(BuildContext context) {
    ref.listen<AppFailure?>(appErrorProvider, (prev, next) {
      if (next == null) return;

      
      if (next.type == AppFailureType.validation) {
        AppErrorReporter.clear(ref);
        return;
      }

      final key = "${next.type}:${next.message}:${next.statusCode ?? ''}:${next.code ?? ''}";
      if (_lastKey == key) return;
      _lastKey = key;

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;

        final navCtx = rootNavigatorKey.currentContext;

        // AUTH failures => modal + logout + navigate to login
        if (next.type == AppFailureType.unauthorized ||
            next.type == AppFailureType.forbidden) {
          if (_authDialogOpen) {
            AppErrorReporter.clear(ref);
            return;
          }
          _authDialogOpen = true;

          await _showSessionExpiredDialog(navCtx ?? context, next);

          _authDialogOpen = false;
          AppErrorReporter.clear(ref);
          return;
        }

        AppToast.show(
          navCtx ?? context,
          title: AppFailurePresenter.title(next),
          message: next.message,
          icon: AppFailurePresenter.icon(next),
        );

        AppErrorReporter.clear(ref);
      });
    });

    return widget.child;
  }

  Future<void> _showSessionExpiredDialog(BuildContext ctx, AppFailure f) async {
    
    try {
      TokenStorage.clear();
      UserStorage.clear();
    } catch (_) {}

    await showDialog<void>(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(AppFailurePresenter.title(f)),
        content: Text(
          (f.message.trim().isNotEmpty)
              ? f.message.trim()
              : 'Your session expired. Please login again.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx, rootNavigator: true).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );

    try {
      appRouter.go(Routes.login);
    } catch (_) {}
  }
}
