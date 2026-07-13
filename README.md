# MVVM Starter

A Flutter starter that demonstrates constructor-injected MVVM, go_router,
typed REST and GraphQL transports, Drift-backed persistence, secure native OIDC,
localized UI, and lifecycle-safe asynchronous state.

Current verification status: `release pending`. Local checks are described
below, but no production issuer, signed release, store release, or real-device
matrix has been verified.

## Requirements

- Flutter 3.44.6 stable
- Dart 3.12.2, bundled with Flutter 3.44.6
- Platform toolchains for the targets you intend to build

Verify the toolchain and resolve exactly the committed lockfile:

```bash
flutter --version
flutter pub get --enforce-lockfile
```

## Run The Anonymous Examples

The starter defaults to public HTTPS endpoints:

- REST: `https://jsonplaceholder.typicode.com/posts`
- GraphQL: `https://countries.trevorblades.com/`

Run without OIDC configuration:

```bash
flutter run
```

To use other HTTPS endpoints:

```bash
flutter run \
  --dart-define=REST_POSTS_URL=https://api.example.com/posts \
  --dart-define=GRAPHQL_URL=https://api.example.com/graphql
```

HTTP is rejected except for localhost test endpoints. Create or log in with a
local name to pass the starter's route gate, then open Network examples. Local
name auth is a demo workflow, not a credential or authorization boundary.

## Configure Native OIDC

Interactive authorization-code login with PKCE is supported on Android, iOS,
and macOS. Web, Windows, and Linux keep anonymous REST/GraphQL support but show
a deterministic unsupported state for interactive OIDC.

Register these exact callbacks in the provider's native/public client:

- Sign-in: `mvvmstarter:/oauthredirect`
- Post-logout: `mvvmstarter:/logout`

Then run a native target with provider values:

```bash
flutter run \
  --dart-define=OIDC_ISSUER=https://identity.example.com \
  --dart-define=OIDC_CLIENT_ID=mvvm-starter-native \
  --dart-define=OIDC_REDIRECT_URI=mvvmstarter:/oauthredirect \
  --dart-define=OIDC_POST_LOGOUT_REDIRECT_URI=mvvmstarter:/logout \
  --dart-define='OIDC_SCOPES=openid profile email offline_access'
```

The callback scheme is registered in:

- Android: `android/app/build.gradle` through `appAuthRedirectScheme`
- iOS: `ios/Runner/Info.plist`
- macOS: `macos/Runner/Info.plist`

OIDC access, refresh, and ID tokens are held only by the secure token-store
adapter. They are never written to Drift, preferences, restoration state, logs,
or UI. The session manager refreshes expiring tokens with single-flight
coordination and the shared HTTP executor performs at most one forced refresh
and one replay after a 401. Logout clears secure local state first; provider
end-session failure can therefore produce a warning while the app remains
locally signed out.

The local name session and OIDC session are deliberately separate examples.
Production routing and roles must be based on a trusted identity provider and
backend policy, never on a display name.

## Architecture

The primary dependency paths are:

```text
View -> ViewModel -> Repository -> RemoteDataSource -> typed REST/GraphQL transport
View -> ViewModel -> Repository -> LocalDataSource -> Drift/SQLite
```

- Views render state, collect input, and invoke ViewModel commands.
- ViewModels own screen state, user actions, latest-request-wins guards, and
  lifecycle-safe publication.
- Repositories select remote-only or persisted behavior and map errors.
- Remote data sources validate payloads and map DTOs to domain models.
- Local data sources own scoped Drift transactions.
- `lib/app/di.dart` is the GetIt composition root.
- `lib/app/router.dart` is the go_router composition point.

Feature Views do not call GetIt or access Drift. The mechanical boundary check
enforces these rules.

## REST, GraphQL, And Offline Persistence

`lib/features/network_examples/` provides four independent screen sections:

- REST remote-only
- REST remote-first with scoped offline fallback
- GraphQL remote-only
- GraphQL remote-first with scoped offline fallback

