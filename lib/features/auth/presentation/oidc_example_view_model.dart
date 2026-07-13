import "package:flutter/foundation.dart";
import "package:mvvm_starter/core/errors/app_error.dart";
import "package:mvvm_starter/core/result/result.dart";
import "package:mvvm_starter/features/auth/data/oidc_session_manager.dart";
import "package:mvvm_starter/features/auth/domain/oidc_configuration.dart";
import "package:mvvm_starter/features/auth/domain/oidc_sign_in_outcome.dart";
import "package:mvvm_starter/features/auth/domain/oidc_token_set.dart";

/// Visible OIDC example states without token-bearing fields.
enum OidcExampleStatus {
  /// Provider settings have not been supplied.
  unconfigured,

  /// Interactive AppAuth is unavailable on this platform.
  unsupported,

  /// The example is configured and locally signed out.
  signedOut,

  /// Interactive sign-in is running.
  signingIn,

  /// A secure local OIDC session exists.
  signedIn,

  /// Token refresh is running.
  refreshing,

  /// Local-first logout is running.
  signingOut,

  /// An operation completed with a displayable warning or error.
  warning,
}

/// Render-safe OIDC state.
@immutable
final class OidcExampleState {
  /// Creates render-safe OIDC state.
  const OidcExampleState({required this.status, this.error});

  /// Current visible status.
  final OidcExampleStatus status;

  /// Optional localization-friendly error.
  final AppError? error;
}

/// ViewModel for the native OIDC example screen.
final class OidcExampleViewModel {
  /// Creates an OIDC example ViewModel.
  OidcExampleViewModel({
    required this.configuration,
    required this.sessionManager,
    bool? platformSupported,
  }) : platformSupported =
           platformSupported ?? isOidcInteractivePlatformSupported,
       _state = ValueNotifier(
         _initialState(
           configuration,
           platformSupported ?? isOidcInteractivePlatformSupported,
           sessionManager.tokenSet.value,
         ),
       ) {
    sessionManager.tokenSet.addListener(_handleSessionChanged);
  }

  /// Provider configuration.
  final OidcConfiguration configuration;

  /// Secure OIDC session service.
  final OidcSessionManager sessionManager;

  /// Whether the current platform supports interactive login.
  final bool platformSupported;

  final ValueNotifier<OidcExampleState> _state;
  var _operationGeneration = 0;
  var _disposed = false;

  /// Current render-safe state.
  ValueListenable<OidcExampleState> get state => _state;

  /// Starts interactive sign-in.
  Future<Result<OidcSignInOutcome>> signIn() async {
    final generation = ++_operationGeneration;
    final unavailable = _unavailableError(generation);
    if (unavailable != null) {
      return Result.failure(unavailable);
    }
    _publish(
      generation,
      const OidcExampleState(status: OidcExampleStatus.signingIn),
    );
    final result = await sessionManager.signIn();
    if (!_canPublish(generation)) {
      return result;
    }
    final outcome = result.valueOrNull;
    if (outcome is OidcSignInCompleted) {
      _publish(
        generation,
        const OidcExampleState(status: OidcExampleStatus.signedIn),
      );
    } else if (outcome is OidcSignInCancelled) {
      _publish(
        generation,
        const OidcExampleState(status: OidcExampleStatus.signedOut),
      );
    } else {
      _publish(
        generation,
        OidcExampleState(
          status: OidcExampleStatus.warning,
          error: result.errorOrNull,
        ),
      );
    }
    return result;
  }

  /// Explicitly refreshes the current session.
  Future<Result<OidcTokenSet>> refresh() async {
    final generation = ++_operationGeneration;
    final unavailable = _unavailableError(generation);
    if (unavailable != null) {
      return Result.failure(unavailable);
    }
    _publish(
      generation,
      const OidcExampleState(status: OidcExampleStatus.refreshing),
    );
    final result = await sessionManager.refresh(force: true);
    if (_canPublish(generation)) {
      _state.value = result.isSuccess
          ? const OidcExampleState(status: OidcExampleStatus.signedIn)
          : OidcExampleState(
              status: OidcExampleStatus.warning,
              error: result.errorOrNull,
            );
    }
    return result;
  }

  /// Logs out locally before attempting provider end-session.
  Future<Result<void>> logout() async {
    final generation = ++_operationGeneration;
    final unavailable = _unavailableError(generation);
    if (unavailable != null) {
      return Result.failure(unavailable);
    }
    _publish(
      generation,
      const OidcExampleState(status: OidcExampleStatus.signingOut),
    );
    final result = await sessionManager.logout();
    if (_canPublish(generation)) {
      _state.value = result.isSuccess
          ? const OidcExampleState(status: OidcExampleStatus.signedOut)
          : OidcExampleState(
              status: OidcExampleStatus.warning,
              error: result.errorOrNull,
            );
    }
    return result;
  }

  /// Releases listeners and render state.
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _operationGeneration += 1;
    sessionManager.tokenSet.removeListener(_handleSessionChanged);
    _state.dispose();
  }

  AppError? _unavailableError(int generation) {
    if (!configuration.isConfigured) {
      _publish(
        generation,
        const OidcExampleState(status: OidcExampleStatus.unconfigured),
      );
      return const AppError.notFound("auth.oidc.notConfigured");
    }
    if (!platformSupported) {
      _publish(
        generation,
        const OidcExampleState(status: OidcExampleStatus.unsupported),
      );
      return const AppError.notFound("auth.oidc.unsupportedPlatform");
    }
    return null;
  }

  void _handleSessionChanged() {
    if (_disposed || _isBusy(_state.value.status)) {
      return;
    }
    final status = sessionManager.tokenSet.value == null
        ? OidcExampleStatus.signedOut
        : OidcExampleStatus.signedIn;
    _state.value = OidcExampleState(status: status);
  }

  bool _canPublish(int generation) {
    return !_disposed && generation == _operationGeneration;
  }

  void _publish(int generation, OidcExampleState state) {
    if (_canPublish(generation)) {
      _state.value = state;
    }
  }

  bool _isBusy(OidcExampleStatus status) {
    return status == OidcExampleStatus.signingIn ||
        status == OidcExampleStatus.refreshing ||
        status == OidcExampleStatus.signingOut;
  }

  static OidcExampleState _initialState(
    OidcConfiguration configuration,
    bool platformSupported,
    OidcTokenSet? tokenSet,
  ) {
    if (!configuration.isConfigured) {
      return const OidcExampleState(status: OidcExampleStatus.unconfigured);
    }
    if (!platformSupported) {
      return const OidcExampleState(status: OidcExampleStatus.unsupported);
    }
    return OidcExampleState(
      status: tokenSet == null
          ? OidcExampleStatus.signedOut
          : OidcExampleStatus.signedIn,
    );
  }
}
