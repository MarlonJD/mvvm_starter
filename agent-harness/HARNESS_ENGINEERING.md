# Harness Engineering Operating Model

## Purpose

Harness engineering means designing the repository so agents can do reliable
work with less hidden context. The human role shifts toward defining intent,
constraints, feedback loops, and verification systems.

For this repo, the harness is not a separate product. It is the set of files,
rules, tests, scripts, and habits that make the Flutter app easier for agents
and humans to change safely.

## Source Basis

This model is adapted from OpenAI's harness engineering write-up:

- https://openai.com/tr-TR/index/harness-engineering/

The local adaptation is intentionally smaller than the source article's full
system. This repo starts with documentation and plan discipline, then promotes
repeated rules into mechanical checks.

## Core Moves

1. Keep the entry point small.
   `AGENTS.md` points to deeper files instead of holding every rule.

2. Make repo knowledge durable.
   Architecture, product intent, quality rules, and debt live in versioned
   markdown under `agent-harness/`.

3. Treat plans as artifacts.
   Multi-step work gets an execution plan with acceptance criteria, decisions,
   verification, and completion notes.

4. Make the app readable to agents.
   Tests, logs, widget keys, deterministic commands, and clear errors should
   make runtime behavior inspectable.

5. Enforce the important parts mechanically.
   Repeated review comments should become lints, tests, scripts, or CI checks.

6. Garden entropy continuously.
   Track known cleanup and missing enforcement in the tech debt tracker instead
   of relying on memory.

## Maturity Ladder

### Level 0: Map

- `AGENTS.md` exists and routes agents to the right local context.
- `CLAUDE.md` delegates to `AGENTS.md`.
- `agent-harness/` contains the initial source-of-truth documents.

### Level 1: Predictable Verification

- `flutter analyze` and `flutter test` are the default quality gates.
- Test expectations are documented in `QUALITY.md`.
- Product behavior has a spec before broad changes.

### Level 2: Execution Plan Discipline

- Complex work has an active plan.
- Plans contain acceptance criteria and verification logs.
- Completed plans move to `exec-plans/completed/`.
- Follow-up work is recorded in the tech debt tracker.

### Level 3: Mechanical Architecture Checks

- Import direction and feature layout are checked by script or tests.
- File-size and naming rules become checkable.
- Error messages explain the fix in agent-readable terms.

### Level 4: Runtime Readability

- Important widgets have stable keys.
- Smoke tests cover core navigation and authentication flows.
- Logs and failures include enough context to diagnose local runs.

### Level 5: Continuous Gardening

- Recurring maintenance tasks scan docs, quality gaps, dependency drift, and
  architectural drift.
- Small cleanup plans are created and retired continuously.

## Current Level

The repository is now at Level 0 with a documented path to Level 2. Level 1 is
partially present because Flutter linting and tests already exist. Level 3 and
above require follow-up implementation.

## Human Escalation

Ask the human when:

- The requested behavior conflicts with product intent.
- A branch, public GitHub write, release, or destructive operation is needed.
- Verification requires credentials, devices, or services unavailable locally.
- A tradeoff changes architecture or user-facing behavior.

Otherwise, make a conservative decision, update the harness if the decision is
durable, and verify locally.
