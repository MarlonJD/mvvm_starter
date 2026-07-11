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

void main() {
  final configuration = OidcConfiguration(
    issuer: "https://issuer.example.com",
    clientId: "client-id",
    redirectUri: Uri.parse("mvvmstarter:/oauthredirect"),
    postLogoutRedirectUri: Uri.parse("mvvmstarter:/logout"),
    scopes: const ["openid", "profile", "offline_access"],
  );
  final now = DateTime.utc(2026, 7, 11, 12);

  OidcTokenSet token({
    String accessToken = "access-token",
    String? refreshToken = "refresh-token",
    String? idToken = "id-token",
    DateTime? expiresAt,
  }) {
    return OidcTokenSet(
      accessToken: accessToken,
      refreshToken: refreshToken,
      idToken: idToken,
      expiresAt: expiresAt ?? now.add(const Duration(hours: 1)),
      issuer: configuration.issuer,
      subject: "subject-1",
    );
  }

  test("restoring a stored token publishes a signed-in session", () async {
    final stored = token();
    final store = _MemoryTokenStore(current: stored);
    final manager = OidcSessionManager(
      configuration: configuration,
      client: _FakeOidcClient(),
      store: store,
      now: () => now,
    );
    addTearDown(manager.dispose);

    final result = await manager.restore();

    expect(result.valueOrNull, stored);
    expect(manager.tokenSet.value, stored);
  });

  test("active tokens do not refresh before authorization", () async {
    final current = token();
    final client = _FakeOidcClient();
    final manager = OidcSessionManager(
      configuration: configuration,
      client: client,
      store: _MemoryTokenStore(current: current),
      now: () => now,
    );
    addTearDown(manager.dispose);
    await manager.restore();

    final result = await manager.authorizationHeader();

    expect(result.valueOrNull, "Bearer access-token");
    expect(client.refreshCount, 0);
  });

  test("tokens within one minute of expiry refresh before use", () async {
    final current = token(expiresAt: now.add(const Duration(seconds: 30)));
    final refreshed = token(accessToken: "new-access-token");
    final client = _FakeOidcClient(refreshResult: Result.success(refreshed));
    final manager = OidcSessionManager(
      configuration: configuration,
      client: client,
      store: _MemoryTokenStore(current: current),
      now: () => now,
    );
    addTearDown(manager.dispose);
    await manager.restore();

    final result = await manager.authorizationHeader();

    expect(result.valueOrNull, "Bearer new-access-token");
    expect(client.refreshCount, 1);
  });

  test("expired token without refresh token clears local session", () async {
    final current = token(
      refreshToken: null,
      expiresAt: now.subtract(const Duration(minutes: 1)),
    );
    final store = _MemoryTokenStore(current: current);
    final manager = OidcSessionManager(
      configuration: configuration,
      client: _FakeOidcClient(),
      store: store,
      now: () => now,
    );
    addTearDown(manager.dispose);
    await manager.restore();

    final result = await manager.authorizationHeader();

    expect(result.errorOrNull?.type, AppErrorType.unauthorized);
    expect(store.current, isNull);
    expect(manager.tokenSet.value, isNull);
  });

  test("ten concurrent expired requests share one provider refresh", () async {
    final current = token(expiresAt: now.subtract(const Duration(minutes: 1)));
    final refreshed = token(accessToken: "new-access-token");
    final refreshCompleter = Completer<Result<OidcTokenSet>>();
    final client = _FakeOidcClient(refreshCompleter: refreshCompleter);
    final manager = OidcSessionManager(
      configuration: configuration,
      client: client,
      store: _MemoryTokenStore(current: current),
      now: () => now,
    );
    addTearDown(manager.dispose);
    await manager.restore();

    final requests = List.generate(10, (_) => manager.authorizationHeader());
    await Future<void>.delayed(Duration.zero);
    expect(client.refreshCount, 1);
    refreshCompleter.complete(Result.success(refreshed));

    final results = await Future.wait(requests);
    expect(results.map((result) => result.valueOrNull).toSet(), {
      "Bearer new-access-token",
    });
    expect(client.refreshCount, 1);
  });

  test("rotated refresh token is stored before publication", () async {
    final operations = <String>[];
    final current = token(expiresAt: now.subtract(const Duration(minutes: 1)));
    final refreshed = token(
      accessToken: "new-access-token",
      refreshToken: "rotated-refresh-token",
    );
    final store = _MemoryTokenStore(current: current, operations: operations);
    final manager = OidcSessionManager(
      configuration: configuration,
      client: _FakeOidcClient(refreshResult: Result.success(refreshed)),
      store: store,
      now: () => now,
    );
    addTearDown(manager.dispose);
    await manager.restore();
    operations.clear();
    manager.tokenSet.addListener(() => operations.add("publish"));

    await manager.authorizationHeader();

    expect(store.current?.refreshToken, "rotated-refresh-token");
    expect(operations, ["write", "publish"]);
  });

  test("refresh retains omitted refresh and ID tokens", () async {
    final current = token(expiresAt: now.subtract(const Duration(minutes: 1)));
    final refreshed = token(
      accessToken: "new-access-token",
      refreshToken: null,
      idToken: null,
    );
    final store = _MemoryTokenStore(current: current);
    final manager = OidcSessionManager(
      configuration: configuration,
      client: _FakeOidcClient(refreshResult: Result.success(refreshed)),
      store: store,
      now: () => now,
    );
    addTearDown(manager.dispose);
    await manager.restore();

    await manager.authorizationHeader();

    expect(store.current?.refreshToken, "refresh-token");
    expect(store.current?.idToken, "id-token");
  });

  test("refresh failure clears local token and returns unauthorized", () async {
    final current = token(expiresAt: now.subtract(const Duration(minutes: 1)));
    final store = _MemoryTokenStore(current: current);
    final manager = OidcSessionManager(
      configuration: configuration,
      client: _FakeOidcClient(
        refreshResult: const Result.failure(
          AppError.network("auth.oidc.refreshFailed"),
        ),
      ),
      store: store,
      now: () => now,
    );
    addTearDown(manager.dispose);
    await manager.restore();

    final result = await manager.authorizationHeader();

    expect(result.errorOrNull?.type, AppErrorType.unauthorized);
    expect(store.current, isNull);
    expect(manager.tokenSet.value, isNull);
  });

  test("logout clears locally before remote end-session", () async {
    final operations = <String>[];
    final current = token();
    final store = _MemoryTokenStore(current: current, operations: operations);
    final client = _FakeOidcClient(operations: operations);
    final manager = OidcSessionManager(
      configuration: configuration,
      client: client,
      store: store,
      now: () => now,
    );
    addTearDown(manager.dispose);
    await manager.restore();
    operations.clear();

    final result = await manager.logout();

    expect(result.isSuccess, isTrue);
    expect(operations, ["clear", "endSession"]);
    expect(manager.tokenSet.value, isNull);
  });

  test("remote logout failure leaves local session signed out", () async {
    final current = token();
    final store = _MemoryTokenStore(current: current);
    final manager = OidcSessionManager(
      configuration: configuration,
      client: _FakeOidcClient(
        endSessionResult: const Result.failure(
          AppError.network("auth.oidc.remoteLogoutWarning"),
        ),
      ),
      store: store,
      now: () => now,
    );
    addTearDown(manager.dispose);
    await manager.restore();

    final result = await manager.logout();

    expect(result.errorOrNull?.messageKey, "auth.oidc.remoteLogoutWarning");
    expect(store.current, isNull);
    expect(manager.tokenSet.value, isNull);
  });

  test("token values are absent from token and error strings", () {
    final current = token();
    const error = AppError.unauthorized("auth.oidc.reauthenticationRequired");

    expect(current.toString(), isNot(contains("access-token")));
    expect(current.toString(), isNot(contains("refresh-token")));
    expect(error.toString(), isNot(contains("access-token")));
  });
}

