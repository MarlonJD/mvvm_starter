# Quality

## Default Gates

Use the narrowest verification that proves the change.

```bash
flutter pub get --enforce-lockfile
flutter analyze
dart run tool/verify_flutter_tests.dart
```

The wrapper forwards `flutter test --machine`, preserves its exit code, and
also fails when Flutter reports zero non-synthetic test starts. A focused
`flutter test <path>` remains the preferred inner loop while implementing a
change.

Use coverage when requested, when a change is broad, or when the risk profile
needs a coverage artifact.

```bash
flutter test --coverage
```

## Test Strategy

### Views

- Use widget tests for visible state, user actions, navigation-sensitive UI,
  and interaction with view models.
- Prefer stable finders. Add keys for important controls when text is
  localized or ambiguous.

### View Models

- Test state transitions and service calls with fakes.
- Keep Flutter widget concerns out of view model tests unless the type requires
  Flutter primitives such as `ValueNotifier`.

### Services

- Test business behavior with fake persistence abstractions.
- Cover error paths that can be caused by user input, persistence state, or
  external package behavior.

### Persistence

- Use parameterized SQL for runtime values.
- Add tests around schema changes and data migration behavior when schema moves
  out of `main.dart`.
- Use in-memory Drift databases for repository, migration, and schema tests.
- Use file-backed reopen tests when restart survival is part of the contract.

## Mechanical Gates

Run these before broad verification:

```bash
dart run tool/check_agent_harness_links.dart
dart run tool/check_mvvm_boundaries.dart
dart run tool/check_platform_network_config.dart
```

The boundary checker keeps service location and persistence out of feature
Views, keeps Drift out of ViewModels, and reserves application routing for
go_router. The platform checker validates network permissions and entitlements,
the pinned Drift web asset hash, native OIDC callbacks, and Keychain capability
configuration.

Generated output must be reproducible:

```bash
dart run build_runner build --delete-conflicting-outputs --build-filter=lib/core/database/app_database.g.dart
dart run drift_dev schema dump lib/core/database/app_database.dart drift_schemas/schema_v4.json
dart run tool/update_drift_web_assets.dart
git diff --exit-code -- lib/core/database/app_database.g.dart drift_schemas web/drift_worker.js web/sqlite3.wasm
```

## CI Matrix

`.github/workflows/flutter.yml` uses read-only permissions, immutable action
revisions, Flutter 3.44.6, and the committed lockfile:

- Ubuntu quality: format, docs links, MVVM boundaries, platform configuration,
  generated freshness, analysis, nonzero tests, and web release.
- Ubuntu Android: release APK.
- macOS: iOS simulator without signing and macOS release.
- Ubuntu Linux: release desktop build with GTK/libsecret dependencies.
- Windows 2022: release desktop build.

The workflow builds candidates only. It does not sign, upload, publish, or
establish production readiness.

### Router

- Cover auth redirects for unauthenticated and authenticated flows.
- Keep go_router route names and paths centralized in app route constants.
- Existing redirect and logout smoke coverage lives in
  `test/app/router_test.dart` and
  `test/features/home/presentation/home_view_test.dart`.

### Restoration

- Use widget tests with `tester.restartAndRestore()` for pages that register
  restorable ViewModel properties.
- Do not use restoration tests to prove domain persistence.

## Verification Labels

Use these exact labels in summaries and plan logs:

- `verified locally`: command or manual check completed in this environment.
- `not run`: verification was intentionally skipped.
- `blocked`: verification could not run because a dependency or permission was
  unavailable.
- `candidate-only`: change is plausible but not fully verified.
- `release pending`: local work is done but release evidence is missing.
- `production-ready`: production, release, or equivalent evidence exists.

## Done Criteria

A change is done when:

- The requested behavior or document exists.
- Relevant tests or static checks pass, or the reason they were not run is
  documented.
- Durable decisions are captured in `docs/agent-harness/`.
- Follow-up work is recorded in `exec-plans/tech-debt-tracker.md`.
- No unrelated user work was reverted.

## Future Mechanical Checks

These checks should be promoted from documentation to tooling:

- Maximum file size warnings for agent readability.
- Translation coverage check for supported locales.
- Secret scanning and dependency vulnerability auditing.
