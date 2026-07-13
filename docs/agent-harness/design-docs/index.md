# Design Docs Index

Design docs capture durable decisions that future agents should be able to
discover without chat history.

## Documents

- `core-beliefs.md` - repo-level principles for agent-readable development.
- `restorable-mvvm.md` - Flutter restoration boundaries and MVVM registration
  pattern.
- `storage-strategy.md` - Drift schema/migration ownership, scoped snapshots,
  secure-token exclusion, and preference/restoration limits.
- `network-and-oidc-strategy.md` - typed REST/GraphQL transports, remote-only
  versus offline-read policy, secure native OIDC, and platform support.

## When To Add A Design Doc

Add a design doc when a decision:

- changes architecture,
- changes product direction,
- introduces a new cross-cutting pattern,
- resolves a tradeoff likely to reappear,
- should influence future code reviews.

Keep each design doc focused on one decision or one cluster of closely related
decisions.
