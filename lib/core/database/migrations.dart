import "package:drift/drift.dart";

/// Creates the migration strategy for [database].
MigrationStrategy appMigrationStrategy(GeneratedDatabase database) {
  return MigrationStrategy(
    onCreate: (migrator) async {
      await database.customStatement("DROP TABLE IF EXISTS sessions");
      await database.customStatement("DROP TABLE IF EXISTS users");
      await migrator.createAll();
    },
    onUpgrade: (migrator, from, to) async {
      if (from < 1) {
        await database.customStatement("DROP TABLE IF EXISTS sessions");
        await database.customStatement("DROP TABLE IF EXISTS users");
        await migrator.createAll();
      }
      if (from < 2) {
        await database.customStatement(
          """
          CREATE TABLE IF NOT EXISTS rest_posts (
            id INTEGER NOT NULL PRIMARY KEY,
            user_id INTEGER NOT NULL,
            title TEXT NOT NULL,
            body TEXT NOT NULL,
            fetched_at INTEGER NOT NULL
          )
          """,
        );
        await database.customStatement(
          """
          CREATE TABLE IF NOT EXISTS graphql_countries (
            code TEXT NOT NULL PRIMARY KEY,
            name TEXT NOT NULL,
            emoji TEXT NOT NULL,
            capital TEXT NULL,
            fetched_at INTEGER NOT NULL
          )
          """,
        );
      }
    },
    beforeOpen: (details) async {
      await database.customStatement("PRAGMA foreign_keys = ON");
    },
  );
}
