import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mvvm_starter/features/auth/data/auth_repository.dart";
import "package:mvvm_starter/features/auth/domain/user.dart";
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

  test("close awaits subscriptions before disposing notifiers", () async {
    final repository = _DelayedCancelAuthRepository();
    final viewModel = DatabaseDebugViewModel(authRepository: repository);
    await viewModel.init();

    var closeCompleted = false;
    final closeFuture = viewModel.close().then((_) {
      closeCompleted = true;
    });
    await Future<void>.delayed(Duration.zero);

    try {
      expect(closeCompleted, isFalse);
      expect(() => viewModel.users.addListener(_noop), returnsNormally);
      viewModel.users.removeListener(_noop);
    } finally {
      repository.usersCancelled.complete();
      repository.sessionsCancelled.complete();
      await closeFuture;
      await repository.closeControllers();
      repository.dispose();
    }

    expect(() => viewModel.users.addListener(_noop), throwsFlutterError);
  });
}

void _noop() {}

final class _DelayedCancelAuthRepository extends AuthRepository {
  _DelayedCancelAuthRepository() : super.fake() {
    usersController = StreamController(onCancel: () => usersCancelled.future);
    sessionsController = StreamController(
      onCancel: () => sessionsCancelled.future,
    );
  }

  final Completer<void> usersCancelled = Completer();
  final Completer<void> sessionsCancelled = Completer();
  late final StreamController<List<User>> usersController;
  late final StreamController<List<int>> sessionsController;

  @override
  Future<List<User>> users() async => const [];

  @override
  Future<List<int>> sessionUserIds() async => const [];

  @override
  Stream<List<User>> watchUsers() => usersController.stream;

  @override
  Stream<List<int>> watchSessionUserIds() => sessionsController.stream;

  Future<void> closeControllers() async {
    await usersController.close();
    await sessionsController.close();
  }
}
