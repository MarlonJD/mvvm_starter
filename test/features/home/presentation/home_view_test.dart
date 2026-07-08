import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mvvm_starter/app/router.dart";
import "package:mvvm_starter/app/routes.dart";
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
}
