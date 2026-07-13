# KILLCRITIC Remediation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Status:** completed

## Progress

- [x] Task 1: Pin the stable toolchain and dependency baseline.
- [x] Task 2: Preserve legacy data, enforce one session, and remove unsafe admin authority.
- [x] Task 3: Make network and Drift startup valid on every claimed platform (`blocked` local Android artifact verification: SDK absent).
- [x] Task 4: Add configurable typed REST and GraphQL transport.
- [x] Task 5: Add secure OIDC login, refresh, headers, and logout (iOS simulator `verified locally`; signed macOS release `blocked` by missing signing identity; unsigned compile `candidate-only`).
- [x] Task 6: Implement explicit offline reads and identity-scoped persistence.
- [x] Task 7: Harden async lifecycle and user-visible failure handling.
- [x] Task 8: Add mechanical architecture, test-truth, generation, and platform CI gates.
- [x] Task 9: Reconcile documentation, starter polish, and final evidence.

**Goal:** Remove the validated data-loss, schema, platform-network, offline, OIDC, lifecycle, CI, and documentation defects so this repository is a dependable MVVM starter for REST and GraphQL applications.

**Architecture:** Preserve the current `View -> ViewModel -> Repository -> RemoteDataSource/LocalDataSource` dependency direction. Repair persistence before adding new behavior, route every HTTP request through one typed executor, keep OIDC tokens in secure storage behind a single-flight session manager, and model offline reads as an explicit repository policy rather than an incidental SQLite write. Keep interactive OIDC provider integration native-only (Android, iOS, and macOS); anonymous REST/GraphQL and Drift remain supported on Android, iOS, macOS, Windows, Linux, and web.

**Tech Stack:** Flutter 3.44.6 stable, Dart 3.12.2, MVVM, GetIt at the composition root, go_router, Drift/SQLite, package:http, flutter_appauth, flutter_secure_storage, flutter_test, integration_test, and GitHub Actions.

## Global Constraints

- Work on the current branch. Do not create, switch, rename, or delete branches.
- Preserve user-owned changes. In particular, review and adopt the existing untracked `tool/check_agent_harness_links.dart` without replacing unrelated content.
- Before every commit, run `git status --short` and stage only files reviewed for that task. Directory pathspecs in commit snippets must be expanded to exact files when unrelated user changes exist.
- Keep GetIt calls inside `lib/app/` and compatibility exports only; feature Views receive constructor-injected ViewModels.
- Use go_router as the only application navigation mechanism.
- Keep Drift/SQLite as canonical durable domain storage; do not add Hive, ObjectBox, or Riverpod.
- Never store access tokens, refresh tokens, or ID tokens in Drift, shared_preferences, Flutter restoration, logs, or test snapshots.
- Use Flutter restoration only for ephemeral UI state.
- Keep all runtime SQL values parameterized.
- Add a failing test before each behavior change and run the focused test before the full suite.
- Commit generated Drift code and web worker output, but add mechanical freshness checks.
- Keep supported-platform claims explicit. Interactive AppAuth login is supported only on Android, iOS, and macOS in this plan.
- Report final evidence with the literal labels `verified locally`, `not run`, `blocked`, `candidate-only`, `release pending`, and `production-ready`. Do not use `production-ready` without release-equivalent evidence.

---

## Scope

- Preserve legacy users and one deterministic legacy session during the raw-SQL-to-Drift migration.
- Enforce one active session at the SQLite schema level.
- Remove client-created admin authority and the release delete-all action.
- Make Android release, sandboxed macOS, and web network/database startup valid.
- Add configurable, timeout-bounded, typed REST and GraphQL transport.
- Add a real AppAuth adapter, secure token storage, single-flight refresh, one 401 retry, and local-first logout.
- Make persisted REST and GraphQL examples work after restart and during network failure.
- Namespace persisted snapshots so private examples cannot leak across identities.
- Make async ViewModels safe under refresh overlap and disposal.
- Add CI gates for analysis, tests, nonzero discovery, generated output, architecture boundaries, web, Android release, and macOS release.
- Reconcile README, AGENTS.md, product specs, design docs, the active hardening roadmap, and the debt tracker.

## Non-Goals

- Shipping real issuer, client, redirect, or production secrets.
- Certifying a particular identity provider.
- Implementing offline writes, an outbox, conflict resolution, or bidirectional synchronization.
- Adding GraphQL subscriptions or generated GraphQL models.
- Publishing a store release or calling the result production-ready.
- Replacing MVVM, GetIt composition, go_router, Drift, easy_localization, or the Result/UiState types.

## Plan Relationship

This plan supersedes the unfinished portions of `2026-07-08-harness-hardening-roadmap.md`. Its final documentation task must mark that roadmap `superseded`, move it to `exec-plans/completed/`, and retain a note that the pre-existing link checker was incorporated rather than overwritten.

## Final File Map

### New runtime files

- `lib/app/app_config.dart` - environment-derived endpoint and OIDC configuration.
- `lib/core/network/network_exception.dart` - typed transport/protocol failure categories.
- `lib/core/network/authorization_header_provider.dart` - protocol-neutral bearer header contract.
- `lib/core/network/http_request_executor.dart` - timeout, status mapping, bearer injection, and one 401 retry.
- `lib/core/network/graphql_request_executor.dart` - GraphQL document, variables, operation name, data, and error envelope handling.
- `lib/features/auth/domain/oidc_configuration.dart` - validated native OIDC settings.
- `lib/features/auth/domain/oidc_sign_in_outcome.dart` - explicit completed or user-cancelled sign-in outcome.
- `lib/features/auth/domain/oidc_token_set.dart` - token model with optional rotated fields.
- `lib/features/auth/data/oidc_client.dart` - provider SDK boundary.
- `lib/features/auth/data/appauth_oidc_client.dart` - flutter_appauth adapter.
- `lib/features/auth/data/oidc_token_store.dart` - secure token persistence boundary.
- `lib/features/auth/data/flutter_secure_oidc_token_store.dart` - one-blob secure storage adapter.
- `lib/features/auth/data/oidc_session_manager.dart` - sign-in, restore, single-flight refresh, header, and logout orchestration.
- `lib/features/auth/presentation/oidc_example_view_model.dart` - OIDC example screen state and commands.
- `lib/features/auth/presentation/oidc_example_view.dart` - provider-configured sign-in/refresh/logout UI.
- `lib/features/network_examples/domain/persistence_scope.dart` - public or identity-scoped persistence key.
- `lib/features/network_examples/domain/persisted_result.dart` - data origin and freshness metadata.
- `web/drift_worker.dart` - Drift web worker source.
- `web/drift_worker.js` - generated worker consumed by the web app.
- `web/sqlite3.wasm` - pinned SQLite 3.3.4 WebAssembly asset.
- `ios/Runner/DebugProfile.entitlements` and `ios/Runner/Release.entitlements` - secure-storage Keychain capability.

### New verification files

- `drift_schemas/schema_v2.json`, `schema_v3.json`, and `schema_v4.json` - migration baselines.
- `test/core/network/http_request_executor_test.dart`.
- `test/features/auth/data/oidc_session_manager_test.dart`.
- `test/features/auth/data/flutter_secure_oidc_token_store_test.dart`.
- `test/features/auth/presentation/oidc_example_view_model_test.dart`.
- `test/platform/platform_configuration_test.dart`.
- `integration_test/app_boot_smoke_test.dart`.
- `tool/update_drift_web_assets.dart`.
- `tool/check_mvvm_boundaries.dart`.
- `tool/check_platform_network_config.dart`.
- `tool/verify_flutter_tests.dart`.
- `test/tool/check_agent_harness_links_test.dart`.
- `.github/workflows/flutter.yml`.

### Primary modified files

- `pubspec.yaml` and `pubspec.lock`.
- `lib/core/database/app_database.dart`, `app_database.g.dart`, and `migrations.dart`.
- Auth domain, data, ViewModel, and View files under `lib/features/auth/` and `lib/features/home/`.
- Network example domain, data, repository, ViewModel, and View files.
- `lib/app/di.dart`, `router.dart`, and `routes.dart`.
- Android, iOS, and macOS platform configuration.
- `analysis_options.yaml`.
- README and `docs/agent-harness/` documents.

---

### Task 1: Pin The Stable Toolchain And Dependency Baseline

**Files:**
- Modify: `pubspec.yaml`
- Modify: `pubspec.lock`
- Modify: `.metadata` only if `flutter pub get` performs an official Flutter migration
- Test: all existing tests

**Interfaces:**
- Consumes: Flutter 3.44.6 stable and Dart 3.12.2.
- Produces: the package versions used by every later task.

- [x] **Step 1: Record the pre-upgrade baseline**

Run:

~~~bash
flutter --version
flutter pub outdated
flutter analyze
flutter test
~~~

Expected: the first two commands record the environment and upgrade candidates; analysis succeeds and the existing suite reports 42 or more passing tests.

- [x] **Step 2: Update the SDK and direct dependency constraints**

Set the relevant `pubspec.yaml` sections to:

~~~yaml
environment:
  sdk: ^3.12.2

