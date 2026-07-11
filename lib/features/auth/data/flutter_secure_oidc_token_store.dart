import "dart:convert";

import "package:flutter_secure_storage/flutter_secure_storage.dart";
import "package:mvvm_starter/features/auth/data/oidc_token_store.dart";
import "package:mvvm_starter/features/auth/domain/oidc_token_set.dart";

/// Stores the complete OIDC token set as one versioned secure-storage value.
final class FlutterSecureOidcTokenStore implements OidcTokenStore {
  /// Creates a secure token store with an injected plugin instance.
  const FlutterSecureOidcTokenStore(this.storage);

  /// Creates the runtime secure store with hardened platform options.
  factory FlutterSecureOidcTokenStore.secure() {
    const storage = FlutterSecureStorage(
      aOptions: AndroidOptions(migrateWithBackup: true),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
      ),
      mOptions: MacOsOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
      ),
    );
    return const FlutterSecureOidcTokenStore(storage);
  }

  /// Underlying platform secure-storage adapter.
  final FlutterSecureStorage storage;

  static const String _key = "oidc.token_set.v1";

  @override
  Future<void> clear() => storage.delete(key: _key);

  @override
  Future<OidcTokenSet?> read() async {
    final encoded = await storage.read(key: _key);
    if (encoded == null) {
      return null;
    }
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! Map<String, Object?> || decoded["version"] != 1) {
        throw const FormatException("Invalid OIDC token document");
      }
      final accessToken = _requiredString(decoded, "access_token");
      final expiresAtValue = _requiredString(decoded, "expires_at");
      final tokenType = _requiredString(decoded, "token_type");
      final issuer = _requiredString(decoded, "issuer");
      final subject = _requiredString(decoded, "subject");
      final refreshToken = _optionalString(decoded, "refresh_token");
      final idToken = _optionalString(decoded, "id_token");
      final expiresAt = DateTime.tryParse(expiresAtValue)?.toUtc();
      if (expiresAt == null) {
        throw const FormatException("Invalid OIDC token document");
      }
      return OidcTokenSet(
        accessToken: accessToken,
        refreshToken: refreshToken,
        idToken: idToken,
        expiresAt: expiresAt,
        tokenType: tokenType,
        issuer: issuer,
        subject: subject,
      );
    } on FormatException {
      throw const FormatException("Invalid OIDC token document");
    } on TypeError {
      throw const FormatException("Invalid OIDC token document");
    }
  }

  @override
  Future<void> write(OidcTokenSet tokenSet) {
    final encoded = jsonEncode({
      "version": 1,
      "access_token": tokenSet.accessToken,
      "refresh_token": tokenSet.refreshToken,
      "id_token": tokenSet.idToken,
      "expires_at": tokenSet.expiresAt.toUtc().toIso8601String(),
      "token_type": tokenSet.tokenType,
      "issuer": tokenSet.issuer,
      "subject": tokenSet.subject,
    });
    return storage.write(key: _key, value: encoded);
  }

  String _requiredString(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is! String || value.isEmpty) {
      throw const FormatException("Invalid OIDC token document");
    }
    return value;
  }

  String? _optionalString(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value == null) {
      return null;
    }
    if (value is! String || value.isEmpty) {
      throw const FormatException("Invalid OIDC token document");
    }
    return value;
  }
}
