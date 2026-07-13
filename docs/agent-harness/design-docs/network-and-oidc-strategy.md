# Network And OIDC Strategy

## Decision

Keep REST, GraphQL, OIDC, and local persistence behind the MVVM repository
boundary. Use the shared typed HTTP executor for both protocols, keep payload
mapping in remote data sources, and add Drift only when offline/restart
behavior is an explicit product contract.

## Data Access Choices

| Requirement | Boundary | Contract |
| --- | --- | --- |
| Reloadable read-only content | Remote-only | No Drift access; remote failure is visible. |
| Short-lived process state | ViewModel/memory | Lost on restart and safe to refetch. |
| Disposable performance cache | Cache-only adapter | Explicit TTL/ETag invalidation; not domain truth. |
| Restart-safe offline reads | Remote-first repository + Drift snapshot | Replace on success; scoped fresh/stale fallback on network failure. |
| Offline edits | Dedicated sync architecture | Outbox, IDs, versions, retries, and conflict policy. Not implemented. |

Do not turn every API response into a database table. Do not present snapshot
persistence as offline-write support.

## Typed REST Flow

```text
View
  -> NetworkExamplesViewModel
  -> NetworkExamplesRepository
  -> RestPostsRemoteDataSource
  -> HttpRequestExecutor
  -> configured REST endpoint
```

`REST_POSTS_URL` selects the HTTPS endpoint. The REST source adds its query
parameters, the shared executor applies a 15-second timeout and optional bearer
header, and DTO parsing rejects malformed envelopes/fields with typed
`NetworkException` categories.

Remote-only returns mapped domain posts without touching Drift. The persisted
method replaces the selected snapshot after success and returns
`DataOrigin.remote`.

## Typed GraphQL Flow

```text
View
  -> NetworkExamplesViewModel
  -> NetworkExamplesRepository
  -> GraphqlCountriesRemoteDataSource
  -> GraphqlRequestExecutor
  -> HttpRequestExecutor
  -> configured GraphQL endpoint
```

`GRAPHQL_URL` selects the HTTPS endpoint. The executor sends a document,
variables, and optional operation name in a JSON request. It validates the
GraphQL envelope, rejects nonempty `errors`, requires a data object, and keeps
response maps out of Views.

Remote-only does not touch Drift. Persisted GraphQL uses the same snapshot
policy as REST.

## Shared Transport Contract

`HttpRequestExecutor`:

- accepts HTTPS endpoints, with HTTP limited to localhost tests;
- applies a timeout to each attempt;
- maps timeout, transport, HTTP status, unauthorized, payload, and GraphQL
  failures;
- injects the current OIDC bearer header when one exists;
- on 401, requests one forced refresh and replays once;
- never loops on repeated 401 responses.

Local read/write failures map to database errors rather than network errors.

## Offline Read And Identity Scope

Persisted REST and GraphQL reads are remote-first:

1. Capture the current persistence scope at request start.
2. Fetch remote data.
3. On success, replace only that scope in one Drift transaction.
4. On `NetworkException`, read only the captured scope.
5. Return `localFresh` when age is at most 15 minutes or `localStale` when
   older.
6. If the scope is empty, return the original remote error.

Anonymous requests use `public`. A validated OIDC token set uses
`oidc:<issuer>:<subject>`. Schema-v3 snapshots migrate to `public`, preserving
existing data while preventing private cross-identity fallback.

Successful empty remote responses clear only the selected scope. They remain a
successful remote result and do not leave an invented fallback timestamp.

## Native OIDC Flow

```text
OidcExampleView
  -> OidcExampleViewModel
  -> OidcSessionManager
  -> AppAuthOidcClient -> OIDC provider
  -> FlutterSecureOidcTokenStore -> platform secure storage
```

The provider-independent configuration comes from:

- `OIDC_ISSUER`
- `OIDC_CLIENT_ID`
- `OIDC_REDIRECT_URI`
- `OIDC_POST_LOGOUT_REDIRECT_URI`
- `OIDC_SCOPES`

The default callback scheme is `mvvmstarter`. Interactive AppAuth is
supported only on Android, iOS, and macOS. Web, Windows, and Linux expose a
deterministic unsupported state; anonymous network examples remain available.

The adapter uses authorization code + PKCE. It requires an access token,
expiration, and ID token, then validates nonblank `iss`/`sub` and issuer
origin before publishing a session.

## Secure Session Behavior

- Access, refresh, and ID tokens live only behind `OidcTokenStore`.
- Tokens never enter Drift, shared preferences, restoration, logs, errors,
  snapshots, or rendered UI.
- Expiring tokens refresh through one shared in-flight Future.
- Rotated refresh/ID tokens atomically replace the secure stored token set.
- Missing or failed refresh clears an unusable local session and requires
  reauthentication.
- Logout clears secure local state before provider end-session.
- Provider end-session failure returns a warning while local sign-out remains
  complete.

The local name auth flow is a demo route gate, not an OIDC substitute or
security boundary. Production roles must come from a trusted provider/backend
policy, never a name.

## Configuration Example

```bash
flutter run \
  --dart-define=REST_POSTS_URL=https://api.example.com/posts \
  --dart-define=GRAPHQL_URL=https://api.example.com/graphql \
  --dart-define=OIDC_ISSUER=https://identity.example.com \
  --dart-define=OIDC_CLIENT_ID=mvvm-starter-native \
  --dart-define=OIDC_REDIRECT_URI=mvvmstarter:/oauthredirect \
  --dart-define=OIDC_POST_LOGOUT_REDIRECT_URI=mvvmstarter:/logout \
  --dart-define='OIDC_SCOPES=openid profile email offline_access'
```

The provider must register both callback URIs, and the scheme must match
Android Gradle plus iOS/macOS Info.plist configuration.

## Testing And Evidence Boundary

- Executor tests cover headers, one 401 retry, timeouts, statuses, and GraphQL
  envelopes.
- OIDC tests cover cancellation, secure storage, identity validation,
  single-flight refresh, rotation, restore, and local-first logout.
- Repository tests prove remote-only isolation, restart fallback, freshness,
  empty replacement, and public/identity scope separation.
- ViewModel/widget tests prove independent section results and lifecycle-safe
  publication.

No production provider, real-device OIDC flow, or release has been verified.
The current status is `release pending`.
