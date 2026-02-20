import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/async_state_view.dart';
import '../storage/token_storage.dart';
import '../storage/user_storage.dart';
import 'session_bootstrap_controller.dart';

/// Gate to ensure /me is loaded after token exists, avoiding role flicker
/// and preventing repeated bootstraps on rebuilds (especially on web).
class SessionBootstrapper extends ConsumerStatefulWidget {
  final Widget child;

  const SessionBootstrapper({super.key, required this.child});

  @override
  ConsumerState<SessionBootstrapper> createState() => _SessionBootstrapperState();
}

class _SessionBootstrapperState extends ConsumerState<SessionBootstrapper> {
  late final Listenable _storageListenable;
  late final VoidCallback _onStorageChanged;

  @override
  void initState() {
    super.initState();

    _storageListenable =
        Listenable.merge([TokenStorage.listenable, UserStorage.listenable]);

    _onStorageChanged = _maybeBootstrap;
    _storageListenable.addListener(_onStorageChanged);

    // initial kick once
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeBootstrap());
  }

  @override
  void dispose() {
    _storageListenable.removeListener(_onStorageChanged);
    super.dispose();
  }

  void _maybeBootstrap() {
    if (!mounted) return;

    // No token => no need to bootstrap
    if (!TokenStorage.hasToken) return;

    // Already have /me => nothing to do
    if (UserStorage.hasMe) return;

    // Trigger controller bootstrap (controller should be idempotent)
    ref.read(sessionBootstrapControllerProvider.notifier).ensureBootstrapped();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(sessionBootstrapControllerProvider);

    final needsBootstrap = TokenStorage.hasToken && !UserStorage.hasMe;

    if (!needsBootstrap) {
      return widget.child;
    }

    final errMsg = async.hasError
        ? (() {
            final e = async.error;
            if (e == null) return 'Failed to load your profile. Please retry.';
            try {
              final s = e.toString();
              return s.trim().isEmpty
                  ? 'Failed to load your profile. Please retry.'
                  : s;
            } catch (_) {
              return 'Failed to load your profile. Please retry.';
            }
          })()
        : null;

    return Scaffold(
      body: SafeArea(
        child: AsyncStateView(
          loading: async.isLoading,
          errorMessage: errMsg,
          isEmpty: false,
          onRetry: _maybeBootstrap,
          child: const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }
}
