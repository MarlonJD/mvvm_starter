import "package:flutter/foundation.dart";
import "package:mvvm_starter/core/errors/app_error.dart";
import "package:mvvm_starter/core/network/authorization_header_provider.dart";
import "package:mvvm_starter/core/result/result.dart";
import "package:mvvm_starter/features/auth/data/oidc_client.dart";
import "package:mvvm_starter/features/auth/data/oidc_token_store.dart";
import "package:mvvm_starter/features/auth/domain/oidc_configuration.dart";
import "package:mvvm_starter/features/auth/domain/oidc_sign_in_outcome.dart";
import "package:mvvm_starter/features/auth/domain/oidc_token_set.dart";

/// Owns secure OIDC session restoration, refresh, headers, and logout.
final class OidcSessionManager implements AuthorizationHeaderProvider {
  /// Creates an OIDC session manager.
  OidcSessionManager({
    required this.configuration,
    required this.client,
    required this.store,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;

  /// Provider configuration.
  final OidcConfiguration configuration;

  /// Native provider adapter.
  final OidcClient client;

  /// Secure local token store.
  final OidcTokenStore store;

  /// Clock used for deterministic expiry checks.
  final DateTime Function() now;

  final ValueNotifier<OidcTokenSet?> _tokenSet = ValueNotifier(null);
  Future<Result<OidcTokenSet>>? _refreshInFlight;

  /// Current validated session token set.
  ValueListenable<OidcTokenSet?> get tokenSet => _tokenSet;

  /// Restores a secure local token set.
  Future<Result<OidcTokenSet?>> restore() async {
    try {
      final restored = await store.read();
      _tokenSet.value = restored;
      return Result.success(restored);
    } on Object catch (error) {
      return Result.failure(
        AppError.unknown("auth.oidc.restoreFailed", cause: error),
      );
    }
  }

  /// Starts interactive sign-in and persists only completed outcomes.
  Future<Result<OidcSignInOutcome>> signIn() async {
    final result = await client.signIn(configuration);
    final outcome = result.valueOrNull;
    if (outcome is! OidcSignInCompleted) {
      return result;
    }
    try {
      await store.write(outcome.tokenSet);
      _tokenSet.value = outcome.tokenSet;
      return result;
    } on Object catch (error) {
      return Result.failure(
        AppError.unknown("auth.oidc.secureStorageFailed", cause: error),
      );
    }
  }

  /// Refreshes the current token set with single-flight coordination.
  Future<Result<OidcTokenSet>> refresh({bool force = false}) async {
    final current = _tokenSet.value;
    if (current == null) {
      return const Result.failure(
        AppError.unauthorized("auth.oidc.reauthenticationRequired"),
      );
    }
    if (!force && !current.needsRefresh(now())) {
      return Result.success(current);
    }

    final activeRefresh = _refreshInFlight;
    if (activeRefresh != null) {
      return activeRefresh;
    }

    final refreshFuture = _performRefresh(current);
    _refreshInFlight = refreshFuture;
    try {
      return await refreshFuture;
    } finally {
      if (identical(_refreshInFlight, refreshFuture)) {
        _refreshInFlight = null;
      }
    }
  }

  @override
  Future<Result<String?>> authorizationHeader({
    bool forceRefresh = false,
  }) async {
    final current = _tokenSet.value;
    if (current == null) {
      return const Result.success(null);
    }
    if (forceRefresh || current.needsRefresh(now())) {
      final result = await refresh(force: true);
      final refreshed = result.valueOrNull;
      if (refreshed == null) {
        return Result.failure(result.errorOrNull!);
      }
      return Result.success("${refreshed.tokenType} ${refreshed.accessToken}");
    }
    return Result.success("${current.tokenType} ${current.accessToken}");
  }

  /// Clears the local session before attempting provider end-session.
  Future<Result<void>> logout() async {
    final current = _tokenSet.value;
    try {
      await store.clear();
    } on Object catch (error) {
      return Result.failure(
        AppError.unknown("auth.oidc.secureStorageFailed", cause: error),
      );
    }
    _tokenSet.value = null;

    final idToken = current?.idToken;
    if (idToken == null) {
      return const Result.success(null);
    }
    return client.endSession(configuration, idToken);
  }

  /// Releases observable session state.
  void dispose() {
    _tokenSet.dispose();
  }

  Future<Result<OidcTokenSet>> _performRefresh(OidcTokenSet current) async {
    if (current.refreshToken == null) {
      await _clearUnrecoverableSession();
      return const Result.failure(
        AppError.unauthorized("auth.oidc.reauthenticationRequired"),
      );
    }

    final result = await client.refresh(configuration, current);
    final refreshed = result.valueOrNull;
    if (refreshed == null) {
      await _clearUnrecoverableSession();
      return Result.failure(
        AppError.unauthorized(
          "auth.oidc.reauthenticationRequired",
          cause: result.errorOrNull,
        ),
      );
    }

    final merged = refreshed.copyWith(
      refreshToken: refreshed.refreshToken ?? current.refreshToken,
      idToken: refreshed.idToken ?? current.idToken,
      issuer: current.issuer,
      subject: current.subject,
    );
    try {
      await store.write(merged);
      _tokenSet.value = merged;
      return Result.success(merged);
    } on Object catch (error) {
      return Result.failure(
        AppError.unknown("auth.oidc.secureStorageFailed", cause: error),
      );
    }
  }

  Future<void> _clearUnrecoverableSession() async {
    try {
      await store.clear();
    } on Object {
      // Publishing signed-out is safer than retaining an unusable token in memory.
    }
    _tokenSet.value = null;
  }
}
