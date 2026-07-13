import "package:flutter/foundation.dart";
import "package:mvvm_starter/core/errors/app_error.dart";
import "package:mvvm_starter/core/result/result.dart";
import "package:mvvm_starter/features/auth/data/auth_local_datasource.dart";
import "package:mvvm_starter/features/auth/domain/user.dart";
import "package:uuid/uuid.dart";

/// Repository for local auth and session behavior.
class AuthRepository {
  /// Creates an auth repository.
  AuthRepository({
    required this._localDataSource,
    String Function()? uidFactory,
    DateTime Function()? now,
  }) : _uidFactory = uidFactory ?? const Uuid().v4,
       _now = now ?? DateTime.now;

  /// Creates a test subclass base without a persistence adapter.
  AuthRepository.fake()
    : _localDataSource = null,
      _uidFactory = const Uuid().v4,
      _now = DateTime.now;

  final AuthLocalDataSource? _localDataSource;
  final String Function() _uidFactory;
  final DateTime Function() _now;

  final ValueNotifier<User?> _activeUser = ValueNotifier<User?>(null);

  AuthLocalDataSource get _local =>
      _localDataSource ?? (throw StateError("Missing auth local data source"));

  /// Active user listenable for Views and router refresh.
  ValueListenable<User?> get activeUser => _activeUser;

  /// Whether there is an active user.
  bool get isLoggedIn => _activeUser.value != null;

  /// Restores the active session from local storage.
  Future<User?> restoreSession() async {
    final user = await _local.activeUser();
    _activeUser.value = user;
    return user;
  }

  /// Creates a user and starts an active session.
  Future<Result<User>> createUser(String name) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return const Result.failure(AppError.validation("auth.nameRequired"));
    }

    try {
      final user = await _local.createUserAndSession(
        uid: _uidFactory(),
        name: trimmedName,
        now: _now(),
      );
      _activeUser.value = user;
      return Result.success(user);
    } on Exception catch (error) {
      return Result.failure(_mapPersistenceError(error));
    }
  }

  /// Logs in an existing user.
  Future<Result<User>> login(String name) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return const Result.failure(AppError.validation("auth.nameRequired"));
    }

    try {
      final user = await _local.findUserByName(trimmedName);
      if (user == null) {
        return const Result.failure(AppError.notFound("auth.userNotFound"));
      }
      await _local.replaceSession(userId: user.id, now: _now());
      _activeUser.value = user;
      return Result.success(user);
    } on Exception catch (error) {
      return Result.failure(_mapPersistenceError(error));
    }
  }

  /// Logs out the active user.
  Future<Result<void>> logout() async {
    try {
      await _local.clearSession();
      _activeUser.value = null;
      return const Result.success(null);
    } on Exception catch (error) {
      return Result.failure(_mapPersistenceError(error));
    }
  }

  /// Deletes one user.
  Future<Result<void>> deleteUser(User user) async {
    try {
      await _local.deleteUser(user);
      if (_activeUser.value?.id == user.id) {
        _activeUser.value = null;
      }
      return const Result.success(null);
    } on Exception catch (error) {
      return Result.failure(_mapPersistenceError(error));
    }
  }

  /// Returns all users.
  Future<List<User>> users() => _local.users();

  /// Watches all users.
  Stream<List<User>> watchUsers() => _local.watchUsers();

  /// Returns active session user ids.
  Future<List<int>> sessionUserIds() => _local.sessionUserIds();

  /// Watches active session user ids.
  Stream<List<int>> watchSessionUserIds() {
    return _local.watchSessionUserIds();
  }

  /// Releases repository resources.
  void dispose() {
    _activeUser.dispose();
  }

  AppError _mapPersistenceError(Exception error) {
    final message = error.toString().toLowerCase();
    if (message.contains("unique")) {
      return AppError.duplicate("auth.userAlreadyExists", cause: error);
    }
    return AppError.database("errors.database", cause: error);
  }
}
