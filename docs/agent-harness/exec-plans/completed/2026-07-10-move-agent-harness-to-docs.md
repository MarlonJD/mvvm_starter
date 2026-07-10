# Move Agent Harness To Docs

## Objective

Move the repo-local agent harness from `agent-harness/` to
`docs/agent-harness/` and update tracked repository references to the new path.

## Scope

- Move tracked harness files under `docs/agent-harness/`.
- Update `AGENTS.md`, `CLAUDE.md`, `README.md`, and harness docs that refer to
  the old location.
- Preserve unrelated user-owned files, including untracked `tool/`.

## Acceptance Criteria

- No tracked files remain under top-level `agent-harness/`.
- Tracked docs point agents to `docs/agent-harness/`.
- `rg "agent-harness"` only reports intentional new-path references or
  historical mentions.
- Local verification is recorded with literal evidence labels.

## Verification

- `git status --short`
- `rg "agent-harness" -n AGENTS.md CLAUDE.md README.md docs`
- `flutter analyze`

## Completion Notes

- Moved tracked harness files from `agent-harness/` to
  `docs/agent-harness/`.
- Updated current agent routing docs and active harness roadmap references to
  `docs/agent-harness/`.
- Left completed execution plan history as historical context where applicable.
- Preserved untracked `tool/`.
- `verified locally`: `find agent-harness -maxdepth 4 -print` returned no
  files.
- `verified locally`: `find docs/agent-harness -maxdepth 3 -type f -print`
  confirmed the new harness location.
- `verified locally`: `rg "agent-harness" -n AGENTS.md CLAUDE.md README.md docs`
  reviewed current and historical references.
