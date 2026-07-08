import "package:get_it/get_it.dart";
import "package:http/http.dart" as http;
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
import "package:mvvm_starter/features/network_examples/data/network_examples_local_data_source.dart";
import "package:mvvm_starter/features/network_examples/data/network_examples_remote_data_sources.dart";
import "package:mvvm_starter/features/network_examples/data/network_examples_repository.dart";
import "package:mvvm_starter/features/network_examples/presentation/network_examples_view.dart";
import "package:mvvm_starter/features/network_examples/presentation/network_examples_view_model.dart";

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
    ..registerLazySingleton<http.Client>(
      http.Client.new,
      dispose: (client) => client.close(),
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
    ..registerLazySingleton<NetworkExamplesLocalDataSource>(
      () => NetworkExamplesLocalDataSource(locator<AppDatabase>()),
    )
    ..registerLazySingleton<RestPostsRemoteDataSource>(
      () => HttpRestPostsRemoteDataSource(client: locator<http.Client>()),
    )
    ..registerLazySingleton<GraphqlCountriesRemoteDataSource>(
      () => HttpGraphqlCountriesRemoteDataSource(
        client: locator<http.Client>(),
      ),
    )
    ..registerLazySingleton<NetworkExamplesRepository>(
      () => NetworkExamplesRepository(
        restRemoteDataSource: locator<RestPostsRemoteDataSource>(),
        graphqlRemoteDataSource: locator<GraphqlCountriesRemoteDataSource>(),
        localDataSource: locator<NetworkExamplesLocalDataSource>(),
      ),
    )
    ..registerFactory<NetworkExamplesViewModel>(
      () => NetworkExamplesViewModel(
        repository: locator<NetworkExamplesRepository>(),
      ),
    )
    ..registerLazySingleton<RouterService>(
      () => RouterService(
        authRepository: locator<AuthRepository>(),
        homeBuilder: (context, state) => HomeView(
          viewModel: locator<HomeViewModel>(),
        ),
        networkExamplesBuilder: (context, state) => NetworkExamplesView(
          viewModel: locator<NetworkExamplesViewModel>(),
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
