# Professional MVVM Architecture Refactor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refactor this Flutter starter into a professional, testable MVVM starter architecture with GetIt composition, go_router navigation, Drift-backed SQLite persistence, and reusable Flutter state restoration support.

**Architecture:** Keep MVVM as the primary application architecture. Use GetIt only at the app composition/root/factory layer, route builders to inject ViewModels into Views, repositories for domain behavior, DAOs/local data sources for database access, and Drift on top of SQLite as the canonical app data store.

**Tech Stack:** Flutter, Dart SDK `^3.6.1`, GetIt, go_router, easy_localization, Drift/SQLite, Flutter RestorationMixin/RestorableProperty, flutter_test, flutter_lints.

## Global Constraints

- This plan is for implementation after explicit user approval; do not implement while only planning.
- Do not create, switch, rename, delete, or otherwise perform branch operations unless the user explicitly asks for that branch action.
- Keep repository plans, verification logs, implementation notes, and project documentation in English.
- Preserve user-owned changes. At plan time, `pubspec.lock` is modified and `tool/` is untracked.
- Keep MVVM as the main architecture.
- Keep GetIt for dependency injection, but use it only at the composition/root/factory layer.
- Avoid calling `locator<T>()` directly inside Views unless absolutely necessary during transitional refactor.
- Keep `go_router` as the only navigation system.
- Remove mixed usage of `Navigator.push(MaterialPageRoute(...))` where `go_router` should be used.
- Prefer SQLite as the single source of truth for app/domain data.
- Strongly consider Drift on top of SQLite for professional type-safe database access, migrations, DAOs, reactive queries, and testability.
- Remove Hive from the starter unless there is a clearly justified cache-only use case.
- `shared_preferences` may be introduced or kept only for very small primitive preferences, such as theme mode, locale, or onboardingSeen.
- Do not use `shared_preferences` for users, sessions, auth data, tokens, domain data, or cache lists.
- Riverpod must not be introduced as the main architecture dependency.
- Restorable state must be short-lived UI state restoration, not persistent domain storage.
- Domain/app data must be stored in SQLite/Drift.
- UI restoration must use Flutter's `RestorationMixin` / `RestorableProperty` system.
- Use package imports for Dart files, matching repo lint rules.
- Use the narrowest verification that proves each change: `flutter analyze`, focused `flutter test`, and `flutter test --coverage` only when requested or when risk is broad.
- Report verification with literal labels: `verified locally`, `not run`, `blocked`, `candidate-only`, `release pending`, `production-ready`.
- Do not call work `production-ready` without production, release, or equivalent evidence.

---

## Repository Audit

### Current Dependencies

Current direct dependencies in `pubspec.yaml`:

- `flutter`
- `cupertino_icons`
- `easy_localization`
- `get_it`
- `go_router`
- `hive_ce`
- `hive_ce_flutter`
- `path`
- `path_provider`
- `sqlite3`
- `uuid`

Current dev dependencies:

- `build_runner`
- `flutter_lints`
- `flutter_test`
- `objectbox_generator: any`

Dependency concerns:

- Hive is initialized but appears unused as an actual app storage requirement.
- `objectbox_generator` appears unused and brings unrelated generated-database concepts into the starter.
- Raw `sqlite3` is useful but shifts schema, migrations, mapping, and query safety into hand-written code.
- `pubspec.lock` has user-owned uncommitted changes and must not be reverted casually.

### Current Architecture

Current layout:

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

The project already has a lightweight MVVM direction, but boundaries are blended:

- Views create ViewModels directly.
- Views call `locator<T>()`.
- `UserService` owns business rules, SQL, session logic, and user notifier state.
- Database schema creation lives in `main.dart`.
- Debug database UI is in `core/`, though it behaves like a debug feature.

### Current Routing

`go_router` is used by `RouterService` in `lib/route.dart` for:

- `/`
- `/login`

Routing concerns:

- Signup is pushed with `Navigator.push(MaterialPageRoute(...))`.
- Database debug page is pushed with `Navigator.push(MaterialPageRoute(...))`.
- Logout relies on auth notifier refresh, but route coverage is minimal.
- Redirect logic currently redirects all unauthenticated routes to `/login`, so `/signup` must be explicitly allowed when it becomes a route.

### Current Database Usage

SQLite is wrapped by `DatabaseAbstraction`.

Current startup schema in `main.dart`:

```sql
CREATE TABLE IF NOT EXISTS users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  uid INTEGER NOT NULL,
  admin INTEGER
)
```

```sql
CREATE TABLE IF NOT EXISTS sessions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id)
)
```

Database concerns:

- `users.uid` is declared `INTEGER`, but Dart parses it as `String` and signup writes UUID strings.
- `users.name` is not unique at the schema level.
- `sessions` can contain multiple active sessions.
- Startup selects the first session row instead of enforcing a single active session.
- Foreign key cascade behavior is not defined.
- Schema ownership in `main.dart` makes migration tests difficult.
- SQL is embedded in service and debug ViewModel code.

### Current State Management

Current ViewModels are mostly plain Dart classes, which is good.

Problems to fix:

