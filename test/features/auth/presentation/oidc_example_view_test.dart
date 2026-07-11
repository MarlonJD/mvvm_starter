import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mvvm_starter/core/result/result.dart";
import "package:mvvm_starter/features/auth/data/oidc_client.dart";
import "package:mvvm_starter/features/auth/data/oidc_session_manager.dart";
import "package:mvvm_starter/features/auth/data/oidc_token_store.dart";
import "package:mvvm_starter/features/auth/domain/oidc_configuration.dart";
import "package:mvvm_starter/features/auth/domain/oidc_sign_in_outcome.dart";
import "package:mvvm_starter/features/auth/domain/oidc_token_set.dart";
import "package:mvvm_starter/features/auth/presentation/oidc_example_view.dart";
import "package:mvvm_starter/features/auth/presentation/oidc_example_view_model.dart";

void main() {
  testWidgets("signed-in OIDC view never renders token values", (tester) async {
    final configuration = OidcConfiguration(
      issuer: "https://issuer.example.com",
      clientId: "client-id",
      redirectUri: Uri.parse("mvvmstarter:/oauthredirect"),
      postLogoutRedirectUri: Uri.parse("mvvmstarter:/logout"),
      scopes: const ["openid"],
    );
    final token = OidcTokenSet(
      accessToken: "secret-access-token",
      refreshToken: "secret-refresh-token",
      idToken: "secret-id-token",
      expiresAt: DateTime.utc(2026, 7, 11, 13),
      issuer: configuration.issuer,
      subject: "subject-1",
    );
    final manager = OidcSessionManager(
      configuration: configuration,
      client: _NoopClient(),
      store: _MemoryStore(token),
      now: () => DateTime.utc(2026, 7, 11, 12),
    );
    addTearDown(manager.dispose);
    await manager.restore();

    await tester.pumpWidget(
      MaterialApp(
        home: OidcExampleView(
          viewModel: OidcExampleViewModel(
            configuration: configuration,
            sessionManager: manager,
            platformSupported: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text("Signed in securely. Tokens are not displayed."),
      findsOneWidget,
    );
    expect(find.textContaining("secret-access-token"), findsNothing);
    expect(find.textContaining("secret-refresh-token"), findsNothing);
    expect(find.textContaining("secret-id-token"), findsNothing);
  });
}

final class _MemoryStore implements OidcTokenStore {
  _MemoryStore(this.current);

  OidcTokenSet? current;

  @override
  Future<void> clear() async => current = null;

  @override
  Future<OidcTokenSet?> read() async => current;

  @override
  Future<void> write(OidcTokenSet tokenSet) async => current = tokenSet;
}

final class _NoopClient implements OidcClient {
  @override
  Future<Result<void>> endSession(
    OidcConfiguration configuration,
    String idToken,
  ) async => const Result.success(null);

  @override
  Future<Result<OidcTokenSet>> refresh(
    OidcConfiguration configuration,
    OidcTokenSet currentTokenSet,
  ) async => Result.success(currentTokenSet);

  @override
  Future<Result<OidcSignInOutcome>> signIn(
    OidcConfiguration configuration,
  ) async => const Result.success(OidcSignInCancelled());
}
