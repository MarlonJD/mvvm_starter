# Agent Harness Hardening Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Promote the bootstrap harness from documentation-only guidance into repeatable checks for architecture, docs, localization, and core app behavior.

**Architecture:** Add small, focused verification scripts and tests that encode the rules already documented in `agent-harness/`. Keep each check independently useful and avoid changing product behavior except where tests expose an existing harness gap.

**Tech Stack:** Flutter, Dart, shell, Markdown, flutter_test.

## Global Constraints

- Do not create, switch, rename, or delete git branches without explicit user approval.
- Keep repository documentation in English unless repo-local instructions require another language.
- Keep checks small enough that failures give agent-readable fix instructions.
- Add follow-up debt to `agent-harness/exec-plans/tech-debt-tracker.md` instead of expanding scope silently.

---

### Task 1: Documentation Link Check

**Files:**
- Create: `tool/check_agent_harness_links.dart`
- Modify: `agent-harness/QUALITY.md`
- Modify: `agent-harness/exec-plans/tech-debt-tracker.md`

**Interfaces:**
- Consumes: Markdown files under `agent-harness/`, `AGENTS.md`, `CLAUDE.md`, and `README.md`.
- Produces: A local command that exits nonzero when a relative markdown link points to a missing file.

- [ ] **Step 1: Add the checker**

Create `tool/check_agent_harness_links.dart` with a scanner for local markdown links and a clear error message for missing targets.

- [ ] **Step 2: Run the checker**

Run: `dart run tool/check_agent_harness_links.dart`

Expected: PASS with a summary of checked files and links.

- [ ] **Step 3: Document the gate**

Add the command to `agent-harness/QUALITY.md` under future mechanical checks and retire `TD-006` in the tech debt tracker.

### Task 2: MVVM Import Boundary Check

**Files:**
- Create: `tool/check_mvvm_boundaries.dart`
- Modify: `agent-harness/ARCHITECTURE.md`
- Modify: `agent-harness/exec-plans/tech-debt-tracker.md`

**Interfaces:**
- Consumes: Dart import statements under `lib/`.
- Produces: A local command that flags direct persistence imports from views and route bypasses that violate `ARCHITECTURE.md`.

- [ ] **Step 1: Add boundary rules**

Encode the first rule set: files ending in `_view.dart` must not import
`drift`, `app_database.dart`, feature `data/` sources, or `locator.dart`.

- [ ] **Step 2: Run the boundary check**

Run: `dart run tool/check_mvvm_boundaries.dart`

Expected: PASS for the current repository.

- [ ] **Step 3: Retire tracked debt**

Mark `TD-002` as retired when the command is documented and passing.

### Task 3: Localization Inventory

**Files:**
- Create: `tool/check_localization_keys.dart`
- Modify: `agent-harness/QUALITY.md`
- Modify: `agent-harness/exec-plans/tech-debt-tracker.md`

**Interfaces:**
- Consumes: JSON files under `assets/translations/`.
- Produces: A command that checks every supported locale has the same key set.

- [ ] **Step 1: Add locale key comparison**

Read each translation JSON file, flatten nested keys, compare key sets, and print missing keys by locale.

- [ ] **Step 2: Run the locale check**

Run: `dart run tool/check_localization_keys.dart`

Expected: PASS or a precise list of missing keys to fix in the same task.

- [ ] **Step 3: Update harness docs**

Document the command and retire or narrow `TD-003`.

### Task 4: Auth Flow Smoke Tests

**Files:**
- Create: `test/auth_flow_smoke_test.dart`
- Modify: `agent-harness/RELIABILITY.md`
- Modify: `agent-harness/exec-plans/tech-debt-tracker.md`

**Interfaces:**
- Consumes: `RouterService`, `AuthRepository`, `HomeView`, and `LoginView`.
- Produces: Widget tests for unauthenticated redirect, authenticated home
  access, and logout behavior.

- [ ] **Step 1: Add deterministic test setup**

Use in-memory Drift databases and real repositories to make auth state
deterministic without touching device storage.

- [ ] **Step 2: Add smoke tests**

Cover unauthenticated redirect to `/login`, authenticated access to `/`, and logout clearing user state.

- [ ] **Step 3: Run tests**

Run: `flutter test test/auth_flow_smoke_test.dart`

Expected: PASS.

- [ ] **Step 4: Update reliability docs**

Mark the smoke test target as covered and retire or narrow `TD-004`.

### Task 5: Schema Ownership Plan

**Files:**
- Create: `agent-harness/design-docs/database-schema-ownership.md`
- Modify: `agent-harness/exec-plans/tech-debt-tracker.md`

**Interfaces:**
- Consumes: `lib/core/database/app_database.dart`,
  `lib/core/database/migrations.dart`, and auth repository schema needs.
- Produces: a design decision for future schema ownership changes.

- [ ] **Step 1: Document current schema ownership**

Record the current Drift tables, startup flow, and risks in the design doc.

- [ ] **Step 2: Choose a migration boundary**

Specify whether future schema changes belong in the shared database, a
feature-local DAO/data source, or an app bootstrap migration.

- [ ] **Step 3: Create a follow-up implementation plan**

Create a separate active execution plan for the schema move if the design doc chooses a code change.

## Verification Log

- `candidate-only`: This hardening roadmap is ready for future execution.

## Decision Log

- 2026-07-08: Keep mechanical hardening as a separate active plan so the bootstrap harness can land without code behavior changes.

## Completion Notes

Move this plan to `completed/` after all five tasks are implemented, verified,
and their related tech debt entries are retired or narrowed.
