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
    },
    beforeOpen: (details) async {
      await database.customStatement("PRAGMA foreign_keys = ON");
    },
  );
}
