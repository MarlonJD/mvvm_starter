import "package:drift/drift.dart";
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

    await database
        .into(database.users)
        .insert(
          UsersCompanion.insert(
            uid: "uid-1",
            name: "alice",
            createdAt: now,
            updatedAt: now,
          ),
        );

    await expectLater(
      database
          .into(database.users)
          .insert(
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

  test(
    "app_sessions rejects a second singleton row for another user",
    () async {
      final now = DateTime.utc(2026);
      final aliceId = await database
          .into(database.users)
          .insert(
            UsersCompanion.insert(
              uid: "uid-alice",
              name: "alice",
              createdAt: now,
              updatedAt: now,
            ),
          );
      final bobId = await database
          .into(database.users)
          .insert(
            UsersCompanion.insert(
              uid: "uid-bob",
              name: "bob",
              createdAt: now,
              updatedAt: now,
            ),
          );

      await database
          .into(database.appSessions)
          .insert(
            AppSessionsCompanion.insert(
              id: const Value(1),
              userId: aliceId,
              createdAt: now,
              updatedAt: now,
            ),
          );

      await expectLater(
        database
            .into(database.appSessions)
            .insert(
              AppSessionsCompanion.insert(
                id: const Value(1),
                userId: bobId,
                createdAt: now,
                updatedAt: now,
              ),
            ),
        throwsException,
      );
    },
  );

  test("foreign keys cascade active session when user is deleted", () async {
    final now = DateTime.utc(2026);
    final userId = await database
        .into(database.users)
        .insert(
          UsersCompanion.insert(
            uid: "uid-1",
            name: "alice",
            createdAt: now,
            updatedAt: now,
          ),
        );

    await database
        .into(database.appSessions)
        .insert(
          AppSessionsCompanion.insert(
            id: const Value(1),
            userId: userId,
            createdAt: now,
            updatedAt: now,
          ),
        );
    await (database.delete(
      database.users,
    )..where((row) => row.id.equals(userId))).go();

    expect(await database.select(database.appSessions).get(), isEmpty);
  });

  test("rest_posts uses a scoped composite primary key", () async {
    final now = DateTime.utc(2026);

    await database
        .into(database.restPosts)
        .insert(
          RestPostsCompanion.insert(
            scopeKey: "public",
            id: 1,
            userId: 1,
            title: "Title",
            body: "Body",
            fetchedAt: now,
          ),
        );

    await expectLater(
      database
          .into(database.restPosts)
          .insert(
            RestPostsCompanion.insert(
              scopeKey: "oidc:https://issuer.example:alice",
              id: 1,
              userId: 2,
              title: "Duplicate",
              body: "Body",
              fetchedAt: now,
            ),
          ),
      completes,
    );

    await expectLater(
      database
          .into(database.restPosts)
          .insert(
            RestPostsCompanion.insert(
              scopeKey: "public",
              id: 1,
              userId: 3,
              title: "Duplicate public",
              body: "Body",
              fetchedAt: now,
            ),
          ),
      throwsException,
    );
  });

  test("graphql_countries uses a scoped composite primary key", () async {
    final now = DateTime.utc(2026);

    await database
        .into(database.graphqlCountries)
        .insert(
          GraphqlCountriesCompanion.insert(
            scopeKey: "public",
            code: "TR",
            name: "Turkey",
            emoji: "TR",
            capital: const Value("Ankara"),
            fetchedAt: now,
          ),
        );

    await expectLater(
      database
          .into(database.graphqlCountries)
          .insert(
            GraphqlCountriesCompanion.insert(
              scopeKey: "oidc:https://issuer.example:alice",
              code: "TR",
              name: "Duplicate",
              emoji: "TR",
              capital: const Value("Ankara"),
              fetchedAt: now,
            ),
          ),
      completes,
    );

    await expectLater(
      database
          .into(database.graphqlCountries)
          .insert(
            GraphqlCountriesCompanion.insert(
              scopeKey: "public",
              code: "TR",
              name: "Duplicate public",
              emoji: "TR",
              capital: const Value("Ankara"),
              fetchedAt: now,
            ),
          ),
      throwsException,
    );
  });
}
