import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:mvvm_starter/auth/user_service.dart";
import "package:mvvm_starter/core/database_abstract.dart";
import "package:mvvm_starter/core/hive_abstract.dart";
import "package:mvvm_starter/core/locator.dart";
import "package:mvvm_starter/route.dart";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  setupLocator();

  await locator<DatabaseAbstraction>().openDatabaseWithTables(
    [
      "CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, uid INTEGER NOT NULL, admin INTEGER)",
      "CREATE TABLE IF NOT EXISTS sessions (id INTEGER PRIMARY KEY AUTOINCREMENT, user_id INTEGER NOT NULL, FOREIGN KEY (user_id) REFERENCES users(id))",
    ],
    "radlofa_app",
  );

  locator<UserService>().sessionExists();

  await locator<HiveDatabaseAbstraction>().initHiveDatabase();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale("en", "US"), Locale("tr", "TR")],
      path: "assets/translations",
      fallbackLocale: const Locale("en", "US"),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final UserService userService = locator<UserService>();

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      routerConfig: RouterService(
        userService: userService,
      ).router,
      title: "Flutter Demo",
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
    );
  }
}
