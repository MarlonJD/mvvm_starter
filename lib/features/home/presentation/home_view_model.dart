import "package:flutter/foundation.dart";
import "package:mvvm_starter/core/result/result.dart";
import "package:mvvm_starter/features/auth/data/auth_repository.dart";
import "package:mvvm_starter/features/auth/domain/user.dart";

/// ViewModel for the home screen.
final class HomeViewModel {
  /// Creates a home ViewModel.
  HomeViewModel({required AuthRepository authRepository})
      : _authRepository = authRepository;

  final AuthRepository _authRepository;

  /// Active user listenable.
  ValueListenable<User?> get activeUser => _authRepository.activeUser;

  /// Logs out the active user.
  Future<Result<void>> logout() => _authRepository.logout();

  /// Deletes all users.
  Future<Result<void>> deleteAllUsers() => _authRepository.deleteAllUsers();
}