dependencies:
  cupertino_icons: ^1.0.9
  drift: ^2.34.1
  drift_flutter: ^0.3.1
  easy_localization: ^3.0.8
  flutter:
    sdk: flutter
  flutter_appauth: ^12.0.2
  flutter_secure_storage: ^10.3.1
  get_it: ^9.2.1
  go_router: ^17.3.0
  http: ^1.6.0
  path: ^1.9.1
  path_provider: ^2.1.6
  uuid: ^4.5.3

dev_dependencies:
  build_runner: ^2.15.1
  crypto: ^3.0.7
  drift_dev: ^2.34.3
  flutter_lints: ^6.0.0
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
~~~

Do not add shared_preferences directly.

- [x] **Step 3: Resolve and inspect the lockfile**

Run:

~~~bash
flutter pub upgrade
flutter pub deps --style=compact
flutter pub outdated
~~~

Expected: resolution succeeds on Dart 3.12.2, `flutter_appauth` and `flutter_secure_storage` are direct dependencies, and discontinued `build_resolvers`, `build_runner_core`, and `js` are absent unless a current direct package still requires them. If one remains, record the exact parent package in this plan's Decision Log before continuing.

- [x] **Step 4: Repair compile errors caused by supported major upgrades**

Limit this step to API migrations required by GetIt 9, go_router 17, Drift 2.34, flutter_lints 6, and drift_flutter 0.3. Do not change product behavior.

- [x] **Step 5: Verify the upgraded baseline**

Run:

~~~bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
~~~

Expected: PASS with no analyzer findings and no test regressions.

- [x] **Step 6: Commit (`not run`: commits are explicitly prohibited for this execution)**

~~~bash
git add pubspec.yaml pubspec.lock .metadata lib test
git commit -m "build: update Flutter dependency baseline"
~~~

---

### Task 2: Preserve Legacy Data, Enforce One Session, And Remove Unsafe Admin Authority

**Files:**
- Modify: `lib/core/database/app_database.dart`
- Modify: `lib/core/database/migrations.dart`
- Modify: `lib/core/database/app_database.g.dart`
- Modify: `lib/features/auth/domain/user.dart`
- Modify: `lib/features/auth/data/auth_local_datasource.dart`
- Modify: `lib/features/auth/data/auth_repository.dart`
- Modify: `lib/features/auth/presentation/signup_view_model.dart`
- Modify: `lib/features/home/presentation/home_view_model.dart`
- Modify: `lib/features/home/presentation/home_view.dart`
- Modify: `assets/translations/en-US.json`
- Modify: `assets/translations/tr-TR.json`
- Modify: `test/core/database/app_database_test.dart`
- Modify: `test/core/database/migration_test.dart`
- Modify: auth and home tests affected by removal of `isAdmin`
- Create: `drift_schemas/schema_v2.json`
- Create: `drift_schemas/schema_v3.json`

**Interfaces:**
- Consumes: legacy version-0 tables, current Drift schema version 2, and existing `User` behavior.
- Produces: schema version 3, `users` without client authority, and `app_sessions.id` as the singleton primary key.

- [x] **Step 1: Capture the authoritative version-2 schema**

Before editing `app_database.dart`, run:

~~~bash
mkdir -p drift_schemas
dart run drift_dev schema dump lib/core/database/app_database.dart drift_schemas/schema_v2.json
~~~

Expected: the snapshot reports schema version 2, `users.is_admin`, and `app_sessions` without a primary key. Commit this snapshot with the migration fix so future tests do not reconstruct version 2 from memory.

- [x] **Step 2: Write the failing singleton test**

Replace the current ambiguous test with a test that inserts two different users and attempts two `id = 1` sessions:

~~~dart
test("app_sessions rejects a second singleton row for another user", () async {
  final now = DateTime.utc(2026);
  final aliceId = await database.into(database.users).insert(
        UsersCompanion.insert(
          uid: "uid-alice",
          name: "alice",
          createdAt: now,
          updatedAt: now,
        ),
      );
  final bobId = await database.into(database.users).insert(
        UsersCompanion.insert(
          uid: "uid-bob",
          name: "bob",
          createdAt: now,
          updatedAt: now,
        ),
      );

  await database.into(database.appSessions).insert(
        AppSessionsCompanion.insert(
          id: 1,
          userId: aliceId,
          createdAt: now,
          updatedAt: now,
        ),
      );

  await expectLater(
    database.into(database.appSessions).insert(
          AppSessionsCompanion.insert(
            id: 1,
            userId: bobId,
            createdAt: now,
            updatedAt: now,
          ),
        ),
    throwsException,
  );
});
~~~

- [x] **Step 3: Write migration preservation tests**

In `migration_test.dart`, create legacy users `alice` and `bob`, duplicate one legacy name in a third row, create two legacy sessions, open `AppDatabase`, and assert:

- all three users survive;
- every migrated `uid` is non-empty and unique;
- the first unique name remains unchanged;
- a duplicate name becomes `<name> [legacy-<id>]`;
- exactly one session survives, selecting the legacy session with the greatest valid session id;
- `PRAGMA foreign_key_check` returns no rows.

Add a version-2 fixture with two legal `id = 1` session rows for different users and assert the version-3 migration deterministically keeps the row with the latest `updated_at`, then greatest `rowid`.

- [x] **Step 4: Run the focused tests and confirm failure**

Run:

~~~bash
flutter test test/core/database/app_database_test.dart
flutter test test/core/database/migration_test.dart
~~~

Expected: the singleton test fails because a second `id = 1` row is accepted; preservation tests fail because legacy tables are dropped.

- [x] **Step 5: Define the corrected schema**

Remove `Users.isAdmin`. Define `AppSessions.id` with both the fixed-value check and primary-key identity:

~~~dart
class AppSessions extends Table {
  IntColumn get id => integer().customConstraint(
        "NOT NULL CHECK (id = 1)",
      )();

