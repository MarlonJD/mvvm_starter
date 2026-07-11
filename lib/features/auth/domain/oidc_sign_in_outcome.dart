import "package:mvvm_starter/features/auth/domain/oidc_token_set.dart";

/// Explicit interactive OIDC sign-in outcome.
sealed class OidcSignInOutcome {
  /// Creates an OIDC sign-in outcome.
  const OidcSignInOutcome();
}

/// A completed authorization-code/PKCE exchange.
final class OidcSignInCompleted extends OidcSignInOutcome {
  /// Creates a completed sign-in outcome.
  const OidcSignInCompleted(this.tokenSet);

  /// Validated token set returned through AppAuth.
  final OidcTokenSet tokenSet;
}

/// The user cancelled the provider interaction.
final class OidcSignInCancelled extends OidcSignInOutcome {
  /// Creates a cancellation outcome.
  const OidcSignInCancelled();
}
