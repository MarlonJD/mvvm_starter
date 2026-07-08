import "package:get_it/get_it.dart";
import "package:mvvm_starter/app/router.dart";
import "package:mvvm_starter/core/database/app_database.dart";
import "package:mvvm_starter/features/auth/data/auth_local_datasource.dart";
import "package:mvvm_starter/features/auth/data/auth_repository.dart";
import "package:mvvm_starter/features/auth/presentation/login_view.dart";
import "package:mvvm_starter/features/auth/presentation/login_view_model.dart";
import "package:mvvm_starter/features/auth/presentation/signup_view.dart";
import "package:mvvm_starter/features/auth/presentation/signup_view_model.dart";
import "package:mvvm_starter/features/debug_database/presentation/database_debug_view.dart";
import "package:mvvm_starter/features/debug_database/presentation/database_debug_view_model.dart";
import "package:mvvm_starter/features/home/presentation/home_view.dart";
import "package:mvvm_starter/features/home/presentation/home_view_model.dart";

/// App-level service locator.
final GetIt locator = GetIt.instance;

/// Registers application dependencies.
void setupDependencies({AppDatabase? database}) {
  if (locator.isRegistered<AppDatabase>()) {
    return;
  }

  locator
    ..registerLazySingleton<AppDatabase>(
      () => database ?? AppDatabase.defaults(),
      dispose: (database) => database.close(),
    )
    ..registerLazySingleton<AuthLocalDataSource>(
      () => AuthLocalDataSource(locator<AppDatabase>()),
    )
    ..registerLazySingleton<AuthRepository>(
      () => AuthRepository(localDataSource: locator<AuthLocalDataSource>()),
      dispose: (repository) => repository.dispose(),
    )
    ..registerFactory<LoginViewModel>(
      () => LoginViewModel(authRepository: locator<AuthRepository>()),
    )
    ..registerFactory<SignupViewModel>(
      () => SignupViewModel(authRepository: locator<AuthRepository>()),
    )
    ..registerFactory<HomeViewModel>(
      () => HomeViewModel(authRepository: locator<AuthRepository>()),
    )
    ..registerFactory<DatabaseDebugViewModel>(
      () => DatabaseDebugViewModel(authRepository: locator<AuthRepository>()),
    )
    ..registerLazySingleton<RouterService>(
      () => RouterService(
        authRepository: locator<AuthRepository>(),
        homeBuilder: (context, state) => HomeView(
          viewModel: locator<HomeViewModel>(),
        ),
        loginBuilder: (context, state) => LoginView(
          viewModel: locator<LoginViewModel>(),
        ),
        signupBuilder: (context, state) => SignupView(
          viewModel: locator<SignupViewModel>(),
        ),
        debugDatabaseBuilder: (context, state) => DatabaseDebugView(
          viewModel: locator<DatabaseDebugViewModel>(),
        ),
      ),
      dispose: (routerService) => routerService.dispose(),
    );
}

/// Restores startup session state after dependencies are registered.
Future<void> restoreStartupSession() async {
  await locator<AuthRepository>().restoreSession();
}
