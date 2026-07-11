import "dart:convert";

import "package:flutter_secure_storage/flutter_secure_storage.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mvvm_starter/features/auth/data/flutter_secure_oidc_token_store.dart";
import "package:mvvm_starter/features/auth/domain/oidc_token_set.dart";

void main() {
  const storage = FlutterSecureStorage();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test("stores and restores one versioned JSON document", () async {
    const store = FlutterSecureOidcTokenStore(storage);
    final tokenSet = OidcTokenSet(
      accessToken: "access-token",
      refreshToken: "refresh-token",
      idToken: "id-token",
      expiresAt: DateTime.utc(2026, 7, 11, 13),
      issuer: "https://issuer.example.com",
      subject: "subject-1",
    );

    await store.write(tokenSet);

    final allValues = await storage.readAll();
    expect(allValues.keys, ["oidc.token_set.v1"]);
    final decoded = jsonDecode(allValues.values.single) as Map<String, Object?>;
    expect(decoded["version"], 1);
    expect(await store.read(), tokenSet);
  });

  test("clear deletes the complete token document", () async {
    const store = FlutterSecureOidcTokenStore(storage);
    await storage.write(key: "oidc.token_set.v1", value: "value");

    await store.clear();

    expect(await storage.read(key: "oidc.token_set.v1"), isNull);
  });

  test("invalid stored JSON fails without exposing its contents", () async {
    const store = FlutterSecureOidcTokenStore(storage);
    await storage.write(
      key: "oidc.token_set.v1",
      value: "secret-invalid-token-document",
    );

    Object? caught;
    try {
      await store.read();
    } on Object catch (error) {
      caught = error;
    }

    expect(caught, isA<FormatException>());
    expect(caught.toString(), isNot(contains("secret-invalid-token-document")));
  });
}
