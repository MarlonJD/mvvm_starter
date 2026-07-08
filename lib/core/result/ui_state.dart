import "package:mvvm_starter/core/errors/app_error.dart";

/// UI state wrapper for ViewModel-rendered screens.
sealed class UiState<T> {
  /// Creates UI state.
  const UiState();

  /// Initial state.
  const factory UiState.idle() = UiIdle<T>;

  /// Loading state.
  const factory UiState.loading() = UiLoading<T>;

  /// Successful state.
  const factory UiState.success(T value) = UiSuccess<T>;

  /// Failed state.
  const factory UiState.failure(AppError error) = UiFailure<T>;

  /// Whether the state is loading.
  bool get isLoading => this is UiLoading<T>;

  /// Successful value, or null otherwise.
  T? get valueOrNull {
    final state = this;
    return switch (state) {
      UiIdle<T>() => null,
      UiLoading<T>() => null,
      UiSuccess<T>(:final value) => value,
      UiFailure<T>() => null,
    };
  }

  /// Failure error, or null otherwise.
  AppError? get errorOrNull {
    final state = this;
    return switch (state) {
      UiIdle<T>() => null,
      UiLoading<T>() => null,
      UiSuccess<T>() => null,
      UiFailure<T>(:final error) => error,
    };
  }
}

/// Initial UI state.
final class UiIdle<T> extends UiState<T> {
  /// Creates initial UI state.
  const UiIdle();
}

/// Loading UI state.
final class UiLoading<T> extends UiState<T> {
  /// Creates loading UI state.
  const UiLoading();
}

/// Success UI state.
final class UiSuccess<T> extends UiState<T> {
  /// Creates success UI state.
  const UiSuccess(this.value);

  /// Successful value.
  final T value;
}

/// Failure UI state.
final class UiFailure<T> extends UiState<T> {
  /// Creates failure UI state.
  const UiFailure(this.error);

  /// Failure error.
  final AppError error;
}
