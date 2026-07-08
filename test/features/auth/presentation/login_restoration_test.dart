import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mvvm_starter/features/auth/data/auth_repository.dart";
import "package:mvvm_starter/features/auth/presentation/login_view.dart";
import "package:mvvm_starter/features/auth/presentation/login_view_model.dart";

import "../../../helpers/test_auth_harness.dart";

void main() {
  testWidgets("login name input restores after restart", (tester) async {
    final harness = createTestAuthHarness();
    addTearDown(harness.dispose);

    await tester.pumpWidget(
      MaterialApp(
        restorationScopeId: "test_app",
        home: _LoginRestorationHost(repository: harness.repository),
      ),
    );

    await tester.enterText(find.byKey(loginNameFieldKey), "alice");
    await tester.pump();
    await tester.restartAndRestore();
    await tester.pump();

    final field = tester.widget<TextFormField>(find.byKey(loginNameFieldKey));
    expect(field.controller?.text, "alice");
  });
}

final class _LoginRestorationHost extends StatefulWidget {
  const _LoginRestorationHost({required this.repository});

  final AuthRepository repository;

  @override
  State<_LoginRestorationHost> createState() => _LoginRestorationHostState();
}

final class _LoginRestorationHostState extends State<_LoginRestorationHost> {
  late final LoginViewModel viewModel =
      LoginViewModel(authRepository: widget.repository);

  @override
  Widget build(BuildContext context) {
    return LoginView(viewModel: viewModel);
  }
}
