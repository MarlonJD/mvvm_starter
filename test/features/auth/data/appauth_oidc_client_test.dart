import "dart:convert";

import "package:flutter_appauth/flutter_appauth.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mvvm_starter/core/errors/app_error.dart";
import "package:mvvm_starter/features/auth/data/appauth_oidc_client.dart";
import "package:mvvm_starter/features/auth/domain/oidc_configuration.dart";
import "package:mvvm_starter/features/auth/domain/oidc_sign_in_outcome.dart";
import "package:mvvm_starter/features/auth/domain/oidc_token_set.dart";

void main() {
  final configuration = OidcConfiguration(
    issuer: "https://issuer.example.com",
    clientId: "client-id",
    redirectUri: Uri.parse("mvvmstarter:/oauthredirect"),
    postLogoutRedirectUri: Uri.parse("mvvmstarter:/logout"),
    scopes: const ["openid", "profile"],
  );

  test("unsupported platforms do not invoke AppAuth", () async {
    final appAuth = _FakeFlutterAppAuth();
    final client = AppAuthOidcClient(
      appAuth: appAuth,
      platformSupported: () => false,
    );

    final result = await client.signIn(configuration);

    expect(result.errorOrNull?.type, AppErrorType.notFound);
    expect(result.errorOrNull?.messageKey, "auth.oidc.unsupportedPlatform");
    expect(appAuth.authorizeCount, 0);
  });

  test("completed AppAuth flow requires matching issuer and subject", () async {
    final idToken = _jwt(
      issuer: "https://issuer.example.com/",
      subject: "subject-1",
    );
    final appAuth = _FakeFlutterAppAuth(
      authorizationResponse: AuthorizationTokenResponse(
        "access-token",
        "refresh-token",
        DateTime.utc(2026, 7, 11, 13),
        idToken,
        "Bearer",
        const ["openid"],
        null,
        null,
      ),
    );
    final client = AppAuthOidcClient(
      appAuth: appAuth,
      platformSupported: () => true,
    );

    final result = await client.signIn(configuration);

    final outcome = result.valueOrNull as OidcSignInCompleted;
    expect(outcome.tokenSet.issuer, "https://issuer.example.com/");
    expect(outcome.tokenSet.subject, "subject-1");
  });

  test("mismatched ID-token issuer is rejected", () async {
    final appAuth = _FakeFlutterAppAuth(
      authorizationResponse: AuthorizationTokenResponse(
        "access-token",
        "refresh-token",
        DateTime.utc(2026, 7, 11, 13),
        _jwt(issuer: "https://other.example.com", subject: "subject-1"),
        "Bearer",
        const ["openid"],
        null,
        null,
      ),
    );
    final client = AppAuthOidcClient(
      appAuth: appAuth,
      platformSupported: () => true,
    );

    final result = await client.signIn(configuration);

    expect(result.errorOrNull?.messageKey, "auth.oidc.invalidTokenResponse");
  });

  test("refresh preserves rotated fields omitted by the provider", () async {
    final appAuth = _FakeFlutterAppAuth(
      tokenResponse: TokenResponse(
        "new-access-token",
        null,
        DateTime.utc(2026, 7, 11, 14),
        null,
        null,
        null,
        null,
      ),
    );
    final client = AppAuthOidcClient(
      appAuth: appAuth,
      platformSupported: () => true,
    );
    final current = OidcTokenSet(
      accessToken: "access-token",
      refreshToken: "refresh-token",
      idToken: "id-token",
      expiresAt: DateTime.utc(2026, 7, 11, 13),
      issuer: configuration.issuer,
      subject: "subject-1",
    );

    final result = await client.refresh(configuration, current);

    expect(result.valueOrNull?.accessToken, "new-access-token");
    expect(result.valueOrNull?.refreshToken, "refresh-token");
    expect(result.valueOrNull?.idToken, "id-token");
    expect(result.valueOrNull?.issuer, configuration.issuer);
    expect(result.valueOrNull?.subject, "subject-1");
  });
}

String _jwt({required String issuer, required String subject}) {
  String encode(Map<String, Object?> value) {
    return base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll("=", "");
  }

  return "${encode(const {"alg": "none"})}.${encode({"iss": issuer, "sub": subject})}.signature";
}

final class _FakeFlutterAppAuth extends FlutterAppAuth {
  _FakeFlutterAppAuth({this.authorizationResponse, this.tokenResponse});

  final AuthorizationTokenResponse? authorizationResponse;
  final TokenResponse? tokenResponse;
  int authorizeCount = 0;

  @override
  Future<AuthorizationTokenResponse> authorizeAndExchangeCode(
    AuthorizationTokenRequest request,
  ) async {
    authorizeCount += 1;
    return authorizationResponse!;
  }

  @override
  Future<TokenResponse> token(TokenRequest request) async {
    return tokenResponse!;
  }
}
