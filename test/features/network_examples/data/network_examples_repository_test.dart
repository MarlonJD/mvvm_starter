import "dart:io";

import "package:drift/native.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mvvm_starter/core/database/app_database.dart";
import "package:mvvm_starter/core/errors/app_error.dart";
import "package:mvvm_starter/core/network/network_exception.dart";
import "package:mvvm_starter/features/network_examples/data/network_examples_local_data_source.dart";
import "package:mvvm_starter/features/network_examples/data/network_examples_remote_data_sources.dart";
import "package:mvvm_starter/features/network_examples/data/network_examples_repository.dart";
import "package:mvvm_starter/features/network_examples/domain/network_example_models.dart";
import "package:mvvm_starter/features/network_examples/domain/persisted_result.dart";
import "package:mvvm_starter/features/network_examples/domain/persistence_scope.dart";

void main() {
  const publicScope = PersistenceScope.public();
  final aliceScope = PersistenceScope.oidc(
    issuer: "https://issuer.example",
    subject: "alice",
  );
  final bobScope = PersistenceScope.oidc(
    issuer: "https://issuer.example",
    subject: "bob",
  );
  final now = DateTime.utc(2026, 7, 13, 12);
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

  late AppDatabase database;
  late NetworkExamplesLocalDataSource localDataSource;
  late _FakeRestRemoteDataSource restRemote;
  late _FakeGraphqlRemoteDataSource graphqlRemote;
  late PersistenceScope selectedScope;
  late NetworkExamplesRepository repository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    localDataSource = NetworkExamplesLocalDataSource(database);
    restRemote = _FakeRestRemoteDataSource([restPost]);
    graphqlRemote = _FakeGraphqlRemoteDataSource([country]);
    selectedScope = publicScope;
    repository = NetworkExamplesRepository(
      restRemoteDataSource: restRemote,
      graphqlRemoteDataSource: graphqlRemote,
      localDataSource: localDataSource,
      persistenceScope: () => selectedScope,
      now: () => now,
    );
  });

  tearDown(() async {
    await database.close();
  });

  test("remote-only REST fetch does not read or persist posts", () async {
    await localDataSource.replaceRestPosts(
      const [restPost],
      scope: publicScope,
      fetchedAt: now,
    );
    await database.customStatement("DROP TABLE rest_posts");

    final result = await repository.fetchRestRemoteOnly();

    expect(result.valueOrNull, [restPost]);
  });

  test(
    "remote-only GraphQL fetch does not read or persist countries",
    () async {
      await localDataSource.replaceGraphqlCountries(
        const [country],
        scope: publicScope,
        fetchedAt: now,
      );
      await database.customStatement("DROP TABLE graphql_countries");

      final result = await repository.fetchGraphqlRemoteOnly();

      expect(result.valueOrNull, [country]);
    },
  );

  test(
    "successful persisted REST fetch writes and returns remote origin",
    () async {
      final result = await repository.fetchRestPersisted();

      expect(result.valueOrNull?.value, [restPost]);
      expect(result.valueOrNull?.origin, DataOrigin.remote);
      expect(result.valueOrNull?.fetchedAt, now);
      expect((await localDataSource.restPosts(scope: publicScope)).value, [
        restPost,
      ]);
    },
  );

  test(
    "successful persisted GraphQL fetch writes and returns remote origin",
    () async {
      final result = await repository.fetchGraphqlPersisted();

      expect(result.valueOrNull?.value, [country]);
      expect(result.valueOrNull?.origin, DataOrigin.remote);
      expect(result.valueOrNull?.fetchedAt, now);
      expect(
        (await localDataSource.graphqlCountries(scope: publicScope)).value,
        [country],
      );
    },
  );

  test("network failure returns a fresh REST snapshot", () async {
    await localDataSource.replaceRestPosts(
      const [restPost],
      scope: publicScope,
      fetchedAt: now.subtract(const Duration(minutes: 14)),
    );
    restRemote.error = const NetworkException.transport("rest.offline");

    final result = await repository.fetchRestPersisted();

    expect(result.valueOrNull?.value, [restPost]);
    expect(result.valueOrNull?.origin, DataOrigin.localFresh);
    expect(
      result.valueOrNull?.fetchedAt,
      now.subtract(const Duration(minutes: 14)),
    );
  });

  test("network failure returns a stale GraphQL snapshot", () async {
    await localDataSource.replaceGraphqlCountries(
      const [country],
      scope: publicScope,
      fetchedAt: now.subtract(const Duration(minutes: 16)),
    );
    graphqlRemote.error = const NetworkException.transport("graphql.offline");

    final result = await repository.fetchGraphqlPersisted();

    expect(result.valueOrNull?.value, [country]);
    expect(result.valueOrNull?.origin, DataOrigin.localStale);
    expect(
      result.valueOrNull?.fetchedAt,
      now.subtract(const Duration(minutes: 16)),
    );
  });

  test(
    "network failure without local rows returns the network error",
    () async {
      restRemote.error = const NetworkException.transport("rest.offline");

      final result = await repository.fetchRestPersisted();

      expect(result.errorOrNull?.type, AppErrorType.network);
      expect(result.errorOrNull?.cause, isA<NetworkException>());
    },
  );

  test("local read failure is mapped as database", () async {
    restRemote.error = const NetworkException.transport("rest.offline");
    await database.customStatement("DROP TABLE rest_posts");

    final result = await repository.fetchRestPersisted();

    expect(result.errorOrNull?.type, AppErrorType.database);
  });

  test("local write failure is mapped as database", () async {
    await database.customStatement("DROP TABLE graphql_countries");

    final result = await repository.fetchGraphqlPersisted();

    expect(result.errorOrNull?.type, AppErrorType.database);
  });

  test("public and OIDC identity scopes cannot read one another", () async {
    await localDataSource.replaceRestPosts(
      const [restPost],
      scope: publicScope,
      fetchedAt: now,
    );
    await localDataSource.replaceRestPosts(
      const [RestPost(id: 7, userId: 2, title: "Alice", body: "Private")],
      scope: aliceScope,
      fetchedAt: now,
    );
    await localDataSource.replaceGraphqlCountries(
      const [country],
      scope: bobScope,
      fetchedAt: now,
    );

    expect(
      (await localDataSource.restPosts(scope: publicScope)).value.single.title,
      "REST title",
    );
    expect(
      (await localDataSource.restPosts(scope: aliceScope)).value.single.title,
      "Alice",
    );
    expect((await localDataSource.restPosts(scope: bobScope)).value, isEmpty);
    expect(
      (await localDataSource.graphqlCountries(scope: publicScope)).value,
      isEmpty,
    );
    expect(
      (await localDataSource.graphqlCountries(scope: aliceScope)).value,
      isEmpty,
    );
    expect((await localDataSource.graphqlCountries(scope: bobScope)).value, [
      country,
    ]);
  });

  test("an empty remote response replaces only its selected scope", () async {
    await localDataSource.replaceRestPosts(
      const [restPost],
      scope: publicScope,
      fetchedAt: now.subtract(const Duration(minutes: 1)),
    );
    await localDataSource.replaceRestPosts(
      const [RestPost(id: 7, userId: 2, title: "Alice", body: "Private")],
      scope: aliceScope,
      fetchedAt: now.subtract(const Duration(minutes: 1)),
    );
    selectedScope = aliceScope;
    restRemote.values = const [];

    final result = await repository.fetchRestPersisted();

    expect(result.valueOrNull?.value, isEmpty);
    expect(result.valueOrNull?.origin, DataOrigin.remote);
    expect((await localDataSource.restPosts(scope: aliceScope)).value, isEmpty);
    expect((await localDataSource.restPosts(scope: publicScope)).value, [
      restPost,
    ]);
  });

  test("REST and GraphQL snapshots survive database restart", () async {
    await database.close();
    final directory = await Directory.systemTemp.createTemp("mvvm-offline-");
    final file = File("${directory.path}/offline.sqlite");
    addTearDown(() async {
      if (directory.existsSync()) {
        await directory.delete(recursive: true);
      }
    });

    final firstDatabase = AppDatabase(NativeDatabase(file));
    final firstLocal = NetworkExamplesLocalDataSource(firstDatabase);
    await firstLocal.replaceRestPosts(
      const [restPost],
      scope: aliceScope,
      fetchedAt: now,
    );
    await firstLocal.replaceGraphqlCountries(
      const [country],
      scope: aliceScope,
      fetchedAt: now,
    );
    await firstDatabase.close();

    final reopenedDatabase = AppDatabase(NativeDatabase(file));
    final reopenedLocal = NetworkExamplesLocalDataSource(reopenedDatabase);
    addTearDown(reopenedDatabase.close);
    final offlineRepository = NetworkExamplesRepository(
      restRemoteDataSource: _FakeRestRemoteDataSource(
        const [],
        error: const NetworkException.transport("rest.offline"),
      ),
      graphqlRemoteDataSource: _FakeGraphqlRemoteDataSource(
        const [],
        error: const NetworkException.transport("graphql.offline"),
      ),
      localDataSource: reopenedLocal,
      persistenceScope: () => aliceScope,
      now: () => now.add(const Duration(minutes: 1)),
    );

    final restResult = await offlineRepository.fetchRestPersisted();
    final graphqlResult = await offlineRepository.fetchGraphqlPersisted();

    expect(restResult.valueOrNull?.value, [restPost]);
    expect(restResult.valueOrNull?.origin, DataOrigin.localFresh);
    expect(graphqlResult.valueOrNull?.value, [country]);
    expect(graphqlResult.valueOrNull?.origin, DataOrigin.localFresh);
  });
}

final class _FakeRestRemoteDataSource implements RestPostsRemoteDataSource {
  _FakeRestRemoteDataSource(this.values, {this.error});

  List<RestPost> values;
  Exception? error;

  @override
  Future<List<RestPost>> fetchPosts({int limit = 5}) async {
    final failure = error;
    if (failure != null) {
      throw failure;
    }
    return values.take(limit).toList();
  }
}

final class _FakeGraphqlRemoteDataSource
    implements GraphqlCountriesRemoteDataSource {
  _FakeGraphqlRemoteDataSource(this.values, {this.error});

  List<GraphqlCountry> values;
  Exception? error;

  @override
  Future<List<GraphqlCountry>> fetchCountries({int limit = 6}) async {
    final failure = error;
    if (failure != null) {
      throw failure;
    }
    return values.take(limit).toList();
  }
}
