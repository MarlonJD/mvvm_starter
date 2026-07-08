import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mvvm_starter/core/result/result.dart";
import "package:mvvm_starter/features/network_examples/data/network_examples_repository.dart";
import "package:mvvm_starter/features/network_examples/domain/network_example_models.dart";
import "package:mvvm_starter/features/network_examples/presentation/network_examples_view.dart";
import "package:mvvm_starter/features/network_examples/presentation/network_examples_view_model.dart";

void main() {
  testWidgets("view loads and displays all four network examples",
      (tester) async {
    final viewModel = NetworkExamplesViewModel(
      repository: _FakeNetworkExamplesRepository(),
    );

    await tester.pumpWidget(
      MaterialApp(home: NetworkExamplesView(viewModel: viewModel)),
    );
    await tester.pumpAndSettle();

    expect(find.text("REST remote-only"), findsOneWidget);
    expect(find.text("REST with local persistence"), findsOneWidget);
    expect(find.text("GraphQL remote-only"), findsOneWidget);
    expect(find.text("GraphQL with local persistence"), findsOneWidget);
    expect(find.text("Remote REST"), findsOneWidget);
    expect(find.text("Persisted REST"), findsOneWidget);
    expect(find.text("Germany"), findsOneWidget);
    expect(find.text("Turkey"), findsOneWidget);
  });
}

final class _FakeNetworkExamplesRepository extends NetworkExamplesRepository {
  _FakeNetworkExamplesRepository() : super.fake();

  @override
  Future<Result<List<RestPost>>> fetchRestRemoteOnly({int limit = 5}) async {
    return const Result.success([
      RestPost(id: 1, userId: 1, title: "Remote REST", body: "Body"),
    ]);
  }

  @override
  Future<Result<List<RestPost>>> fetchRestPersisted({int limit = 5}) async {
    return const Result.success([
      RestPost(id: 2, userId: 1, title: "Persisted REST", body: "Body"),
    ]);
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
  Future<Result<List<GraphqlCountry>>> fetchGraphqlPersisted({
    int limit = 6,
  }) async {
    return const Result.success([
      GraphqlCountry(
        code: "TR",
        name: "Turkey",
        emoji: "TR",
        capital: "Ankara",
      ),
    ]);
  }
}
