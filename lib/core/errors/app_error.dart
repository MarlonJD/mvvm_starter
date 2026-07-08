import "package:flutter/foundation.dart";

/// Coarse error categories used by repositories and ViewModels.
enum AppErrorType {
  /// User input failed validation.
  validation,

  /// Requested data does not exist.
  notFound,

  /// A unique or duplicate constraint failed.
  duplicate,

  /// Persistence failed.
  database,

  /// An unexpected error occurred.
  unknown,
}

/// Lightweight application error with a localization-friendly message key.
@immutable
final class AppError {
  /// Creates an application error.
  const AppError({
    required this.type,
    required this.messageKey,
    this.cause,
  });

  /// Creates a validation error.
  const AppError.validation(String messageKey, {Object? cause})
      : this(
          type: AppErrorType.validation,
          messageKey: messageKey,
          cause: cause,
        );

  /// Creates a not-found error.
  const AppError.notFound(String messageKey, {Object? cause})
      : this(
          type: AppErrorType.notFound,
          messageKey: messageKey,
          cause: cause,
        );

  /// Creates a duplicate error.
  const AppError.duplicate(String messageKey, {Object? cause})
      : this(
          type: AppErrorType.duplicate,
          messageKey: messageKey,
          cause: cause,
        );

  /// Creates a database error.
  const AppError.database(String messageKey, {Object? cause})
      : this(
          type: AppErrorType.database,
          messageKey: messageKey,
          cause: cause,
        );

  /// Creates an unknown error.
  const AppError.unknown(String messageKey, {Object? cause})
      : this(
          type: AppErrorType.unknown,
          messageKey: messageKey,
          cause: cause,
        );

  /// Error category.
  final AppErrorType type;

  /// Translation key or stable display key.
  final String messageKey;

  /// Optional original cause for diagnostics.
  final Object? cause;

  @override
  bool operator ==(Object other) {
    return other is AppError &&
        other.type == type &&
        other.messageKey == messageKey;
  }

  @override
  int get hashCode => Object.hash(type, messageKey);

  @override
  String toString() => "AppError($type, $messageKey)";
}
