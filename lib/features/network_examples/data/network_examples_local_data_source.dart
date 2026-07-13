import "package:drift/drift.dart";
import "package:mvvm_starter/core/database/app_database.dart";
import "package:mvvm_starter/features/network_examples/domain/network_example_models.dart";
import "package:mvvm_starter/features/network_examples/domain/persisted_result.dart";
import "package:mvvm_starter/features/network_examples/domain/persistence_scope.dart";

/// Drift-backed local source for persisted network example snapshots.
final class NetworkExamplesLocalDataSource {
  /// Creates a local network examples source.
  const NetworkExamplesLocalDataSource(this._database);

  final AppDatabase _database;

  /// Replaces the persisted REST post snapshot.
  Future<void> replaceRestPosts(
    List<RestPost> posts, {
    required PersistenceScope scope,
    required DateTime fetchedAt,
  }) async {
    await _database.transaction(() async {
      await (_database.delete(
        _database.restPosts,
      )..where((row) => row.scopeKey.equals(scope.key))).go();
      if (posts.isEmpty) {
        return;
      }
      await _database.batch((batch) {
        batch.insertAll(
          _database.restPosts,
          posts.map(
            (post) => RestPostsCompanion.insert(
              scopeKey: scope.key,
              id: post.id,
              userId: post.userId,
              title: post.title,
              body: post.body,
              fetchedAt: fetchedAt,
            ),
          ),
        );
      });
    });
  }

  /// Reads the persisted REST post snapshot.
  Future<LocalSnapshot<List<RestPost>>> restPosts({
    required PersistenceScope scope,
  }) async {
    final rows =
        await (_database.select(_database.restPosts)
              ..where((row) => row.scopeKey.equals(scope.key))
              ..orderBy([(row) => OrderingTerm.asc(row.id)]))
            .get();
    return LocalSnapshot(
      value: rows
          .map(
            (row) => RestPost(
              id: row.id,
              userId: row.userId,
              title: row.title,
              body: row.body,
            ),
          )
          .toList(),
      fetchedAt: _latestFetchedAt(rows.map((row) => row.fetchedAt)),
    );
  }

  /// Replaces the persisted GraphQL countries snapshot.
  Future<void> replaceGraphqlCountries(
    List<GraphqlCountry> countries, {
    required PersistenceScope scope,
    required DateTime fetchedAt,
  }) async {
    await _database.transaction(() async {
      await (_database.delete(
        _database.graphqlCountries,
      )..where((row) => row.scopeKey.equals(scope.key))).go();
      if (countries.isEmpty) {
        return;
      }
      await _database.batch((batch) {
        batch.insertAll(
          _database.graphqlCountries,
          countries.map(
            (country) => GraphqlCountriesCompanion.insert(
              scopeKey: scope.key,
              code: country.code,
              name: country.name,
              emoji: country.emoji,
              capital: Value(country.capital),
              fetchedAt: fetchedAt,
            ),
          ),
        );
      });
    });
  }

  /// Reads the persisted GraphQL countries snapshot.
  Future<LocalSnapshot<List<GraphqlCountry>>> graphqlCountries({
    required PersistenceScope scope,
  }) async {
    final rows =
        await (_database.select(_database.graphqlCountries)
              ..where((row) => row.scopeKey.equals(scope.key))
              ..orderBy([(row) => OrderingTerm.asc(row.code)]))
            .get();
    return LocalSnapshot(
      value: rows
          .map(
            (row) => GraphqlCountry(
              code: row.code,
              name: row.name,
              emoji: row.emoji,
              capital: row.capital,
            ),
          )
          .toList(),
      fetchedAt: _latestFetchedAt(rows.map((row) => row.fetchedAt)),
    );
  }

  DateTime? _latestFetchedAt(Iterable<DateTime> values) {
    DateTime? latest;
    for (final value in values) {
      if (latest == null || value.isAfter(latest)) {
        latest = value;
      }
    }
    return latest?.toUtc();
  }
}
