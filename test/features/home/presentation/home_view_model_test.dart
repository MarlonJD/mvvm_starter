import "package:flutter_test/flutter_test.dart";
import "package:mvvm_starter/features/home/presentation/home_view_model.dart";

import "../../../helpers/test_auth_harness.dart";

void main() {
  test("logout clears active user", () async {
    final harness = createTestAuthHarness();
    addTearDown(harness.dispose);
    await harness.repository.createUser("alice");
    final viewModel = HomeViewModel(authRepository: harness.repository);

    await viewModel.logout();

    expect(viewModel.activeUser.value, isNull);
  });
}
