# MVVM Starter Product Baseline

## Purpose

This app is a Flutter starter that demonstrates an MVVM-style structure with
authentication screens, local persistence abstractions, routing, dependency
injection, and localization.

## Current User-Facing Areas

- Login flow through `/login`.
- Home view through `/`.
- Session-aware routing based on `UserService`.
- English and Turkish localization assets.

## Current Acceptance Criteria

- App initializes Flutter bindings and localization before rendering.
- Shared services are registered through `setupLocator()`.
- Local database tables for users and sessions are created at startup.
- If no user session exists, protected navigation redirects to `/login`.
- If a user session exists, the home route is available.
- Home UI can display the current user and perform logout behavior.

## Non-Goals

- Hosted authentication.
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
