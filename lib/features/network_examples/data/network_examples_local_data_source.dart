import "package:drift/drift.dart";
import "package:mvvm_starter/core/database/app_database.dart";
import "package:mvvm_starter/features/network_examples/domain/network_example_models.dart";

/// Drift-backed local source for persisted network example snapshots.
final class NetworkExamplesLocalDataSource {
  /// Creates a local network examples source.
  const NetworkExamplesLocalDataSource(this._database);

  final AppDatabase _database;

  /// Replaces the persisted REST post snapshot.
  Future<void> replaceRestPosts(
    List<RestPost> posts, {
    required DateTime fetchedAt,
  }) async {
    await _database.transaction(() async {
      await _database.delete(_database.restPosts).go();
      if (posts.isEmpty) {
        return;
      }
      await _database.batch((batch) {
        batch.insertAll(
          _database.restPosts,
          posts.map(
            (post) => RestPostsCompanion.insert(
              id: Value(post.id),
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
  Future<List<RestPost>> restPosts() async {
    final rows = await (_database.select(_database.restPosts)
          ..orderBy([(row) => OrderingTerm.asc(row.id)]))
        .get();
    return rows
        .map(
          (row) => RestPost(
            id: row.id,
            userId: row.userId,
            title: row.title,
            body: row.body,
          ),
        )
        .toList();
  }

  /// Replaces the persisted GraphQL countries snapshot.
  Future<void> replaceGraphqlCountries(
    List<GraphqlCountry> countries, {
    required DateTime fetchedAt,
  }) async {
    await _database.transaction(() async {
      await _database.delete(_database.graphqlCountries).go();
      if (countries.isEmpty) {
        return;
      }
      await _database.batch((batch) {
        batch.insertAll(
          _database.graphqlCountries,
          countries.map(
            (country) => GraphqlCountriesCompanion.insert(
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
  Future<List<GraphqlCountry>> graphqlCountries() async {
    final rows = await (_database.select(_database.graphqlCountries)
          ..orderBy([(row) => OrderingTerm.asc(row.code)]))
        .get();
    return rows
        .map(
          (row) => GraphqlCountry(
            code: row.code,
            name: row.name,
            emoji: row.emoji,
            capital: row.capital,
          ),
        )
        .toList();
  }
}
