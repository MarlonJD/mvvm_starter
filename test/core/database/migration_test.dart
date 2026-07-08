import "package:drift/native.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mvvm_starter/core/database/app_database.dart";

void main() {
  test("legacy starter tables are reset into the Drift schema", () async {
    final executor = NativeDatabase.memory(
      setup: (database) {
        database
          ..execute(
            "CREATE TABLE users (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, uid INTEGER NOT NULL, admin INTEGER)",
          )
          ..execute(
            "CREATE TABLE sessions (id INTEGER PRIMARY KEY AUTOINCREMENT, user_id INTEGER NOT NULL, FOREIGN KEY (user_id) REFERENCES users(id))",
          );
      },
    );
    final database = AppDatabase(executor);
    addTearDown(database.close);

    final tables = await database
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' AND name IN ('users', 'app_sessions')",
        )
        .get();

    expect(tables.map((row) => row.read<String>("name")), {
      "users",
      "app_sessions",
    });
  });
}
