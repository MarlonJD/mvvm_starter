# Agent Instructions

This file is the short map for agentic work in this repository. Keep it small.
Deep context lives under `docs/agent-harness/`.

## Read Order

1. Start with `docs/agent-harness/README.md` for the harness map.
2. Read `docs/agent-harness/ARCHITECTURE.md` before changing app structure.
3. Read `docs/agent-harness/QUALITY.md` before changing behavior or tests.
4. Read the relevant `docs/agent-harness/product-specs/` file before changing product behavior.
5. For multi-step work, create or update an execution plan in
   `docs/agent-harness/exec-plans/active/`.

## Repository Snapshot

- App type: Flutter application.
- Language: Dart, SDK `^3.6.1`.
- Architecture: MVVM-style views and view models, with services behind
  injected abstractions.
- Routing: `go_router` through `lib/route.dart`.
- Dependency injection: `get_it` through `lib/core/locator.dart`.
- Localization: `easy_localization` using `assets/translations/`.
- Persistence: SQLite through `lib/core/database_abstract.dart` and Hive
  through `lib/core/hive_abstract.dart`.
- Linting: `flutter_lints` plus repo-specific rules in
  `analysis_options.yaml`.

## Working Rules

- Make the smallest change that satisfies the request.
- State assumptions when they affect behavior, architecture, or verification.
- Prefer existing patterns over new abstractions.
- Touch only files required for the task.
- Do not clean up unrelated code unless the user asks.
- Keep user changes intact; never revert unowned work.
- Use package imports for Dart files, matching the repo lint rules.
- Put durable decisions in `docs/agent-harness/`, not only in chat.

## Architecture Rules

- Keep UI widgets focused on rendering and user interaction.
- Keep state transitions and user actions in view models.
- Put domain behavior in services.
- Access external systems through abstractions in `lib/core/`.
- Register shared runtime dependencies in `lib/core/locator.dart`.
- Keep routing changes centralized in `lib/route.dart`.
- Keep translations in `assets/translations/` when user-facing strings need
  localization.

## Planning Rules

- Small mechanical changes may use an inline plan.
- Work that touches multiple files, product behavior, architecture, or testing
  gets an execution plan in `docs/agent-harness/exec-plans/active/`.
- Execution plans should include files, acceptance criteria, verification
  commands, decision log entries, and completion notes.
- When a plan is completed, move it to `docs/agent-harness/exec-plans/completed/`
  and leave a short completion note.
- Track known follow-up work in
  `docs/agent-harness/exec-plans/tech-debt-tracker.md`.

## Verification

Use the narrowest verification that proves the change.

- Static analysis: `flutter analyze`
- Unit and widget tests: `flutter test`
- Coverage when requested or risk is broad: `flutter test --coverage`

Report verification with literal labels:

- `verified locally`
- `not run`
- `blocked`
- `candidate-only`
- `release pending`
- `production-ready`

Do not call work production-ready without production, release, or equivalent
evidence.

## Review Standard

- Every changed line should trace to the user request or the active plan.
- Prefer simple code that a future agent can inspect quickly.
- If documentation is repeatedly insufficient, promote the rule into a lint,
  test, script, or other mechanical check.
- If an agent gets stuck, treat it as a harness gap: missing context, missing
  tool, missing test, missing invariant, or unclear acceptance criteria.
