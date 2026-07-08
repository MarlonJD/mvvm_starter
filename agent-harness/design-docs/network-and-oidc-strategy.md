# Network And OIDC Strategy

## Decision

Keep REST, GraphQL, OIDC, and local persistence behind the MVVM repository
boundary. A feature can fetch remote data without local persistence, or it can
add a Drift local data source when the product requires offline access,
durability, relational queries, constraints, migrations, or sync.

The starter includes `network_examples` to make the split visible:

- REST remote-only: fetch JSONPlaceholder posts and render them directly.
- REST persisted: fetch posts, replace a Drift snapshot, then render local rows.
- GraphQL remote-only: fetch Countries API data and render it directly.
- GraphQL persisted: fetch countries, replace a Drift snapshot, then render
  local rows.

## Data Access Choices

Use remote-only when:

- The content is read-only or easy to reload.
- Offline behavior is not a product requirement.
- The screen does not need local search, filtering, joins, or history.
- Losing the data after app restart is acceptable.

Use in-memory state when:

- Data only needs to survive the current screen or app process.
- The source of truth remains the remote API.
- A refresh can safely discard the old value.

Use a cache-only layer when:

- You need short-lived performance caching, not domain truth.
- Stale data can be invalidated by TTL, ETag, or server cache headers.
- The cache is clearly documented as disposable.

Use Drift local persistence when:

- The user expects offline reads or writes.
- The app must survive restart without refetching.
- Records need constraints, relationships, migrations, or local queries.
- A sync boundary is needed between local changes and remote APIs.

Use a sync model when:

- Users can edit data offline.
- Conflicts are possible.
- Records need remote ids, local dirty flags, version fields, retry queues, and
  conflict resolution policy.

## REST Shape

Remote-only:

```text
View -> ViewModel -> Repository -> RestRemoteDataSource -> REST API
```

Persisted snapshot:

```text
View -> ViewModel -> Repository
  -> RestRemoteDataSource -> REST API
  -> LocalDataSource -> Drift/SQLite
```

The persisted example intentionally returns rows read back from Drift after the
network fetch. That keeps the local boundary obvious and testable.

## GraphQL Shape

Remote-only:

```text
View -> ViewModel -> Repository -> GraphqlRemoteDataSource -> GraphQL API
```

Persisted snapshot:

```text
View -> ViewModel -> Repository
  -> GraphqlRemoteDataSource -> GraphQL API
  -> LocalDataSource -> Drift/SQLite
```

For larger GraphQL features, keep query documents near the remote data source
or generate typed clients in the data layer. Do not expose GraphQL response
maps directly to Views.

## OIDC Shape

The starter does not ship a real OIDC provider because production OIDC needs an
issuer, client id, redirect URI, platform callback configuration, token storage
policy, and provider-specific logout support. It does include the boundary that
future OIDC work should plug into:

```text
Repository/RemoteDataSource -> OidcAuthorization -> OidcTokenProvider
```

`OidcAuthorization` demonstrates:

- REST `Authorization: Bearer <access token>` headers.
- GraphQL `Authorization` plus JSON content headers.
- Refresh before use when the access token is expired or near expiry.
- Logout delegation to the provider boundary.

## OIDC Token Storage

Do not store refresh tokens in Flutter restoration, `shared_preferences`, or
plain domain tables. A real OIDC integration should use platform secure storage
such as Keychain/Keystore through an approved package, or an explicitly
reviewed encrypted storage design.

Recommended token lifetime:

- Keep access tokens short-lived.
- Refresh expired access tokens through `OidcTokenProvider.refresh()`.
- Support refresh token rotation by replacing the stored refresh token after
  each successful refresh.
- On logout, clear local token storage first, then call the provider
  end-session or revocation endpoint when available.
- Treat failed refresh as signed out unless product requirements define a
  recoverable re-auth path.

## REST And GraphQL With OIDC

REST example:

```text
headers = await oidcAuthorization.restHeaders()
GET /api/items
Authorization: Bearer <access token>
```

GraphQL example:

```text
headers = await oidcAuthorization.graphqlHeaders()
POST /graphql
Authorization: Bearer <access token>
Content-Type: application/json
```

The transport differs, but the token boundary should not. REST and GraphQL
remote data sources should both depend on the same auth header abstraction when
the backend requires OIDC.

## Testing

- Repository tests should prove remote-only paths do not write Drift tables.
- Repository tests should prove persisted paths write and read local snapshots.
- OIDC tests should prove active-token headers, refresh-before-use, and logout
  delegation without requiring a real provider.
- Widget tests should use fake repositories and avoid live network.
- Live endpoint checks can be done manually or through narrow smoke commands;
  they should not make the unit suite flaky.
