# Quality

## Default Gates

Use the narrowest verification that proves the change.

```bash
flutter analyze
flutter test
```

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
- Durable decisions are captured in `agent-harness/`.
- Follow-up work is recorded in `exec-plans/tech-debt-tracker.md`.
- No unrelated user work was reverted.

## Future Mechanical Checks

These checks should be promoted from documentation to tooling:

- Import direction validation for MVVM layers.
- Maximum file size warnings for agent readability.
- Translation coverage check for supported locales.
- Route smoke tests for authentication redirects.
- Documentation link check for `agent-harness/`.
