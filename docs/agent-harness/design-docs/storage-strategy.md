# Storage Strategy

## Decision

Use SQLite through Drift as the canonical app and domain data store.

This starter demonstrates one durable storage path for app/domain data instead
of mixing persistence systems. Users, the local demo session, and explicitly
persisted network snapshots belong in Drift. Schema, migrations, and
constraints are owned by `lib/core/database/`, not startup code or Views.

Drift/SQLite is not the default storage choice for every content feature. Use
it when a feature needs durable local domain state, offline-first behavior,
relational queries, local search/filtering at scale, sync boundaries, schema
constraints, or migrations. If a feature only reads remote content and does not
need offline behavior, its repository can depend on a remote data source without
adding a Drift table.

## Boundaries

Store these in Drift/SQLite:

- Users.
- The schema-enforced singleton local demo session.
- REST/GraphQL snapshots whose contract includes offline reads.
- Relational data that needs constraints, migrations, or queries.

Persisted network snapshots must be scoped. Anonymous data uses `public`;
validated OIDC identity data uses `oidc:<issuer>:<subject>`. Replacement
deletes/inserts only the selected scope in one transaction. Remote-only
repository methods never access Drift.

Do not store content in Drift/SQLite solely because it is displayed in the app.
Choose a remote data source, memory state, file cache, or dedicated cache layer
when that better matches the feature's lifetime and access pattern.

Do not store these in Flutter restoration:

- Users.
- Sessions.
- Auth tokens.
- Domain data.
- Settings.
- Cache lists.

Do not store OIDC access, refresh, or ID tokens in Drift, preferences,
restoration, logs, or rendered UI. They belong only behind the secure token
store.

Use `shared_preferences` only for tiny primitive preferences if a settings
example is intentionally added, such as theme mode, locale, or onboardingSeen.
Do not use `shared_preferences` for users, sessions, tokens, domain data, or
lists of cached records.

Hive is not included by default. It can be reintroduced only for a documented
cache-only use case where Drift is a poor fit and the cache is clearly not the
source of truth.

## Schema Principles

- Use Drift tables and DAOs/local data sources for database access.
- Enforce uniqueness in the schema for user `uid` and `name`.
- Store timestamps for created and updated rows.
- Keep one active session by using a singleton `app_sessions` row.
- Use composite primary keys for scoped REST and GraphQL snapshots.
- Enable foreign keys when opening the database.
- Use transactions for operations that change users and sessions together.
- Add migration tests when the schema version changes.
- Validate row counts before dropping rebuilt legacy tables.

Schema v4 preserves legacy users, keeps one deterministic valid legacy session,
and migrates every pre-scope network row into `public`. The native database
filename remains `radlofa_app` for migration continuity; do not rename it
without a tested file migration.

## Consequences

The app startup path becomes simpler because database setup moves behind
`AppDatabase`. Repository and ViewModel tests can use in-memory Drift
databases, while restart contracts use file-backed reopen tests. Starter users
have one recommended persistence model to copy.

Offline writes, an outbox, retry queues, and conflict resolution remain
non-goals. Add them as a dedicated sync architecture rather than extending the
snapshot cache implicitly.
