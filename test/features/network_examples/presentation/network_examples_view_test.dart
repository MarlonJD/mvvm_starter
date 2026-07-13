import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mvvm_starter/core/errors/app_error.dart";
import "package:mvvm_starter/core/result/result.dart";
import "package:mvvm_starter/features/network_examples/data/network_examples_repository.dart";
import "package:mvvm_starter/features/network_examples/domain/network_example_models.dart";
import "package:mvvm_starter/features/network_examples/domain/persisted_result.dart";
import "package:mvvm_starter/features/network_examples/presentation/network_examples_view.dart";
import "package:mvvm_starter/features/network_examples/presentation/network_examples_view_model.dart";

void main() {
  testWidgets("view displays all successful sections and local freshness", (
    tester,
  ) async {
    final viewModel = NetworkExamplesViewModel(
      repository: _FakeNetworkExamplesRepository(),
    );

    await tester.pumpWidget(
      MaterialApp(home: NetworkExamplesView(viewModel: viewModel)),
    );
    await tester.pumpAndSettle();

    expect(find.text("REST remote-only"), findsOneWidget);
    expect(find.text("REST with local persistence"), findsOneWidget);
    expect(find.text("Remote REST"), findsOneWidget);
    expect(find.text("Persisted REST"), findsOneWidget);
    expect(find.text("Fresh offline snapshot"), findsOneWidget);

    await tester.scrollUntilVisible(find.text("Germany"), 200);
    expect(find.text("GraphQL remote-only"), findsOneWidget);
    expect(find.text("Germany"), findsOneWidget);

    await tester.scrollUntilVisible(find.text("Turkey"), 200);
    expect(find.text("GraphQL with local persistence"), findsOneWidget);
    expect(find.text("Turkey"), findsOneWidget);
    expect(find.text("Stale offline snapshot"), findsOneWidget);
  });

  testWidgets("one failed section does not hide successful sections", (
    tester,
  ) async {
    final viewModel = NetworkExamplesViewModel(
      repository: _FakeNetworkExamplesRepository(restRemoteFails: true),
    );

    await tester.pumpWidget(
      MaterialApp(home: NetworkExamplesView(viewModel: viewModel)),
    );
    await tester.pumpAndSettle();

    expect(find.text("Network request failed"), findsOneWidget);
    expect(find.text("Persisted REST"), findsOneWidget);
    expect(find.text("Germany"), findsOneWidget);
    expect(find.text("Turkey"), findsOneWidget);
  });

  testWidgets("refresh is disabled while the current generation loads", (
    tester,
  ) async {
    final repository = _PendingNetworkExamplesRepository();
    final viewModel = NetworkExamplesViewModel(repository: repository);

    await tester.pumpWidget(
      MaterialApp(home: NetworkExamplesView(viewModel: viewModel)),
    );
    await tester.pump();

    final buttonWhileLoading = tester.widget<IconButton>(
      find.byKey(const ValueKey("networkExamples.refreshButton")),
    );
    final wasDisabled = buttonWhileLoading.onPressed == null;

    repository.complete();
    await tester.pumpAndSettle();
    final buttonAfterLoad = tester.widget<IconButton>(
      find.byKey(const ValueKey("networkExamples.refreshButton")),
    );

    expect(wasDisabled, isTrue);
    expect(buttonAfterLoad.onPressed, isNotNull);
  });
}

final class _FakeNetworkExamplesRepository extends NetworkExamplesRepository {
  _FakeNetworkExamplesRepository({this.restRemoteFails = false}) : super.fake();

  final bool restRemoteFails;
  final DateTime fetchedAt = DateTime.utc(2026, 7, 13);

  @override
  Future<Result<List<RestPost>>> fetchRestRemoteOnly({int limit = 5}) async {
    if (restRemoteFails) {
      return const Result.failure(AppError.network("errors.network"));
    }
    return const Result.success([
      RestPost(id: 1, userId: 1, title: "Remote REST", body: "Body"),
    ]);
  }

  @override
  Future<Result<PersistedResult<List<RestPost>>>> fetchRestPersisted({
    int limit = 5,
  }) async {
    return Result.success(
      PersistedResult(
        value: const [
          RestPost(id: 2, userId: 1, title: "Persisted REST", body: "Body"),
        ],
        origin: DataOrigin.localFresh,
        fetchedAt: fetchedAt,
      ),
    );
  }

  @override
  Future<Result<List<GraphqlCountry>>> fetchGraphqlRemoteOnly({
    int limit = 6,
  }) async {
    return const Result.success([
      GraphqlCountry(
        code: "DE",
        name: "Germany",
        emoji: "DE",
        capital: "Berlin",
      ),
    ]);
  }

  @override
  Future<Result<PersistedResult<List<GraphqlCountry>>>> fetchGraphqlPersisted({
    int limit = 6,
  }) async {
    return Result.success(
      PersistedResult(
        value: const [
          GraphqlCountry(
            code: "TR",
            name: "Turkey",
            emoji: "TR",
            capital: "Ankara",
          ),
        ],
        origin: DataOrigin.localStale,
        fetchedAt: fetchedAt,
      ),
    );
  }
}

final class _PendingNetworkExamplesRepository
    extends NetworkExamplesRepository {
  _PendingNetworkExamplesRepository() : super.fake();

  final Completer<Result<List<RestPost>>> restRemoteOnly = Completer();
  final Completer<Result<PersistedResult<List<RestPost>>>> restPersisted =
      Completer();
  final Completer<Result<List<GraphqlCountry>>> graphqlRemoteOnly = Completer();
  final Completer<Result<PersistedResult<List<GraphqlCountry>>>>
  graphqlPersisted = Completer();

  @override
  Future<Result<List<RestPost>>> fetchRestRemoteOnly({int limit = 5}) =>
      restRemoteOnly.future;

  @override
  Future<Result<PersistedResult<List<RestPost>>>> fetchRestPersisted({
    int limit = 5,
  }) => restPersisted.future;

  @override
  Future<Result<List<GraphqlCountry>>> fetchGraphqlRemoteOnly({
    int limit = 6,
  }) => graphqlRemoteOnly.future;

  @override
  Future<Result<PersistedResult<List<GraphqlCountry>>>> fetchGraphqlPersisted({
    int limit = 6,
  }) => graphqlPersisted.future;

  void complete() {
    final fetchedAt = DateTime.utc(2026, 7, 13);
    restRemoteOnly.complete(const Result.success([]));
    restPersisted.complete(
      Result.success(
        PersistedResult(
          value: const [],
          origin: DataOrigin.remote,
          fetchedAt: fetchedAt,
        ),
      ),
    );
    graphqlRemoteOnly.complete(const Result.success([]));
    graphqlPersisted.complete(
      Result.success(
        PersistedResult(
          value: const [],
          origin: DataOrigin.remote,
          fetchedAt: fetchedAt,
        ),
      ),
    );
  }
}
