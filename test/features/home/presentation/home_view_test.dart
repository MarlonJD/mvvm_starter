import "dart:async";

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:mvvm_starter/app/router.dart";
import "package:mvvm_starter/app/routes.dart";
import "package:mvvm_starter/core/errors/app_error.dart";
import "package:mvvm_starter/core/result/result.dart";
import "package:mvvm_starter/features/auth/data/auth_repository.dart";
import "package:mvvm_starter/features/auth/domain/user.dart";
import "package:mvvm_starter/features/auth/presentation/login_view.dart";
import "package:mvvm_starter/features/auth/presentation/login_view_model.dart";
import "package:mvvm_starter/features/auth/presentation/signup_view.dart";
import "package:mvvm_starter/features/auth/presentation/signup_view_model.dart";
import "package:mvvm_starter/features/debug_database/presentation/database_debug_view.dart";
import "package:mvvm_starter/features/debug_database/presentation/database_debug_view_model.dart";
import "package:mvvm_starter/features/home/presentation/home_view.dart";
import "package:mvvm_starter/features/home/presentation/home_view_model.dart";
import "package:mvvm_starter/features/network_examples/data/network_examples_repository.dart";
import "package:mvvm_starter/features/network_examples/presentation/network_examples_view.dart";
import "package:mvvm_starter/features/network_examples/presentation/network_examples_view_model.dart";

import "../../../helpers/test_auth_harness.dart";

void main() {
  testWidgets("home displays active user and supports logout", (tester) async {
    final harness = createTestAuthHarness();
    addTearDown(harness.dispose);
    await harness.repository.createUser("alice");

    final routerService = RouterService(
      authRepository: harness.repository,
      homeBuilder: (context, state) => HomeView(
        viewModel: HomeViewModel(authRepository: harness.repository),
      ),
      networkExamplesBuilder: (context, state) => NetworkExamplesView(
        viewModel: NetworkExamplesViewModel(
          repository: NetworkExamplesRepository.fake(),
        ),
      ),
      oidcExampleBuilder: (context, state) => const SizedBox.shrink(),
      loginBuilder: (context, state) => LoginView(
        viewModel: LoginViewModel(authRepository: harness.repository),
      ),
      signupBuilder: (context, state) => SignupView(
        viewModel: SignupViewModel(authRepository: harness.repository),
      ),
      debugDatabaseBuilder: (context, state) => DatabaseDebugView(
        viewModel: DatabaseDebugViewModel(authRepository: harness.repository),
      ),
    );
    addTearDown(routerService.dispose);
    routerService.router.go(AppRoute.home.path);

    await tester.pumpWidget(
      MaterialApp.router(routerConfig: routerService.router),
    );
    await tester.pumpAndSettle();

    expect(find.text("Welcome, alice"), findsOneWidget);

    await tester.tap(find.byKey(logoutButtonKey));
    await tester.pumpAndSettle();

    expect(harness.repository.activeUser.value, isNull);
    expect(find.text("Login"), findsWidgets);
  });

  testWidgets("admin display name does not expose delete-all authority", (
    tester,
  ) async {
    final harness = createTestAuthHarness();
    addTearDown(harness.dispose);
    final signupViewModel = SignupViewModel(authRepository: harness.repository);
    addTearDown(signupViewModel.dispose);
    signupViewModel.nameController.value.text = "admin";
    await signupViewModel.createUser();

    final routerService = RouterService(
      authRepository: harness.repository,
      homeBuilder: (context, state) => HomeView(
        viewModel: HomeViewModel(authRepository: harness.repository),
      ),
      networkExamplesBuilder: (context, state) => NetworkExamplesView(
        viewModel: NetworkExamplesViewModel(
          repository: NetworkExamplesRepository.fake(),
        ),
      ),
      oidcExampleBuilder: (context, state) => const SizedBox.shrink(),
      loginBuilder: (context, state) => LoginView(
        viewModel: LoginViewModel(authRepository: harness.repository),
      ),
      signupBuilder: (context, state) => SignupView(
        viewModel: SignupViewModel(authRepository: harness.repository),
      ),
      debugDatabaseBuilder: (context, state) => DatabaseDebugView(
        viewModel: DatabaseDebugViewModel(authRepository: harness.repository),
      ),
    );
    addTearDown(routerService.dispose);
    routerService.router.go(AppRoute.home.path);

    await tester.pumpWidget(
      MaterialApp.router(routerConfig: routerService.router),
    );
    await tester.pumpAndSettle();

    expect(find.text("Welcome, admin"), findsOneWidget);
    expect(find.text("Delete All Users"), findsNothing);
  });

  testWidgets("logout failure stays on Home and shows the error", (
    tester,
  ) async {
    final repository = _ControlledLogoutRepository(
      immediateResult: const Result.failure(
        AppError.database("errors.database"),
      ),
    );
    final router = _logoutRouter(repository);
    addTearDown(router.dispose);
    addTearDown(repository.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(logoutButtonKey));
    await tester.pumpAndSettle();

    expect(find.text("Welcome, alice"), findsOneWidget);
    expect(find.text("Database error"), findsOneWidget);
    expect(find.text("Login destination"), findsNothing);
  });

  testWidgets("logout navigates only after persistence succeeds", (
    tester,
  ) async {
    final completer = Completer<Result<void>>();
    final repository = _ControlledLogoutRepository(completer: completer);
    final router = _logoutRouter(repository);
    addTearDown(router.dispose);
    addTearDown(repository.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(logoutButtonKey));
    await tester.pump();

    expect(find.text("Welcome, alice"), findsOneWidget);
    expect(find.text("Login destination"), findsNothing);

    completer.complete(const Result.success(null));
    await tester.pumpAndSettle();

    expect(find.text("Login destination"), findsOneWidget);
  });
}

GoRouter _logoutRouter(_ControlledLogoutRepository repository) {
  return GoRouter(
    routes: [
      GoRoute(
        name: AppRoute.home.name,
        path: AppRoute.home.path,
        builder: (context, state) =>
            HomeView(viewModel: HomeViewModel(authRepository: repository)),
      ),
      GoRoute(
        name: AppRoute.login.name,
        path: AppRoute.login.path,
        builder: (context, state) =>
            const Scaffold(body: Text("Login destination")),
      ),
    ],
  );
}

final class _ControlledLogoutRepository extends AuthRepository {
  _ControlledLogoutRepository({this.immediateResult, this.completer})
    : super.fake();

  final Result<void>? immediateResult;
  final Completer<Result<void>>? completer;
  final ValueNotifier<User?> _user = ValueNotifier(_alice);

  @override
  ValueListenable<User?> get activeUser => _user;

  @override
  Future<Result<void>> logout() async {
    final result = immediateResult ?? await completer!.future;
    if (result.isSuccess) {
      _user.value = null;
    }
    return result;
  }

  @override
  void dispose() {
    _user.dispose();
    super.dispose();
  }
}

final _now = DateTime.utc(2026);
final _alice = User(
  id: 1,
  uid: "uid-alice",
  name: "alice",
  createdAt: _now,
  updatedAt: _now,
);
