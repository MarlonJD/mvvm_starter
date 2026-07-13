import "dart:async";

import "package:flutter_test/flutter_test.dart";
import "package:mvvm_starter/core/errors/app_error.dart";
import "package:mvvm_starter/core/result/result.dart";
import "package:mvvm_starter/core/result/ui_state.dart";
import "package:mvvm_starter/features/network_examples/data/network_examples_repository.dart";
import "package:mvvm_starter/features/network_examples/domain/network_example_models.dart";
import "package:mvvm_starter/features/network_examples/domain/persisted_result.dart";
import "package:mvvm_starter/features/network_examples/presentation/network_examples_view_model.dart";

void main() {
  const restRemoteOnly = RestPost(
    id: 1,
    userId: 1,
    title: "Remote REST",
    body: "Body",
  );
  const restPersisted = RestPost(
    id: 2,
    userId: 1,
    title: "Persisted REST",
    body: "Body",
  );
  const graphqlRemoteOnly = GraphqlCountry(
    code: "DE",
    name: "Germany",
    emoji: "DE",
    capital: "Berlin",
  );
  const graphqlPersisted = GraphqlCountry(
    code: "TR",
    name: "Turkey",
    emoji: "TR",
    capital: "Ankara",
  );
  final fetchedAt = DateTime.utc(2026, 7, 13);

  test("load publishes four independent section outcomes", () async {
    final repository = _FakeNetworkExamplesRepository(
      restRemoteOnly: const Result.failure(AppError.network("errors.network")),
      restPersisted: Result.success(
        PersistedResult(
          value: const [restPersisted],
          origin: DataOrigin.localFresh,
          fetchedAt: fetchedAt,
        ),
      ),
      graphqlRemoteOnly: const Result.success([graphqlRemoteOnly]),
      graphqlPersisted: Result.success(
        PersistedResult(
          value: const [graphqlPersisted],
          origin: DataOrigin.localStale,
          fetchedAt: fetchedAt,
        ),
      ),
    );
    final viewModel = NetworkExamplesViewModel(repository: repository);
    addTearDown(viewModel.dispose);

    await viewModel.load();

    final state = viewModel.state.value;
    expect(state.restRemoteOnly, isA<UiFailure<List<RestPost>>>());
    expect(state.restPersisted.valueOrNull?.value, [restPersisted]);
    expect(state.restPersisted.valueOrNull?.origin, DataOrigin.localFresh);
    expect(state.graphqlRemoteOnly.valueOrNull, [graphqlRemoteOnly]);
    expect(state.graphqlPersisted.valueOrNull?.value, [graphqlPersisted]);
    expect(state.graphqlPersisted.valueOrNull?.origin, DataOrigin.localStale);
  });

  test("load launches every section before awaiting any result", () async {
    final repository = _CompleterNetworkExamplesRepository();
    final viewModel = NetworkExamplesViewModel(repository: repository);
    addTearDown(viewModel.dispose);

    final loadFuture = viewModel.load();
    await Future<void>.delayed(Duration.zero);

    expect(repository.started, {
      "restRemoteOnly",
      "restPersisted",
      "graphqlRemoteOnly",
      "graphqlPersisted",
    });
    final loading = viewModel.state.value;
    expect(loading.restRemoteOnly.isLoading, isTrue);
    expect(loading.restPersisted.isLoading, isTrue);
    expect(loading.graphqlRemoteOnly.isLoading, isTrue);
    expect(loading.graphqlPersisted.isLoading, isTrue);

    repository
      ..restRemoteOnly.complete(const Result.success([restRemoteOnly]))
      ..restPersisted.complete(
        Result.success(
          PersistedResult(
            value: const [restPersisted],
            origin: DataOrigin.remote,
            fetchedAt: fetchedAt,
          ),
        ),
      )
      ..graphqlRemoteOnly.complete(const Result.success([graphqlRemoteOnly]))
      ..graphqlPersisted.complete(
        Result.success(
          PersistedResult(
            value: const [graphqlPersisted],
            origin: DataOrigin.remote,
            fetchedAt: fetchedAt,
          ),
        ),
      );

    await loadFuture;
  });

  test("dispose before load completes does not publish", () async {
    final generation = _NetworkGeneration();
    final repository = _QueuedNetworkExamplesRepository([generation]);
    final viewModel = NetworkExamplesViewModel(repository: repository);

    final operation = viewModel.load();
    await Future<void>.delayed(Duration.zero);
    viewModel.dispose();
    generation.completeSuccess("disposed");

    await expectLater(operation, completes);
  });

  test("an older load cannot overwrite a newer generation", () async {
    final first = _NetworkGeneration();
    final second = _NetworkGeneration();
    final repository = _QueuedNetworkExamplesRepository([first, second]);
    final viewModel = NetworkExamplesViewModel(repository: repository);
    addTearDown(viewModel.dispose);

    final firstOperation = viewModel.load();
    await Future<void>.delayed(Duration.zero);
    final secondOperation = viewModel.load();
    await Future<void>.delayed(Duration.zero);
    second.completeSuccess("newer");
    await secondOperation;
    first.completeFailure();
    await firstOperation;

    final state = viewModel.state.value;
    expect(state.restRemoteOnly.valueOrNull?.single.title, "newer");
    expect(state.restPersisted.valueOrNull?.value.single.title, "newer");
    expect(state.graphqlRemoteOnly.valueOrNull?.single.name, "newer");
    expect(state.graphqlPersisted.valueOrNull?.value.single.name, "newer");
  });
}

