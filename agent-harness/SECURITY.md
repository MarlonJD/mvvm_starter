# Security

## Security Posture

This is a starter Flutter app. Security rules should stay practical and become
mechanical only when the behavior exists in code.

## Rules

- Never commit secrets, tokens, private keys, or machine-specific credentials.
- Do not log personal data, session identifiers, or raw persistence rows.
- Use SQL parameter binding for runtime values.
- Keep authentication and session behavior in `UserService` and route
  composition.
- Avoid direct persistence access from views.
- Treat dependency updates as behavior changes when they touch persistence,
  routing, auth, localization, or build tooling.
- Keep generated files out of source control unless they are required for
  reproducible builds or agent-readable context.

## Current Risk Notes

- Session handling is simple and local-only.
- Database schema creation currently lives in `main.dart`.
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
