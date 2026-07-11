import "dart:convert";

import "package:flutter_appauth/flutter_appauth.dart";
import "package:mvvm_starter/core/errors/app_error.dart";
import "package:mvvm_starter/core/result/result.dart";
import "package:mvvm_starter/features/auth/data/oidc_client.dart";
import "package:mvvm_starter/features/auth/domain/oidc_configuration.dart";
import "package:mvvm_starter/features/auth/domain/oidc_sign_in_outcome.dart";
import "package:mvvm_starter/features/auth/domain/oidc_token_set.dart";

/// Native flutter_appauth adapter using authorization code with PKCE.
final class AppAuthOidcClient implements OidcClient {
  /// Creates an AppAuth adapter.
  AppAuthOidcClient({
    FlutterAppAuth? appAuth,
    bool Function()? platformSupported,
  }) : appAuth = appAuth ?? const FlutterAppAuth(),
       platformSupported =
           platformSupported ?? (() => isOidcInteractivePlatformSupported);

  /// AppAuth plugin boundary.
  final FlutterAppAuth appAuth;

  /// Injectable support check used to avoid unsupported plugin channels.
  final bool Function() platformSupported;

  @override
  Future<Result<OidcSignInOutcome>> signIn(
    OidcConfiguration configuration,
  ) async {
    final availabilityError = _availabilityError(configuration);
    if (availabilityError != null) {
      return Result.failure(availabilityError);
    }
    try {
      final response = await appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          configuration.clientId,
          configuration.redirectUri.toString(),
          issuer: configuration.issuer,
          scopes: configuration.scopes,
        ),
      );
      final accessToken = response.accessToken;
      final expiresAt = response.accessTokenExpirationDateTime;
      final idToken = response.idToken;
      if (accessToken == null || expiresAt == null || idToken == null) {
        return const Result.failure(
          AppError.unknown("auth.oidc.invalidTokenResponse"),
        );
      }
      final identity = _validatedIdentity(idToken, configuration.issuer);
      if (identity == null) {
        return const Result.failure(
          AppError.unknown("auth.oidc.invalidTokenResponse"),
        );
      }
      return Result.success(
        OidcSignInCompleted(
          OidcTokenSet(
            accessToken: accessToken,
            refreshToken: response.refreshToken,
            idToken: idToken,
            expiresAt: expiresAt,
            tokenType: response.tokenType ?? "Bearer",
            issuer: identity.issuer,
            subject: identity.subject,
          ),
        ),
      );
    } on FlutterAppAuthUserCancelledException {
      return const Result.success(OidcSignInCancelled());
    } on Object catch (error) {
      return Result.failure(
        AppError.unknown("auth.oidc.signInFailed", cause: error),
      );
    }
  }

  @override
  Future<Result<OidcTokenSet>> refresh(
    OidcConfiguration configuration,
    OidcTokenSet currentTokenSet,
  ) async {
    final availabilityError = _availabilityError(configuration);
    if (availabilityError != null) {
      return Result.failure(availabilityError);
    }
    final refreshToken = currentTokenSet.refreshToken;
    if (refreshToken == null) {
      return const Result.failure(
        AppError.unauthorized("auth.oidc.reauthenticationRequired"),
      );
    }
    try {
      final response = await appAuth.token(
        TokenRequest(
          configuration.clientId,
          configuration.redirectUri.toString(),
          issuer: configuration.issuer,
          scopes: configuration.scopes,
          refreshToken: refreshToken,
        ),
      );
      final accessToken = response.accessToken;
      final expiresAt = response.accessTokenExpirationDateTime;
      if (accessToken == null || expiresAt == null) {
        return const Result.failure(
          AppError.unknown("auth.oidc.invalidTokenResponse"),
        );
      }
      return Result.success(
        currentTokenSet.copyWith(
          accessToken: accessToken,
          refreshToken: response.refreshToken ?? currentTokenSet.refreshToken,
          idToken: response.idToken ?? currentTokenSet.idToken,
          expiresAt: expiresAt,
          tokenType: response.tokenType ?? currentTokenSet.tokenType,
        ),
      );
    } on Object catch (error) {
      return Result.failure(
        AppError.unknown("auth.oidc.refreshFailed", cause: error),
      );
    }
  }

  @override
  Future<Result<void>> endSession(
    OidcConfiguration configuration,
    String idToken,
  ) async {
    final availabilityError = _availabilityError(configuration);
    if (availabilityError != null) {
      return Result.failure(availabilityError);
    }
    try {
      await appAuth.endSession(
        EndSessionRequest(
          idTokenHint: idToken,
          postLogoutRedirectUrl: configuration.postLogoutRedirectUri.toString(),
          issuer: configuration.issuer,
        ),
      );
      return const Result.success(null);
    } on Object catch (error) {
      return Result.failure(
        AppError.network("auth.oidc.remoteLogoutWarning", cause: error),
      );
    }
  }

  AppError? _availabilityError(OidcConfiguration configuration) {
    if (!configuration.isConfigured) {
      return const AppError.notFound("auth.oidc.notConfigured");
    }
    if (!platformSupported()) {
      return const AppError.notFound("auth.oidc.unsupportedPlatform");
    }
    return null;
  }

  _OidcIdentity? _validatedIdentity(String idToken, String expectedIssuer) {
    try {
      final segments = idToken.split(".");
      if (segments.length != 3) {
        return null;
      }
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(segments[1])),
      );
      final decoded = jsonDecode(payload);
      if (decoded is! Map<String, Object?>) {
        return null;
      }
      final issuer = decoded["iss"];
      final subject = decoded["sub"];
      if (issuer is! String ||
          issuer.isEmpty ||
          subject is! String ||
          subject.isEmpty ||
          normalizeOidcIssuer(issuer) != normalizeOidcIssuer(expectedIssuer)) {
        return null;
      }
      return _OidcIdentity(issuer: issuer, subject: subject);
    } on Object {
      return null;
    }
  }
}

final class _OidcIdentity {
  const _OidcIdentity({required this.issuer, required this.subject});

  final String issuer;
  final String subject;
}
