# Network And OIDC Examples

## Objective

Add repo-local examples that show REST and GraphQL data access with and without
local persistence, plus the intended OIDC token, refresh, and logout boundaries
for REST and GraphQL clients.

## Scope

- Add a `network_examples` feature under `lib/features/`.
- Fetch and render live data from public REST and GraphQL endpoints.
- Show remote-only and Drift-backed local persistence variants.
- Keep persistence behind Repository -> LocalDataSource -> Drift.
- Keep HTTP/OIDC concerns behind remote data sources and token abstractions.
- Document when to choose remote-only, cache, offline persistence, and sync.
- Document OIDC refresh token and logout approaches for REST and GraphQL.

## Non-Goals

- Do not ship a production OIDC provider integration without issuer, client id,
  redirect URI, token storage policy, and platform configuration.
- Do not turn Drift into a default cache for every network response.
- Do not add Riverpod or another app-wide state architecture.

## Implementation Notes

- REST example endpoint: `https://jsonplaceholder.typicode.com/posts`.
- GraphQL example endpoint: `https://countries.trevorblades.com/`.
- Remote-only examples fetch and render data but do not write local tables.
- Persisted examples fetch, replace the local snapshot in Drift, and render the
  persisted rows so the boundary is visible.
- OIDC examples should be documented and represented as small abstractions that
  can be wired to either REST authorization headers or GraphQL request headers.

## Acceptance Criteria

- Home can navigate to a network examples route.
- The examples screen loads live REST and GraphQL data on entry.
- The screen shows remote-only and persisted variants for both protocols.
- Drift schema includes only the persisted example tables needed by the demo.
- Tests cover repository persistence boundaries, database constraints, route
  registration, ViewModel state, and visible widget output.
- README and harness docs explain the alternatives and OIDC boundaries.

## Verification

- `flutter test test/features/network_examples`
- `flutter test test/core/database`
- `flutter test test/app/router_test.dart`
- `flutter analyze`
- `flutter test`

## Completion Notes

- Added `network_examples` with live REST and GraphQL remote data sources.
- Added remote-only and Drift-backed persisted snapshot flows for both REST and
  GraphQL.
- Added OIDC token/header helper examples for REST headers, GraphQL headers,
  refresh-before-use, and logout delegation.
- Added `rest_posts` and `graphql_countries` Drift tables with migration and
  generated database updates.
- Added `/network-examples` go_router route and Home navigation action.
- Added README and design doc guidance for remote-only, cache, offline
  persistence, sync, and OIDC boundaries.
- `verified locally`: `curl -sS 'https://jsonplaceholder.typicode.com/posts?_limit=1'`.
- `verified locally`: `curl -sS -X POST 'https://countries.trevorblades.com/' -H 'content-type: application/json' --data '{"query":"query Countries { countries { code name emoji capital } }"}'`.
- `verified locally`: `dart run build_runner build --delete-conflicting-outputs --build-filter=lib/core/database/app_database.g.dart`.
- `verified locally`: `flutter test test/features/network_examples`.
- `verified locally`: `flutter test test/core/database`.
- `verified locally`: `flutter test test/app/router_test.dart`.
- `verified locally`: `flutter analyze`.
- `verified locally`: `flutter test`.
- `release pending`: no production release, real OIDC provider, or real backend
  integration evidence was produced.
