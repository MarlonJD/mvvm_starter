import "package:flutter_test/flutter_test.dart";
import "package:mvvm_starter/core/result/result.dart";
import "package:mvvm_starter/features/network_examples/data/oidc_authorization.dart";
import "package:mvvm_starter/features/network_examples/domain/oidc_token_set.dart";

void main() {
  test("REST headers use the active access token", () async {
    final provider = _FakeOidcTokenProvider(
      current: OidcTokenSet(
        accessToken: "access-token",
        refreshToken: "refresh-token",
        idToken: "id-token",
        expiresAt: DateTime.utc(2026, 7, 8, 12),
      ),
    );
    final authorization = OidcAuthorization(
      tokenProvider: provider,
      now: () => DateTime.utc(2026, 7, 8, 11),
    );

    final result = await authorization.restHeaders();

    expect(result.valueOrNull, {"Authorization": "Bearer access-token"});
    expect(provider.refreshCount, 0);
  });

  test("GraphQL headers refresh expired tokens before use", () async {
    final provider = _FakeOidcTokenProvider(
      current: OidcTokenSet(
        accessToken: "old-token",
        refreshToken: "refresh-token",
        idToken: "id-token",
        expiresAt: DateTime.utc(2026, 7, 8, 10),
      ),
      refreshed: OidcTokenSet(
        accessToken: "new-token",
        refreshToken: "refresh-token-2",
        idToken: "id-token-2",
        expiresAt: DateTime.utc(2026, 7, 8, 12),
      ),
    );
    final authorization = OidcAuthorization(
      tokenProvider: provider,
      now: () => DateTime.utc(2026, 7, 8, 11),
    );

    final result = await authorization.graphqlHeaders();

    expect(
      result.valueOrNull,
      {
        "Authorization": "Bearer new-token",
        "Content-Type": "application/json",
      },
    );
    expect(provider.refreshCount, 1);
  });

  test("logout delegates to the OIDC provider boundary", () async {
    final provider = _FakeOidcTokenProvider();
    final authorization = OidcAuthorization(tokenProvider: provider);

    final result = await authorization.logout();

    expect(result.isSuccess, isTrue);
    expect(provider.logoutCount, 1);
  });
}

final class _FakeOidcTokenProvider implements OidcTokenProvider {
  _FakeOidcTokenProvider({this.current, this.refreshed});

  OidcTokenSet? current;
  final OidcTokenSet? refreshed;
  int refreshCount = 0;
  int logoutCount = 0;

  @override
  Future<Result<OidcTokenSet?>> currentTokenSet() async {
    return Result.success(current);
  }

  @override
  Future<Result<OidcTokenSet>> refresh() async {
    refreshCount += 1;
    current = refreshed;
    return Result.success(refreshed!);
  }

  @override
  Future<Result<void>> logout() async {
    logoutCount += 1;
    current = null;
    return const Result.success(null);
  }
}
