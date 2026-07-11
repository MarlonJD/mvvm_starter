import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:mvvm_starter/app/app.dart";
import "package:mvvm_starter/app/di.dart";
import "package:mvvm_starter/app/router.dart";

/// Initializes the app and starts Flutter.
Future<void> bootstrapApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  setupDependencies();
  await restoreStartupSession();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale("en", "US"), Locale("tr", "TR")],
      path: "assets/translations",
      fallbackLocale: const Locale("en", "US"),
      child: MvvmStarterApp(routerConfig: locator<RouterService>().router),
    ),
  );
}
