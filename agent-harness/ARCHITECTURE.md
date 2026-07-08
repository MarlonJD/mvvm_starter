# Architecture

## Overview

This is a Flutter application using an MVVM-style structure. Views render UI,
view models coordinate user actions and state, services hold business behavior,
and core abstractions isolate persistence and runtime dependencies.

## Current Technology

- Flutter and Dart SDK `^3.6.1`
- `get_it` for dependency injection
- `go_router` for navigation
- `easy_localization` for localization
- Drift over SQLite for canonical app/domain persistence
- `flutter_lints` plus repo-specific lint rules

## Current Layout

```text
lib/
|-- app/
|   |-- app.dart
|   |-- bootstrap.dart
|   |-- di.dart
|   |-- router.dart
|   `-- routes.dart
|-- core/
|   |-- database/
|   |-- errors/
|   |-- restoration/
|   `-- result/
|-- features/
|   |-- auth/
|   |-- debug_database/
|   `-- home/
|-- main.dart
`-- route.dart
```

## Dependency Direction

Use this direction for new work:

```text
View -> ViewModel -> Repository -> LocalDataSource -> Drift/SQLite
```

Rules:

- Views may depend on Flutter, localization, route state, and their view model.
- View models may depend on repositories and simple model/result types.
- Repositories may depend on feature-local data sources and domain model types.
- Local data sources may depend on Drift database APIs.
- `lib/app/di.dart` is the composition root for shared dependencies.
- `lib/app/router.dart` is the routing composition point.
- `lib/core/locator.dart` and `lib/route.dart` are transitional exports only.

## Feature Shape

For a new feature, prefer a folder shaped like this:

```text
lib/features/<feature>/
|-- data/
|-- domain/
`-- presentation/
```

Use subfolders only when the feature grows enough that file names stop being
self-explanatory.

## Persistence

Drift owns the SQLite schema in `lib/core/database/app_database.dart`.
The starter stores users and active sessions in SQLite and enforces a singleton
active session with the `app_sessions` table.

Hive is removed from the default starter. `shared_preferences` is not used for
domain data and should only be added for tiny primitive preferences if a
settings example is implemented.

## Routing

Routes are declared in `RouterService` in `lib/app/router.dart`.
Authentication redirects are based on `AuthRepository.activeUser`.

When adding routes:

- Keep route paths stable and simple.
- Add tests for redirect-sensitive flows.
- Keep auth decisions in services or router composition, not scattered across
  widgets.

## Localization

The app uses `easy_localization` with translations under
`assets/translations/`.

When adding user-facing copy:

- Prefer translation keys over hard-coded strings in product UI.
- Keep test-only strings local to tests.
- Update both supported locales when a product string is added.

## Architectural Invariants

- No direct persistence package calls from views.
- No direct service locator calls from feature Views.
- No navigation side effects inside persistence or repository layers.
- No service lookup hidden inside model types.
- No broad refactors without an execution plan.
- No new global mutable state outside the dependency injection boundary.
- Use go_router for app navigation.
- Store app/domain data in Drift/SQLite.
- Use Flutter restoration only for ephemeral UI state.

## Known Gaps

- Import direction is documented but not mechanically enforced.
- Widget key strategy is not defined yet.
- Product strings are localized for the main starter flows, but enforcement is
  only covered by key parity tests.

Track follow-up work in `exec-plans/tech-debt-tracker.md`.