final class _FakeNetworkExamplesRepository extends NetworkExamplesRepository {
  _FakeNetworkExamplesRepository({
    required this.restRemoteOnly,
    required this.restPersisted,
    required this.graphqlRemoteOnly,
    required this.graphqlPersisted,
  }) : super.fake();

  final Result<List<RestPost>> restRemoteOnly;
  final Result<PersistedResult<List<RestPost>>> restPersisted;
  final Result<List<GraphqlCountry>> graphqlRemoteOnly;
  final Result<PersistedResult<List<GraphqlCountry>>> graphqlPersisted;

  @override
  Future<Result<List<RestPost>>> fetchRestRemoteOnly({int limit = 5}) async =>
      restRemoteOnly;

  @override
  Future<Result<PersistedResult<List<RestPost>>>> fetchRestPersisted({
    int limit = 5,
  }) async => restPersisted;

  @override
  Future<Result<List<GraphqlCountry>>> fetchGraphqlRemoteOnly({
    int limit = 6,
  }) async => graphqlRemoteOnly;

  @override
  Future<Result<PersistedResult<List<GraphqlCountry>>>> fetchGraphqlPersisted({
    int limit = 6,
  }) async => graphqlPersisted;
}

final class _CompleterNetworkExamplesRepository
    extends NetworkExamplesRepository {
  _CompleterNetworkExamplesRepository() : super.fake();

  final Set<String> started = {};
  final Completer<Result<List<RestPost>>> restRemoteOnly = Completer();
  final Completer<Result<PersistedResult<List<RestPost>>>> restPersisted =
      Completer();
  final Completer<Result<List<GraphqlCountry>>> graphqlRemoteOnly = Completer();
  final Completer<Result<PersistedResult<List<GraphqlCountry>>>>
  graphqlPersisted = Completer();

  @override
  Future<Result<List<RestPost>>> fetchRestRemoteOnly({int limit = 5}) {
    started.add("restRemoteOnly");
    return restRemoteOnly.future;
  }

  @override
  Future<Result<PersistedResult<List<RestPost>>>> fetchRestPersisted({
    int limit = 5,
  }) {
    started.add("restPersisted");
    return restPersisted.future;
  }

  @override
  Future<Result<List<GraphqlCountry>>> fetchGraphqlRemoteOnly({int limit = 6}) {
    started.add("graphqlRemoteOnly");
    return graphqlRemoteOnly.future;
  }

  @override
  Future<Result<PersistedResult<List<GraphqlCountry>>>> fetchGraphqlPersisted({
    int limit = 6,
  }) {
    started.add("graphqlPersisted");
    return graphqlPersisted.future;
  }
}

final class _QueuedNetworkExamplesRepository extends NetworkExamplesRepository {
  _QueuedNetworkExamplesRepository(this.generations) : super.fake();

  final List<_NetworkGeneration> generations;
  var _restRemoteOnlyIndex = 0;
  var _restPersistedIndex = 0;
  var _graphqlRemoteOnlyIndex = 0;
  var _graphqlPersistedIndex = 0;

  @override
  Future<Result<List<RestPost>>> fetchRestRemoteOnly({int limit = 5}) {
    return generations[_restRemoteOnlyIndex++].restRemoteOnly.future;
  }

  @override
  Future<Result<PersistedResult<List<RestPost>>>> fetchRestPersisted({
    int limit = 5,
  }) {
    return generations[_restPersistedIndex++].restPersisted.future;
  }

  @override
  Future<Result<List<GraphqlCountry>>> fetchGraphqlRemoteOnly({int limit = 6}) {
    return generations[_graphqlRemoteOnlyIndex++].graphqlRemoteOnly.future;
  }

  @override
  Future<Result<PersistedResult<List<GraphqlCountry>>>> fetchGraphqlPersisted({
    int limit = 6,
  }) {
    return generations[_graphqlPersistedIndex++].graphqlPersisted.future;
  }
}

final class _NetworkGeneration {
  final Completer<Result<List<RestPost>>> restRemoteOnly = Completer();
  final Completer<Result<PersistedResult<List<RestPost>>>> restPersisted =
      Completer();
  final Completer<Result<List<GraphqlCountry>>> graphqlRemoteOnly = Completer();
  final Completer<Result<PersistedResult<List<GraphqlCountry>>>>
  graphqlPersisted = Completer();

  void completeSuccess(String label) {
    final fetchedAt = DateTime.utc(2026, 7, 13);
    restRemoteOnly.complete(
      Result.success([RestPost(id: 1, userId: 1, title: label, body: "Body")]),
    );
    restPersisted.complete(
      Result.success(
        PersistedResult(
          value: [RestPost(id: 2, userId: 1, title: label, body: "Body")],
          origin: DataOrigin.remote,
          fetchedAt: fetchedAt,
        ),
      ),
    );
    graphqlRemoteOnly.complete(
      Result.success([
        GraphqlCountry(code: "DE", name: label, emoji: "DE", capital: null),
      ]),
    );
    graphqlPersisted.complete(
      Result.success(
        PersistedResult(
          value: [
            GraphqlCountry(code: "TR", name: label, emoji: "TR", capital: null),
          ],
          origin: DataOrigin.remote,
          fetchedAt: fetchedAt,
        ),
      ),
    );
  }

  void completeFailure() {
    restRemoteOnly.complete(
      const Result.failure(AppError.network("errors.network")),
    );
    restPersisted.complete(
      const Result.failure(AppError.network("errors.network")),
    );
    graphqlRemoteOnly.complete(
      const Result.failure(AppError.network("errors.network")),
    );
    graphqlPersisted.complete(
      const Result.failure(AppError.network("errors.network")),
    );
  }
}