- ViewModels expose mutable `ValueNotifier` objects.
- `LoginViewModel.login` and `SignupViewModel.createUser` return `null` for failure.
- Broad catches hide the real error.
- ViewModels depend on service classes that perform direct SQL.
- Views own transient text controller state without state restoration.
- Some controllers are not disposed.

### Current Restoration Support

No restoration support exists yet:

- `MaterialApp.router` has no `restorationScopeId`.
- Pages do not use `RestorationMixin`.
- Text inputs use normal `TextEditingController`.
- There is no reusable restorable ViewModel contract.

Reference repository `MarlonJD/flutter_restorable_mvvm` shows:

- ViewModels can own restorable properties.
- Views can register those properties from `restoreState`.
- A naive `RestorableValueNotifier<T>` can work for primitives.

Reference concern:

- The reference exposes a mutable `ValueNotifier`, which lets callers mutate `.value` without calling `RestorableProperty.notifyListeners()`. This starter should expose `ValueListenable<T>` publicly and keep mutation controlled.

### Current Tests

Current tests:

- `test/widget_test.dart` is commented out.
- `test/home_test.dart` has one basic Home widget test with a fake `UserService`.
- `test/flutter_test_config.dart` manually loads English easy_localization data.

Testing gaps:

- No repository tests.
- No database tests.
- No migration tests.
- No router redirect tests.
- No restoration tests.
- No meaningful widget coverage for login/signup.
- Generated coverage HTML is committed under `coverage/`.

### Current Documentation

README is mostly default Flutter text plus an agent harness note.

Needed documentation:

- Why MVVM.
- Why GetIt.
- Why not Riverpod in this starter.
- Why SQLite/Drift.
- Why Hive is removed.
- What restoration is and is not.
- Folder conventions.
- Feature creation guide.
- Test strategy.
- Migration strategy.

## Architecture Recommendation

Recommended dependency flow:

```text
View
  -> ViewModel
    -> Repository
      -> DAO / LocalDataSource
        -> Drift / SQLite
```

Recommended app composition flow:

```text
main.dart
  -> app/bootstrap.dart
    -> app/di.dart
    -> app/app.dart
      -> app/router.dart
        -> route builder creates/injects ViewModel
```

Recommended decisions:

- Keep MVVM.
- Keep GetIt, but use it from `app/di.dart` and route/view factory composition only.
- Do not introduce Riverpod as the primary architecture dependency.
- Keep ViewModels plain Dart classes.
- Keep Views focused on rendering, user input, UI feedback, and route calls.
- Keep repositories responsible for domain use cases.
- Keep DAOs/local data sources responsible for Drift access.
- Keep app routing centralized in `app/router.dart`.
- Keep debug database as an optional debug-only feature.

## Storage Strategy

Recommended storage model:

```text
SQLite / Drift
  Canonical app and domain data:
  users, sessions, future feature data

shared_preferences
  Tiny primitive preferences only:
  themeMode, locale, onboardingSeen

Flutter restoration
  Short-lived UI state only:
  form text, selected tab, scroll position, wizard step, temporary filter,
  temporary counter

Hive
  Not included by default
```

Do not store these in restoration:

- User database.
- Session database.
- Auth token.
- Domain data.
- Settings.
- Long-lived cache.

Do not store these in `shared_preferences`:

- Users.
- Sessions.
- Auth data.
- Tokens.
- Domain data.
- Cache lists.

Recommended database schema:

```sql
users(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  uid TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL UNIQUE,
  is_admin INTEGER NOT NULL DEFAULT 0 CHECK (is_admin IN (0, 1)),
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
)
```

```sql
app_sessions(
  id INTEGER PRIMARY KEY CHECK (id = 1),
  user_id INTEGER NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
)
```

Recommended session behavior:

- Only one active session exists.
- Login replaces the single active session in a transaction.
- Logout deletes the active session.
- Startup restores session from `app_sessions`.
- User deletion cascades session cleanup.
- No code selects an arbitrary first session row.

## Restorable MVVM Design

Recommended approach: explicit `RestorationMixin` registration with a small registrar helper.

Do not start with a magical base `State` class. A base class can reduce boilerplate, but it hides lifecycle details and becomes awkward when pages need route parameters, nested tabs, multiple restoration scopes, or mixed restorable and non-restorable state. Prefer explicit registration first; add a base helper later only if repeated boilerplate becomes measurable.

Target files:

```text
lib/core/restoration/
|-- restorable_notifier.dart
|-- restorable_view_model.dart
`-- restoration_registrar.dart
```

Target interfaces:

```dart
abstract interface class RestorableViewModel {
  void registerRestorableProperties(RestorationRegistrar registrar);
  void dispose();
}
```

```dart
abstract interface class RestorationRegistrar {
  void register(RestorableProperty<Object?> property, String restorationId);
}
```

```dart
final class MixinRestorationRegistrar implements RestorationRegistrar {
  MixinRestorationRegistrar(this.state);

  final RestorationMixin state;

