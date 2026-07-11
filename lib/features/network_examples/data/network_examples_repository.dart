import "package:mvvm_starter/core/errors/app_error.dart";
import "package:mvvm_starter/core/network/network_exception.dart";
import "package:mvvm_starter/core/result/result.dart";
import "package:mvvm_starter/features/network_examples/data/network_examples_local_data_source.dart";
import "package:mvvm_starter/features/network_examples/data/network_examples_remote_data_sources.dart";
import "package:mvvm_starter/features/network_examples/domain/network_example_models.dart";

/// Repository that demonstrates remote-only and persisted network patterns.
class NetworkExamplesRepository {
  /// Creates a repository for network examples.
  NetworkExamplesRepository({
    required RestPostsRemoteDataSource this._restRemoteDataSource,
    required GraphqlCountriesRemoteDataSource this._graphqlRemoteDataSource,
    required NetworkExamplesLocalDataSource this._localDataSource,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  /// Creates a test subclass base.
  NetworkExamplesRepository.fake()
    : _restRemoteDataSource = null,
      _graphqlRemoteDataSource = null,
      _localDataSource = null,
      _now = DateTime.now;

  final RestPostsRemoteDataSource? _restRemoteDataSource;
  final GraphqlCountriesRemoteDataSource? _graphqlRemoteDataSource;
  final NetworkExamplesLocalDataSource? _localDataSource;
  final DateTime Function() _now;

  RestPostsRemoteDataSource get _restRemote =>
      _restRemoteDataSource ?? (throw StateError("Missing REST data source"));

  GraphqlCountriesRemoteDataSource get _graphqlRemote =>
      _graphqlRemoteDataSource ??
      (throw StateError("Missing GraphQL data source"));

  NetworkExamplesLocalDataSource get _local =>
      _localDataSource ?? (throw StateError("Missing local data source"));

  /// Fetches REST posts without writing local persistence.
  Future<Result<List<RestPost>>> fetchRestRemoteOnly({int limit = 5}) async {
    try {
      return Result.success(await _restRemote.fetchPosts(limit: limit));
    } on Object catch (error) {
      return Result.failure(_mapRemoteError(error));
    }
  }

  /// Fetches REST posts, stores them locally, then returns the persisted rows.
  Future<Result<List<RestPost>>> fetchRestPersisted({int limit = 5}) async {
    final List<RestPost> posts;
    try {
      posts = await _restRemote.fetchPosts(limit: limit);
    } on Object catch (error) {
      return Result.failure(_mapRemoteError(error));
    }
    try {
      await _local.replaceRestPosts(posts, fetchedAt: _now());
      return Result.success(await _local.restPosts());
    } on Object catch (error) {
      return Result.failure(AppError.database("errors.database", cause: error));
    }
  }

  /// Fetches GraphQL countries without writing local persistence.
  Future<Result<List<GraphqlCountry>>> fetchGraphqlRemoteOnly({
    int limit = 6,
  }) async {
    try {
      return Result.success(await _graphqlRemote.fetchCountries(limit: limit));
    } on Object catch (error) {
      return Result.failure(_mapRemoteError(error));
    }
  }

  /// Fetches GraphQL countries, stores them, then returns the persisted rows.
  Future<Result<List<GraphqlCountry>>> fetchGraphqlPersisted({
    int limit = 6,
  }) async {
    final List<GraphqlCountry> countries;
    try {
      countries = await _graphqlRemote.fetchCountries(limit: limit);
    } on Object catch (error) {
      return Result.failure(_mapRemoteError(error));
    }
    try {
      await _local.replaceGraphqlCountries(countries, fetchedAt: _now());
      return Result.success(await _local.graphqlCountries());
    } on Object catch (error) {
      return Result.failure(AppError.database("errors.database", cause: error));
    }
  }

  AppError _mapRemoteError(Object error) {
    if (error is NetworkException &&
        error.kind == NetworkExceptionKind.unauthorized) {
      return AppError.unauthorized("errors.unauthorized", cause: error);
    }
    return AppError.network("errors.network", cause: error);
  }
}
