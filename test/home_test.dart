import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mvvm_starter/auth/user.dart";
import "package:mvvm_starter/auth/user_service.dart";
import "package:mvvm_starter/core/locator.dart";
import "package:mvvm_starter/pages/home/home_view.dart";

class FakeUserService extends Fake implements UserService {
  final _userNotifier = ValueNotifier<User?>(
    User(id: 1, name: "Test User", uid: "test-uid", isAdmin: 0),
  );
  bool deleteSessionCalled = false;

  @override
  ValueNotifier<User?> get userNotifier => _userNotifier;

  @override
  void deleteSession(User user) {
    deleteSessionCalled = true;
    _userNotifier.value = null;
  }
}

void main() {
  tearDown(locator.reset);

  group("HomeView", () {
    testWidgets("shows user name", (tester) async {
      // Register fake implementation
      final fakeUserService = FakeUserService();
      locator.registerSingleton<UserService>(fakeUserService);

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeView(),
        ),
      );

      // Verify initial state shows user name
      expect(find.text("Welcome, Test User"), findsOneWidget);

      // Tap logout button
      await tester.tap(find.text("Logout"));
      await tester.pump();

      // Verify snackbar is shown
      expect(find.text("Logged out"), findsOneWidget);

      // Verify deleteSession was called
      expect(fakeUserService.deleteSessionCalled, true);
    });
  });
}