  @override
  void register(RestorableProperty<Object?> property, String restorationId) {
    state.registerForRestoration(property, restorationId);
  }
}
```

Typed restorable notifier recommendation:

- Prefer `RestorableIntNotifier`, `RestorableStringNotifier`, and `RestorableBoolNotifier`.
- Add `RestorableJsonNotifier<T>` only with explicit `encode` and `decode` callbacks.
- Do not expose mutable `ValueNotifier<T>`.
- Expose `ValueListenable<T>` and controlled methods.
- Ensure `toPrimitives` returns only StandardMessageCodec-compatible data.
- Ensure `fromPrimitives` validates types.

Example page target:

```dart
class LoginViewModel implements RestorableViewModel {
  LoginViewModel({required AuthRepository authRepository})
      : _authRepository = authRepository;

  final AuthRepository _authRepository;

  final RestorableTextEditingController nameController =
      RestorableTextEditingController();

  final ValueNotifier<UiState<User>> _state =
      ValueNotifier<UiState<User>>(const UiState.idle());

  ValueListenable<UiState<User>> get state => _state;

  Future<Result<User>> login() async {
    final name = nameController.value.text.trim();
    if (name.isEmpty) {
      return const Result.failure(AppError.validation("auth.nameRequired"));
    }
    return _authRepository.login(name);
  }

  @override
  void registerRestorableProperties(RestorationRegistrar registrar) {
    registrar.register(nameController, "name");
  }

  @override
  void dispose() {
    nameController.dispose();
    _state.dispose();
  }
}
```

```dart
class LoginView extends StatefulWidget {
  const LoginView({super.key, required this.viewModel});

  final LoginViewModel viewModel;

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> with RestorationMixin {
  LoginViewModel get viewModel => widget.viewModel;

  @override
  String? get restorationId => "login_view";

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    viewModel.registerRestorableProperties(
      MixinRestorationRegistrar(this),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: viewModel.nameController.value,
    );
  }

  @override
  void dispose() {
    viewModel.dispose();
    super.dispose();
  }
}
```

## Proposed Folder Structure

```text
lib/
  app/
    app.dart
    bootstrap.dart
    di.dart
    router.dart
    routes.dart

  core/
    database/
      app_database.dart
      app_database_connection.dart
      migrations.dart
    errors/
      app_error.dart
    localization/
      localization_keys.dart
    preferences/
      app_preferences.dart
    result/
      result.dart
      ui_state.dart
    restoration/
      restorable_notifier.dart
      restorable_view_model.dart
      restoration_registrar.dart
    utils/

  features/
    auth/
      data/
        auth_local_datasource.dart
        auth_repository.dart
      domain/
        user.dart
      presentation/
        login_view.dart
        login_view_model.dart
        signup_view.dart
        signup_view_model.dart

    home/
      presentation/
        home_view.dart
        home_view_model.dart

    settings/
      data/
        settings_repository.dart
      presentation/
        settings_view.dart
        settings_view_model.dart

    debug_database/
      presentation/
        database_debug_view.dart
        database_debug_view_model.dart
