import "dart:async";

import "package:flutter_test/flutter_test.dart";
import "package:mvvm_starter/core/errors/app_error.dart";
import "package:mvvm_starter/core/result/result.dart";
import "package:mvvm_starter/features/auth/data/oidc_client.dart";
import "package:mvvm_starter/features/auth/data/oidc_session_manager.dart";
import "package:mvvm_starter/features/auth/data/oidc_token_store.dart";
import "package:mvvm_starter/features/auth/domain/oidc_configuration.dart";
import "package:mvvm_starter/features/auth/domain/oidc_sign_in_outcome.dart";
import "package:mvvm_starter/features/auth/domain/oidc_token_set.dart";
import "package:mvvm_starter/features/auth/presentation/oidc_example_view_model.dart";

void main() {
  final configuration = OidcConfiguration(
    issuer: "https://issuer.example.com",
    clientId: "client-id",
    redirectUri: Uri.parse("mvvmstarter:/oauthredirect"),
    postLogoutRedirectUri: Uri.parse("mvvmstarter:/logout"),
    scopes: const ["openid", "offline_access"],
  );
  final token = OidcTokenSet(
    accessToken: "access-token",
    refreshToken: "refresh-token",
    idToken: "id-token",
    expiresAt: DateTime.utc(2026, 7, 11, 13),
    issuer: "https://issuer.example.com",
    subject: "subject-1",
  );

  test(
    "configured supported example signs in without exposing tokens",
    () async {
      final store = _MemoryStore();
      final client = _FakeClient(
        signInResult: Result.success(OidcSignInCompleted(token)),
      );
      final manager = OidcSessionManager(
        configuration: configuration,
        client: client,
        store: store,
        now: () => DateTime.utc(2026, 7, 11, 12),
      );
      final viewModel = OidcExampleViewModel(
        configuration: configuration,
        sessionManager: manager,
        platformSupported: true,
      );
      addTearDown(viewModel.dispose);
      addTearDown(manager.dispose);

      expect(viewModel.state.value.status, OidcExampleStatus.signedOut);

      final result = await viewModel.signIn();

      expect(result.isSuccess, isTrue);
      expect(viewModel.state.value.status, OidcExampleStatus.signedIn);
      expect(viewModel.state.value.toString(), isNot(contains("access-token")));
    },
  );

  test("unsupported example never invokes the provider client", () async {
    final client = _FakeClient();
    final manager = OidcSessionManager(
      configuration: configuration,
      client: client,
      store: _MemoryStore(),
    );
    final viewModel = OidcExampleViewModel(
      configuration: configuration,
      sessionManager: manager,
      platformSupported: false,
    );
    addTearDown(viewModel.dispose);
    addTearDown(manager.dispose);

    final result = await viewModel.signIn();

    expect(result.errorOrNull?.messageKey, "auth.oidc.unsupportedPlatform");
    expect(viewModel.state.value.status, OidcExampleStatus.unsupported);
    expect(client.signInCount, 0);
  });

  test("remote logout warning remains signed out", () async {
    final store = _MemoryStore(current: token);
    final client = _FakeClient(
      endSessionResult: const Result.failure(
        AppError.network("auth.oidc.remoteLogoutWarning"),
      ),
    );
    final manager = OidcSessionManager(
      configuration: configuration,
      client: client,
      store: store,
    );
    await manager.restore();
    final viewModel = OidcExampleViewModel(
      configuration: configuration,
      sessionManager: manager,
      platformSupported: true,
    );
    addTearDown(viewModel.dispose);
    addTearDown(manager.dispose);

    final result = await viewModel.logout();

    expect(result.isFailure, isTrue);
    expect(viewModel.state.value.status, OidcExampleStatus.warning);
    expect(manager.tokenSet.value, isNull);
  });

  test("dispose before sign-in completes does not publish", () async {
    final client = _CompleterClient();
    final manager = OidcSessionManager(
      configuration: configuration,
      client: client,
      store: _MemoryStore(),
    );
    final viewModel = OidcExampleViewModel(
      configuration: configuration,
      sessionManager: manager,
      platformSupported: true,
    );
    addTearDown(manager.dispose);

    final operation = viewModel.signIn();
    viewModel.dispose();
    client.signInCompleter.complete(Result.success(OidcSignInCompleted(token)));

    await expectLater(operation, completes);
  });
}

final class _MemoryStore implements OidcTokenStore {
  _MemoryStore({this.current});

  OidcTokenSet? current;

  @override
  Future<void> clear() async => current = null;

  @override
  Future<OidcTokenSet?> read() async => current;

  @override
  Future<void> write(OidcTokenSet tokenSet) async => current = tokenSet;
}

final class _FakeClient implements OidcClient {
  _FakeClient({
    this.signInResult,
    this.endSessionResult = const Result.success(null),
  });

  final Result<OidcSignInOutcome>? signInResult;
  final Result<void> endSessionResult;
  int signInCount = 0;

  @override
  Future<Result<void>> endSession(
    OidcConfiguration configuration,
    String idToken,
  ) async => endSessionResult;

  @override
  Future<Result<OidcTokenSet>> refresh(
    OidcConfiguration configuration,
    OidcTokenSet currentTokenSet,
  ) async => Result.success(currentTokenSet);

  @override
  Future<Result<OidcSignInOutcome>> signIn(
    OidcConfiguration configuration,
  ) async {
    signInCount += 1;
    return signInResult!;
  }
}

final class _CompleterClient implements OidcClient {
  final Completer<Result<OidcSignInOutcome>> signInCompleter = Completer();

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
  Future<Result<OidcSignInOutcome>> signIn(OidcConfiguration configuration) =>
      signInCompleter.future;
}
