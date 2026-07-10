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
| TD-005 | Observability | No structured diagnostics or logging policy is implemented. | Runtime failures are harder for agents to inspect. | Add a lightweight diagnostics guide and structured error conventions. |
| TD-006 | Documentation | Harness docs are not checked for broken local links. | Agent map can drift as files move. | Add a markdown link check script or CI job. |
| TD-007 | Architecture | Storage and restoration decisions are documented but not mechanically enforced. | Future changes could reintroduce domain data in restoration or secondary persistence without review. | Add architectural tests or import-boundary checks for storage/restoration packages. |

## Retired

| ID | Area | Retired by | Evidence |
| --- | --- | --- | --- |
| TD-001 | Architecture | Drift database owns schema and migrations under `lib/core/database/`. | `test/core/database/app_database_test.dart`, `test/core/database/migration_test.dart` |
| TD-004 | Reliability | Auth/router smoke coverage added for redirects, home, and logout. | `test/app/router_test.dart`, `test/features/home/presentation/home_view_test.dart` |
