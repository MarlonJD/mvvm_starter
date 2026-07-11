import "package:mvvm_starter/core/result/result.dart";
import "package:mvvm_starter/features/auth/domain/oidc_configuration.dart";
import "package:mvvm_starter/features/auth/domain/oidc_sign_in_outcome.dart";
import "package:mvvm_starter/features/auth/domain/oidc_token_set.dart";

/// Native provider-SDK boundary for OIDC operations.
abstract interface class OidcClient {
  /// Starts an interactive authorization-code flow with PKCE.
  Future<Result<OidcSignInOutcome>> signIn(OidcConfiguration configuration);

  /// Refreshes a previously validated token set.
  Future<Result<OidcTokenSet>> refresh(
    OidcConfiguration configuration,
    OidcTokenSet currentTokenSet,
  );

  /// Attempts provider end-session with the last ID token.
  Future<Result<void>> endSession(
    OidcConfiguration configuration,
    String idToken,
  );
}
