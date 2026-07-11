import "package:drift/native.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mvvm_starter/core/database/app_database.dart";

void main() {
  test("legacy version-0 users and one deterministic session survive", () async {
    final executor = NativeDatabase.memory(
      setup: (database) {
        database
          ..execute(
            "CREATE TABLE users (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, uid INTEGER NOT NULL, admin INTEGER)",
          )
          ..execute(
            "CREATE TABLE sessions (id INTEGER PRIMARY KEY AUTOINCREMENT, user_id INTEGER NOT NULL, FOREIGN KEY (user_id) REFERENCES users(id))",
          )
          ..execute(
            "INSERT INTO users (id, name, uid, admin) VALUES (1, 'alice', 7, 0)",
          )
          ..execute(
            "INSERT INTO users (id, name, uid, admin) VALUES (2, 'bob', 8, 1)",
          )
          ..execute(
            "INSERT INTO users (id, name, uid, admin) VALUES (3, 'bob', 8, 0)",
          )
          ..execute("INSERT INTO sessions (id, user_id) VALUES (4, 1)")
          ..execute("INSERT INTO sessions (id, user_id) VALUES (9, 3)")
          ..execute("INSERT INTO sessions (id, user_id) VALUES (10, 999)");
      },
    );
    final database = AppDatabase(executor);
    addTearDown(database.close);

    final users = await database
        .customSelect("SELECT id, uid, name FROM users ORDER BY id")
        .get();

    expect(users, hasLength(3));
    expect(
      users.map((row) => row.read<String>("name")),
      ["alice", "bob", "bob [legacy-3]"],
    );
    final migratedUids = users
        .map((row) => row.read<String>("uid"))
        .toList();
    expect(migratedUids, everyElement(isNotEmpty));
    expect(migratedUids.toSet(), hasLength(migratedUids.length));

    final sessions = await database
        .customSelect("SELECT id, user_id FROM app_sessions")
        .get();
    expect(sessions, hasLength(1));
    expect(sessions.single.read<int>("id"), 1);
    expect(sessions.single.read<int>("user_id"), 3);

    expect(await database.customSelect("PRAGMA foreign_key_check").get(), isEmpty);
  });

  test(
    "version-2 migration keeps users and the latest deterministic session",
    () async {
      final executor = NativeDatabase.memory(
        setup: (database) {
          database
            ..execute("PRAGMA foreign_keys = OFF")
            ..execute(
              "CREATE TABLE users (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, uid TEXT NOT NULL UNIQUE, name TEXT NOT NULL UNIQUE, is_admin INTEGER NOT NULL DEFAULT 0 CHECK (is_admin IN (0, 1)), created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL)",
            )
            ..execute(
              "CREATE TABLE app_sessions (id INTEGER NOT NULL CHECK (id = 1), user_id INTEGER NOT NULL UNIQUE REFERENCES users (id) ON DELETE CASCADE, created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL)",
            )
            ..execute(
              "CREATE TABLE rest_posts (id INTEGER NOT NULL, user_id INTEGER NOT NULL, title TEXT NOT NULL, body TEXT NOT NULL, fetched_at INTEGER NOT NULL, PRIMARY KEY (id))",
            )
            ..execute(
              "CREATE TABLE graphql_countries (code TEXT NOT NULL, name TEXT NOT NULL, emoji TEXT NOT NULL, capital TEXT NULL, fetched_at INTEGER NOT NULL, PRIMARY KEY (code))",
            )
            ..execute(
              "INSERT INTO users (id, uid, name, is_admin, created_at, updated_at) VALUES (1, 'uid-alice', 'alice', 0, 100, 100)",
            )
            ..execute(
              "INSERT INTO users (id, uid, name, is_admin, created_at, updated_at) VALUES (2, 'uid-bob', 'bob', 1, 100, 100)",
            )
            ..execute(
              "INSERT INTO users (id, uid, name, is_admin, created_at, updated_at) VALUES (3, 'uid-charlie', 'charlie', 0, 100, 100)",
            )
            ..execute(
              "INSERT INTO app_sessions (id, user_id, created_at, updated_at) VALUES (1, 1, 100, 100)",
            )
            ..execute(
              "INSERT INTO app_sessions (id, user_id, created_at, updated_at) VALUES (1, 2, 100, 200)",
            )
            ..execute(
              "INSERT INTO app_sessions (id, user_id, created_at, updated_at) VALUES (1, 3, 100, 200)",
            )
            ..execute("PRAGMA user_version = 2");
        },
      );
      final database = AppDatabase(executor);
      addTearDown(database.close);

      final users = await database
          .customSelect("SELECT id, uid, name FROM users ORDER BY id")
          .get();
      expect(users, hasLength(3));

      final sessions = await database
          .customSelect("SELECT id, user_id FROM app_sessions")
          .get();
      expect(sessions, hasLength(1));
      expect(sessions.single.read<int>("id"), 1);
      expect(sessions.single.read<int>("user_id"), 3);

      final sessionColumns = await database
          .customSelect("PRAGMA table_info(app_sessions)")
          .get();
      final idColumn = sessionColumns.singleWhere(
        (row) => row.read<String>("name") == "id",
      );
      expect(idColumn.read<int>("pk"), 1);

      final userColumns = await database
          .customSelect("PRAGMA table_info(users)")
          .get();
      expect(
        userColumns.map((row) => row.read<String>("name")),
        isNot(contains("is_admin")),
      );
      expect(
        await database.customSelect("PRAGMA foreign_key_check").get(),
        isEmpty,
      );
    },
  );
}
