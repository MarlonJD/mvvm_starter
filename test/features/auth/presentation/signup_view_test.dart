import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mvvm_starter/features/auth/presentation/signup_view.dart";
import "package:mvvm_starter/features/auth/presentation/signup_view_model.dart";

import "../../../helpers/test_auth_harness.dart";

void main() {
  testWidgets("signup displays duplicate-user feedback", (tester) async {
    final harness = createTestAuthHarness();
    addTearDown(harness.dispose);
    await harness.repository.createUser("alice");
    await harness.repository.logout();

    await tester.pumpWidget(
      MaterialApp(
        home: SignupView(
          viewModel: SignupViewModel(authRepository: harness.repository),
        ),
      ),
    );

    await tester.enterText(find.byKey(signupNameFieldKey), "alice");
    await tester.tap(find.byKey(signupButtonKey));
    await tester.pump();

    expect(find.text("User already exists"), findsOneWidget);
  });
}
