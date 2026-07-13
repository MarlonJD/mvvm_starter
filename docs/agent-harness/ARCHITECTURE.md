# Architecture

## Overview

This Flutter 3.44.6/Dart 3.12.2 starter uses MVVM as its primary architecture.
Views render and forward interaction, ViewModels own observable screen state,
repositories select product policy, and typed data sources isolate Drift,
REST, GraphQL, and native OIDC.

## Current Technology

- GetIt at the app composition root
- go_router for application navigation
- easy_localization for English and Turkish UI
- Drift/SQLite schema version 4 for durable app/domain state
- package:http behind typed REST and GraphQL executors
- flutter_appauth for native authorization-code + PKCE
- flutter_secure_storage behind the OIDC token-store interface

## Current Layout

```text
lib/
|-- app/
|   |-- app.dart
|   |-- app_config.dart
|   |-- bootstrap.dart
|   |-- di.dart
|   |-- router.dart
|   `-- routes.dart
|-- core/
|   |-- database/
|   |-- errors/
|   |-- network/
|   |-- restoration/
|   `-- result/
|-- features/
|   |-- auth/
|   |-- debug_database/
|   |-- home/
|   `-- network_examples/
`-- main.dart
```

`lib/app/di.dart` is the only service-location composition root.
`lib/app/router.dart` is the route composition point. Legacy
`lib/core/locator.dart` and `lib/route.dart` files are compatibility exports,
not locations for new implementation.

## Dependency Direction

```text
View -> ViewModel -> Repository -> RemoteDataSource -> typed transport -> API
View -> ViewModel -> Repository -> LocalDataSource -> Drift/SQLite
```

- Views may depend on Flutter, localization, route APIs, domain presentation
  types, and their constructor-injected ViewModel.
- ViewModels may depend on repositories and simple domain/result types.
- Repositories own remote-only, persisted-read, scope, and error-mapping policy.
- Remote data sources validate envelopes/DTOs and return domain models.
- Local data sources own parameterized Drift queries and transactions.
- GetIt calls stay under `lib/app/`; feature code receives dependencies.
- go_router is the only application routing mechanism.

`dart run tool/check_mvvm_boundaries.dart` mechanically checks the most
important import, service-location, restoration, and route-bypass rules.

## Remote Flow

The REST and GraphQL examples share one timeout-bounded HTTP executor:

```text
NetworkExamplesView
  -> NetworkExamplesViewModel
  -> NetworkExamplesRepository
  -> RestPostsRemoteDataSource / GraphqlCountriesRemoteDataSource
  -> HttpRequestExecutor / GraphqlRequestExecutor
  -> configured HTTPS endpoint
```

The executor injects a bearer header when an OIDC session exists, maps timeout,
transport, status, payload, and GraphQL errors, and performs at most one forced
refresh plus one replay after a 401. GraphQL documents and DTO parsing stay in
the data layer; Views never receive response maps.

## Offline-Read Flow

Persisted examples are remote-first:

```text
remote success
  -> replace selected Drift scope in one transaction
  -> return DataOrigin.remote

network failure
  -> read the same selected scope
  -> return localFresh (age <= 15 minutes) or localStale
  -> return original network failure when no snapshot exists
```

Remote-only operations do not touch Drift. Persisted REST keys are
`{scope_key, id}`; persisted GraphQL keys are `{scope_key, code}`.
Anonymous data uses `public`. A validated OIDC session uses
`oidc:<issuer>:<subject>`, captured at request start so an identity change
cannot redirect an in-flight write or fallback read.

Offline writes, an outbox, synchronization, and conflict resolution are not
implemented. A product that accepts offline edits needs a separate sync model.

## Authentication Flows

Local name auth stores users and one schema-enforced app session in Drift. It
exists to demonstrate signup, login, routing, logout, and migration behavior;
it is not a credential, role, or production authorization boundary.

Native OIDC is a separate example:

```text
OidcExampleView
  -> OidcExampleViewModel
  -> OidcSessionManager
  -> AppAuthOidcClient -> provider
  -> OidcTokenStore -> platform secure storage
```

The AppAuth adapter validates issuer and subject claims from the returned ID
token before publishing identity-scoped state. The session manager restores
tokens, coordinates a single refresh, atomically replaces rotated tokens, and
clears secure local storage before provider end-session. Remote end-session may
return a warning while local sign-out remains complete.

Access, refresh, and ID tokens never enter Drift, preferences, restoration,
logs, errors, or rendered UI.

## OIDC Support Matrix

| Platform | Anonymous REST/GraphQL | Drift | Interactive AppAuth OIDC |
| --- | --- | --- | --- |
| Android | Supported | Supported | Supported when configured |
| iOS | Supported | Supported | Supported when configured |
| macOS | Supported | Supported | Supported when configured |
| Web | Supported | Supported | Unsupported |
| Windows | Supported | Supported | Unsupported |
| Linux | Supported | Supported | Unsupported |

No production issuer/client, provider policy, or real-device flow is verified.

## Persistence And Migration

Drift schema and migrations live under `lib/core/database/`. The current
schema preserves legacy users, deterministically keeps one valid legacy
session, enforces a singleton session row, and migrates pre-scope network rows
into `public`.

The native filename remains `radlofa_app` for migration continuity. Renaming
it without a tested file migration would strand existing user data.

Restoration is only for ephemeral UI input. It must not contain domain records,
sessions, tokens, repositories, or database types.

## Async Lifecycle

Async ViewModels use monotonically increasing operation generations and a
synchronous disposed guard. Every post-await publication must belong to the
latest generation. Views check `context.mounted` after awaits, refresh controls
are disabled for the active load, and owned stream subscriptions are cancelled
before notifiers are disposed.

## Routing And Localization

Routes and names live in `lib/app/router.dart` and `lib/app/routes.dart`.
Redirects observe `AuthRepository.activeUser`; unauthenticated protected
routes go to `/login`, while authenticated users leave login/signup for home.

User-facing strings use translation keys from `assets/translations/`. Update
both locales together.

## Known Release Gaps

- Production OIDC provider and backend role policy are unverified.
- Native OIDC has not been exercised on real Android, iOS, or macOS devices.
- Structured diagnostics/observability is not implemented.
- Signing, packaging, store distribution, and the CI workflow have no release
  evidence yet.

Track these in `exec-plans/tech-debt-tracker.md`.
