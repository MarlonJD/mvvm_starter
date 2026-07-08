# Technical Debt Tracker

This file tracks accepted debt and missing harness enforcement. Keep entries
small enough that a future agent can convert one entry into a focused execution
plan.

## Open

| ID | Area | Debt | Impact | Retirement trigger |
| --- | --- | --- | --- | --- |
| TD-001 | Architecture | Database schema creation lives in `lib/main.dart`. | Startup owns persistence details, making schema evolution harder to test. | Move schema ownership behind a service or migration boundary with tests. |
| TD-002 | Architecture | MVVM dependency direction is documented but not mechanically enforced. | Future changes can introduce imports that bypass view models or services. | Add an import-boundary check or structural test. |
| TD-003 | Localization | User-facing strings are not guaranteed to use translation keys. | English-only strings can leak into localized UI. | Add a translation inventory and coverage check. |
| TD-004 | Reliability | Core auth/navigation flow has partial widget coverage only. | Routing regressions may be missed. | Add smoke tests for unauthenticated redirect, authenticated home, and logout. |
| TD-005 | Observability | No structured diagnostics or logging policy is implemented. | Runtime failures are harder for agents to inspect. | Add a lightweight diagnostics guide and structured error conventions. |
| TD-006 | Documentation | Harness docs are not checked for broken local links. | Agent map can drift as files move. | Add a markdown link check script or CI job. |

## Retired

No retired debt yet.
