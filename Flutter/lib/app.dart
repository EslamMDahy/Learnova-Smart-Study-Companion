import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/routing/app_router.dart';
import 'core/session/session_bootstrapper.dart';
import 'core/theme/app_theme.dart';
import 'core/ui/global_loading_overlay.dart';
import 'core/ui/global_loading_bus_binder.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      // ignore: flutter_style_todos
      themeMode: ThemeMode.light, // TODO: drive from user preferences provider
      builder: (context, child) {
        return GlobalLoadingBusBinder(
          child: SessionBootstrapper(
            child: Stack(
              children: [
                child ?? const SizedBox.shrink(),
                const GlobalLoadingOverlay(),
              ],
            ),
          ),
        );
      },
    );
  }
}
