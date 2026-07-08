import "package:flutter/foundation.dart";

/// Token set returned by an OIDC provider.
@immutable
final class OidcTokenSet {
  /// Creates an OIDC token set.
  const OidcTokenSet({
    required this.accessToken,
    required this.refreshToken,
    required this.idToken,
    required this.expiresAt,
    this.tokenType = "Bearer",
  });

  /// Access token used in REST and GraphQL authorization headers.
  final String accessToken;

  /// Refresh token used at the OIDC provider boundary.
  final String refreshToken;

  /// ID token returned by the OIDC provider.
  final String idToken;

  /// Access token expiry time.
  final DateTime expiresAt;

  /// Authorization header token type.
  final String tokenType;

  /// Whether the access token should be refreshed before another request.
  bool isExpired(
    DateTime now, {
    Duration clockSkew = const Duration(minutes: 1),
  }) {
    return !expiresAt.isAfter(now.add(clockSkew));
  }

  @override
  bool operator ==(Object other) {
    return other is OidcTokenSet &&
        other.accessToken == accessToken &&
        other.refreshToken == refreshToken &&
        other.idToken == idToken &&
        other.expiresAt == expiresAt &&
        other.tokenType == tokenType;
  }

  @override
  int get hashCode {
    return Object.hash(
      accessToken,
      refreshToken,
      idToken,
      expiresAt,
      tokenType,
    );
  }
}
