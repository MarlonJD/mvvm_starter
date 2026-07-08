import "package:flutter_test/flutter_test.dart";
import "package:mvvm_starter/core/result/result.dart";
import "package:mvvm_starter/core/result/ui_state.dart";
import "package:mvvm_starter/features/network_examples/data/network_examples_repository.dart";
import "package:mvvm_starter/features/network_examples/domain/network_example_models.dart";
import "package:mvvm_starter/features/network_examples/presentation/network_examples_view_model.dart";

void main() {
  test("load exposes remote-only and persisted REST and GraphQL data",
      () async {
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
    final viewModel = NetworkExamplesViewModel(
      repository: _FakeNetworkExamplesRepository(
        restRemoteOnly: [restRemoteOnly],
        restPersisted: [restPersisted],
        graphqlRemoteOnly: [graphqlRemoteOnly],
        graphqlPersisted: [graphqlPersisted],
      ),
    );
    addTearDown(viewModel.dispose);

    await viewModel.load();

    final state = viewModel.state.value;
    expect(state, isA<UiSuccess<NetworkExamplesState>>());
    expect(state.valueOrNull?.restRemoteOnly, [restRemoteOnly]);
    expect(state.valueOrNull?.restPersisted, [restPersisted]);
    expect(state.valueOrNull?.graphqlRemoteOnly, [graphqlRemoteOnly]);
    expect(state.valueOrNull?.graphqlPersisted, [graphqlPersisted]);
  });
}

final class _FakeNetworkExamplesRepository extends NetworkExamplesRepository {
  _FakeNetworkExamplesRepository({
    required this.restRemoteOnly,
    required this.restPersisted,
    required this.graphqlRemoteOnly,
    required this.graphqlPersisted,
  }) : super.fake();

  final List<RestPost> restRemoteOnly;
  final List<RestPost> restPersisted;
  final List<GraphqlCountry> graphqlRemoteOnly;
  final List<GraphqlCountry> graphqlPersisted;

  @override
  Future<Result<List<RestPost>>> fetchRestRemoteOnly({int limit = 5}) async {
    return Result.success(restRemoteOnly);
  }

  @override
  Future<Result<List<RestPost>>> fetchRestPersisted({int limit = 5}) async {
    return Result.success(restPersisted);
  }

  @override
  Future<Result<List<GraphqlCountry>>> fetchGraphqlRemoteOnly({
    int limit = 6,
  }) async {
    return Result.success(graphqlRemoteOnly);
  }

  @override
  Future<Result<List<GraphqlCountry>>> fetchGraphqlPersisted({
    int limit = 6,
  }) async {
    return Result.success(graphqlPersisted);
  }
}
