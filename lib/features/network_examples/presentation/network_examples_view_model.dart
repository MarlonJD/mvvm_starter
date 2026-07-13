import "package:flutter/foundation.dart";
import "package:mvvm_starter/core/result/result.dart";
import "package:mvvm_starter/core/result/ui_state.dart";
import "package:mvvm_starter/features/network_examples/data/network_examples_repository.dart";
import "package:mvvm_starter/features/network_examples/domain/network_example_models.dart";
import "package:mvvm_starter/features/network_examples/domain/persisted_result.dart";

/// Four independently renderable states on the network examples screen.
@immutable
final class NetworkExamplesState {
  /// Creates a network examples state.
  const NetworkExamplesState({
    required this.restRemoteOnly,
    required this.restPersisted,
    required this.graphqlRemoteOnly,
    required this.graphqlPersisted,
  });

  /// Creates the initial idle state.
  factory NetworkExamplesState.idle() => const NetworkExamplesState(
    restRemoteOnly: UiState<List<RestPost>>.idle(),
    restPersisted: UiState<PersistedResult<List<RestPost>>>.idle(),
    graphqlRemoteOnly: UiState<List<GraphqlCountry>>.idle(),
    graphqlPersisted: UiState<PersistedResult<List<GraphqlCountry>>>.idle(),
  );

  /// Creates a state with all sections loading.
  factory NetworkExamplesState.loading() => const NetworkExamplesState(
    restRemoteOnly: UiState<List<RestPost>>.loading(),
    restPersisted: UiState<PersistedResult<List<RestPost>>>.loading(),
    graphqlRemoteOnly: UiState<List<GraphqlCountry>>.loading(),
    graphqlPersisted: UiState<PersistedResult<List<GraphqlCountry>>>.loading(),
  );

  /// REST data fetched without local persistence.
  final UiState<List<RestPost>> restRemoteOnly;

  /// REST data fetched remotely or restored from a scoped snapshot.
  final UiState<PersistedResult<List<RestPost>>> restPersisted;

  /// GraphQL data fetched without local persistence.
  final UiState<List<GraphqlCountry>> graphqlRemoteOnly;

  /// GraphQL data fetched remotely or restored from a scoped snapshot.
  final UiState<PersistedResult<List<GraphqlCountry>>> graphqlPersisted;

  /// Whether any section is loading.
  bool get isLoading =>
      restRemoteOnly.isLoading ||
      restPersisted.isLoading ||
      graphqlRemoteOnly.isLoading ||
      graphqlPersisted.isLoading;

  /// Copies this state while replacing selected sections.
  NetworkExamplesState copyWith({
    UiState<List<RestPost>>? restRemoteOnly,
    UiState<PersistedResult<List<RestPost>>>? restPersisted,
    UiState<List<GraphqlCountry>>? graphqlRemoteOnly,
    UiState<PersistedResult<List<GraphqlCountry>>>? graphqlPersisted,
  }) {
    return NetworkExamplesState(
      restRemoteOnly: restRemoteOnly ?? this.restRemoteOnly,
      restPersisted: restPersisted ?? this.restPersisted,
      graphqlRemoteOnly: graphqlRemoteOnly ?? this.graphqlRemoteOnly,
      graphqlPersisted: graphqlPersisted ?? this.graphqlPersisted,
    );
  }
}

/// ViewModel for the network examples screen.
final class NetworkExamplesViewModel {
  /// Creates a network examples ViewModel.
  NetworkExamplesViewModel({required this._repository});

  final NetworkExamplesRepository _repository;
  final ValueNotifier<NetworkExamplesState> _state = ValueNotifier(
    NetworkExamplesState.idle(),
  );
  var _operationGeneration = 0;
  var _disposed = false;

  /// Current independently renderable section state.
  ValueListenable<NetworkExamplesState> get state => _state;

  /// Loads all sections concurrently and publishes each result independently.
  Future<void> load() async {
    if (_disposed) {
      return;
    }
    final generation = ++_operationGeneration;
    _state.value = NetworkExamplesState.loading();
    await Future.wait([
      _loadRestRemoteOnly(generation),
      _loadRestPersisted(generation),
      _loadGraphqlRemoteOnly(generation),
      _loadGraphqlPersisted(generation),
    ]);
  }

  Future<void> _loadRestRemoteOnly(int generation) async {
    final result = await _repository.fetchRestRemoteOnly();
    if (_canPublish(generation)) {
      _state.value = _state.value.copyWith(restRemoteOnly: _uiState(result));
    }
  }

  Future<void> _loadRestPersisted(int generation) async {
    final result = await _repository.fetchRestPersisted();
    if (_canPublish(generation)) {
      _state.value = _state.value.copyWith(restPersisted: _uiState(result));
    }
  }

  Future<void> _loadGraphqlRemoteOnly(int generation) async {
    final result = await _repository.fetchGraphqlRemoteOnly();
    if (_canPublish(generation)) {
      _state.value = _state.value.copyWith(graphqlRemoteOnly: _uiState(result));
    }
  }

  Future<void> _loadGraphqlPersisted(int generation) async {
    final result = await _repository.fetchGraphqlPersisted();
    if (_canPublish(generation)) {
      _state.value = _state.value.copyWith(graphqlPersisted: _uiState(result));
    }
  }

  UiState<T> _uiState<T>(Result<T> result) {
    final error = result.errorOrNull;
    return error == null
        ? UiState.success(result.valueOrNull as T)
        : UiState.failure(error);
  }

  /// Releases ViewModel resources.
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _operationGeneration += 1;
    _state.dispose();
  }

  bool _canPublish(int generation) {
    return !_disposed && generation == _operationGeneration;
  }
}
