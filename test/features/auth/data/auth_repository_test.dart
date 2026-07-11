import "package:drift/native.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mvvm_starter/core/database/app_database.dart";
import "package:mvvm_starter/core/errors/app_error.dart";
import "package:mvvm_starter/features/auth/data/auth_local_datasource.dart";
import "package:mvvm_starter/features/auth/data/auth_repository.dart";

void main() {
  late AppDatabase database;
  late AuthRepository repository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = AuthRepository(
      localDataSource: AuthLocalDataSource(database),
      uidFactory: () => "uid-${DateTime.now().microsecondsSinceEpoch}",
      now: () => DateTime.utc(2026),
    );
  });

  tearDown(() async {
    repository.dispose();
    await database.close();
  });

  test("create user starts a single active session", () async {
    final result = await repository.createUser("alice");

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull?.name, "alice");
    expect(repository.activeUser.value?.name, "alice");
    expect(await repository.sessionUserIds(), [result.valueOrNull?.id]);
  });

  test("duplicate user name returns duplicate error", () async {
    await repository.createUser("alice");

    final result = await repository.createUser("alice");

    expect(result.errorOrNull?.type, AppErrorType.duplicate);
  });

  test("login unknown user returns not found", () async {
    final result = await repository.login("missing");

    expect(result.errorOrNull?.type, AppErrorType.notFound);
    expect(repository.activeUser.value, isNull);
  });

  test("login replaces the active session", () async {
    await repository.createUser("alice");
    await repository.logout();
    await repository.createUser("bob");
    await repository.login("alice");

    expect(repository.activeUser.value?.name, "alice");
    expect(await repository.sessionUserIds(), [
      repository.activeUser.value?.id,
    ]);
  });

  test("deleting active user clears the active session", () async {
    final result = await repository.createUser("alice");

    await repository.deleteUser(result.valueOrNull!);

    expect(repository.activeUser.value, isNull);
    expect(await repository.sessionUserIds(), isEmpty);
  });
}
