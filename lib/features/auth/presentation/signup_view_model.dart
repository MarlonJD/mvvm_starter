import "package:flutter/foundation.dart";
import "package:mvvm_starter/core/errors/app_error.dart";
import "package:mvvm_starter/core/restoration/app_restorable_text_editing_controller.dart";
import "package:mvvm_starter/core/restoration/restorable_view_model.dart";
import "package:mvvm_starter/core/restoration/restoration_registrar.dart";
import "package:mvvm_starter/core/result/result.dart";
import "package:mvvm_starter/core/result/ui_state.dart";
import "package:mvvm_starter/features/auth/data/auth_repository.dart";
import "package:mvvm_starter/features/auth/domain/user.dart";

/// ViewModel for the signup screen.
final class SignupViewModel implements RestorableViewModel {
  /// Creates a signup ViewModel.
  SignupViewModel({required AuthRepository authRepository})
      : _authRepository = authRepository;

  final AuthRepository _authRepository;

  /// Restorable name field controller.
  final AppRestorableTextEditingController nameController =
      AppRestorableTextEditingController();

  final ValueNotifier<UiState<User>> _state =
      ValueNotifier<UiState<User>>(const UiState.idle());

  /// Current signup UI state.
  ValueListenable<UiState<User>> get state => _state;

  /// Creates a user from the current name field.
  Future<Result<User>> createUser() async {
    final name = nameController.value.text.trim();
    if (name.isEmpty) {
      const error = AppError.validation("auth.nameRequired");
      _state.value = const UiState.failure(error);
      return const Result.failure(error);
    }

    _state.value = const UiState.loading();
    final result = await _authRepository.createUser(
      name,
      isAdmin: name == "admin",
    );
    final user = result.valueOrNull;
    final error = result.errorOrNull;
    if (user != null) {
      _state.value = UiState.success(user);
    } else if (error != null) {
      _state.value = UiState.failure(error);
    }
    return result;
  }

  @override
  void registerRestorableProperties(RestorationRegistrar registrar) {
    registrar.register(nameController, "name");
  }

  @override
  void dispose() {
    nameController.dispose();
    _state.dispose();
  }
}
