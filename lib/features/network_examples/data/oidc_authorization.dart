import "package:mvvm_starter/core/errors/app_error.dart";
import "package:mvvm_starter/core/result/result.dart";
import "package:mvvm_starter/features/network_examples/domain/oidc_token_set.dart";

/// Boundary implemented by a real OIDC adapter such as AppAuth.
abstract interface class OidcTokenProvider {
  /// Returns the currently stored token set, if the user is signed in.
  Future<Result<OidcTokenSet?>> currentTokenSet();

  /// Refreshes the current OIDC token set.
  Future<Result<OidcTokenSet>> refresh();

  /// Logs out locally and, when configured, calls the provider end-session URL.
  Future<Result<void>> logout();
}

/// Produces REST and GraphQL auth headers from an OIDC token provider.
final class OidcAuthorization {
  /// Creates an OIDC authorization helper.
  OidcAuthorization({
    required OidcTokenProvider tokenProvider,
    DateTime Function()? now,
  })  : _tokenProvider = tokenProvider,
        _now = now ?? DateTime.now;

  final OidcTokenProvider _tokenProvider;
  final DateTime Function() _now;

  /// Headers for authenticated REST calls.
  Future<Result<Map<String, String>>> restHeaders() async {
    final tokenResult = await _activeTokenSet();
    final token = tokenResult.valueOrNull;
    if (token == null) {
      return Result.failure(tokenResult.errorOrNull!);
    }

    return Result.success({
      "Authorization": "${token.tokenType} ${token.accessToken}",
    });
  }

  /// Headers for authenticated GraphQL calls.
  Future<Result<Map<String, String>>> graphqlHeaders() async {
    final tokenResult = await _activeTokenSet();
    final token = tokenResult.valueOrNull;
    if (token == null) {
      return Result.failure(tokenResult.errorOrNull!);
    }

    return Result.success({
      "Authorization": "${token.tokenType} ${token.accessToken}",
      "Content-Type": "application/json",
    });
  }

  /// Logs out through the configured OIDC provider boundary.
  Future<Result<void>> logout() => _tokenProvider.logout();

  Future<Result<OidcTokenSet>> _activeTokenSet() async {
    final currentResult = await _tokenProvider.currentTokenSet();
    final current = currentResult.valueOrNull;
    if (currentResult.isFailure) {
      return Result.failure(currentResult.errorOrNull!);
    }
    if (current == null) {
      return const Result.failure(
        AppError.notFound("networkExamples.oidc.noSession"),
      );
    }
    if (current.isExpired(_now())) {
      return _tokenProvider.refresh();
    }
    return Result.success(current);
  }
}
