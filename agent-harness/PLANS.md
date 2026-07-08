# Planning Standard

## When To Create An Execution Plan

Create an execution plan in `exec-plans/active/` when work has any of these
properties:

- touches more than one architectural layer,
- changes user-facing behavior,
- changes persistence, routing, localization, or dependency injection,
- introduces or removes a dependency,
- changes test strategy or quality gates,
- has unresolved tradeoffs that future agents need to see.

Small, single-file, mechanical changes can use an inline plan in chat.

## Plan File Naming

Use:

```text
YYYY-MM-DD-short-feature-name.md
```

Example:

```text
2026-07-08-agent-harness-engineering.md
```

## Required Sections

Each execution plan should include:

- Goal
- Scope
- Non-goals
- Files
- Acceptance criteria
- Task checklist
- Verification log
- Decision log
- Completion notes

## Plan Lifecycle

1. Create the plan under `exec-plans/active/`.
2. Keep the checklist current as work progresses.
3. Record important decisions in the decision log.
4. Record commands and outcomes in the verification log.
5. Move the plan to `exec-plans/completed/` when done.
6. Add follow-up work to `tech-debt-tracker.md`.

## Plan Quality Bar

- A fresh agent should be able to execute the plan without chat history.
- Acceptance criteria should be observable.
- Verification commands should be exact.
- Follow-ups should be tracked explicitly rather than left in prose.
