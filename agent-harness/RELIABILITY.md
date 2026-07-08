# Reliability

## Goal

Make the app easy for agents to run, inspect, and verify without relying on
implicit human knowledge.

## Current Local Signals

- Static analysis through `flutter analyze`.
- Unit and widget tests through `flutter test`.
- Coverage through `flutter test --coverage`.
- Runtime routing through `go_router`.
- User/session state through `UserService.userNotifier`.

## Runtime Readability Rules

- Important flows should have tests before being refactored.
- Important UI controls should have stable keys when text finders are fragile.
- Errors should include enough context for a future agent to identify the
  failing boundary.
- Long-running async work should be awaitable or explicitly documented.
- Avoid fire-and-forget behavior unless the lifecycle is clear.

## Logging

The repo currently has no structured logging layer. Until one exists:

- Do not add noisy `debugPrint` calls without a plan.
- Prefer test assertions over logs for verification.
- Avoid logging personal data, tokens, session identifiers, or raw database
  rows.

## Smoke Test Targets

The first smoke tests should cover:

- App boots with localization initialized.
- Unauthenticated users redirect to `/login`.
- Authenticated users can reach `/`.
- Logout clears the session and returns the expected UI state.

## Future Harness Work

- Add a documented command for running the app on the preferred local target.
- Add browser or simulator UI automation for the core auth flow.
- Add screenshots or videos as optional evidence for visual behavior changes.
- Add a small diagnostics document for common Flutter, SQLite, Hive, and
  localization failures.
