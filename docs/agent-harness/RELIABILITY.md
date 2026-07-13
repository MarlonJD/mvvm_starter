# Reliability

## Goal

Make the app easy for agents to run, inspect, and verify without relying on
implicit human knowledge.

## Current Local Signals

- Static analysis through `flutter analyze`.
- Nonzero unit and widget test discovery through
  `dart run tool/verify_flutter_tests.dart`.
- Coverage through `flutter test --coverage`.
- Runtime routing through `go_router`.
- User/session state through `AuthRepository.activeUser`.
- Generated Drift code, schema snapshots, and web runtime freshness checks.
- Web, Android release, iOS simulator, macOS release, Linux release, and
  Windows release jobs defined in GitHub Actions. These jobs remain
  `candidate-only` until an external run supplies evidence.

## Runtime Readability Rules

- Important flows should have tests before being refactored.
- Important UI controls should have stable keys when text finders are fragile.
- Errors should include enough context for a future agent to identify the
  failing boundary.
- Long-running async work should be awaitable or explicitly documented.
- Avoid fire-and-forget behavior unless the lifecycle is clear.
- Async ViewModels use latest-generation and disposed guards before every
  post-await publication.
- Stream cancellation completes before owned notifiers are disposed.
- Persisted network reads capture one public/OIDC scope at request start and
  fall back only on network failures.
- Remote-only methods never read or write Drift.
- Local snapshot replacement is transactional and limited to one scope.

## Logging

The repo currently has no structured logging layer. Until one exists:

- Do not add noisy `debugPrint` calls without a plan.
- Prefer test assertions over logs for verification.
- Avoid logging personal data, tokens, session identifiers, or raw database
  rows.

## Covered Smoke Targets

- `integration_test/app_boot_smoke_test.dart` covers production web bootstrap.
- `test/app/router_test.dart` covers unauthenticated and authenticated route
  redirects.
- `test/features/home/presentation/home_view_test.dart` covers logout success
  and visible failure handling.
- File-backed repository tests close/reopen Drift and cover scoped offline
  fallback across restart.
- Lifecycle tests cover disposal, overlapping loads, and awaited stream
  cancellation.

## Release Boundaries

- Local unit/widget/static/build results are `verified locally` only.
- The GitHub Actions matrix is `not run` for uncommitted changes.
- Real-provider OIDC and real-device validation are `not run`.
- Missing Android SDK or managed SDK-cache permissions are reported as
  `blocked`, not silently bypassed.
- Status stays `release pending` until signed/release-equivalent evidence
  exists.

## Future Harness Work

- Add a documented command for running the app on the preferred local target.
- Add provider-backed real-device UI automation for native OIDC.
- Add screenshots or videos as optional evidence for visual behavior changes.
- Add a small diagnostics document for common Flutter, Drift/SQLite, and
  localization failures.