  IntColumn get userId => integer()
      .named("user_id")
      .unique()
      .references(Users, #id, onDelete: KeyAction.cascade)();

  DateTimeColumn get createdAt => dateTime().named("created_at")();
  DateTimeColumn get updatedAt => dateTime().named("updated_at")();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
~~~

Set `schemaVersion => 3`. Remove `isAdmin` from `User` and every mapping/caller.

- [x] **Step 6: Replace destructive migration with deterministic conversion**

Implement these private helpers in `migrations.dart`:

~~~dart
Future<bool> tableExists(GeneratedDatabase database, String tableName);
String uniqueLegacyName(String rawName, int id, Set<String> usedNames);
Future<void> migrateLegacyVersionZero(
  GeneratedDatabase database,
  Migrator migrator,
);
Future<void> migrateVersionTwoToThree(GeneratedDatabase database);
Future<void> assertNoForeignKeyViolations(GeneratedDatabase database);
~~~

Required algorithm:

1. Detect legacy version-0 `users` before calling `createAll`.
2. Rename legacy tables to `legacy_users` and `legacy_sessions`.
3. Call `migrator.createAll()`.
4. Read legacy users ordered by id.
5. Preserve id and trimmed name when unique; use `legacy-user-<id>` for blank names and `<name> [legacy-<id>]` for duplicates, adding a numeric suffix only if that generated name is also occupied.
6. Store each legacy uid as `legacy:<id>:<old uid>` so malformed duplicate integer uids remain unique and traceable.
7. Set `created_at` and `updated_at` to one captured UTC migration timestamp, binding `migrationTimestamp.millisecondsSinceEpoch ~/ 1000` because the current integer Drift mapping stores Unix seconds.
8. Select the greatest legacy session id whose user survived and insert only `app_sessions.id = 1`.
9. Compare migrated and source user counts.
10. Run `PRAGMA foreign_key_check`.
11. Drop legacy tables only after all validations pass.
12. For version 2, rebuild `users` without `is_admin` and rebuild `app_sessions` with the primary key; preserve all users and keep one deterministic latest session.

Any failed validation must throw so Drift rolls back the migration.

- [x] **Step 7: Remove release authority and destructive UI**

Remove the `isAdmin` argument from `AuthRepository.createUser`. Delete `deleteAllUsers` from the local data source, repository, and HomeViewModel. Remove the Home delete-all control and both translation keys. Keep per-user deletion only in the debug-only database route.

- [x] **Step 8: Generate code and schema snapshot**

Run:

~~~bash
dart run build_runner build --delete-conflicting-outputs --build-filter=lib/core/database/app_database.g.dart
dart run drift_dev schema dump lib/core/database/app_database.dart drift_schemas/schema_v3.json
~~~

Expected: generated `AppSessions` reports `id` as its primary key and the schema snapshot contains no `is_admin` column.

- [x] **Step 9: Verify safety behavior**

Run:

~~~bash
flutter test test/core/database
flutter test test/features/auth
flutter test test/features/home
flutter analyze
~~~

Expected: PASS; migration tests prove row preservation and singleton enforcement.

- [x] **Step 10: Commit (`not run`: commits are explicitly prohibited for this execution)**

~~~bash
git add lib/core/database lib/features/auth lib/features/home assets/translations test/core/database test/features/auth test/features/home drift_schemas/schema_v2.json drift_schemas/schema_v3.json
git commit -m "fix: preserve auth data during Drift migration"
~~~

---

### Task 3: Make Network And Drift Startup Valid On Every Claimed Platform

**Files:**
- Modify: `android/app/src/main/AndroidManifest.xml`
- Modify: `macos/Runner/DebugProfile.entitlements`
- Modify: `macos/Runner/Release.entitlements`
- Modify: `lib/core/database/app_database_connection.dart`
- Create: `web/drift_worker.dart`
- Create: `web/drift_worker.js`
- Create: `web/sqlite3.wasm`
- Create: `tool/update_drift_web_assets.dart`
- Create: `test/platform/platform_configuration_test.dart`
- Create: `integration_test/app_boot_smoke_test.dart`

**Interfaces:**
- Consumes: Drift 2.34, sqlite3 3.3.4, and the existing database name `radlofa_app`.
- Produces: release-capable outbound networking and a web-capable Drift executor.

- [x] **Step 1: Write failing structural platform tests**

The host-side test must assert:

- the Android main manifest contains `android.permission.INTERNET`;
- both macOS entitlement files contain `com.apple.security.network.client = true`;
- `web/sqlite3.wasm` and `web/drift_worker.js` exist and are non-empty;
- the SHA-256 of `web/sqlite3.wasm` equals `cfab48c6bbb718552ec19bc4f1365e19185311b72e4739cc19ef7333758304d3`.

- [x] **Step 2: Run the structural test and confirm failure**

Run:

~~~bash
flutter test test/platform/platform_configuration_test.dart
~~~

Expected: FAIL for Android, macOS, and missing web assets.

- [x] **Step 3: Add release network permissions**

Add this directly below the Android manifest root:

~~~xml
<uses-permission android:name="android.permission.INTERNET"/>
~~~

Add this key/value to both macOS entitlement dictionaries:

~~~xml
<key>com.apple.security.network.client</key>
<true/>
~~~

- [x] **Step 4: Add reproducible Drift web assets**

Create `web/drift_worker.dart`:

~~~dart
import "package:drift/wasm.dart";

void main() {
  WasmDatabase.workerMainForOpen();
}
~~~

Implement `tool/update_drift_web_assets.dart` with these constants:

~~~dart
const sqliteVersion = "3.3.4";
const sqliteUri = "https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-3.3.4/sqlite3.wasm";
const sqliteSha256 =
    "cfab48c6bbb718552ec19bc4f1365e19185311b72e4739cc19ef7333758304d3";
~~~

The script must download to a temporary file, verify SHA-256 before replacing `web/sqlite3.wasm`, compile `web/drift_worker.dart` using `dart compile js -O4 -o web/drift_worker.js`, and exit nonzero on HTTP, hash, or compiler failure.

- [x] **Step 5: Configure Drift web without changing the native database name**

Use:

~~~dart
QueryExecutor openAppDatabaseConnection() {
  return driftDatabase(
    name: "radlofa_app",
    web: DriftWebOptions(
      sqlite3Wasm: Uri.parse("sqlite3.wasm"),
      driftWorker: Uri.parse("drift_worker.js"),
    ),
  );
}
~~~

Keeping `radlofa_app` is required for native migration continuity.

- [x] **Step 6: Generate assets and rerun structural tests** (assets generated manually with the pinned source/hash because the updater cannot be created without authorization)

Run:

~~~bash
dart run tool/update_drift_web_assets.dart
flutter test test/platform/platform_configuration_test.dart
~~~

Expected: PASS.

- [x] **Step 7: Add a real app boot smoke test** (verified through the installed SDK's documented `flutter drive` web path because `flutter test -d chrome` rejects integration-test targets)

The integration test must call the production `bootstrapApp` composition through a testable bootstrap entry, wait for either Login or Home, and fail on uncaught startup errors. It must not use an in-memory database on web.

Run:

~~~bash
flutter test integration_test/app_boot_smoke_test.dart -d chrome
~~~

Expected: PASS and no `DriftWebOptions` startup exception.

- [x] **Step 8: Build platform artifacts** (`blocked`: web and macOS release builds passed during Task 3; Android SDK is not installed)

Run:

~~~bash
flutter build web --release
flutter build apk --release
flutter build macos --release
~~~

Expected: all three builds succeed. Inspect the APK merged manifest and signed macOS entitlements to confirm the release artifacts contain the settings, not only source files.

- [x] **Step 9: Commit (`not run` for non-`tool/` files; only `tool/` commits are authorized)**

~~~bash
git add android/app/src/main/AndroidManifest.xml macos/Runner/DebugProfile.entitlements macos/Runner/Release.entitlements lib/core/database/app_database_connection.dart web tool/update_drift_web_assets.dart test/platform integration_test
git commit -m "fix: enable network persistence across platforms"
~~~

---

### Task 4: Add Configurable Typed REST And GraphQL Transport

**Files:**
- Create: `lib/app/app_config.dart`
- Create: `lib/core/network/network_exception.dart`
- Create: `lib/core/network/authorization_header_provider.dart`
- Create: `lib/core/network/http_request_executor.dart`
- Create: `lib/core/network/graphql_request_executor.dart`
- Modify: `lib/core/errors/app_error.dart`
- Create: `lib/features/network_examples/data/network_example_dtos.dart`
- Modify: `lib/features/network_examples/data/network_examples_remote_data_sources.dart`
- Modify: `lib/features/network_examples/data/network_examples_repository.dart`
- Modify: `lib/app/di.dart`
- Create: `test/core/network/http_request_executor_test.dart`
- Add remote data source parsing tests under `test/features/network_examples/data/`

**Interfaces:**
- Consumes: package:http and optional `AuthorizationHeaderProvider`.
- Produces: `AppConfig`, `NetworkException`, and `HttpRequestExecutor` used by REST, GraphQL, and OIDC.

- [x] **Step 1: Write failing transport tests**

Using `MockClient`, cover:

- REST base URI and query parameters come from `AppConfig`;
- every request times out after the injected duration;
- 400, 401, 403, 429, and 500 map to distinct `NetworkExceptionKind` values;
- malformed REST JSON maps to `invalidPayload`;
- GraphQL HTTP 200 with a non-empty `errors` list maps to `graphql`;
- GraphQL variables and an optional operation name are serialized into the request envelope;
- GraphQL success returns a typed `Map<String, Object?>` data object rather than exposing the full response envelope;
- a database exception in a persisted repository method maps to `AppErrorType.database`, never `network`;
- a request without an authorization provider sends no Authorization header.

- [x] **Step 2: Run focused tests and confirm failure**

Run:

~~~bash
flutter test test/core/network
flutter test test/features/network_examples/data
~~~

Expected: FAIL because configuration and typed transport do not exist.

- [x] **Step 3: Add environment-derived configuration**

Define:

~~~dart
final class AppConfig {
  const AppConfig({
    required this.restPostsUri,
    required this.graphqlUri,
    required this.requestTimeout,
  });

  factory AppConfig.fromEnvironment() {
    return AppConfig(
      restPostsUri: Uri.parse(
        const String.fromEnvironment(
          "REST_POSTS_URL",
          defaultValue: "https://jsonplaceholder.typicode.com/posts",
        ),
      ),
      graphqlUri: Uri.parse(
        const String.fromEnvironment(
          "GRAPHQL_URL",
          defaultValue: "https://countries.trevorblades.com/",
        ),
      ),
      requestTimeout: const Duration(seconds: 15),
    );
  }

  final Uri restPostsUri;
  final Uri graphqlUri;
  final Duration requestTimeout;
}
~~~

Validate that both URIs use HTTPS unless a test injects localhost.

- [x] **Step 4: Add transport contracts**

Define these exact categories:

~~~dart
enum NetworkExceptionKind {
  timeout,
  transport,
  badRequest,
  unauthorized,
  forbidden,
  rateLimited,
  server,
  invalidPayload,
  graphql,
}
~~~

Add `AppErrorType.unauthorized` and `AppError.unauthorized(String messageKey, {Object? cause})` so repositories and ViewModels can distinguish re-authentication from generic connectivity failures.

Define:

~~~dart
abstract interface class AuthorizationHeaderProvider {
  Future<Result<String?>> authorizationHeader({
    bool forceRefresh = false,
  });
}
~~~

`HttpRequestExecutor` must expose `Future<http.Response> get(Uri)` and `Future<http.Response> postJson(Uri, Object?)`, apply the configured timeout, decode no feature-specific models, attach a bearer value returned by the provider, and retry exactly once after a 401 by requesting `forceRefresh: true`. It must never retry a second 401 or any non-401 response.

- [x] **Step 5: Add the GraphQL envelope executor**

Define:

~~~dart
abstract interface class GraphqlRequestExecutor {
  Future<Map<String, Object?>> execute({
    required Uri uri,
    required String document,
    Map<String, Object?> variables = const {},
    String? operationName,
  });
}

final class HttpGraphqlRequestExecutor implements GraphqlRequestExecutor {
  const HttpGraphqlRequestExecutor(this._http);

  final HttpRequestExecutor _http;

  @override
  Future<Map<String, Object?>> execute({
    required Uri uri,
    required String document,
    Map<String, Object?> variables = const {},
    String? operationName,
  }) async {
    final body = <String, Object?>{
      "query": document,
      "variables": variables,
      if (operationName != null) "operationName": operationName,
    };
    final response = await _http.postJson(uri, body);
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, Object?>) {
      throw const NetworkException.invalidPayload("graphql.envelope");
    }
    final errors = decoded["errors"];
    if (errors is List<Object?> && errors.isNotEmpty) {
      throw const NetworkException.graphql();
    }
    final data = decoded["data"];
    if (data is! Map<String, Object?>) {
      throw const NetworkException.invalidPayload("graphql.data");
    }
    return data;
  }
}
~~~

The implementation must POST `query` and `variables`, include `operationName` only when non-null, reject a non-object response, reject every non-empty `errors` list even when partial data exists, and return only the validated `data` object. Error objects may contribute a stable `extensions.code` to diagnostics but response bodies and tokens must not be logged.

- [x] **Step 6: Refactor both remote sources onto the executors**

Inject endpoint URIs and the relevant executor through constructors. REST uses `HttpRequestExecutor` and GraphQL uses `GraphqlRequestExecutor`. Decode payloads into `RestPostDto` and `GraphqlCountryDto`, validate every required JSON field before construction, and map DTOs to domain models. Throw `NetworkException.invalidPayload` with the field name but not the response body.

- [x] **Step 7: Split remote and local exception mapping**

In persisted repository methods:

1. Map `NetworkException` from the remote phase to `AppErrorType.network` or a new `unauthorized` type.
2. Map exceptions from `replaceRestPosts`, `replaceGraphqlCountries`, and local reads to `AppErrorType.database`.
3. Do not use one catch block around both phases.

- [x] **Step 8: Register configuration and executors at the composition root**

Register `AppConfig`, one shared `http.Client`, one `HttpRequestExecutor`, and one `GraphqlRequestExecutor` in `lib/app/di.dart`. The HTTP executor's authorization provider is nullable until Task 5 registers `OidcSessionManager`.

- [x] **Step 9: Verify transport behavior**

Run:

~~~bash
flutter test test/core/network
flutter test test/features/network_examples/data
flutter analyze
~~~

Expected: PASS with no live network dependency.

- [x] **Step 10: Commit (`not run`: authorization is limited to `tool/` commits)**

~~~bash
git add lib/app/app_config.dart lib/app/di.dart lib/core/network lib/features/network_examples/data test/core/network test/features/network_examples/data
git commit -m "feat: add typed REST and GraphQL transport"
~~~

---

### Task 5: Add Secure OIDC Login, Refresh, Headers, And Logout

**Files:**
- Move: `lib/features/network_examples/domain/oidc_token_set.dart` to `lib/features/auth/domain/oidc_token_set.dart`
- Move/refactor: `lib/features/network_examples/data/oidc_authorization.dart` into the auth files listed below
- Create: `lib/features/auth/domain/oidc_configuration.dart`
- Create: `lib/features/auth/domain/oidc_sign_in_outcome.dart`
- Create: `lib/features/auth/data/oidc_client.dart`
- Create: `lib/features/auth/data/appauth_oidc_client.dart`
- Create: `lib/features/auth/data/oidc_token_store.dart`
- Create: `lib/features/auth/data/flutter_secure_oidc_token_store.dart`
- Create: `lib/features/auth/data/oidc_session_manager.dart`
- Create: `lib/features/auth/presentation/oidc_example_view_model.dart`
- Create: `lib/features/auth/presentation/oidc_example_view.dart`
- Modify: `lib/core/network/http_request_executor.dart`
- Modify: `lib/app/di.dart`
- Modify: `lib/app/router.dart`
- Modify: `lib/app/routes.dart`
- Modify: `android/app/build.gradle`
- Modify: `android/app/src/main/AndroidManifest.xml`
- Modify: `ios/Runner/Info.plist`
- Create: `ios/Runner/DebugProfile.entitlements`
- Create: `ios/Runner/Release.entitlements`
- Modify: `ios/Runner.xcodeproj/project.pbxproj`
- Modify: `macos/Runner/Info.plist`
- Modify: `macos/Runner/DebugProfile.entitlements`
- Modify: `macos/Runner/Release.entitlements`
- Modify: translation files
- Create/modify: OIDC tests under `test/features/auth/` and transport tests

**Interfaces:**
- Consumes: flutter_appauth, flutter_secure_storage, `AuthorizationHeaderProvider`, and `OidcConfiguration`.
- Produces: `OidcSessionManager implements AuthorizationHeaderProvider` and an executable OIDC example route.

- [x] **Step 1: Write failing token lifecycle tests**

Use fake `OidcClient` and in-memory `OidcTokenStore` to prove:

- restoring a stored token publishes a signed-in session;
- active tokens do not refresh;
- tokens within one minute of expiry refresh before use;
- an expired token without a refresh token clears the local session and returns unauthorized;
- ten concurrent header requests cause exactly one provider refresh;
- a rotated refresh token replaces the old token atomically;
- when refresh omits refresh or ID token, the previous non-null values are retained;
- refresh failure clears the local token and returns unauthorized;
- a 401 causes one forced refresh and one replay for both REST and GraphQL;
- logout deletes local secure storage before calling remote end-session;
- remote end-session failure leaves the local session signed out and returns a displayable warning result;
- no token value appears in `toString`, errors, or logs.

- [x] **Step 2: Run OIDC tests and confirm failure**

Run:

~~~bash
flutter test test/features/auth/data
flutter test test/core/network/http_request_executor_test.dart
~~~

Expected: FAIL because the session manager and secure store do not exist.

- [x] **Step 3: Define configuration and token contracts**

`OidcConfiguration.fromEnvironment` must consume:

- `OIDC_ISSUER`
- `OIDC_CLIENT_ID`
- `OIDC_REDIRECT_URI`, default `mvvmstarter:/oauthredirect`
- `OIDC_POST_LOGOUT_REDIRECT_URI`, default `mvvmstarter:/logout`
- `OIDC_SCOPES`, default `openid profile email offline_access`

An empty issuer or client id means `isConfigured == false` and disables interactive buttons without failing anonymous network examples.

Define `OidcTokenSet` with required access token and expiry, nullable refresh/ID token, token type default `Bearer`, issuer, subject, and a `copyWith` method. Do not implement a token-bearing `toString`.

Define the sign-in result without overloading nullable token values:

~~~dart
sealed class OidcSignInOutcome {
  const OidcSignInOutcome();
}

final class OidcSignInCompleted extends OidcSignInOutcome {
  const OidcSignInCompleted(this.tokenSet);

  final OidcTokenSet tokenSet;
}

final class OidcSignInCancelled extends OidcSignInOutcome {
  const OidcSignInCancelled();
}
~~~

- [x] **Step 4: Add the provider and secure-store boundaries**

Define:

~~~dart
abstract interface class OidcClient {
  Future<Result<OidcSignInOutcome>> signIn(
    OidcConfiguration configuration,
  );
  Future<Result<OidcTokenSet>> refresh(
    OidcConfiguration configuration,
    OidcTokenSet currentTokenSet,
  );
  Future<Result<void>> endSession(
    OidcConfiguration configuration,
    String idToken,
  );
}

abstract interface class OidcTokenStore {
  Future<OidcTokenSet?> read();
  Future<void> write(OidcTokenSet tokenSet);
  Future<void> clear();
}
~~~

`FlutterSecureOidcTokenStore` must store one versioned JSON document under `oidc.token_set.v1` so rotation is a single write. Construct storage with:

~~~dart
final storage = FlutterSecureStorage(
  aOptions: AndroidOptions(migrateWithBackup: true),
  iOptions: IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
  ),
  mOptions: MacOsOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
  ),
);
~~~

