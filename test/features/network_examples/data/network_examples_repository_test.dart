import "package:drift/native.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mvvm_starter/core/database/app_database.dart";
import "package:mvvm_starter/features/network_examples/data/network_examples_local_data_source.dart";
import "package:mvvm_starter/features/network_examples/data/network_examples_remote_data_sources.dart";
import "package:mvvm_starter/features/network_examples/data/network_examples_repository.dart";
import "package:mvvm_starter/features/network_examples/domain/network_example_models.dart";

void main() {
  late AppDatabase database;
  late NetworkExamplesLocalDataSource localDataSource;
  late NetworkExamplesRepository repository;

  const restPost = RestPost(
    id: 7,
    userId: 1,
    title: "REST title",
    body: "REST body",
  );
  const country = GraphqlCountry(
    code: "TR",
    name: "Turkey",
    emoji: "TR",
    capital: "Ankara",
  );

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    localDataSource = NetworkExamplesLocalDataSource(database);
    repository = NetworkExamplesRepository(
      restRemoteDataSource: _FakeRestRemoteDataSource([restPost]),
      graphqlRemoteDataSource: _FakeGraphqlRemoteDataSource([country]),
      localDataSource: localDataSource,
      now: () => DateTime.utc(2026, 7, 8),
    );
  });

  tearDown(() async {
    await database.close();
  });

  test("remote-only REST fetch does not persist posts", () async {
    final result = await repository.fetchRestRemoteOnly();

    expect(result.valueOrNull, [restPost]);
    expect(await localDataSource.restPosts(), isEmpty);
  });

  test("persisted REST fetch stores and returns local snapshot", () async {
    final result = await repository.fetchRestPersisted();

    expect(result.valueOrNull, [restPost]);
    expect(await localDataSource.restPosts(), [restPost]);
  });

  test("remote-only GraphQL fetch does not persist countries", () async {
    final result = await repository.fetchGraphqlRemoteOnly();

    expect(result.valueOrNull, [country]);
    expect(await localDataSource.graphqlCountries(), isEmpty);
  });

  test("persisted GraphQL fetch stores and returns local snapshot", () async {
    final result = await repository.fetchGraphqlPersisted();

    expect(result.valueOrNull, [country]);
    expect(await localDataSource.graphqlCountries(), [country]);
  });
}

final class _FakeRestRemoteDataSource implements RestPostsRemoteDataSource {
  _FakeRestRemoteDataSource(this.posts);

  final List<RestPost> posts;

  @override
  Future<List<RestPost>> fetchPosts({int limit = 5}) async {
    return posts.take(limit).toList();
  }
}

final class _FakeGraphqlRemoteDataSource
    implements GraphqlCountriesRemoteDataSource {
  _FakeGraphqlRemoteDataSource(this.countries);

  final List<GraphqlCountry> countries;

  @override
  Future<List<GraphqlCountry>> fetchCountries({int limit = 6}) async {
    return countries.take(limit).toList();
  }
}
