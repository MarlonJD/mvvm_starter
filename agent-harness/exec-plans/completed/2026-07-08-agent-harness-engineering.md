# Agent Harness Engineering Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Establish a repository-local harness engineering system for this Flutter MVVM starter app.

**Architecture:** Keep `AGENTS.md` as the short map and put durable context in focused files under `agent-harness/`. Use execution plans and a technical debt tracker as first-class repo artifacts. Defer mechanical enforcement to follow-up plans so the bootstrap stays documentation-only and low risk.

**Tech Stack:** Flutter, Dart, get_it, go_router, easy_localization, sqlite3, hive_ce, flutter_lints, Markdown.

## Global Constraints

- Do not create, switch, rename, or delete git branches without explicit user approval.
- Keep repository documentation in English unless repo-local instructions require another language.
- Use `AGENTS.md` as the canonical cross-agent instruction file.
- Keep `CLAUDE.md` as a redirect to `AGENTS.md`.
- Track complex work in `agent-harness/exec-plans/active/`.
- Track accepted technical debt in `agent-harness/exec-plans/tech-debt-tracker.md`.

---

## Files

- Create: `AGENTS.md`
- Create: `CLAUDE.md`
- Create: `agent-harness/README.md`
- Create: `agent-harness/HARNESS_ENGINEERING.md`
- Create: `agent-harness/ARCHITECTURE.md`
- Create: `agent-harness/PLANS.md`
- Create: `agent-harness/QUALITY.md`
- Create: `agent-harness/RELIABILITY.md`
- Create: `agent-harness/SECURITY.md`
- Create: `agent-harness/design-docs/index.md`
- Create: `agent-harness/design-docs/core-beliefs.md`
- Create: `agent-harness/product-specs/index.md`
- Create: `agent-harness/product-specs/mvvm-starter.md`
- Create: `agent-harness/references/index.md`
- Create: `agent-harness/generated/README.md`
- Create: `agent-harness/exec-plans/README.md`
- Create: `agent-harness/exec-plans/tech-debt-tracker.md`
- Create: `agent-harness/exec-plans/active/2026-07-08-agent-harness-engineering.md`
- Create: `agent-harness/exec-plans/completed/README.md`
- Modify: `README.md`

## Acceptance Criteria

- `AGENTS.md` gives agents a short repo-specific map and routes deeper context to `agent-harness/`.
- `CLAUDE.md` delegates to `AGENTS.md`.
- `agent-harness/` documents architecture, planning, quality, reliability, security, product baseline, references, and design beliefs.
- `agent-harness/exec-plans/` contains `active/`, `completed/`, and `tech-debt-tracker.md`.
- Technical debt entries are concrete and retireable.
- The root README points humans to the harness.
- Markdown files contain no unfinished placeholder labels.

## Task Checklist

- [x] Create the directory structure under `agent-harness/`.
- [x] Create `AGENTS.md` as the canonical agent entry point.
- [x] Create `CLAUDE.md` as a redirect to `AGENTS.md`.
- [x] Add harness overview and operating model docs.
- [x] Add architecture, planning, quality, reliability, and security docs.
- [x] Add design, product, reference, and generated-context indexes.
- [x] Add execution plan lifecycle docs.
- [x] Add the technical debt tracker.
- [x] Update `README.md` with a short agent harness pointer.
- [x] Run documentation checks with shell search.
- [x] Run `git diff --check`.

## Verification Log

- `verified locally`: `find agent-harness -maxdepth 4 -type f | sort` confirmed the harness file map.
- `verified locally`: `git diff --check` passed with no whitespace errors.
- `verified locally`: shell placeholder search found only the acceptance-criteria wording, which was rewritten.

## Decision Log

- 2026-07-08: Use `agent-harness/` instead of `docs/` because the user explicitly requested an `agent-harness` folder.
- 2026-07-08: Treat "tech dept" as "tech debt" and use `tech-debt-tracker.md`, matching the harness engineering pattern.
- 2026-07-08: Keep this bootstrap documentation-only. Mechanical checks are tracked as debt so they can be implemented with focused tests later.

## Completion Notes

Completed on 2026-07-08. The root agent instructions, Claude redirect, harness
directory, execution plan lifecycle, and technical debt tracker are in place.
