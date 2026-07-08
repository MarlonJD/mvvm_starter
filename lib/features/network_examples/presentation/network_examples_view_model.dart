import "package:flutter/foundation.dart";
import "package:mvvm_starter/core/result/result.dart";
import "package:mvvm_starter/core/result/ui_state.dart";
import "package:mvvm_starter/features/network_examples/data/network_examples_repository.dart";
import "package:mvvm_starter/features/network_examples/domain/network_example_models.dart";

/// Aggregated state rendered by the network examples view.
@immutable
final class NetworkExamplesState {
  /// Creates network examples state.
  const NetworkExamplesState({
    required this.restRemoteOnly,
    required this.restPersisted,
    required this.graphqlRemoteOnly,
    required this.graphqlPersisted,
  });

  /// REST data fetched without local persistence.
  final List<RestPost> restRemoteOnly;

  /// REST data fetched and then read from Drift.
  final List<RestPost> restPersisted;

  /// GraphQL data fetched without local persistence.
  final List<GraphqlCountry> graphqlRemoteOnly;

  /// GraphQL data fetched and then read from Drift.
  final List<GraphqlCountry> graphqlPersisted;
}

/// ViewModel for the network examples screen.
final class NetworkExamplesViewModel {
  /// Creates a network examples ViewModel.
  NetworkExamplesViewModel({required NetworkExamplesRepository repository})
      : _repository = repository;

  final NetworkExamplesRepository _repository;
  final ValueNotifier<UiState<NetworkExamplesState>> _state =
      ValueNotifier<UiState<NetworkExamplesState>>(
    const UiState.idle(),
  );

  /// Current view state.
  ValueListenable<UiState<NetworkExamplesState>> get state => _state;

  /// Loads all live examples.
  Future<void> load() async {
    _state.value = const UiState.loading();

    final restRemoteOnly = await _repository.fetchRestRemoteOnly();
    if (_fail(restRemoteOnly)) {
      return;
    }
    final restPersisted = await _repository.fetchRestPersisted();
    if (_fail(restPersisted)) {
      return;
    }
    final graphqlRemoteOnly = await _repository.fetchGraphqlRemoteOnly();
    if (_fail(graphqlRemoteOnly)) {
      return;
    }
    final graphqlPersisted = await _repository.fetchGraphqlPersisted();
    if (_fail(graphqlPersisted)) {
      return;
    }

    _state.value = UiState.success(
      NetworkExamplesState(
        restRemoteOnly: restRemoteOnly.valueOrNull!,
        restPersisted: restPersisted.valueOrNull!,
        graphqlRemoteOnly: graphqlRemoteOnly.valueOrNull!,
        graphqlPersisted: graphqlPersisted.valueOrNull!,
      ),
    );
  }

  bool _fail<T>(Result<T> result) {
    final error = result.errorOrNull;
    if (error == null) {
      return false;
    }
    _state.value = UiState.failure(error);
    return true;
  }

  /// Releases ViewModel resources.
  void dispose() {
    _state.dispose();
  }
}
