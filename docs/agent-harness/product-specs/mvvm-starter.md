# MVVM Starter Product Baseline

## Purpose

This app demonstrates a dependable Flutter MVVM foundation with local demo
auth, session-aware routing, typed REST/GraphQL examples, explicit offline-read
persistence, secure native OIDC, localization, and testable lifecycle behavior.

## Current User-Facing Areas

- Local name signup/login through `/signup` and `/login`.
- Session-aware Home through `/`.
- Four independent REST/GraphQL sections through `/network-examples`.
- Native OIDC example through `/oidc-example`.
- Debug database view through `/debug/database` in debug builds.
- English and Turkish localization.

Local name auth is a demo route gate. It is not a credential, role, or
production authorization boundary.

## Current Acceptance Criteria

- Bootstrap initializes Flutter bindings, localization, dependency injection,
  local app session restoration, and secure OIDC restoration before rendering.
- `lib/app/di.dart` composes shared dependencies and Views receive
  constructor-injected ViewModels.
- go_router redirects protected routes from signed-out users and reacts to
  local session changes.
- Drift schema v4 preserves legacy users, retains one deterministic valid
  legacy session, enforces one current session, and scopes persisted network
  snapshots.
- Anonymous snapshots use `public`; validated OIDC snapshots use the
  issuer/subject identity scope.
- REST and GraphQL endpoints are configurable HTTPS values and share typed,
  timeout-bounded transport behavior.
- Remote-only network calls never read or write Drift.
- Persisted calls replace a selected scope after remote success and provide
  fresh/stale local fallback only after network failure.
- All four network sections load concurrently and render success/failure
  independently.
- Native Android/iOS/macOS OIDC uses AppAuth authorization code + PKCE.
- Access, refresh, and ID tokens live only in secure storage; refresh is
  single-flight and HTTP 401 replay occurs at most once.
- OIDC logout clears secure local state before remote end-session; remote
  failure yields a warning without signing back in.
- Async ViewModels cannot publish after disposal or let older work overwrite a
  newer generation.
- Login/signup input restoration remains ephemeral UI state only.

## Supported Platforms

Anonymous REST/GraphQL and Drift are intended for Android, iOS, macOS, web,
Windows, and Linux. Interactive OIDC is supported only on Android, iOS, and
macOS when provider values and callbacks are configured.

## Non-Goals

- Shipping a production issuer, client, redirect secret, or backend.
- Treating names as credentials or deriving roles from names.
- Certifying a provider or production authorization policy.
- Offline writes, outbox processing, bidirectional sync, or conflict
  resolution.
- GraphQL subscriptions or generated GraphQL models.
- Full design system, signing, store publication, or production-ready claims.

## Release Boundary

No production issuer, provider-backed real-device session, signed package,
store release, or full external CI run has been verified. Status remains
`release pending`.

## Open Product Questions

- Will a product fork replace the local demo gate with provider/backend auth?
- Which data, if any, requires offline edits and a conflict policy?
- What observability and privacy policy applies to production failures?
- Which signed device/platform matrix is required before release?

Record resolved questions here or in a linked design doc.
