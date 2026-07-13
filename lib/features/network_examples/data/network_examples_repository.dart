import "package:mvvm_starter/core/errors/app_error.dart";
import "package:mvvm_starter/core/network/network_exception.dart";
import "package:mvvm_starter/core/result/result.dart";
import "package:mvvm_starter/features/network_examples/data/network_examples_local_data_source.dart";
import "package:mvvm_starter/features/network_examples/data/network_examples_remote_data_sources.dart";
import "package:mvvm_starter/features/network_examples/domain/network_example_models.dart";
import "package:mvvm_starter/features/network_examples/domain/persisted_result.dart";
import "package:mvvm_starter/features/network_examples/domain/persistence_scope.dart";

/// Repository that demonstrates remote-only and scoped offline-read patterns.
class NetworkExamplesRepository {
  /// Creates a repository for network examples.
  NetworkExamplesRepository({
    required RestPostsRemoteDataSource this._restRemoteDataSource,
    required GraphqlCountriesRemoteDataSource this._graphqlRemoteDataSource,
    required NetworkExamplesLocalDataSource this._localDataSource,
    PersistenceScope Function()? persistenceScope,
    DateTime Function()? now,
  }) : _persistenceScope = persistenceScope ?? PersistenceScope.public,
       _now = now ?? DateTime.now;

  /// Creates a test subclass base.
  NetworkExamplesRepository.fake()
    : _restRemoteDataSource = null,
      _graphqlRemoteDataSource = null,
      _localDataSource = null,
      _persistenceScope = PersistenceScope.public,
      _now = DateTime.now;

  static const _freshnessThreshold = Duration(minutes: 15);

  final RestPostsRemoteDataSource? _restRemoteDataSource;
  final GraphqlCountriesRemoteDataSource? _graphqlRemoteDataSource;
  final NetworkExamplesLocalDataSource? _localDataSource;
  final PersistenceScope Function() _persistenceScope;
  final DateTime Function() _now;

  RestPostsRemoteDataSource get _restRemote =>
      _restRemoteDataSource ?? (throw StateError("Missing REST data source"));

  GraphqlCountriesRemoteDataSource get _graphqlRemote =>
      _graphqlRemoteDataSource ??
      (throw StateError("Missing GraphQL data source"));

  NetworkExamplesLocalDataSource get _local =>
      _localDataSource ?? (throw StateError("Missing local data source"));

  /// Fetches REST posts without reading or writing local persistence.
  Future<Result<List<RestPost>>> fetchRestRemoteOnly({int limit = 5}) async {
    try {
      return Result.success(await _restRemote.fetchPosts(limit: limit));
    } on Object catch (error) {
      return Result.failure(_mapRemoteError(error));
    }
  }

  /// Fetches REST posts remotely with a scoped local fallback on network error.
  Future<Result<PersistedResult<List<RestPost>>>> fetchRestPersisted({
    int limit = 5,
  }) async {
    final scope = _persistenceScope();
    final fetchedAt = _now();
    try {
      final posts = await _restRemote.fetchPosts(limit: limit);
      try {
        await _local.replaceRestPosts(
          posts,
          scope: scope,
          fetchedAt: fetchedAt,
        );
      } on Object catch (error) {
        return Result.failure(_databaseError(error));
      }
      return Result.success(
        PersistedResult(
          value: posts,
          origin: DataOrigin.remote,
          fetchedAt: fetchedAt,
        ),
      );
    } on NetworkException catch (error) {
      return _readRestFallback(scope: scope, remoteError: error);
    } on Object catch (error) {
      return Result.failure(_mapRemoteError(error));
    }
  }

  /// Fetches GraphQL countries without reading or writing local persistence.
  Future<Result<List<GraphqlCountry>>> fetchGraphqlRemoteOnly({
    int limit = 6,
  }) async {
    try {
      return Result.success(await _graphqlRemote.fetchCountries(limit: limit));
    } on Object catch (error) {
      return Result.failure(_mapRemoteError(error));
    }
  }

  /// Fetches GraphQL countries with a scoped local fallback on network error.
  Future<Result<PersistedResult<List<GraphqlCountry>>>> fetchGraphqlPersisted({
    int limit = 6,
  }) async {
    final scope = _persistenceScope();
    final fetchedAt = _now();
    try {
      final countries = await _graphqlRemote.fetchCountries(limit: limit);
      try {
        await _local.replaceGraphqlCountries(
          countries,
          scope: scope,
          fetchedAt: fetchedAt,
        );
      } on Object catch (error) {
        return Result.failure(_databaseError(error));
      }
      return Result.success(
        PersistedResult(
          value: countries,
          origin: DataOrigin.remote,
          fetchedAt: fetchedAt,
        ),
      );
    } on NetworkException catch (error) {
      return _readGraphqlFallback(scope: scope, remoteError: error);
    } on Object catch (error) {
      return Result.failure(_mapRemoteError(error));
    }
  }

  Future<Result<PersistedResult<List<RestPost>>>> _readRestFallback({
    required PersistenceScope scope,
    required NetworkException remoteError,
  }) async {
    final LocalSnapshot<List<RestPost>> snapshot;
    try {
      snapshot = await _local.restPosts(scope: scope);
    } on Object catch (error) {
      return Result.failure(_databaseError(error));
    }
    final fetchedAt = snapshot.fetchedAt;
    if (snapshot.value.isEmpty || fetchedAt == null) {
      return Result.failure(_mapRemoteError(remoteError));
    }
    return Result.success(
      PersistedResult(
        value: snapshot.value,
        origin: _localOrigin(fetchedAt),
        fetchedAt: fetchedAt,
      ),
    );
  }

  Future<Result<PersistedResult<List<GraphqlCountry>>>> _readGraphqlFallback({
    required PersistenceScope scope,
    required NetworkException remoteError,
  }) async {
    final LocalSnapshot<List<GraphqlCountry>> snapshot;
    try {
      snapshot = await _local.graphqlCountries(scope: scope);
    } on Object catch (error) {
      return Result.failure(_databaseError(error));
    }
    final fetchedAt = snapshot.fetchedAt;
    if (snapshot.value.isEmpty || fetchedAt == null) {
      return Result.failure(_mapRemoteError(remoteError));
    }
    return Result.success(
      PersistedResult(
        value: snapshot.value,
        origin: _localOrigin(fetchedAt),
        fetchedAt: fetchedAt,
      ),
    );
  }

  DataOrigin _localOrigin(DateTime fetchedAt) {
    final age = _now().difference(fetchedAt);
    return age <= _freshnessThreshold
        ? DataOrigin.localFresh
        : DataOrigin.localStale;
  }

  AppError _databaseError(Object error) =>
      AppError.database("errors.database", cause: error);

  AppError _mapRemoteError(Object error) {
    if (error is NetworkException &&
        error.kind == NetworkExceptionKind.unauthorized) {
      return AppError.unauthorized("errors.unauthorized", cause: error);
    }
    return AppError.network("errors.network", cause: error);
  }
}