Set `android:allowBackup="false"` on the Android application so encrypted preferences are not restored without their Keystore key.

- [x] **Step 5: Implement AppAuth with PKCE**

`AppAuthOidcClient.signIn` must call `authorizeAndExchangeCode` using issuer discovery and scopes. Return `OidcSignInCancelled` for `FlutterAppAuthUserCancelledException`; map provider errors to `AppErrorType.unknown` without embedding tokens. After AppAuth succeeds, decode the ID-token payload, require non-empty `iss` and `sub` claims, and require the normalized issuer to match `OidcConfiguration.issuer`. Rely on AppAuth for protocol validation; never accept an arbitrary JWT supplied outside that completed flow and never derive roles from a display name.

`AppAuthOidcClient.refresh` must read the refresh token from `currentTokenSet` and fail unauthorized when it is absent. After a successful AppAuth token request, construct the result with:

~~~dart
final accessToken = response.accessToken;
final expiresAt = response.accessTokenExpirationDateTime;
if (accessToken == null || expiresAt == null) {
  return const Result.failure(
    AppError.unknown("auth.oidc.invalidTokenResponse"),
  );
}

return Result.success(
  currentTokenSet.copyWith(
    accessToken: accessToken,
    refreshToken: response.refreshToken ?? currentTokenSet.refreshToken,
    idToken: response.idToken ?? currentTokenSet.idToken,
    expiresAt: expiresAt,
    tokenType: response.tokenType ?? currentTokenSet.tokenType,
  ),
);
~~~

Keeping the current object as the copy source preserves issuer and subject when a provider omits an ID token during refresh.

Interactive support matrix:

- Android, iOS, macOS: enabled when configuration exists.
- Web, Windows, Linux: return `AppError.notFound("auth.oidc.unsupportedPlatform")` without invoking a plugin channel.

- [x] **Step 6: Implement single-flight session orchestration**

`OidcSessionManager` must:

- return `Future<Result<OidcSignInOutcome>>` from sign-in and publish tokens only for `OidcSignInCompleted`;
- implement `AuthorizationHeaderProvider`;
- keep at most one `Future<Result<OidcTokenSet>>` in `_refreshInFlight`;
- merge omitted rotated fields with the previous token;
- write the merged token before publishing it;
- clear storage and publish signed-out on unrecoverable refresh failure;
- clear storage and publish signed-out before attempting end-session;
- return `"<tokenType> <accessToken>"` only from `authorizationHeader`.

- [x] **Step 7: Wire actual REST and GraphQL requests**

Inject `OidcSessionManager` into `HttpRequestExecutor` through the authorization contract. Extend transport tests so both the REST GET and GraphQL POST receive the current bearer header and both follow the same forced-refresh path after one 401.

- [x] **Step 8: Add the OIDC example route**

Add `AppRoute.oidcExample("/auth/oidc-example")`. The ViewModel must expose configured, unsupported, signed-out, signing-in, signed-in, refreshing, signing-out, and warning states. The View must offer sign-in, explicit refresh, and logout commands and link back to Network Examples. It must not display raw access, refresh, or ID tokens.

- [x] **Step 9: Configure native callbacks**

Use the lowercase `mvvmstarter` callback scheme in Android manifest placeholders and iOS/macOS `CFBundleURLTypes`. Remove `android:taskAffinity=""` from MainActivity because it prevents reliable AppAuth callback return on affected Android versions. Keep issuer and client id outside platform files.

Add Apple Keychain configuration:

~~~xml
<key>keychain-access-groups</key>
<array/>
~~~

Add it to both macOS entitlement files. Create iOS Debug/Profile and Release entitlement files with the same key and configure `CODE_SIGN_ENTITLEMENTS` for every Runner build configuration in the Xcode project. Extend platform configuration tests to assert the callback scheme, Android task-affinity removal, `android:allowBackup="false"`, and all Keychain entitlement paths. Add a README rename/configuration checklist because starter consumers must register their own scheme and redirect URIs.

- [x] **Step 10: Verify OIDC behavior** (`verified locally` tests/analyze/platform structure; `blocked` Android SDK and current-session Apple rebuilds; real provider/device `not run`)

Run:

~~~bash
flutter test test/features/auth
flutter test test/core/network
flutter test test/features/network_examples
flutter analyze
flutter build apk --debug
flutter build ios --simulator --no-codesign
flutter build macos --debug
~~~

Expected: unit/widget tests and native builds pass. Real-provider login remains `not run` until issuer/client/redirect configuration is supplied.

- [x] **Step 11: Commit** (user explicitly requested committing and pushing the current work-in-progress state)

~~~bash
git add lib/features/auth lib/features/network_examples lib/core/network lib/app android/app/build.gradle android/app/src/main/AndroidManifest.xml ios/Runner ios/Runner.xcodeproj/project.pbxproj macos/Runner/Info.plist macos/Runner/DebugProfile.entitlements macos/Runner/Release.entitlements assets/translations test
git commit -m "feat: add secure OIDC network authorization"
~~~

---

### Task 6: Implement Explicit Offline Reads And Identity-Scoped Persistence

**Files:**
- Modify: `lib/core/database/app_database.dart`
- Modify: `lib/core/database/migrations.dart`
- Modify: `lib/core/database/app_database.g.dart`
- Create: `lib/features/network_examples/domain/persistence_scope.dart`
- Create: `lib/features/network_examples/domain/persisted_result.dart`
- Modify: `lib/features/network_examples/data/network_examples_local_data_source.dart`
- Modify: `lib/features/network_examples/data/network_examples_repository.dart`
- Modify: `lib/features/network_examples/presentation/network_examples_view_model.dart`
- Modify: `lib/features/network_examples/presentation/network_examples_view.dart`
- Create: `drift_schemas/schema_v4.json`
- Modify/add: database, repository, ViewModel, and widget tests

**Interfaces:**
- Consumes: authenticated identity when present and the typed network errors from Task 4.
- Produces: schema version 4, `PersistenceScope`, and `PersistedResult<T>` with remote/local freshness.

- [x] **Step 1: Write failing offline and scope tests**

Cover REST and GraphQL symmetrically:

- successful remote fetch writes and returns `DataOrigin.remote`;
- after closing and reopening the database, a network failure returns saved rows;
- local rows younger than 15 minutes return `localFresh`;
- older rows return `localStale`;
- no local rows plus network failure returns the original network error;
- local database failure returns `AppErrorType.database`;
- `public` and two different OIDC identity scopes cannot read one another's rows;
- an empty successful remote response replaces only its own scope;
- one failed section does not erase or hide successful sections.

- [x] **Step 2: Run focused tests and confirm failure**

Run:

~~~bash
flutter test test/features/network_examples/data
flutter test test/features/network_examples/presentation
flutter test test/core/database
~~~

Expected: FAIL because persisted reads require a successful network request and tables have no scope.

- [x] **Step 3: Add scope and result models**

Define:

~~~dart
enum DataOrigin { remote, localFresh, localStale }

final class PersistenceScope {
  const PersistenceScope.public() : key = "public";

  PersistenceScope.oidc({
    required String issuer,
    required String subject,
  }) : key = "oidc:$issuer:$subject";

  final String key;
}

final class PersistedResult<T> {
  const PersistedResult({
    required this.value,
    required this.origin,
    required this.fetchedAt,
  });

  final T value;
  final DataOrigin origin;
  final DateTime fetchedAt;
}
~~~

Reject blank issuer or subject before creating an OIDC scope.

- [x] **Step 4: Add scoped composite keys**

Add `scope_key TEXT NOT NULL` to both network tables and change primary keys to:

- REST: `{scopeKey, id}`
- GraphQL: `{scopeKey, code}`

Set `schemaVersion => 4`. The version-3-to-4 migration must rebuild both tables, copy every existing row with `scope_key = "public"`, preserve `fetched_at`, validate row counts, and drop old tables only after validation.

- [x] **Step 5: Return complete local snapshots**

Local data source reads must return rows plus their shared/latest `fetchedAt` and require a `PersistenceScope` argument. Replacement must delete and insert only the selected scope inside one transaction.

- [x] **Step 6: Implement remote-first with local fallback**

For each persisted repository operation:

1. Attempt remote fetch.
2. On success, replace the selected scope and return `remote`.
3. On `NetworkException`, read the selected scope.
4. If rows exist, compare `fetchedAt` with injected `now` and the 15-minute TTL, then return `localFresh` or `localStale`.
5. If no rows exist, return the original network failure.
6. Map local read/write failures to database errors.

Remote-only methods must remain free of Drift writes and reads.

- [x] **Step 7: Make screen sections independent**

Replace the all-or-nothing sequential ViewModel load with four independently renderable section states. Launch sections concurrently after publishing loading state. A REST remote-only failure must not suppress GraphQL persisted local data. Display local freshness using localized text, without exposing implementation instructions in the UI.

- [x] **Step 8: Generate code and schema snapshot**

Run:

~~~bash
dart run build_runner build --delete-conflicting-outputs --build-filter=lib/core/database/app_database.g.dart
dart run drift_dev schema dump lib/core/database/app_database.dart drift_schemas/schema_v4.json
~~~

Expected: both network tables have scoped composite primary keys.

- [x] **Step 9: Verify offline behavior**

Run:

~~~bash
flutter test test/core/database
flutter test test/features/network_examples
flutter analyze
~~~

Expected: PASS, including restart, offline fallback, stale-state, and scope-isolation tests.

- [x] **Step 10: Commit** (`not run`: the prior commit/push request applied to the then-current work-in-progress; no fresh authorization exists for later commits)

~~~bash
git add lib/core/database lib/features/network_examples assets/translations test/core/database test/features/network_examples drift_schemas/schema_v4.json
git commit -m "feat: add scoped offline network persistence"
~~~

---

### Task 7: Harden Async Lifecycle And User-Visible Failure Handling

**Files:**
- Modify: `analysis_options.yaml`
- Modify: `lib/features/network_examples/presentation/network_examples_view_model.dart`
- Modify: `lib/features/network_examples/presentation/network_examples_view.dart`
- Modify: `lib/features/auth/presentation/login_view.dart`
- Modify: `lib/features/auth/presentation/login_view_model.dart`
- Modify: `lib/features/auth/presentation/signup_view.dart`
- Modify: `lib/features/auth/presentation/signup_view_model.dart`
- Modify: `lib/features/home/presentation/home_view.dart`
- Modify: `lib/features/debug_database/presentation/database_debug_view_model.dart`
- Modify: affected ViewModel and widget tests

**Interfaces:**
- Consumes: `Result<T>` and independent network section state.
- Produces: latest-request-wins ViewModels and mounted-safe Views.

- [x] **Step 1: Write failing lifecycle tests**

Add deterministic completers and verify:

- disposing Login, Signup, OIDC, or NetworkExamples ViewModel before an operation completes produces no notifier-after-dispose error;
- starting load A then load B cannot let A overwrite B;
- refresh is disabled while the current generation is loading;
- logout failure keeps the user on Home and shows the translated error;
- logout success navigates only after persistence succeeds;
- DatabaseDebug subscriptions are cancelled before notifiers are disposed.

- [x] **Step 2: Enable the context lifecycle lint**

Change:

~~~yaml
use_build_context_synchronously: true
~~~

Run `flutter analyze` and record every new finding before editing runtime code.

- [x] **Step 3: Add latest-request-wins publication guards**

Each async ViewModel with disposable notifiers must maintain:

~~~dart
var _operationGeneration = 0;
var _disposed = false;

bool canPublish(int generation) {
  return !_disposed && generation == _operationGeneration;
}
~~~

Increment generation at operation start and disposal. Check `canPublish` after every await and before every notifier write.

- [x] **Step 4: Add mounted checks and Result handling**

After awaiting ViewModel commands, Views must return when `!context.mounted`. Home must inspect logout failure before showing success or navigating. Login and Signup must not clear controllers or navigate after disposal.

- [x] **Step 5: Await stream cancellation internally**

`DatabaseDebugViewModel.close` must await both subscription cancellations, null the references, then dispose notifiers exactly once. `dispose` may call `unawaited(close())` only after setting the disposed guard synchronously.

- [x] **Step 6: Verify lifecycle behavior**

Run:

~~~bash
flutter test test/features/auth/presentation
flutter test test/features/home/presentation
flutter test test/features/network_examples/presentation
flutter test test/features/debug_database/presentation
flutter analyze
~~~

Expected: PASS and no `use_build_context_synchronously` findings.

- [x] **Step 7: Commit** (`not run`: no fresh authorization for a later commit)

~~~bash
git add analysis_options.yaml lib/features test/features
git commit -m "fix: guard async MVVM lifecycle transitions"
~~~

---

### Task 8: Add Mechanical Architecture, Test-Truth, Generation, And Platform CI Gates

**Files:**
- Modify: existing untracked `tool/check_agent_harness_links.dart`
- Create: `tool/check_mvvm_boundaries.dart`
- Create: `tool/check_platform_network_config.dart`
- Create: `tool/verify_flutter_tests.dart`
- Create: `test/tool/check_agent_harness_links_test.dart`
- Create: `.github/workflows/flutter.yml`
- Modify: `docs/agent-harness/QUALITY.md`
- Modify: `docs/agent-harness/RELIABILITY.md`
- Modify: `docs/agent-harness/SECURITY.md`

**Interfaces:**
- Consumes: repository source, generated files, Flutter test machine output, and platform configuration.
- Produces: deterministic local and CI commands that fail on architecture drift or zero-test success.

- [x] **Step 1: Repair and test the existing link checker**

Change its harness root from `agent-harness` to `docs/agent-harness` and add an optional `--root <path>` argument used only to select the scan root. In `test/tool/check_agent_harness_links_test.dart`, create a temporary root containing `AGENTS.md` and `docs/agent-harness/README.md`, run the checker as a subprocess, and assert exit 0 for an existing relative link. Replace that target with a missing path, rerun, and assert exit 1 plus the exact `source:line -> target does not exist` diagnostic. Preserve the user's parsing and reporting structure.

- [x] **Step 2: Add MVVM boundary checks**

`tool/check_mvvm_boundaries.dart` must fail when:

- a `*_view.dart` imports GetIt, `locator.dart`, Drift, `app_database.dart`, or a feature `data/` file;
- a ViewModel imports Drift or `app_database.dart`;
- any feature file calls the `locator` function;
- any runtime file uses `MaterialPageRoute` or `Navigator.push` for application routes;
- restoration files import auth tokens, repositories, or database tables.

The command must print `file:line` and the violated rule.

- [x] **Step 3: Add platform configuration checks**

`tool/check_platform_network_config.dart` must verify the same source and SHA-256 requirements as the platform test, plus OIDC callback schemes in Android/iOS/macOS.

- [x] **Step 4: Add nonzero runtime test discovery**

`tool/verify_flutter_tests.dart` must spawn `flutter test --machine`, forward output, count non-synthetic `testStart` events, preserve the Flutter exit code, and fail when the count is zero. Print the final discovered test count.

- [x] **Step 5: Add generated-output freshness commands**

CI must run:

~~~bash
dart run build_runner build --delete-conflicting-outputs --build-filter=lib/core/database/app_database.g.dart
dart run drift_dev schema dump lib/core/database/app_database.dart drift_schemas/schema_v4.json
dart run tool/update_drift_web_assets.dart
git diff --exit-code -- lib/core/database/app_database.g.dart drift_schemas web/drift_worker.js web/sqlite3.wasm
~~~

Expected: no diff.

- [x] **Step 6: Add CI workflow**

Use read-only workflow permissions and immutable action revisions:

~~~yaml
permissions:
  contents: read

steps:
  - uses: actions/checkout@34e114876b0b11c390a56381ad16ebd13914f8d5 # v4
    with:
      persist-credentials: false
  - uses: subosito/flutter-action@1a449444c387b1966244ae4d4f8c696479add0b2 # v2
    with:
      channel: stable
      flutter-version: 3.44.6
      cache: true
~~~

Create:

- `quality` on Ubuntu: enforce lockfile, format, harness links, MVVM boundaries, platform config, generated freshness, analyze, nonzero test runner, and web release build;
- `android-release` on Ubuntu: build release APK;
- `apple-builds` on macOS: build iOS simulator without signing and macOS release;
- `linux-release` on Ubuntu: install `clang cmake ninja-build pkg-config libgtk-3-dev libsecret-1-dev` and build Linux release;
- `windows-release` on Windows: build Windows release using the runner's Visual Studio C++ and ATL workload.

Do not upload signing credentials or publish release artifacts.

- [x] **Step 7: Run all local mechanical gates**

Run:

~~~bash
dart run tool/check_agent_harness_links.dart
dart run tool/check_mvvm_boundaries.dart
dart run tool/check_platform_network_config.dart
dart run tool/verify_flutter_tests.dart
flutter analyze
~~~

Expected: PASS with a nonzero test count.

- [x] **Step 8: Commit** (`not run`: no fresh authorization for a later commit)

~~~bash
git add tool .github/workflows/flutter.yml docs/agent-harness/QUALITY.md docs/agent-harness/RELIABILITY.md docs/agent-harness/SECURITY.md
git commit -m "ci: enforce Flutter architecture and platform gates"
~~~

---

### Task 9: Reconcile Documentation, Starter Polish, And Final Evidence

**Files:**
- Modify: `README.md`
- Modify: `AGENTS.md`
- Modify: `docs/agent-harness/ARCHITECTURE.md`
- Modify: `docs/agent-harness/QUALITY.md`
- Modify: `docs/agent-harness/RELIABILITY.md`
- Modify: `docs/agent-harness/SECURITY.md`
- Modify: `docs/agent-harness/design-docs/storage-strategy.md`
- Modify: `docs/agent-harness/design-docs/network-and-oidc-strategy.md`
- Modify: `docs/agent-harness/design-docs/index.md`
- Modify: `docs/agent-harness/product-specs/mvvm-starter.md`
- Modify: `docs/agent-harness/exec-plans/tech-debt-tracker.md`
- Move: `docs/agent-harness/exec-plans/active/2026-07-08-harness-hardening-roadmap.md` to `docs/agent-harness/exec-plans/completed/` with `superseded` status
- Modify: `pubspec.yaml` description
- Modify: `ios/Runner/Info.plist` display name
- Move: `android/app/src/main/kotlin/com/example/flutter_application_1/MainActivity.kt` to `android/app/src/main/kotlin/com/example/mvvm_starter/MainActivity.kt`
- Delete: `ios/Podfile~`
- Delete: `macos/Podfile~`
- Delete: unused `lib/core/date_service.dart`

**Interfaces:**
- Consumes: final implemented behavior and verification output.
- Produces: accurate starter guidance with no stale architecture claims.

- [x] **Step 1: Rewrite the quick-start and support matrix**

README must include:

- Flutter 3.44.6 setup and `flutter pub get --enforce-lockfile`;
- anonymous REST/GraphQL launch;
- OIDC `--dart-define` keys and native platform support;
- Android/iOS/macOS callback registration;
- remote-only, offline-read, cache-only, and offline-write/sync decision table;
- public versus OIDC identity persistence scope;
- generated Drift/web asset commands;
- platform build commands;
- bundle identifier, callback scheme, app display name, and database filename rename cautions;
- the explicit statement that `radlofa_app` remains for migration continuity;
- `release pending` status.

- [x] **Step 2: Correct the agent map and architecture docs**

AGENTS.md must point directly to `lib/app/router.dart`, `lib/app/di.dart`, and Drift under `lib/core/database/`. Remove every current-tense Hive/raw SQLite statement. Architecture docs must show the actual remote, auth, and offline flows and the native-only interactive OIDC support matrix.

- [x] **Step 3: Correct security and product claims**

Document:

- local name auth is a demo gate, not a security boundary;
- OIDC tokens live only in secure storage;
- roles must come from trusted provider/backend policy, not names;
- logout is local-first and remote end-session may yield a warning;
- offline writes and conflict resolution remain non-goals;
- no production issuer or release has been verified.

- [x] **Step 4: Reconcile plans and debt**

Remove duplicate TD-001 state. Retire entries only when their mechanical command and CI gate pass. Mark the old hardening roadmap `superseded`, note its replacement by this plan, and move it to completed. Keep unresolved production-provider, real-device, observability, and release verification debt open.

- [x] **Step 5: Remove starter debris without changing compatibility data**

