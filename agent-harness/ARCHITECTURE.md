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
- `sqlite3` through a local abstraction
- `hive_ce` and `hive_ce_flutter` through a local abstraction
- `flutter_lints` plus repo-specific lint rules

## Current Layout

```text
lib/
|-- auth/
|   |-- login_view.dart
|   |-- login_view_model.dart
|   |-- signup_view.dart
|   |-- signup_view_model.dart
|   |-- user.dart
|   `-- user_service.dart
|-- core/
|   |-- database_abstract.dart
|   |-- database_view.dart
|   |-- database_view_model.dart
|   |-- date_service.dart
|   |-- hive_abstract.dart
|   |-- locator.dart
|   `-- sqlite/
|-- pages/
|   `-- home/
|-- main.dart
`-- route.dart
```

## Dependency Direction

Use this direction for new work:

```text
View -> ViewModel -> Service -> Core Abstraction -> Platform Implementation
```

Rules:

- Views may depend on Flutter, localization, route state, and their view model.
- View models may depend on services and simple model types.
- Services may depend on core abstractions and model types.
- Core abstractions may depend on package APIs they wrap.
- Platform-specific implementations stay under `lib/core/` or a feature-local
  implementation folder.
- `lib/core/locator.dart` is the composition root for shared services.
- `lib/route.dart` is the routing composition point.

## Feature Shape

For a new feature, prefer a folder shaped like this:

```text
lib/<feature>/
|-- <feature>_view.dart
|-- <feature>_view_model.dart
|-- <feature>_service.dart
`-- <feature>_model.dart
```

Use subfolders only when the feature grows enough that file names stop being
self-explanatory.

## Persistence

SQLite is currently used for users and sessions through
`DatabaseAbstraction`. SQL statements should use parameter binding for runtime
values.

Hive is wrapped by `HiveDatabaseAbstraction`. Keep direct Hive access behind
that abstraction unless a plan explicitly changes the persistence boundary.

## Routing

Routes are declared in `RouterService` in `lib/route.dart`. Authentication
redirects are based on `UserService.userNotifier`.

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
- No navigation side effects inside persistence abstractions.
- No service lookup hidden inside model types.
- No broad refactors without an execution plan.
- No new global mutable state outside the dependency injection boundary.

## Known Gaps

- Import direction is documented but not mechanically enforced.
- Widget key strategy is not defined yet.
- Product strings are not consistently localized.
- Database schema ownership is still embedded in `main.dart`.

Track follow-up work in `exec-plans/tech-debt-tracker.md`.
