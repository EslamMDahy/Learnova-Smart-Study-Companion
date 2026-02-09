import 'package:flutter/material.dart';

import 'core/routing/app_router.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Learnova Smart Study Companion',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Lexend',
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF137FEC)),
      ),
      routerConfig: appRouter,
    );
  }
}
