/// Namespace used to isolate persisted network snapshots.
final class PersistenceScope {
  /// Creates the anonymous/public persistence namespace.
  const PersistenceScope.public() : key = "public";

  /// Creates a namespace owned by one validated OIDC identity.
  PersistenceScope.oidc({required String issuer, required String subject})
    : key = _oidcKey(issuer: issuer, subject: subject);

  /// Stable database key for this namespace.
  final String key;

  static String _oidcKey({required String issuer, required String subject}) {
    if (issuer.trim().isEmpty) {
      throw ArgumentError.value(issuer, "issuer", "Must not be blank");
    }
    if (subject.trim().isEmpty) {
      throw ArgumentError.value(subject, "subject", "Must not be blank");
    }
    return "oidc:$issuer:$subject";
  }
}
