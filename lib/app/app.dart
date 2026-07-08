import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";

/// Root Flutter application.
final class MvvmStarterApp extends StatelessWidget {
  /// Creates the root app.
  const MvvmStarterApp({required this.routerConfig, super.key});

  /// Router configuration.
  final GoRouter routerConfig;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      restorationScopeId: "mvvm_starter",
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      routerConfig: routerConfig,
      title: "MVVM Starter",
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
    );
  }
}
