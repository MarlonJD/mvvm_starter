import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";
import "package:mvvm_starter/app/bootstrap.dart";
import "package:mvvm_starter/features/auth/presentation/login_view.dart";
import "package:mvvm_starter/features/home/presentation/home_view.dart";

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets("production composition boots to Login or Home", (tester) async {
    await bootstrapApp();
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
    final visibleStartupScreens =
        find.byType(LoginView).evaluate().length +
        find.byType(HomeView).evaluate().length;
    expect(visibleStartupScreens, 1);
  });
}