Delete backup Podfiles and unused DateService, move MainActivity to match its package, update the generic pubspec description and iOS display name. Do not rename the native database file during this plan.

- [x] **Step 6: Run documentation and hygiene checks**

Run:

~~~bash
dart run tool/check_agent_harness_links.dart
rg -n "database_abstract|hive_abstract|lib/core/locator.dart|lib/route.dart" AGENTS.md README.md docs/agent-harness
git diff --check
~~~

Expected: the link checker passes; remaining matches refer only to historical context or compatibility exports and are explicitly labeled.

- [x] **Step 7: Run the final verification matrix** (`verified locally` except Android and signed macOS release, which are `blocked` by missing platform credentials/tooling)

Run:

~~~bash
flutter pub get --enforce-lockfile
dart format --output=none --set-exit-if-changed lib test integration_test tool
dart run tool/check_agent_harness_links.dart
dart run tool/check_mvvm_boundaries.dart
dart run tool/check_platform_network_config.dart
dart run tool/verify_flutter_tests.dart
flutter analyze
flutter build web --release
flutter build apk --release
flutter build ios --simulator --no-codesign
flutter build macos --release
git diff --check
~~~

Expected: all commands pass locally. Record real-provider and real-device checks as `not run` unless they actually occur.

- [x] **Step 8: Update this plan's evidence**

Record:

- `verified locally` commands with literal outcomes and test count;
- `not run` provider/device/release checks;
- `release pending` until release-equivalent evidence exists;
- no `production-ready` statement.

- [x] **Step 9: Commit** (`not run`: no fresh commit or push authorization)

~~~bash
git add README.md AGENTS.md pubspec.yaml ios macos android lib/core/date_service.dart docs/agent-harness
git commit -m "docs: finalize hardened MVVM starter guidance"
~~~

---

## Acceptance Criteria

- Legacy version-0 users survive migration and one deterministic valid session is retained.
- Version-2 databases migrate to a schema-enforced singleton session without losing users.
- `app_sessions.id` is a primary key constrained to 1, and the test uses two different users with `id = 1`.
- No release UI derives admin authority from a name or exposes delete-all users.
- Android release has Internet permission; macOS debug/release has network-client entitlement.
- Web boot opens the real Drift database using committed, hash-verified assets.
- REST and GraphQL endpoints are configurable and use one timeout-bounded typed executor.
- Local database failures are distinguishable from remote transport failures.
- OIDC uses AppAuth/PKCE on Android, iOS, and macOS when configured.
- Tokens are atomically stored in secure storage and never written to Drift, shared_preferences, restoration, logs, or rendered UI.
- Concurrent expired requests cause one refresh; a 401 causes at most one refresh and one replay.
- Local logout completes before remote end-session and remains signed out if remote logout fails.
- Persisted REST and GraphQL data is available after restart and network failure.
- Persisted snapshots expose remote/local-fresh/local-stale origin and are isolated by persistence scope.
- Remote-only flows never read or write Drift.
- Async operations cannot publish after disposal or overwrite a newer generation.
- CI proves nonzero test discovery and checks generated output, architecture boundaries, platform configuration, analysis, tests, and representative builds.
- CI builds web, Android release, iOS simulator, macOS release, Linux release, and Windows release.
- AGENTS.md, README, product specs, design docs, active plans, and debt tracker agree with implementation.
- `flutter analyze` and `flutter test` pass; release status remains `release pending` without external evidence.

## Verification Log

- `verified locally`: Task 9 `flutter pub get --enforce-lockfile` resolved the committed lockfile; final Dart formatting passed for 91 files after applying one mechanical formatter change.
- `verified locally`: Task 9 documentation/hygiene checks passed: the link checker inspected 28 Markdown files, stale architecture-path matches were limited to explicitly labeled compatibility exports or historical/completed plans, workflow YAML parsed, and `git diff --check` reported no errors.
- `verified locally`: Task 9 final `dart run tool/check_mvvm_boundaries.dart` inspected 54 runtime Dart files and the platform configuration checker passed.
- `verified locally`: Task 9 final `dart run tool/verify_flutter_tests.dart` passed 111 non-synthetic runtime tests across 29 files with Flutter exit code 0; final `flutter analyze` reported no issues.
- `verified locally`: Task 9 `flutter build web --release` and `flutter build ios --simulator --no-codesign` succeeded.
- `blocked`: Task 9 `flutter build apk --release` cannot run because no Android SDK/`ANDROID_HOME` exists in the environment.
- `blocked`: Task 9 direct signed `flutter build macos --release` cannot run because Keychain Sharing entitlements require a development signing identity and this machine has zero valid identities.
- `candidate-only`: Task 9 macOS release compiled successfully with Flutter's documented CI build-setting bridge disabling code signing; the workflow applies those settings only to its unsigned macOS candidate and does not weaken production Xcode entitlements.
- `not run`: GitHub Actions, Linux/Windows local builds, production-provider OIDC, real-device OIDC, signing, packaging, publication, and release checks.
- `not run`: Task 9 commit and push; the prior authorization did not extend to these later changes.
- `release pending`: local implementation and verification are complete, but external CI, provider/device, signing, and distribution evidence is absent. The `production-ready` label is intentionally not assigned.
- `verified locally`: Task 8 link-checker TDD first failed because the checker ignored the supplied root and scanned a nonexistent legacy `agent-harness/` directory; `flutter test test/tool/check_agent_harness_links_test.dart` then passed its exact success/failure diagnostic test.
- `verified locally`: Task 8 mechanical gates passed: the link checker inspected 28 Markdown files, the MVVM checker inspected 55 runtime Dart files, the platform checker validated networking, Drift web assets, callbacks, and Keychain configuration, workflow YAML parsed successfully, and `git diff --check` reported no errors.
- `verified locally`: Task 8 regenerated Drift code, schema v4, and pinned web assets; byte-for-byte comparisons against pre-generation copies showed no generated-output drift. The CI workflow runs the plan's exact `git diff --exit-code` freshness command from a clean checkout.
- `verified locally`: Task 8 `dart run tool/verify_flutter_tests.dart` passed 111 non-synthetic runtime tests across 29 test files, preserved Flutter exit code 0, and printed the discovered count; `flutter analyze` reported no issues afterward.
- `candidate-only`: Task 8 added read-only GitHub Actions jobs with immutable action revisions for quality/web, Android release, Apple builds, Linux release, and Windows release.
- `not run`: Task 8 GitHub Actions jobs; no workflow run exists for the uncommitted changes.
- `not run`: Task 8 commit; no fresh commit authorization was provided after resuming the previously committed work-in-progress.
- `verified locally`: Task 7 RED tests reproduced notifier-after-dispose failures in Login, Signup, OIDC, and NetworkExamples ViewModels; an older network load overwrote a newer result; refresh stayed enabled during loading; Home navigated after logout failure; and DatabaseDebug disposed notifiers before asynchronous stream cancellation completed.
- `verified locally`: Enabling `use_build_context_synchronously` produced six findings in Login, Signup, and Home before runtime edits; after mounted guards and Result handling, `flutter analyze` reported no issues.
- `verified locally`: Task 7 `flutter test test/features/auth/presentation` passed 16 tests, `flutter test test/features/home/presentation` passed 5 tests, `flutter test test/features/network_examples/presentation` passed 7 tests, and `flutter test test/features/debug_database/presentation` passed 2 tests.
- `not run`: Task 7 commit; no fresh commit authorization was provided after resuming the previously committed work-in-progress.
- `verified locally`: Task 6 TDD first failed because persistence scope/result types did not exist, schema v3 had no `scope_key`, repository methods had no scoped offline fallback, and the ViewModel exposed one all-or-nothing state.
- `verified locally`: Task 6 generated `app_database.g.dart` and `schema_v4.json`; the snapshot declares schema version 4 with `PRIMARY KEY ("scope_key", "id")` for REST and `PRIMARY KEY ("scope_key", "code")` for GraphQL.
- `verified locally`: Task 6 `flutter test test/core/database` passed 8 tests, `flutter test test/features/network_examples` passed 23 tests, and `flutter analyze` reported no issues on 2026-07-13.
- `verified locally`: Task 6 restart tests closed and reopened a file-backed Drift database, then returned identity-scoped REST and GraphQL snapshots during simulated network failure with fresh/stale origin metadata.
- `not run`: Task 6 commit; no fresh commit authorization was provided after resuming the previously committed work-in-progress.
- `blocked`: Task 5 iOS simulator and macOS debug rebuilds could not run on 2026-07-13 because Flutter attempted to update its SDK cache outside the workspace and the managed environment rejected the required elevated write even after explicit user approval; no policy workaround was attempted.
- `verified locally`: Task 5 tests first failed because secure OIDC storage, token/session contracts, single-flight orchestration, and presentation state did not exist; native callback tests also failed before platform configuration.
- `verified locally`: Task 5 `flutter test test/features/auth` passed 36 tests, `flutter test test/core/network` passed 15 tests, `flutter test test/features/network_examples` passed 10 tests, `flutter test test/app/router_test.dart` passed 5 tests, `flutter test test/platform/platform_configuration_test.dart` passed 4 tests, and `flutter analyze` reported no findings before the final iOS build attempt.
- `blocked`: Task 5 Android debug build cannot run because the configured Android SDK path does not exist.
- `not run`: Task 5 real-provider and real-device OIDC login remain unverified.
- `not run`: Task 5 iOS simulator rebuild after restoring missing Flutter xcconfig files was interrupted at the user's request to commit, push, and stop.
- `verified locally`: Task 4 tests first failed because AppConfig, typed HTTP/GraphQL executors, typed payload validation, and database-error separation did not exist.
- `verified locally`: Task 4 `flutter test test/core/network` passed 12 tests, `flutter test test/features/network_examples/data` passed 11 tests, and `flutter analyze` reported no findings.
- `not run`: Task 4 commit; the later commit authorization is explicitly limited to files under `tool/`.
- `verified locally`: Task 3 structural tests first failed independently for missing Android Internet permission, both missing macOS network-client entitlements, and missing Drift web assets.
- `verified locally`: Task 3 downloaded sqlite3 3.3.4 WebAssembly from the planned source, verified SHA-256 `cfab48c6bbb718552ec19bc4f1365e19185311b72e4739cc19ef7333758304d3`, compiled `web/drift_worker.js`, and passed all 3 platform-configuration tests.
- `verified locally`: Task 3 `flutter build web --release` and `flutter build macos --release` succeeded; `codesign -d --entitlements :-` confirmed `com.apple.security.network.client = true` in the built macOS application.
- `verified locally`: Task 3 `flutter analyze` reported no findings after the runtime/platform changes.
- `verified locally`: Task 3 production web bootstrap passed with `flutter drive -d web-server --browser-name chrome --driver test_driver/integration_test.dart --target integration_test/app_boot_smoke_test.dart --web-port 7357 --headless`; the temporary matching ChromeDriver and isolated Chrome processes were stopped and confirmed absent afterward. The plan's direct `flutter test ... -d chrome` form remains unsupported by the installed Flutter master tool.
- `blocked`: Task 3 `flutter build apk --release` could not run because the environment has no Android SDK.
- `verified locally`: Task 3 `dart run tool/update_drift_web_assets.dart` downloaded and hash-verified sqlite3 3.3.4, regenerated the worker, and the structural platform test passed afterward.
- `verified locally`: Task 2 red tests demonstrated the prior defects: a second `id = 1` session for another user was accepted, version-0 users were dropped, three legal version-2 session rows survived, and the release Home UI exposed delete-all authority for the display name `admin`.
- `verified locally`: Task 2 generated authoritative `schema_v2.json` and `schema_v3.json`; v3 contains no `is_admin` and declares `PRIMARY KEY ("id")` for `app_sessions`.
- `verified locally`: Task 2 `flutter test test/core/database` passed 7 tests, `flutter test test/features/auth` passed 14 tests, `flutter test test/features/home` passed 3 tests, and `flutter analyze` reported no findings.
- `not run`: Task 2 commit, per the explicit no-commit instruction for this execution.
- `verified locally`: Task 1 pre-upgrade `flutter --version` reported local Flutter `3.46.0-1.0.pre-403` master with Dart `3.13.0-266.0.dev`; the implementation remains pinned to the plan's Flutter 3.44.6/Dart 3.12.2 baseline through dependency and CI configuration.
- `verified locally`: Task 1 pre-upgrade `flutter analyze` completed with no findings and `flutter test` passed 42 tests.
- `verified locally`: Task 1 `flutter pub upgrade`, `flutter pub deps --style=compact`, and `flutter pub outdated` resolved the exact direct constraints; discontinued `build_resolvers`, `build_runner_core`, and `js` are absent.
- `verified locally`: Task 1 `dart format --output=none --set-exit-if-changed lib test`, `flutter analyze`, and `flutter test` passed; the suite reported 42 tests.
- `not run`: Task 1 commit, per the explicit no-commit instruction for this execution.
- `candidate-only`: plan created from the 2026-07-11 KILLCRITIC review.
- `verified locally`: pre-plan review ran `flutter analyze` successfully.
- `verified locally`: pre-plan review ran 42 Flutter tests successfully, while identifying false-green singleton and migration assertions.
- `verified locally`: REST and GraphQL public endpoints responded.
- `verified locally`: SQLite accepted two `id = 1` session rows under the current schema.
- `verified locally`: official SQLite 3.3.4 WebAssembly asset SHA-256 is `cfab48c6bbb718552ec19bc4f1365e19185311b72e4739cc19ef7333758304d3`.
- `verified locally`: official Flutter release metadata identified Flutter 3.44.6 stable with Dart 3.12.2 on 2026-07-11.
- `release pending`: no production release, configured OIDC provider, or real-device evidence exists.

