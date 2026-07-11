import "dart:async";

import "package:flutter/foundation.dart";
import "package:mvvm_starter/features/auth/data/auth_repository.dart";
import "package:mvvm_starter/features/auth/domain/user.dart";

/// ViewModel for the debug database page.
final class DatabaseDebugViewModel {
  /// Creates a debug database ViewModel.
  DatabaseDebugViewModel({
    required this._authRepository,
    this._watchForChanges = true,
  });

  final AuthRepository _authRepository;
  final bool _watchForChanges;

  final ValueNotifier<List<User>> _users = ValueNotifier<List<User>>([]);
  final ValueNotifier<List<int>> _sessions = ValueNotifier<List<int>>([]);

  StreamSubscription<List<User>>? _usersSubscription;
  StreamSubscription<List<int>>? _sessionsSubscription;
  bool _disposed = false;
  bool _notifiersDisposed = false;

  /// Users for display.
  ValueListenable<List<User>> get users => _users;

  /// Active session user ids for display.
  ValueListenable<List<int>> get sessions => _sessions;

  /// Starts database watches.
  Future<void> init() async {
    final users = await _authRepository.users();
    final sessions = await _authRepository.sessionUserIds();
    if (_disposed) {
      return;
    }

    _users.value = users;
    _sessions.value = sessions;
    if (!_watchForChanges) {
      return;
    }
    _usersSubscription = _authRepository.watchUsers().listen((users) {
      if (_disposed) {
        return;
      }
      _users.value = users;
    });
    _sessionsSubscription = _authRepository.watchSessionUserIds().listen((
      sessions,
    ) {
      if (_disposed) {
        return;
      }
      _sessions.value = sessions;
    });
  }

  /// Deletes one user.
  Future<void> deleteUser(User user) async {
    await _authRepository.deleteUser(user);
  }

  /// Releases resources.
  void dispose() {
    unawaited(close());
  }

  /// Releases resources and waits for stream cancellation.
  Future<void> close() {
    _disposed = true;
    unawaited(_usersSubscription?.cancel());
    unawaited(_sessionsSubscription?.cancel());
    _usersSubscription = null;
    _sessionsSubscription = null;
    if (!_notifiersDisposed) {
      _notifiersDisposed = true;
      _users.dispose();
      _sessions.dispose();
    }
    return Future<void>.value();
  }
}
