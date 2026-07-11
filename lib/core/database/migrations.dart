import "package:drift/drift.dart";

/// Creates the migration strategy for [database].
MigrationStrategy appMigrationStrategy(GeneratedDatabase database) {
  return MigrationStrategy(
    onCreate: (migrator) async {
      if (await _tableExists(database, "users")) {
        await _migrateLegacyVersionZero(database, migrator);
      } else {
        await migrator.createAll();
      }
    },
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await database.customStatement("""
          CREATE TABLE IF NOT EXISTS rest_posts (
            id INTEGER NOT NULL PRIMARY KEY,
            user_id INTEGER NOT NULL,
            title TEXT NOT NULL,
            body TEXT NOT NULL,
            fetched_at INTEGER NOT NULL
          )
          """);
        await database.customStatement("""
          CREATE TABLE IF NOT EXISTS graphql_countries (
            code TEXT NOT NULL PRIMARY KEY,
            name TEXT NOT NULL,
            emoji TEXT NOT NULL,
            capital TEXT NULL,
            fetched_at INTEGER NOT NULL
          )
          """);
      }
      if (from < 3) {
        await _migrateVersionTwoToThree(database);
      }
    },
    beforeOpen: (details) async {
      await database.customStatement("PRAGMA foreign_keys = ON");
    },
  );
}

Future<bool> _tableExists(
  GeneratedDatabase database,
  String tableName,
) async {
  final rows = await database.customSelect(
    "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = ? LIMIT 1",
    variables: [Variable.withString(tableName)],
  ).get();
  return rows.isNotEmpty;
}

String _uniqueLegacyName(
  String rawName,
  int id,
  Set<String> usedNames,
) {
  final trimmed = rawName.trim();
  final baseName = trimmed.isEmpty ? "legacy-user-$id" : trimmed;
  var candidate = baseName;
  if (usedNames.contains(candidate)) {
    candidate = "$baseName [legacy-$id]";
  }
  var suffix = 2;
  while (usedNames.contains(candidate)) {
    candidate = "$baseName [legacy-$id]-$suffix";
    suffix += 1;
  }
  usedNames.add(candidate);
  return candidate;
}

Future<void> _migrateLegacyVersionZero(
  GeneratedDatabase database,
  Migrator migrator,
) async {
  final hasLegacySessions = await _tableExists(database, "sessions");
  await database.customStatement("ALTER TABLE users RENAME TO legacy_users");
  if (hasLegacySessions) {
    await database.customStatement(
      "ALTER TABLE sessions RENAME TO legacy_sessions",
    );
  }

  await migrator.createAll();

  final migrationTimestamp = DateTime.now().toUtc();
  final timestampSeconds =
      migrationTimestamp.millisecondsSinceEpoch ~/ Duration.millisecondsPerSecond;
  final legacyUsers = await database
      .customSelect("SELECT id, name, uid FROM legacy_users ORDER BY id")
      .get();
  final usedNames = <String>{};

  for (final legacyUser in legacyUsers) {
    final id = legacyUser.read<int>("id");
    final rawName = legacyUser.data["name"]?.toString() ?? "";
    final oldUid = legacyUser.data["uid"]?.toString() ?? "";
    final name = _uniqueLegacyName(rawName, id, usedNames);
    final uid = "legacy:$id:$oldUid";

    await database.customStatement(
      "INSERT INTO users (id, uid, name, created_at, updated_at) VALUES (?, ?, ?, ?, ?)",
      [
        id,
        uid,
        name,
        timestampSeconds,
        timestampSeconds,
      ],
    );
  }

  if (hasLegacySessions) {
    final validSessions = await database.customSelect("""
      SELECT legacy_sessions.id, legacy_sessions.user_id
      FROM legacy_sessions
      INNER JOIN users ON users.id = legacy_sessions.user_id
      ORDER BY legacy_sessions.id DESC
      LIMIT 1
      """).get();
    if (validSessions.isNotEmpty) {
      await database.customStatement(
        "INSERT INTO app_sessions (id, user_id, created_at, updated_at) VALUES (1, ?, ?, ?)",
        [
          validSessions.single.read<int>("user_id"),
          timestampSeconds,
          timestampSeconds,
        ],
      );
    }
  }

  final migratedUserCount = await _rowCount(database, "users");
  if (migratedUserCount != legacyUsers.length) {
    throw StateError(
      "Legacy user migration count mismatch: ${legacyUsers.length} source, $migratedUserCount migrated",
    );
  }
  await _assertNoForeignKeyViolationsForTable(database, "app_sessions");

  if (hasLegacySessions) {
    await database.customStatement("DROP TABLE legacy_sessions");
  }
  await database.customStatement("DROP TABLE legacy_users");
  await _assertNoForeignKeyViolations(database);
}

