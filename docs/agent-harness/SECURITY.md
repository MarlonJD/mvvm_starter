# Security

## Security Posture

This is a starter Flutter app. Security rules should stay practical and become
mechanical only when the behavior exists in code.

## Rules

- Never commit secrets, tokens, private keys, or machine-specific credentials.
- Do not log personal data, session identifiers, or raw persistence rows.
- Keep SQL access behind Drift data sources and repositories.
- Keep authentication and session behavior in `AuthRepository` and route
  composition.
- Treat local name signup/login as a demo route gate only. Never derive a role
  or authorization decision from a name.
- Derive production identity and roles from a validated provider plus trusted
  backend policy.
- Keep access, refresh, and ID tokens only in the secure OIDC token store; do
  not put them in Drift, preferences, restoration, logs, errors, or rendered
  UI.
- Scope persisted private network snapshots by validated OIDC issuer and
  subject. Anonymous snapshots use the separate `public` namespace.
- Clear secure local OIDC state before provider end-session. A remote
  end-session failure may surface a warning but must not restore the local
  session.
- Avoid direct persistence access from views.
- Treat dependency updates as behavior changes when they touch persistence,
  routing, auth, localization, or build tooling.
- Commit required Drift and web runtime output and verify its freshness in CI.
- Run `dart run tool/check_platform_network_config.dart` after changing native
  networking, callbacks, secure storage, or web database assets.

## Current Risk Notes

- Name-based local auth is a starter demonstration, not a security boundary.
- Interactive OIDC is native-only and has no production issuer/client
  configuration in the repository.
- No production provider, backend role policy, signed release, or real-device
  OIDC flow has been verified.
- Database schema and migrations live in Drift.
- No secret scanning or dependency audit command is documented.
- No threat model exists for production use.

## Escalation

Ask the human before:

- adding external auth,
- changing credential storage,
- publishing packages,
- connecting to hosted services,
- adding analytics or telemetry,
- changing release signing or platform entitlements.
