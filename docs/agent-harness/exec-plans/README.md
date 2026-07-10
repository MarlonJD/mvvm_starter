# Execution Plans

Execution plans are durable task records for multi-step work. They let a future
agent continue without chat history.

## Folders

- `active/` - plans currently being executed or ready to execute.
- `completed/` - plans that have shipped or been closed.
- `tech-debt-tracker.md` - accepted debt, missing checks, and cleanup work.

## Required Plan Shape

Each plan should include:

- Goal
- Scope
- Non-goals
- Files
- Acceptance criteria
- Task checklist
- Verification log
- Decision log
- Completion notes

## Status Values

- `active`: work is currently planned or in progress.
- `blocked`: work cannot continue without a named dependency or decision.
- `completed`: acceptance criteria were met.
- `superseded`: another plan replaced this one.

## Completion Rule

When a plan is completed, move the file from `active/` to `completed/` and add
a completion note with verification evidence.
