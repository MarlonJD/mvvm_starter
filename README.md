# MVVM Starter

A Flutter starter app that demonstrates a professional MVVM architecture with
constructor-injected ViewModels, GetIt composition, go_router navigation,
Drift-backed SQLite persistence, typed results/errors, and Flutter restoration
for short-lived UI state.

## Architecture

The main dependency flow is:

```text
View -> ViewModel -> Repository -> LocalDataSource -> Drift/SQLite
```

- Views render UI, collect input, show feedback, and call route APIs.
- ViewModels own screen state and user actions.
- Repositories own domain behavior and error mapping.
- Local data sources own database access.
- Drift owns schema, constraints, migrations, and generated data classes.

GetIt is kept because it is small and explicit for a starter app, but it is
limited to `lib/app/di.dart` and route/view factory composition. Feature Views
do not call the service locator.

Riverpod is intentionally not the main dependency. This starter teaches a
plain MVVM shape with lightweight dependency injection instead of mixing state
management architectures.

## Project Layout

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
`-- features/
    |-- auth/
    |-- debug_database/
    |-- home/
    `-- network_examples/
```

Create new features under `lib/features/<feature>/` with `data/`, `domain/`,
and `presentation/` folders when the feature has persistence/domain behavior.
Keep small UI-only examples under `presentation/` until they need more layers.

## Routing

Routes live in `lib/app/router.dart` and route constants live in
`lib/app/routes.dart`. The app uses go_router only; do not add
`MaterialPageRoute` pushes for app routes.

Auth redirects are based on `AuthRepository.activeUser`:

- unauthenticated protected routes redirect to `/login`;
- unauthenticated `/login` and `/signup` are allowed;
- authenticated `/login` and `/signup` redirect to `/`.

The authenticated `/network-examples` route demonstrates REST and GraphQL data
access patterns.

## Storage

SQLite through Drift is the canonical store for app/domain data. The current
schema has `users`, singleton `app_sessions`, and small persisted network
example tables with uniqueness, foreign keys where applicable, timestamps, and
a single active session guarantee.

Drift/SQLite is not the default place for every piece of app content. Use it
when data is durable domain state, offline-first data, relational/query-heavy
data, or data that needs migrations and constraints. Content that is simply
fetched from a remote API can stay behind a repository and remote data source
until offline behavior, search, sync, or durable local state is required.

## REST, GraphQL, And OIDC Examples

`lib/features/network_examples/` shows four live network flows:

- REST remote-only: fetches JSONPlaceholder posts and renders the response.
- REST persisted: fetches posts, writes a Drift snapshot, then renders local
  rows.
- GraphQL remote-only: fetches Countries API data and renders the response.
- GraphQL persisted: fetches countries, writes a Drift snapshot, then renders
  local rows.

The same folder includes a small OIDC boundary example. `OidcAuthorization`
turns an `OidcTokenProvider` into REST or GraphQL headers, refreshes expired
access tokens before use, and delegates logout to the provider adapter. A real
OIDC login is intentionally not wired without issuer/client/redirect
configuration and an approved secure token storage policy.

Use remote-only for content that can be reloaded. Use Drift persistence when
offline reads, app restart durability, local queries, constraints, migrations,
or sync boundaries are real product requirements. For offline writes, add a
sync model with dirty flags, remote ids, versioning, retry queues, and conflict
resolution instead of treating SQLite as a simple response cache.

Hive is not included by default. Reintroduce it only for a documented
cache-only use case where Drift is not the source of truth.

`shared_preferences` should be used only for tiny primitive preferences if a
settings example is added, such as theme mode or onboardingSeen. Do not store
users, sessions, tokens, domain records, or lists there.

## Restoration

Flutter restoration is used only for short-lived UI state, such as login and
signup text fields. Restoration is not persistence and must not store users,
sessions, tokens, settings, or domain data.

Views using restoration call `registerRestorableProperties` on their ViewModel
from `restoreState`. ViewModels expose safe listenables and controlled actions
instead of mutable state objects.

## Tests

Common commands:

```bash
flutter analyze
flutter test
dart run build_runner build --delete-conflicting-outputs --build-filter=lib/core/database/app_database.g.dart
```

Coverage is generated only when needed:

```bash
flutter test --coverage
```

The test suite includes examples for database constraints/migration,
repositories, ViewModels, router redirects, widget flows, localization key
parity, network persistence boundaries, OIDC token headers, and restoration.

## Agent Harness

Repo-local agent instructions live in `AGENTS.md`; deeper durable context lives
under `docs/agent-harness/`. Update harness design docs or execution plans when
an architecture decision changes.
