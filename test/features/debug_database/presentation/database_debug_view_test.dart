import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mvvm_starter/features/debug_database/presentation/database_debug_view.dart";
import "package:mvvm_starter/features/debug_database/presentation/database_debug_view_model.dart";

import "../../../helpers/test_auth_harness.dart";

void main() {
  testWidgets("debug database renders users and sessions", (tester) async {
    final harness = createTestAuthHarness();
    final user = (await harness.repository.createUser("alice")).valueOrNull!;
    final viewModel = DatabaseDebugViewModel(
      authRepository: harness.repository,
      watchForChanges: false,
    );

    await tester.pumpWidget(
      MaterialApp(home: DatabaseDebugView(viewModel: viewModel)),
    );
    await tester.pump();

    expect(find.text("alice"), findsOneWidget);
    expect(find.text("Session user_id: ${user.id}"), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await viewModel.close();
    await harness.dispose();
  });
}
