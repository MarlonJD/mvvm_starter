import "package:drift/native.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mvvm_starter/core/database/app_database.dart";
import "package:mvvm_starter/core/errors/app_error.dart";
import "package:mvvm_starter/features/auth/data/auth_local_datasource.dart";
import "package:mvvm_starter/features/auth/data/auth_repository.dart";
import "package:mvvm_starter/features/auth/presentation/signup_view_model.dart";

void main() {
  late AppDatabase database;
  late AuthRepository repository;
  late SignupViewModel viewModel;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = AuthRepository(
      localDataSource: AuthLocalDataSource(database),
      uidFactory: () => "uid",
      now: () => DateTime.utc(2026),
    );
    viewModel = SignupViewModel(authRepository: repository);
  });

  tearDown(() async {
    viewModel.dispose();
    repository.dispose();
    await database.close();
  });

  test("empty name returns validation failure", () async {
    viewModel.nameController.value.text = "";

    final result = await viewModel.createUser();

    expect(result.errorOrNull?.type, AppErrorType.validation);
  });

  test("admin name marks the example user as admin", () async {
    viewModel.nameController.value.text = "admin";

    final result = await viewModel.createUser();

    expect(result.valueOrNull?.isAdmin, isTrue);
  });
}