final class _MemoryTokenStore implements OidcTokenStore {
  _MemoryTokenStore({this.current, List<String>? operations})
    : operations = operations ?? <String>[];

  OidcTokenSet? current;
  final List<String> operations;

  @override
  Future<void> clear() async {
    operations.add("clear");
    current = null;
  }

  @override
  Future<OidcTokenSet?> read() async => current;

  @override
  Future<void> write(OidcTokenSet tokenSet) async {
    operations.add("write");
    current = tokenSet;
  }
}

final class _FakeOidcClient implements OidcClient {
  _FakeOidcClient({
    this.refreshResult,
    this.refreshCompleter,
    this.endSessionResult = const Result.success(null),
    List<String>? operations,
  }) : operations = operations ?? <String>[];

  final Result<OidcTokenSet>? refreshResult;
  final Completer<Result<OidcTokenSet>>? refreshCompleter;
  final Result<void> endSessionResult;
  final List<String> operations;
  int refreshCount = 0;

  @override
  Future<Result<void>> endSession(
    OidcConfiguration configuration,
    String idToken,
  ) async {
    operations.add("endSession");
    return endSessionResult;
  }

  @override
  Future<Result<OidcTokenSet>> refresh(
    OidcConfiguration configuration,
    OidcTokenSet currentTokenSet,
  ) {
    refreshCount += 1;
    return refreshCompleter?.future ?? Future.value(refreshResult!);
  }

  @override
  Future<Result<OidcSignInOutcome>> signIn(
    OidcConfiguration configuration,
  ) async {
    return const Result.success(OidcSignInCancelled());
  }
}
