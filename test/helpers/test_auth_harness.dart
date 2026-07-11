import "package:drift/native.dart";
import "package:mvvm_starter/core/database/app_database.dart";
import "package:mvvm_starter/features/auth/data/auth_local_datasource.dart";
import "package:mvvm_starter/features/auth/data/auth_repository.dart";

final class TestAuthHarness {
  TestAuthHarness({required this.database, required this.repository});

  final AppDatabase database;
  final AuthRepository repository;

  Future<void> dispose() async {
    repository.dispose();
    await database.close();
  }
}

TestAuthHarness createTestAuthHarness() {
  var uidCounter = 0;
  final database = AppDatabase(NativeDatabase.memory());
  final repository = AuthRepository(
    localDataSource: AuthLocalDataSource(database),
    uidFactory: () {
      uidCounter += 1;
      return "uid-$uidCounter";
    },
    now: () => DateTime.utc(2026),
  );
  return TestAuthHarness(database: database, repository: repository);
}
