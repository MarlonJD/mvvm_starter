import "package:flutter_test/flutter_test.dart";
import "package:mvvm_starter/features/network_examples/domain/persisted_result.dart";
import "package:mvvm_starter/features/network_examples/domain/persistence_scope.dart";

void main() {
  test("public persistence uses the stable public key", () {
    expect(const PersistenceScope.public().key, "public");
  });

  test("OIDC persistence includes issuer and subject in its key", () {
    final scope = PersistenceScope.oidc(
      issuer: "https://issuer.example",
      subject: "user-123",
    );

    expect(scope.key, "oidc:https://issuer.example:user-123");
  });

  test("OIDC persistence rejects blank issuer or subject", () {
    expect(
      () => PersistenceScope.oidc(issuer: " ", subject: "user-123"),
      throwsArgumentError,
    );
    expect(
      () =>
          PersistenceScope.oidc(issuer: "https://issuer.example", subject: " "),
      throwsArgumentError,
    );
  });

  test("persisted results expose value origin and fetch time", () {
    final fetchedAt = DateTime.utc(2026, 7, 13);
    final result = PersistedResult<List<int>>(
      value: const [1, 2],
      origin: DataOrigin.localFresh,
      fetchedAt: fetchedAt,
    );

    expect(result.value, [1, 2]);
    expect(result.origin, DataOrigin.localFresh);
    expect(result.fetchedAt, fetchedAt);
  });
}
