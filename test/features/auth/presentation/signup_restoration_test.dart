import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mvvm_starter/features/auth/data/auth_repository.dart";
import "package:mvvm_starter/features/auth/presentation/signup_view.dart";
import "package:mvvm_starter/features/auth/presentation/signup_view_model.dart";

import "../../../helpers/test_auth_harness.dart";

void main() {
  testWidgets("signup name input restores after restart", (tester) async {
    final harness = createTestAuthHarness();
    addTearDown(harness.dispose);

    await tester.pumpWidget(
      MaterialApp(
        restorationScopeId: "test_app",
        home: _SignupRestorationHost(repository: harness.repository),
      ),
    );

    await tester.enterText(find.byKey(signupNameFieldKey), "alice");
    await tester.pump();
    await tester.restartAndRestore();
    await tester.pump();

    final field = tester.widget<TextFormField>(find.byKey(signupNameFieldKey));
    expect(field.controller?.text, "alice");
  });
}

final class _SignupRestorationHost extends StatefulWidget {
  const _SignupRestorationHost({required this.repository});

  final AuthRepository repository;

  @override
  State<_SignupRestorationHost> createState() => _SignupRestorationHostState();
}

final class _SignupRestorationHostState extends State<_SignupRestorationHost> {
  late final SignupViewModel viewModel =
      SignupViewModel(authRepository: widget.repository);

  @override
  Widget build(BuildContext context) {
    return SignupView(viewModel: viewModel);
  }
}
