import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mvvm_starter/features/auth/presentation/login_view.dart";
import "package:mvvm_starter/features/auth/presentation/login_view_model.dart";

import "../../../helpers/test_auth_harness.dart";

void main() {
  testWidgets("login displays validation feedback for empty name",
      (tester) async {
    final harness = createTestAuthHarness();
    addTearDown(harness.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: LoginView(
          viewModel: LoginViewModel(authRepository: harness.repository),
        ),
      ),
    );

    await tester.tap(find.byKey(loginButtonKey));
    await tester.pump();

    expect(find.text("Please enter a name"), findsOneWidget);
  });

  testWidgets("login displays not-found feedback", (tester) async {
    final harness = createTestAuthHarness();
    addTearDown(harness.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: LoginView(
          viewModel: LoginViewModel(authRepository: harness.repository),
        ),
      ),
    );

    await tester.enterText(find.byKey(loginNameFieldKey), "missing");
    await tester.tap(find.byKey(loginButtonKey));
    await tester.pump();

    expect(find.text("No user associated with this name"), findsOneWidget);
  });
}