Remote-only methods never read or write Drift. Persisted methods replace one
scope transactionally after a successful request. On a transport/network
failure they read only that scope and report `localFresh` for snapshots no
older than 15 minutes or `localStale` for older snapshots. Protocol,
authorization, and database failures remain typed and distinguishable.

Choose a data boundary deliberately:

| Requirement | Recommended boundary | Expected behavior |
| --- | --- | --- |
| Reloadable read-only content | Remote-only | No Drift access; show the remote error when unavailable. |
| Restart-safe offline reads | Remote-first + Drift snapshot | Replace on success; fall back to scoped fresh/stale data on network failure. |
| Disposable performance optimization | Cache-only layer | Apply an explicit TTL/ETag policy; never treat it as domain truth. |
| Offline writes and synchronization | Dedicated sync model | Add an outbox, remote/local IDs, versions, retry policy, and conflict resolution. Not implemented here. |

Anonymous snapshots use the `public` scope. After a validated OIDC login,
snapshots use `oidc:<issuer>:<subject>`. Existing schema-v3 rows migrate into
`public`, so upgrades preserve earlier example data without exposing one
identity's rows to another.

## Storage And Migration Compatibility

Drift owns schema version 4 under `lib/core/database/`. Migrations preserve
legacy users, retain one deterministic valid legacy session, enforce the
singleton session at the schema level, and move pre-scope network snapshots
into the public namespace.

The native database filename remains `radlofa_app` for migration continuity.
Do not rename it in an existing application's upgrade path: doing so creates a
new database and strands existing user data. A new product fork may choose a
different filename only before release, or after implementing and testing an
explicit file migration.

Flutter restoration is only for ephemeral UI state such as login/signup text.
Tokens, users, sessions, settings, and domain records do not belong there.

## Generated Files

Regenerate committed Drift and web runtime outputs with:

```bash
dart run build_runner build --delete-conflicting-outputs --build-filter=lib/core/database/app_database.g.dart
dart run drift_dev schema dump lib/core/database/app_database.dart drift_schemas/schema_v4.json
dart run tool/update_drift_web_assets.dart
git diff --exit-code -- lib/core/database/app_database.g.dart drift_schemas web/drift_worker.js web/sqlite3.wasm
```

`update_drift_web_assets.dart` downloads the pinned SQLite WebAssembly asset,
verifies its SHA-256, and rebuilds the committed Drift worker.

## Verification And Builds

Run the same quality gates used by CI:

```bash
dart format --output=none --set-exit-if-changed lib test integration_test tool
dart run tool/check_agent_harness_links.dart
dart run tool/check_mvvm_boundaries.dart
dart run tool/check_platform_network_config.dart
dart run tool/verify_flutter_tests.dart
flutter analyze
```

Representative platform builds:

```bash
flutter build web --release
flutter build apk --release
flutter build ios --simulator --no-codesign
flutter build macos --release
flutter build linux --release
flutter build windows --release
```

Each command requires its native toolchain. CI defines independent quality,
Android, Apple, Linux, and Windows jobs; it does not sign or publish artifacts.

## Renaming A Product Fork

Before a first release, review all of these together:

- Android application ID and Kotlin package/path
- iOS and macOS bundle identifiers, including test targets
- Android, iOS, and macOS display names
- OIDC callback scheme in Dart defines, Android Gradle, both Apple plists, and
  provider registration
- secure-storage/keychain access groups and signing entitlements
- database filename and migration strategy

Changing an identifier or callback after release also requires provider,
signing, upgrade, and secure-storage compatibility validation. Keep
`radlofa_app` unchanged when preserving this starter's existing installations.

## Repository Map

```text
lib/
|-- app/                 # bootstrap, configuration, DI, routing
|-- core/
|   |-- database/        # Drift schema, migrations, connection
|   |-- network/         # typed HTTP/GraphQL transport
|   |-- restoration/     # ephemeral UI restoration helpers
|   `-- result/          # Result and UI state
`-- features/
    |-- auth/
    |-- debug_database/
    |-- home/
    `-- network_examples/
```

Repo-local agent instructions live in `AGENTS.md`; durable architecture,
quality, reliability, security, product, and execution context lives under
`docs/agent-harness/`.