Future<void> _migrateVersionTwoToThree(
  GeneratedDatabase database,
) async {
  final sourceUserCount = await _rowCount(database, "users");

  await database.customStatement(
    "ALTER TABLE app_sessions RENAME TO app_sessions_v2",
  );
  await database.customStatement("ALTER TABLE users RENAME TO users_v2");
  await database.customStatement("""
    CREATE TABLE users (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      uid TEXT NOT NULL UNIQUE,
      name TEXT NOT NULL UNIQUE,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    )
    """);
  await database.customStatement("""
    CREATE TABLE app_sessions (
      id INTEGER NOT NULL CHECK (id = 1),
      user_id INTEGER NOT NULL UNIQUE REFERENCES users (id) ON DELETE CASCADE,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      PRIMARY KEY (id)
    )
    """);

  await database.customStatement("""
    INSERT INTO users (id, uid, name, created_at, updated_at)
    SELECT id, uid, name, created_at, updated_at
    FROM users_v2
    ORDER BY id
    """);

  final selectedSession = await database.customSelect("""
    SELECT user_id, created_at, updated_at
    FROM app_sessions_v2
    WHERE user_id IN (SELECT id FROM users)
    ORDER BY updated_at DESC, rowid DESC
    LIMIT 1
    """).get();
  if (selectedSession.isNotEmpty) {
    final session = selectedSession.single;
    await database.customStatement(
      "INSERT INTO app_sessions (id, user_id, created_at, updated_at) VALUES (1, ?, ?, ?)",
      [
        session.read<int>("user_id"),
        session.read<int>("created_at"),
        session.read<int>("updated_at"),
      ],
    );
  }

  final migratedUserCount = await _rowCount(database, "users");
  if (migratedUserCount != sourceUserCount) {
    throw StateError(
      "Version-2 user migration count mismatch: $sourceUserCount source, $migratedUserCount migrated",
    );
  }
  await _assertNoForeignKeyViolations(database);

  await database.customStatement("DROP TABLE app_sessions_v2");
  await database.customStatement("DROP TABLE users_v2");
}

Future<int> _rowCount(GeneratedDatabase database, String tableName) async {
  const allowedTables = {
    "users",
    "legacy_users",
  };
  if (!allowedTables.contains(tableName)) {
    throw ArgumentError.value(tableName, "tableName", "Unexpected table");
  }
  final row = await database.customSelect("SELECT COUNT(*) AS count FROM $tableName").getSingle();
  return row.read<int>("count");
}

Future<void> _assertNoForeignKeyViolations(
  GeneratedDatabase database,
) async {
  final violations = await database.customSelect("PRAGMA foreign_key_check").get();
  if (violations.isNotEmpty) {
    throw StateError("Database migration left foreign-key violations");
  }
}

Future<void> _assertNoForeignKeyViolationsForTable(
  GeneratedDatabase database,
  String tableName,
) async {
  if (tableName != "app_sessions") {
    throw ArgumentError.value(tableName, "tableName", "Unexpected table");
  }
  final violations = await database
      .customSelect("PRAGMA foreign_key_check($tableName)")
      .get();
  if (violations.isNotEmpty) {
    throw StateError("Database migration left foreign-key violations");
  }
}
