import "package:get_it/get_it.dart";
import "package:mvvm_starter/auth/user_service.dart";
import "package:mvvm_starter/core/database_abstract.dart";
import "package:mvvm_starter/core/date_service.dart";
import "package:mvvm_starter/core/hive_abstract.dart";

final locator = GetIt.instance;

void setupLocator() {
  locator
    ..registerSingleton(DateService())
    ..registerLazySingleton(DatabaseAbstraction.new)
    ..registerLazySingleton(HiveDatabaseAbstraction.new)
    ..registerLazySingleton(
      () => UserService(
        databaseAbstraction: locator.get<DatabaseAbstraction>(),
      ),
    );
}
