import "package:drift/native.dart";
import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mvvm_starter/app/router.dart";
import "package:mvvm_starter/app/routes.dart";
import "package:mvvm_starter/core/database/app_database.dart";
import "package:mvvm_starter/features/auth/data/auth_local_datasource.dart";
import "package:mvvm_starter/features/auth/data/auth_repository.dart";

void main() {
  late AppDatabase database;
  late AuthRepository repository;
  late RouterService routerService;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = AuthRepository(
      localDataSource: AuthLocalDataSource(database),
      uidFactory: () => "uid",
      now: () => DateTime.utc(2026),
    );
    routerService = RouterService(
      authRepository: repository,
      homeBuilder: (context, state) => const SizedBox(key: Key("home")),
      loginBuilder: (context, state) => const SizedBox(key: Key("login")),
      signupBuilder: (context, state) => const SizedBox(key: Key("signup")),
      debugDatabaseBuilder: (context, state) =>
          const SizedBox(key: Key("database")),
    );
  });

  tearDown(() async {
    routerService.dispose();
    repository.dispose();
    await database.close();
  });

  testWidgets("unauthenticated home redirects to login", (tester) async {
    routerService.router.go(AppRoute.home.path);

    await tester.pumpWidget(
      WidgetsApp.router(
        color: const Color(0xffffffff),
        routerConfig: routerService.router,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key("login")), findsOneWidget);
  });

  testWidgets("unauthenticated signup is allowed", (tester) async {
    routerService.router.go(AppRoute.signup.path);

    await tester.pumpWidget(
      WidgetsApp.router(
        color: const Color(0xffffffff),
        routerConfig: routerService.router,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key("signup")), findsOneWidget);
  });

  testWidgets("authenticated login redirects home", (tester) async {
    await repository.createUser("alice");
    routerService.router.go(AppRoute.login.path);

    await tester.pumpWidget(
      WidgetsApp.router(
        color: const Color(0xffffffff),
        routerConfig: routerService.router,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key("home")), findsOneWidget);
  });
}
