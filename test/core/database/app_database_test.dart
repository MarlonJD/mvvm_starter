import "package:drift/native.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mvvm_starter/core/database/app_database.dart";

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test("users enforce unique uid and name", () async {
    final now = DateTime.utc(2026);

    await database.into(database.users).insert(
          UsersCompanion.insert(
            uid: "uid-1",
            name: "alice",
            createdAt: now,
            updatedAt: now,
          ),
        );

    await expectLater(
      database.into(database.users).insert(
            UsersCompanion.insert(
              uid: "uid-2",
              name: "alice",
              createdAt: now,
              updatedAt: now,
            ),
          ),
      throwsException,
    );
  });

  test("app_sessions allows only singleton active session row", () async {
    final now = DateTime.utc(2026);
    final userId = await database.into(database.users).insert(
          UsersCompanion.insert(
            uid: "uid-1",
            name: "alice",
            createdAt: now,
            updatedAt: now,
          ),
        );

    await database.into(database.appSessions).insert(
          AppSessionsCompanion.insert(
            id: 1,
            userId: userId,
            createdAt: now,
            updatedAt: now,
          ),
        );

    await expectLater(
      database.into(database.appSessions).insert(
            AppSessionsCompanion.insert(
              id: 2,
              userId: userId,
              createdAt: now,
              updatedAt: now,
            ),
          ),
      throwsException,
    );
  });

  test("foreign keys cascade active session when user is deleted", () async {
    final now = DateTime.utc(2026);
    final userId = await database.into(database.users).insert(
          UsersCompanion.insert(
            uid: "uid-1",
            name: "alice",
            createdAt: now,
            updatedAt: now,
          ),
        );

    await database.into(database.appSessions).insert(
          AppSessionsCompanion.insert(
            id: 1,
            userId: userId,
            createdAt: now,
            updatedAt: now,
          ),
        );
    await (database.delete(database.users)
          ..where((row) => row.id.equals(userId)))
        .go();

    expect(await database.select(database.appSessions).get(), isEmpty);
  });
}