```

## Dependency Changes

Keep:

- `flutter`
- `flutter_test`
- `flutter_lints`
- `easy_localization`
- `get_it`
- `go_router`
- `path`
- `path_provider`
- `uuid`

Add:

- `drift`
- `drift_flutter`
- `drift_dev`
- `shared_preferences` only if the settings preference example is implemented

Remove:

- `hive_ce`
- `hive_ce_flutter`
- `objectbox_generator`
- direct `sqlite3` only if Drift/Drift Flutter fully covers the required platform targets

Generated files:

- Commit Drift generated Dart files if the project convention is to keep generated code available to starter users.
- Do not commit generated coverage HTML.

Lint recommendations:

- Keep strict lints.
- Consider re-enabling `use_build_context_synchronously`.
- Do not remove `avoid_catches_without_on_clauses`; refactor error handling instead.

## Refactor Plan By Phase

### Phase 0: Capture The Plan As Durable Context

**Goal:** Preserve the architecture decision and implementation path before code changes begin.

**Files affected:**

- `agent-harness/exec-plans/active/2026-07-08-professional-mvvm-architecture-refactor.md`
- `agent-harness/design-docs/index.md`
- `agent-harness/exec-plans/tech-debt-tracker.md`

**New files:**

- `agent-harness/design-docs/storage-strategy.md`
- `agent-harness/design-docs/restorable-mvvm.md`

**Deleted files:**

- None.

**Detailed steps:**

- [ ] Read `AGENTS.md`, `agent-harness/README.md`, `agent-harness/ARCHITECTURE.md`, `agent-harness/QUALITY.md`, and `agent-harness/product-specs/mvvm-starter.md`.
- [ ] Note current user-owned changes with `git status --short`.
- [ ] Add `storage-strategy.md` documenting SQLite/Drift as canonical storage, `shared_preferences` boundaries, restoration boundaries, and Hive removal.
- [ ] Add `restorable-mvvm.md` documenting explicit registration, ViewModel-owned restorable properties, safe `ValueListenable` exposure, and what restoration must not store.
- [ ] Link the new design docs from `agent-harness/design-docs/index.md`.
- [ ] Add this refactor as an active execution plan and reference related tech-debt entries.

**Risks:**

- Documentation can drift if the implementation changes decisions without updating design docs.

**Verification:**

- `not run`: code checks are not required for documentation-only plan capture.
- Manual check: links point to existing files.

**Acceptance criteria:**

- Durable design docs exist.
- Active plan captures the staged implementation.
- No product code has changed in this phase.

### Phase 1: App Shell, Composition Root, And Route Factory Boundary

**Goal:** Move app composition into `lib/app/` and make GetIt usage a root/factory concern.

**Files affected:**

- `lib/main.dart`
- `lib/route.dart`
- `lib/core/locator.dart`
- `lib/auth/login_view.dart`
- `lib/auth/signup_view.dart`
- `lib/pages/home/home_view.dart`

**New files:**

- `lib/app/app.dart`
- `lib/app/bootstrap.dart`
- `lib/app/di.dart`
- `lib/app/router.dart`
- `lib/app/routes.dart`

**Deleted files:**

- None in this phase.

**Detailed steps:**

- [ ] Create `AppRoute` constants/names in `lib/app/routes.dart`.
- [ ] Move `setupLocator()` responsibilities into `lib/app/di.dart`; keep `lib/core/locator.dart` as a transitional export only if needed.
- [ ] Create `bootstrapApp()` in `lib/app/bootstrap.dart` to initialize Flutter bindings, localization, dependencies, database/session startup, and `runApp`.
- [ ] Create `MvvmStarterApp` in `lib/app/app.dart` to own `MaterialApp.router`.
- [ ] Move `RouterService` to `lib/app/router.dart`.
- [ ] Register ViewModel factories in `di.dart`.
- [ ] Update route builders so they construct/inject ViewModels and pass them into Views.
- [ ] Keep transitional direct locator calls only where a later phase explicitly removes them.

**Risks:**

- Initialization order changes can break localization, database startup, or router redirects.

**Verification:**

- `flutter analyze`
- `flutter test`

**Acceptance criteria:**

- `main.dart` delegates to bootstrap.
- `MaterialApp.router` lives in `app/app.dart`.
- Router composition lives in `app/router.dart`.
- New ViewModel creation happens at route/factory boundaries.

### Phase 2: Drift Database Foundation

**Goal:** Replace startup SQL ownership with a Drift database foundation.

**Files affected:**

- `pubspec.yaml`
- `pubspec.lock`
- `lib/main.dart`
- `lib/core/database_abstract.dart`
- `lib/core/sqlite/native.dart`
- `lib/core/sqlite/web.dart`
- `lib/core/sqlite/unsupported.dart`
- `lib/core/sqlite/sqlite3.dart`

**New files:**

- `lib/core/database/app_database.dart`
- `lib/core/database/app_database_connection.dart`
- `lib/core/database/migrations.dart`
- `test/core/database/app_database_test.dart`
- `test/core/database/migration_test.dart`

**Deleted files:**

- Delete `lib/core/database_abstract.dart` and `lib/core/sqlite/` only after all consumers migrate.

**Detailed steps:**

- [ ] Add `drift`, `drift_flutter`, and `drift_dev`.
- [ ] Keep `build_runner`.
- [ ] Create `AppDatabase` with `Users` and `AppSessions` tables.
- [ ] Use `uid TEXT UNIQUE`, `name TEXT UNIQUE`, `is_admin` boolean/integer semantics, `created_at`, and `updated_at`.
- [ ] Enforce single active session with `app_sessions.id == 1`.
- [ ] Enable foreign keys on database open.
- [ ] Add migration strategy in `migrations.dart`.
- [ ] Decide web support: use `drift_flutter` web options or preserve explicit conditional database connection with Drift-supported web worker/wasm assets.
- [ ] Run `dart run build_runner build --delete-conflicting-outputs`.
- [ ] Add in-memory database tests for schema and constraints.

**Risks:**

- Drift web support requires worker/wasm assets and server headers for best persistence behavior.
- Generated code can produce analyzer errors until build_runner succeeds.
- Existing local databases with malformed `uid INTEGER` schema need a migration/reset decision.

**Verification:**

- `dart run build_runner build --delete-conflicting-outputs`
- `flutter analyze`
- `flutter test test/core/database`

**Acceptance criteria:**

- Drift owns database schema.
- App startup no longer creates SQL tables manually.
- Tests cover schema constraints and migration path.

### Phase 3: Auth Repository, DAO, And Session Model

**Goal:** Move auth/session behavior behind Repository and LocalDataSource/DAO boundaries.

**Files affected:**

- `lib/auth/user_service.dart`
- `lib/auth/user.dart`
- `lib/auth/login_view_model.dart`
- `lib/auth/signup_view_model.dart`
- `lib/pages/home/home_view_model.dart`
- `lib/core/database_view_model.dart`

**New files:**

- `lib/features/auth/domain/user.dart`
- `lib/features/auth/data/auth_local_datasource.dart`
- `lib/features/auth/data/auth_repository.dart`
- `test/features/auth/data/auth_repository_test.dart`

**Deleted files:**

- `lib/auth/user_service.dart` after consumers migrate.
- `lib/auth/user.dart` after consumers migrate.

**Detailed steps:**

- [ ] Create immutable domain `User` with `id`, `uid`, `name`, `isAdmin`, `createdAt`, and `updatedAt`.
- [ ] Create `AuthLocalDataSource` that depends on `AppDatabase`.
- [ ] Implement `createUser`, `findUserByName`, `watchActiveUser`, `restoreSession`, `login`, `logout`, `deleteUser`, and `deleteAllUsers`.
- [ ] Implement repository methods that expose domain-focused behavior and hide Drift row types.
- [ ] Use transactions for create-user-plus-session, login session replacement, logout, and destructive admin operations.
- [ ] Ensure user deletion cascades active session cleanup.
- [ ] Replace `UserService.userNotifier` with an auth/session listenable owned by repository or session coordinator.

**Risks:**

- Router refresh depends on a stable `Listenable`; the repository may need an adapter such as `AuthSessionController`.

**Verification:**

- `flutter test test/features/auth/data/auth_repository_test.dart`
- `flutter analyze`

**Acceptance criteria:**

- No auth service performs direct SQL.
- Single active session is enforced by database and repository behavior.
- Session startup never selects an arbitrary first row.

### Phase 4: Result, UiState, And Typed Errors

**Goal:** Replace nullable failure states with explicit outcomes.

**Files affected:**

- Auth repository and ViewModels.
- Home ViewModel.
- Debug database ViewModel.

**New files:**

- `lib/core/result/result.dart`
- `lib/core/result/ui_state.dart`
- `lib/core/errors/app_error.dart`
- `test/core/result/result_test.dart`
- `test/features/auth/presentation/login_view_model_test.dart`
- `test/features/auth/presentation/signup_view_model_test.dart`

**Deleted files:**

- None.

**Detailed steps:**

- [ ] Define `Result<T>` with `success` and `failure`.
- [ ] Define `UiState<T>` with `idle`, `loading`, `success`, and `failure`.
- [ ] Define lightweight `AppError` variants: `validation`, `notFound`, `duplicate`, `database`, and `unknown`.
- [ ] Map Drift unique constraint failures to `duplicate`.
- [ ] Map missing user login to `notFound`.
- [ ] Map empty form input to `validation`.
- [ ] Update Login and Signup ViewModels to return `Future<Result<User>>` or expose `UiState<User>`.
- [ ] Remove broad catches that return `null`.

**Risks:**

- Too much error taxonomy can overcomplicate the starter; keep variants small.

**Verification:**

- `flutter test test/core/result test/features/auth/presentation`
- `flutter analyze`

**Acceptance criteria:**

- Auth ViewModels do not use `null` as error state.
- User-facing failure paths can be tested without throwing broad exceptions.

### Phase 5: go_router-Only Navigation

**Goal:** Remove `MaterialPageRoute` usage and centralize routes in go_router.

**Files affected:**

- `lib/app/router.dart`
- `lib/app/routes.dart`
- `lib/auth/login_view.dart`
- `lib/auth/signup_view.dart`
- `lib/pages/home/home_view.dart`
- `lib/core/database_view.dart`

**New files:**

- `test/app/router_test.dart`

**Deleted files:**

- None.

**Detailed steps:**

- [ ] Add route names and paths for `home`, `login`, `signup`, and `debugDatabase`.
- [ ] Allow unauthenticated users to access `/login` and `/signup`.
- [ ] Redirect unauthenticated users away from protected routes.
- [ ] Redirect authenticated users away from `/login` and `/signup` to `/`.
- [ ] Add debug database route only when `kDebugMode` is true.
- [ ] Replace signup navigation with `context.pushNamed(AppRoute.signup.name)`.
- [ ] Replace database debug navigation with `context.pushNamed(AppRoute.debugDatabase.name)`.
- [ ] Replace signup success pop with `context.pop()` or `context.goNamed(AppRoute.login.name)` depending on final UX.
- [ ] Search with `rg "MaterialPageRoute|Navigator.push" lib` and remove remaining feature-view route pushes.

**Risks:**

- Redirect loops can occur if auth state changes synchronously during routing.

**Verification:**

- `flutter test test/app/router_test.dart`
- `flutter analyze`
- `rg "MaterialPageRoute|Navigator.push" lib`

**Acceptance criteria:**

- `go_router` is the only navigation system for app routes.
- Router redirect behavior is covered by tests.

### Phase 6: Restorable MVVM Infrastructure

**Goal:** Add reusable Flutter restoration support for MVVM pages.

**Files affected:**

- `lib/app/app.dart`
- Login and Signup ViewModels/Views.

**New files:**

- `lib/core/restoration/restorable_notifier.dart`
- `lib/core/restoration/restorable_view_model.dart`
- `lib/core/restoration/restoration_registrar.dart`
- `test/core/restoration/restorable_notifier_test.dart`
- `test/features/auth/presentation/login_restoration_test.dart`
- `test/features/auth/presentation/signup_restoration_test.dart`

**Deleted files:**

- None.

**Detailed steps:**

- [ ] Add `restorationScopeId: "mvvm_starter"` to `MaterialApp.router`.
- [ ] Add `RestorableViewModel` interface.
- [ ] Add `RestorationRegistrar` and `MixinRestorationRegistrar`.
- [ ] Add typed restorable notifiers that expose `ValueListenable<T>` publicly.
- [ ] Use Flutter's built-in `RestorableTextEditingController` for Login and Signup name fields.
- [ ] Make LoginView and SignupView use `RestorationMixin`.
- [ ] Register ViewModel-owned restorable properties from `restoreState`.
- [ ] Dispose restorable properties through ViewModel disposal.
- [ ] Add tests using `tester.restartAndRestore()`.

**Risks:**

- Public mutable notifiers can bypass restoration notifications if the wrapper is too permissive.
- Restorable state can be misunderstood as persistence unless docs are explicit.

**Verification:**

- `flutter test test/core/restoration test/features/auth/presentation/login_restoration_test.dart test/features/auth/presentation/signup_restoration_test.dart`
- `flutter analyze`

**Acceptance criteria:**

- Login and Signup name input restore after simulated restart.
- Restorable wrappers do not expose mutable `ValueNotifier<T>`.
- Docs state that restoration is not domain persistence.

### Phase 7: Feature Folder Migration

**Goal:** Move auth, home, settings, and debug database into the proposed feature structure.

**Files affected:**

- `lib/auth/*`
- `lib/pages/home/*`
- `lib/core/database_view.dart`
- `lib/core/database_view_model.dart`
- Imports across `lib/` and `test/`.

**New files:**

- `lib/features/auth/presentation/login_view.dart`
- `lib/features/auth/presentation/login_view_model.dart`
- `lib/features/auth/presentation/signup_view.dart`
- `lib/features/auth/presentation/signup_view_model.dart`
- `lib/features/home/presentation/home_view.dart`
- `lib/features/home/presentation/home_view_model.dart`
- `lib/features/debug_database/presentation/database_debug_view.dart`
- `lib/features/debug_database/presentation/database_debug_view_model.dart`
- Optional `lib/features/settings/...` if preferences are included.

**Deleted files:**

- Old files under `lib/auth/`.
- Old files under `lib/pages/home/`.
- Old database debug files under `lib/core/`.

**Detailed steps:**

- [ ] Move domain user to `features/auth/domain`.
- [ ] Move auth UI and ViewModels to `features/auth/presentation`.
- [ ] Move home UI and ViewModel to `features/home/presentation`.
- [ ] Move database debug UI and ViewModel to `features/debug_database/presentation`.
- [ ] Update package imports.
- [ ] Ensure Views receive ViewModels through constructors.
- [ ] Ensure ViewModels avoid `BuildContext`, `Navigator`, `ScaffoldMessenger`, direct SQL, and direct locator usage.
- [ ] Localize user-facing strings as files move.

**Risks:**

- Broad moves can obscure behavior changes in review.

**Verification:**

- `flutter analyze`
- `flutter test`
- `rg "locator<|locator\\.get" lib/features`

**Acceptance criteria:**

- Feature files live under `lib/features`.
- No feature View calls `locator<T>()`.
- Debug database is a debug feature, not a core database abstraction.

### Phase 8: Localization Cleanup

**Goal:** Keep localization clean without making it the main refactor.

**Files affected:**

- `assets/translations/en-US.json`
- `assets/translations/tr-TR.json`
- Feature Views.

**New files:**

- `lib/core/localization/localization_keys.dart`
- Optional `test/localization/localization_keys_test.dart`

**Deleted files:**

- None.

**Detailed steps:**

- [ ] Define a key naming convention, such as `auth.login.title`, `auth.login.nameLabel`, `home.welcome`.
- [ ] Move hard-coded product UI strings to translation files.
- [ ] Ensure English and Turkish files have matching keys.
- [ ] Keep debug-only copy simple, but prefer localization if visible in product flow.
- [ ] Add a localization key inventory test or reuse harness script if it lands first.

**Risks:**

- Localization can balloon scope if every debug label is polished.

**Verification:**

- `flutter test test/localization` if added.
- `flutter analyze`

**Acceptance criteria:**

- Main auth/home user-facing strings use translation keys.
- Supported locale files have matching key sets.

### Phase 9: Test Suite Hardening

**Goal:** Add professional but realistic starter coverage.

**Files affected:**

- `test/`
- `test/flutter_test_config.dart`

**New files:**

- `test/features/auth/data/auth_repository_test.dart`
- `test/features/auth/presentation/login_view_model_test.dart`
- `test/features/auth/presentation/signup_view_model_test.dart`
- `test/features/home/presentation/home_view_model_test.dart`
- `test/features/auth/presentation/login_view_test.dart`
- `test/features/auth/presentation/signup_view_test.dart`
- `test/features/home/presentation/home_view_test.dart`
- `test/app/router_test.dart`
- `test/core/database/app_database_test.dart`
- `test/core/database/migration_test.dart`
- `test/core/restoration/restorable_notifier_test.dart`
- `test/core/restoration/restoration_widget_test.dart`

**Deleted files:**

- Replace or remove the commented-out `test/widget_test.dart`.

**Detailed steps:**

- [ ] Add in-memory Drift database test helpers.
- [ ] Add repository tests for create user, duplicate user, login unknown user, single active session, logout, and user deletion cascade.
- [ ] Add ViewModel tests with fake repositories.
- [ ] Add router redirect tests.
- [ ] Add restoration tests with `tester.restartAndRestore()`.
- [ ] Add widget tests for login, signup, home, and logout UI.
- [ ] Keep tests stable with keys where localized text is ambiguous.

**Risks:**

- Tests can become brittle if they assert implementation details rather than behavior.

**Verification:**

- `flutter test`
- `flutter test --coverage` only when coverage artifact is requested or CI needs it.

**Acceptance criteria:**

- Core architecture behavior is covered.
- Starter users have clear examples for unit, widget, repository, router, database, and restoration tests.

### Phase 10: README, Cleanup, And CI

**Goal:** Make the starter self-explanatory and remove generated/source-control noise.

**Files affected:**

- `README.md`
- `.gitignore`
- `test_command.md`
- `agent-harness/ARCHITECTURE.md`
- `agent-harness/QUALITY.md`
- `agent-harness/exec-plans/tech-debt-tracker.md`
- `pubspec.yaml`
- `pubspec.lock`

**New files:**

- Optional `.github/workflows/flutter-ci.yml`

**Deleted files:**

- `coverage/` generated HTML and `coverage/lcov.info` from source control.
- Old Hive wrapper files.
- Old raw sqlite wrapper files after Drift migration.

**Detailed steps:**

- [ ] Rewrite README with architecture overview, folder conventions, storage strategy, restoration boundaries, feature creation guide, testing strategy, and migration strategy.
- [ ] Explain why MVVM is kept.
- [ ] Explain why GetIt is kept and constrained to composition.
- [ ] Explain why Riverpod is not the main dependency in this starter.
- [ ] Explain why SQLite/Drift is recommended.
- [ ] Explain why Hive is removed.
- [ ] Add `coverage/` to `.gitignore`.
- [ ] Remove committed generated coverage artifacts.
- [ ] Remove unused Hive and ObjectBox dependencies.
- [ ] Add CI suggestion for `flutter analyze` and `flutter test`.
- [ ] Update harness tech-debt entries as retired or narrowed.

**Risks:**

- README can overpromise if it describes features not yet implemented.

**Verification:**

- `flutter analyze`
- `flutter test`
- Optional markdown link checker if available.

**Acceptance criteria:**

- README is no longer default Flutter text.
- Generated coverage is not tracked.
- Dependency list matches the architecture.
- Harness docs match the final structure.

## Testing Plan

Unit tests:

- `LoginViewModel` validates empty name, unknown user, loading/success/failure state.
- `SignupViewModel` validates empty name, duplicate name, admin example behavior if retained.
- `HomeViewModel` exposes active user and logs out without BuildContext.
- `DatabaseDebugViewModel` watches users and sessions through repository/DAO, not raw SQL.

Repository tests:

- Create user succeeds.
- Duplicate name fails with typed duplicate error.
- Login unknown user fails with typed not-found error.
- Login creates/replaces single active session.
- Logout clears active session.
- Deleting active user clears session through cascade.
- Delete all users clears sessions.

Database tests:

- Schema creates `users` and `app_sessions`.
- `uid` and `name` are unique.
- `is_admin` accepts only valid boolean/integer values.
- Foreign keys are enabled.
- `ON DELETE CASCADE` works.
- Migration from legacy schema is handled or explicitly reset for starter usage.

Router tests:

- Unauthenticated `/` redirects to `/login`.
- Unauthenticated `/signup` is allowed.
- Authenticated `/login` redirects to `/`.
- Authenticated `/signup` redirects to `/` unless signup is explicitly allowed.
- Logout causes router refresh and redirects to `/login`.
- Debug database route is available only in debug builds.

Restoration tests:

- Login name input restores after simulated restart.
- Signup name input restores after simulated restart.
- Temporary selected tab/filter restores if added.
- Session/auth data is not restored from restoration properties.

Widget tests:

- Login renders localized title/input/button.
- Login displays validation and not-found feedback.
- Signup displays duplicate-user feedback.
- Home displays active user and supports logout.
- Debug database view renders users/sessions in debug route.

## Documentation Plan

README sections:

- Project purpose.
- Architecture overview.
- MVVM dependency flow.
- Why GetIt.
- Why not Riverpod.
- Routing with go_router.
- Storage strategy.
- Drift schema and migration strategy.
- Why Hive is not included by default.
- Restoration strategy and boundaries.
- Folder conventions.
- How to create a new feature.
- Localization conventions.
- Testing strategy.
- Common commands.

Harness docs:

- Add or update design docs for storage and restoration.
- Update `agent-harness/ARCHITECTURE.md` after implementation.
- Update `agent-harness/QUALITY.md` with new test commands.
- Retire or narrow tech-debt entries for schema ownership, MVVM boundary checks, localization, and auth/navigation smoke tests.

## Open Questions And Assumptions

Assumptions:

- This starter does not need to preserve production user data across the refactor.
- A dev migration/reset strategy is acceptable for malformed local databases unless the user asks for a true migration from all legacy states.
- Keep debug database page, but make it debug-only and route-based.
- Keep web support unless explicitly dropped; Drift web support needs worker/wasm assets and deployment notes.
- Keep `uuid` for local user UID generation.
- Add `shared_preferences` only if a settings example lands.

Non-blocking questions:

- Should signup be reachable while already authenticated, or should authenticated users be redirected home?
- Should the `admin` username behavior remain as a teaching example, or should admin be removed from the starter?
- Should Drift generated files be committed for starter usability, or generated by users locally?

## Completion Criteria

- MVVM flow is `View -> ViewModel -> Repository -> DAO/LocalDataSource -> Drift/SQLite`.
- GetIt is only used at composition/factory boundaries.
- Feature Views do not call `locator<T>()`.
- `go_router` is the only navigation system for app routes.
- Hive is removed from the starter.
- Drift/SQLite is canonical app data storage.
- Session model guarantees a single active session.
- Restoration is available for page-level ephemeral UI state.
- Login and Signup demonstrate restorable ViewModel-owned text state.
- Error handling uses `Result<T>`, `UiState<T>`, and lightweight typed errors.
- README and harness docs explain the architecture.
- Tests cover ViewModels, repositories, database/migrations, router redirects, restoration, and representative widgets.
- `flutter analyze` passes.
- `flutter test` passes.

## Future Implementation Prompt

```text
You are working in /Users/marlonjd/Developer/mobile/mvvm_starter.

Implement the professional MVVM architecture refactor described in agent-harness/exec-plans/active/2026-07-08-professional-mvvm-architecture-refactor.md.

Follow repo-local AGENTS.md and agent-harness instructions. Do not create, switch, rename, or delete branches unless explicitly asked in the current task. Preserve user-owned changes; at plan creation time, pubspec.lock was modified and tool/ was untracked. Do not revert unrelated work.

Architecture targets:
- Keep MVVM as the main architecture.
- Use GetIt only at the app composition/root/factory layer.
- Avoid locator<T>() directly inside feature Views.
- Use go_router as the only navigation system.
- Use SQLite/Drift as canonical app/domain data storage.
- Remove Hive from the starter unless a documented cache-only use case is approved.
- Use shared_preferences only for tiny primitive preferences if a settings example is implemented.
- Do not introduce Riverpod as the main architecture dependency.
- Use Flutter RestorationMixin/RestorableProperty for short-lived UI restoration only.

Implementation sequence:
1. Read AGENTS.md, agent-harness/README.md, ARCHITECTURE.md, QUALITY.md, product-specs/mvvm-starter.md, and the active plan.
2. Create storage/restoration design docs and update harness links.
3. Move app shell into lib/app/{app.dart,bootstrap.dart,di.dart,router.dart,routes.dart}.
4. Add Drift database foundation with users and app_sessions schema, migrations, foreign keys, single active session guarantee, and tests.
5. Refactor auth/session to View -> ViewModel -> Repository -> DAO/LocalDataSource -> Drift.
6. Add Result<T>, UiState<T>, and lightweight AppError types.
7. Replace all MaterialPageRoute route pushes with go_router routes.
8. Add restorable MVVM infrastructure with explicit registration and safe ValueListenable exposure.
9. Migrate Login, Signup, Home, and debug database into lib/features/.
10. Add unit, repository, database/migration, router, restoration, and widget tests.
11. Rewrite README and update harness docs.
12. Remove Hive/ObjectBox dependencies and generated coverage files from source control; add coverage/ to .gitignore.

Verification:
- Run flutter analyze.
- Run flutter test.
- Run focused test commands as each phase lands.
- Use flutter test --coverage only when coverage cleanup or CI artifacts require it.

Report verification with literal labels: verified locally, not run, blocked, candidate-only, release pending, production-ready.
Do not call the result production-ready without production, release, or equivalent evidence.
```

## Verification Log

- `candidate-only`: Plan file created for future implementation. No app code was changed by this planning task.
- `verified locally`: `dart run build_runner build --delete-conflicting-outputs --build-filter=lib/core/database/app_database.g.dart`
- `verified locally`: `flutter test test/core/result test/core/restoration test/core/database test/features/auth test/app/router_test.dart`
- `verified locally`: `flutter test test/features/auth/presentation test/features/home/presentation test/features/debug_database/presentation test/localization`
- `verified locally`: `flutter analyze`
- `verified locally`: `flutter test`
- `verified locally`: `rg "MaterialPageRoute|Navigator\\.push" lib` returned no matches.
- `verified locally`: `rg "locator<|locator\\.get" lib/features` returned no matches.
- `verified locally`: `rg "hive_ce|hive_ce_flutter|objectbox_generator" pubspec.yaml pubspec.lock` returned no matches.

## Decision Log

- 2026-07-08: Recommended Drift on top of SQLite for the professional starter architecture.
- 2026-07-08: Recommended removing Hive from the default starter.
- 2026-07-08: Recommended explicit restorable property registration over an abstract base State class for the first implementation.
- 2026-07-08: Recommended keeping GetIt only at app composition/factory boundaries.
- 2026-07-08: Recommended keeping Riverpod out of the main architecture to preserve MVVM/GetIt teaching clarity.
- 2026-07-08: Implemented Drift/SQLite as canonical storage and removed Hive/ObjectBox from dependencies.
- 2026-07-08: Kept GetIt usage in `lib/app/di.dart`, route factories, and bootstrap only.
- 2026-07-08: Added snapshot mode to the debug database ViewModel for deterministic widget tests while keeping live watches as the app default.

## Completion Notes

Completed on 2026-07-08. The app now uses the target MVVM flow:
`View -> ViewModel -> Repository -> LocalDataSource -> Drift/SQLite`.
GetIt is constrained to app composition/factory code, go_router is the only app
navigation system, Hive/ObjectBox dependencies are removed, restoration is used
only for short-lived login/signup text state, and tests cover database,
migration, repository, ViewModel, router, restoration, localization, and widget
behavior.
