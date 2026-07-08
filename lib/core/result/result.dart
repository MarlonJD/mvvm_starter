import "package:mvvm_starter/core/errors/app_error.dart";

/// Explicit success or failure result for domain and ViewModel operations.
sealed class Result<T> {
  /// Creates a result.
  const Result();

  /// Creates a successful result.
  const factory Result.success(T value) = ResultSuccess<T>;

  /// Creates a failed result.
  const factory Result.failure(AppError error) = ResultFailure<T>;

  /// Whether this result is successful.
  bool get isSuccess => this is ResultSuccess<T>;

  /// Whether this result is a failure.
  bool get isFailure => this is ResultFailure<T>;

  /// Successful value, or null for failures.
  T? get valueOrNull {
    final result = this;
    return switch (result) {
      ResultSuccess<T>(:final value) => value,
      ResultFailure<T>() => null,
    };
  }

  /// Failure error, or null for successes.
  AppError? get errorOrNull {
    final result = this;
    return switch (result) {
      ResultSuccess<T>() => null,
      ResultFailure<T>(:final error) => error,
    };
  }
}

/// Successful operation result.
final class ResultSuccess<T> extends Result<T> {
  /// Creates a successful operation result.
  const ResultSuccess(this.value);

  /// Successful value.
  final T value;
}

/// Failed operation result.
final class ResultFailure<T> extends Result<T> {
  /// Creates a failed operation result.
  const ResultFailure(this.error);

  /// Failure error.
  final AppError error;
}
