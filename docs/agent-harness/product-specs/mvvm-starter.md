# MVVM Starter Product Baseline

## Purpose

This app is a Flutter starter that demonstrates an MVVM-style structure with
authentication screens, local persistence abstractions, routing, dependency
injection, and localization.

## Current User-Facing Areas

- Login flow through `/login`.
- Signup flow through `/signup`.
- Home view through `/`.
- Network examples through `/network-examples`.
- Debug database view through `/debug/database` in debug builds.
- Session-aware routing based on `AuthRepository`.
- English and Turkish localization assets.

## Current Acceptance Criteria

- App initializes Flutter bindings and localization before rendering.
- Shared services are registered through `setupDependencies()`.
- Drift owns local database tables for users and app sessions.
- If no user session exists, protected navigation redirects to `/login`.
- If a user session exists, the home route is available.
- Home UI can display the current user and perform logout behavior.
- Network examples can fetch and render live REST and GraphQL data.
- Network examples demonstrate remote-only and Drift-backed persistence paths.
- OIDC examples document token header, refresh, and logout boundaries for REST
  and GraphQL clients.
- Login and signup name inputs restore short-lived text through Flutter
  restoration.

## Non-Goals

- Hosted authentication.
- Production OIDC provider configuration.
- Production-grade credential storage.
- Remote synchronization.
- Full design system.
- Release packaging.

## Open Product Questions

- Should sign-up and login be example-only flows or production-bound flows?
- Should all visible strings be localized before adding new screens?
- Should local session behavior persist across app reinstall or only app
  restarts?

Record answered questions here or in a linked design doc.
