# Agent Harness

This directory is the repo-local operating system for agentic engineering.
It turns project knowledge into versioned, discoverable, and reviewable files
instead of relying on chat history or implicit memory.

The structure follows the harness engineering pattern described by OpenAI:
`AGENTS.md` stays short and acts as a map, while deeper context is split into
focused repository documents and execution plans.

Reference: https://openai.com/tr-TR/index/harness-engineering/

## Current Status

This repository is a Flutter MVVM starter app. The harness is at bootstrap
maturity: durable documentation, plan lifecycle, quality rules, and technical
debt tracking are now defined. Mechanical enforcement can be added as the next
phase.

## Reading Path

1. `../AGENTS.md` - short entry point for all agents.
2. `HARNESS_ENGINEERING.md` - operating model and maturity ladder.
3. `ARCHITECTURE.md` - current Flutter/MVVM architecture.
4. `QUALITY.md` - verification and testing policy.
5. `product-specs/index.md` - product context.
6. `exec-plans/README.md` - execution plan lifecycle.
7. `exec-plans/active/` - current multi-step work.
8. `exec-plans/tech-debt-tracker.md` - known follow-up work.

## Directory Map

```text
agent-harness/
|-- README.md
|-- HARNESS_ENGINEERING.md
|-- ARCHITECTURE.md
|-- PLANS.md
|-- QUALITY.md
|-- RELIABILITY.md
|-- SECURITY.md
|-- design-docs/
|   |-- index.md
|   `-- core-beliefs.md
|-- exec-plans/
|   |-- README.md
|   |-- active/
|   |-- completed/
|   `-- tech-debt-tracker.md
|-- generated/
|   `-- README.md
|-- product-specs/
|   |-- index.md
|   `-- mvvm-starter.md
`-- references/
    `-- index.md
```

## Harness Principles

- The repository is the source of truth for agent-readable knowledge.
- `AGENTS.md` is a table of contents, not an encyclopedia.
- Execution plans are first-class artifacts for complex work.
- Quality and architecture rules should become mechanical checks when they
  repeat.
- Technical debt is tracked continuously and retired in small changes.
- The app should become easier for agents to run, inspect, test, and debug over
  time.

## How To Add Knowledge

- Add product intent to `product-specs/`.
- Add architecture decisions to `design-docs/`.
- Add generated or derived references to `generated/`.
- Add external reference summaries to `references/`.
- Add multi-step work plans to `exec-plans/active/`.
- Add known cleanup, risk, or missing enforcement to
  `exec-plans/tech-debt-tracker.md`.

Keep each file focused. If a document becomes hard to scan, split it and update
this index.
