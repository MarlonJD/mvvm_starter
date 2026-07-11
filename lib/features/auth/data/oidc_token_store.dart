import "package:mvvm_starter/features/auth/domain/oidc_token_set.dart";

/// Secure persistence boundary for one OIDC token set.
abstract interface class OidcTokenStore {
  /// Reads the current token set.
  Future<OidcTokenSet?> read();

  /// Atomically replaces the current token set.
  Future<void> write(OidcTokenSet tokenSet);

  /// Deletes the complete local token set.
  Future<void> clear();
}