## Decision Log

- 2026-07-13: Keep macOS production entitlements/signing configuration intact; for the credential-free CI compile only, pass `CODE_SIGNING_ALLOWED=NO` and related values through Flutter's `FLUTTER_XCODE_` build-setting bridge. Treat that artifact as `candidate-only`, while signed release verification remains `blocked`/`release pending`.
- 2026-07-13: Preserve `radlofa_app` and all migration paths, mark the older harness roadmap `superseded`, and keep provider/device, observability, first external CI run, signing, and release validation open in the debt tracker.
- 2026-07-13: Keep CI read-only, pin third-party actions to the revisions specified by the plan, verify generated output with a clean-checkout diff in CI, and use byte-for-byte local comparisons while the intended implementation remains uncommitted.
- 2026-07-13: Use monotonically increasing operation generations plus synchronous disposed guards in async ViewModels; each post-await publication must match the current generation, and DatabaseDebug cancellation Futures complete before notifier disposal.
- 2026-07-13: Make `AuthRepository` subclassable only through a persistence-free `AuthRepository.fake()` test base, matching the existing network repository test seam without changing runtime DI construction.
- 2026-07-13: Resolve the persistence scope at the start of each persisted request from the current validated OIDC issuer/subject, defaulting to `public`, so a mid-request session change cannot redirect writes or fallback reads into another namespace.
- 2026-07-13: Keep successful empty remote responses as `DataOrigin.remote` while deleting only the selected scope; after restart an empty scope has no fallback timestamp and therefore returns the original network error.
- 2026-07-13: Treat current-session Apple native rebuilds as `blocked` rather than bypassing the managed sandbox after it rejected Flutter SDK cache writes; continue source and focused test work that remains within the workspace.
- 2026-07-11: The user explicitly authorized planned `tool/*.dart` edits and commits; restrict staging and commits to exact files under `tool/`, leaving every non-`tool/` change unstaged and uncommitted.
- 2026-07-11: Use Flutter's documented `flutter drive` web integration path with a version-matched temporary ChromeDriver because the installed Flutter master command rejects `flutter test` integration targets on web before launch.
- 2026-07-11: Preserve `tool/` unchanged despite Task 3 and Task 8 plan steps that require edits there; web assets may be generated manually for runtime progress, but the reproducibility/CI gate remains incomplete until the ownership conflict is resolved.
- 2026-07-11: Validate the rebuilt `app_sessions` table before dropping invalid legacy-only rows, then run a full `PRAGMA foreign_key_check` after legacy tables are removed; this preserves rollback safety without allowing malformed legacy foreign keys to mask the validity of the migrated schema.
- 2026-07-11: Keep the local Flutter master SDK unchanged because branch/toolchain mutation was not authorized; validate source compatibility locally while pinning the repository and CI contract to Flutter 3.44.6 stable and Dart 3.12.2.
- 2026-07-11: Do not execute any plan commit steps because the user explicitly prohibited commits and pushes for this execution.
- 2026-07-11: Treat destructive legacy migration as the first implementation blocker.
- 2026-07-11: Preserve `radlofa_app` as the native database name so the fixed migration can find existing installations.
- 2026-07-11: Remove client-derived admin behavior instead of attempting to harden a local name-based role.
- 2026-07-11: Support interactive AppAuth login on Android, iOS, and macOS; expose a deterministic unsupported state on web, Windows, and Linux.
- 2026-07-11: Keep anonymous REST/GraphQL examples operational when OIDC configuration is absent.
- 2026-07-11: Use remote-first with local fallback and a 15-minute freshness threshold for the persisted read examples.
- 2026-07-11: Namespace persisted network rows as public or OIDC identity scoped.
- 2026-07-11: Keep offline writes and synchronization documented but out of implementation scope.
- 2026-07-11: Pin CI to Flutter 3.44.6 stable rather than the local master-channel SDK used during the review.
- 2026-07-11: Commit Drift generated code and web runtime assets, with CI freshness and checksum gates.

## Completion Notes

Completed locally on 2026-07-13. Tasks 1-9 implemented migration-safe Drift
schema/session hardening, platform networking and web assets, typed
REST/GraphQL transports, secure native OIDC, identity-scoped offline reads,
async lifecycle guards, mechanical/CI gates, starter cleanup, and reconciled
documentation.

The final suite passed 111 runtime tests and static analysis. Web and iOS
simulator builds passed. Android is blocked by the absent SDK; signed macOS is
blocked by the absent development identity, while an unsigned macOS CI
candidate compiled. External workflow, production provider, real-device,
signing, packaging, and release evidence remain open in the technical debt
tracker, so status is `release pending` and not `production-ready`.

No Task 6-9 commit or push was made because no fresh authorization was given.
This completed plan is stored under `exec-plans/completed/`.
