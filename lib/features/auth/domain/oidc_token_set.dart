import "package:flutter/foundation.dart";

/// Token set returned by a completed native OIDC flow.
@immutable
final class OidcTokenSet {
  /// Creates a token set.
  const OidcTokenSet({
    required this.accessToken,
    required this.expiresAt,
    required this.issuer,
    required this.subject,
    this.refreshToken,
    this.idToken,
    this.tokenType = "Bearer",
  });

  /// Access token used only to construct an Authorization header.
  final String accessToken;

  /// Refresh token retained only in secure storage.
  final String? refreshToken;

  /// ID token retained only for identity scope and provider end-session.
  final String? idToken;

  /// Access-token expiration instant.
  final DateTime expiresAt;

  /// Authorization header token type.
  final String tokenType;

  /// Validated issuer claim.
  final String issuer;

  /// Validated subject claim.
  final String subject;

  /// Returns a token set with selected fields replaced.
  OidcTokenSet copyWith({
    String? accessToken,
    String? refreshToken,
    String? idToken,
    DateTime? expiresAt,
    String? tokenType,
    String? issuer,
    String? subject,
  }) {
    return OidcTokenSet(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      idToken: idToken ?? this.idToken,
      expiresAt: expiresAt ?? this.expiresAt,
      tokenType: tokenType ?? this.tokenType,
      issuer: issuer ?? this.issuer,
      subject: subject ?? this.subject,
    );
  }

  /// Whether the token needs refresh before another request.
  bool needsRefresh(
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
        other.tokenType == tokenType &&
        other.issuer == issuer &&
        other.subject == subject;
  }

  @override
  int get hashCode => Object.hash(
    accessToken,
    refreshToken,
    idToken,
    expiresAt,
    tokenType,
    issuer,
    subject,
  );
}
