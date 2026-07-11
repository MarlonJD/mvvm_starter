import "package:flutter/foundation.dart";

/// Provider-independent OIDC settings supplied through dart-defines.
final class OidcConfiguration {
  factory OidcConfiguration({
    required String issuer,
    required String clientId,
    required Uri redirectUri,
    required Uri postLogoutRedirectUri,
    required List<String> scopes,
  }) {
    final normalizedIssuer = issuer.trim();
    final normalizedClientId = clientId.trim();
    if (normalizedIssuer.isNotEmpty && normalizedClientId.isNotEmpty) {
      final issuerUri = Uri.tryParse(normalizedIssuer);
      if (issuerUri == null ||
          issuerUri.scheme != "https" ||
          !issuerUri.hasAuthority) {
        throw ArgumentError.value(
          issuer,
          "issuer",
          "configured issuers must use HTTPS",
        );
      }
    }
    if (!redirectUri.hasScheme || !postLogoutRedirectUri.hasScheme) {
      throw ArgumentError("OIDC redirect URIs must include a scheme");
    }
    final normalizedScopes = scopes
        .map((scope) => scope.trim())
        .where((scope) => scope.isNotEmpty)
        .toList(growable: false);
    return OidcConfiguration._(
      issuer: normalizedIssuer,
      clientId: normalizedClientId,
      redirectUri: redirectUri,
      postLogoutRedirectUri: postLogoutRedirectUri,
      scopes: normalizedScopes,
    );
  }

  const OidcConfiguration._({
    required this.issuer,
    required this.clientId,
    required this.redirectUri,
    required this.postLogoutRedirectUri,
    required this.scopes,
  });

  /// Reads OIDC settings from compile-time environment values.
  factory OidcConfiguration.fromEnvironment() {
    return OidcConfiguration(
      issuer: const String.fromEnvironment("OIDC_ISSUER"),
      clientId: const String.fromEnvironment("OIDC_CLIENT_ID"),
      redirectUri: Uri.parse(
        const String.fromEnvironment(
          "OIDC_REDIRECT_URI",
          defaultValue: "mvvmstarter:/oauthredirect",
        ),
      ),
      postLogoutRedirectUri: Uri.parse(
        const String.fromEnvironment(
          "OIDC_POST_LOGOUT_REDIRECT_URI",
          defaultValue: "mvvmstarter:/logout",
        ),
      ),
      scopes: const String.fromEnvironment(
        "OIDC_SCOPES",
        defaultValue: "openid profile email offline_access",
      ).split(RegExp(r"\s+")),
    );
  }

  /// Provider issuer URL, empty when the example is not configured.
  final String issuer;

  /// Public native client id, empty when the example is not configured.
  final String clientId;

  /// Native authorization callback URI.
  final Uri redirectUri;

  /// Native post-logout callback URI.
  final Uri postLogoutRedirectUri;

  /// Requested OIDC scopes.
  final List<String> scopes;

  /// Whether the minimum provider settings are present.
  bool get isConfigured => issuer.isNotEmpty && clientId.isNotEmpty;
}

/// Whether interactive AppAuth is supported on the current Flutter platform.
bool get isOidcInteractivePlatformSupported {
  if (kIsWeb) {
    return false;
  }
  return switch (defaultTargetPlatform) {
    TargetPlatform.android ||
    TargetPlatform.iOS ||
    TargetPlatform.macOS => true,
    TargetPlatform.fuchsia ||
    TargetPlatform.linux ||
    TargetPlatform.windows => false,
  };
}

/// Normalizes an issuer for comparison without weakening its origin boundary.
String normalizeOidcIssuer(String issuer) {
  final uri = Uri.parse(issuer.trim());
  var path = uri.path;
  while (path.length > 1 && path.endsWith("/")) {
    path = path.substring(0, path.length - 1);
  }
  if (path == "/") {
    path = "";
  }
  return uri
      .replace(
        scheme: uri.scheme.toLowerCase(),
        host: uri.host.toLowerCase(),
        path: path,
        fragment: "",
      )
      .toString();
}
