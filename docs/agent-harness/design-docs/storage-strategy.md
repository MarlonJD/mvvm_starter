# Storage Strategy

## Decision

Use SQLite through Drift as the canonical app and domain data store.

This starter should demonstrate one durable storage path for app data instead
of mixing persistence systems. Users, auth sessions, and future domain records
belong in the Drift database. The database schema, migrations, and constraints
must be owned by the database layer, not by app startup code or Views.

Drift/SQLite is not the default storage choice for every content feature. Use
it when a feature needs durable local domain state, offline-first behavior,
relational queries, local search/filtering at scale, sync boundaries, schema
constraints, or migrations. If a feature only reads remote content and does not
need offline behavior, its repository can depend on a remote data source without
adding a Drift table.

## Boundaries

Store these in Drift/SQLite:

- Users.
- App sessions.
- Domain entities added by future features.
- Relational data that needs constraints, migrations, or queries.

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
- Enable foreign keys when opening the database.
- Use transactions for operations that change users and sessions together.
- Add migration tests when the schema version changes.

## Consequences

The app startup path becomes simpler because database setup moves behind
`AppDatabase`. Repository and ViewModel tests can use in-memory Drift
databases. Starter users have one recommended persistence model to copy.
