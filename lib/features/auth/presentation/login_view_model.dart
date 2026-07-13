import "package:flutter/foundation.dart";
import "package:mvvm_starter/core/errors/app_error.dart";
import "package:mvvm_starter/core/restoration/app_restorable_text_editing_controller.dart";
import "package:mvvm_starter/core/restoration/restorable_view_model.dart";
import "package:mvvm_starter/core/restoration/restoration_registrar.dart";
import "package:mvvm_starter/core/result/result.dart";
import "package:mvvm_starter/core/result/ui_state.dart";
import "package:mvvm_starter/features/auth/data/auth_repository.dart";
import "package:mvvm_starter/features/auth/domain/user.dart";

/// ViewModel for the login screen.
final class LoginViewModel implements RestorableViewModel {
  /// Creates a login ViewModel.
  LoginViewModel({required this._authRepository});

  final AuthRepository _authRepository;

  /// Restorable name field controller.
  final AppRestorableTextEditingController nameController =
      AppRestorableTextEditingController();

  final ValueNotifier<UiState<User>> _state = ValueNotifier<UiState<User>>(
    const UiState.idle(),
  );
  var _operationGeneration = 0;
  var _disposed = false;

  /// Current login UI state.
  ValueListenable<UiState<User>> get state => _state;

  /// Attempts login with the current name field.
  Future<Result<User>> login() async {
    final generation = ++_operationGeneration;
    final name = nameController.value.text.trim();
    if (name.isEmpty) {
      const error = AppError.validation("auth.nameRequired");
      if (_canPublish(generation)) {
        _state.value = const UiState.failure(error);
      }
      return const Result.failure(error);
    }

    if (_canPublish(generation)) {
      _state.value = const UiState.loading();
    }
    final result = await _authRepository.login(name);
    if (!_canPublish(generation)) {
      return result;
    }
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
    if (_disposed) {
      return;
    }
    _disposed = true;
    _operationGeneration += 1;
    nameController.dispose();
    _state.dispose();
  }

  bool _canPublish(int generation) {
    return !_disposed && generation == _operationGeneration;
  }
}
