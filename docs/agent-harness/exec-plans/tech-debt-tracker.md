# Technical Debt Tracker

This file tracks accepted debt and missing evidence. Retire a mechanical debt
only after its local command and configured CI gate both pass.

## Open

| ID | Area | Debt | Impact | Retirement trigger |
| --- | --- | --- | --- | --- |
| TD-002 | Architecture | MVVM/restoration boundaries now have `tool/check_mvvm_boundaries.dart` and a CI step, but the new workflow has not run externally. | Local drift is blocked, but no CI evidence exists yet. | Pass the boundary command in the committed GitHub Actions quality job. |
| TD-003 | Localization | Locale key parity is tested, but user-facing Dart strings are not mechanically inventoried. | English-only strings can still bypass translation keys. | Add a runtime-source translation inventory/coverage gate and pass it in CI. |
| TD-005 | Observability | No structured diagnostics or logging policy is implemented. | Runtime failures are harder to diagnose without risking sensitive logging. | Add a privacy-aware diagnostics design, structured error conventions, and tests. |
| TD-006 | Documentation | `tool/check_agent_harness_links.dart` and its subprocess test pass locally, but the new workflow has not run externally. | Broken-link prevention lacks CI evidence. | Pass the link checker/test in the committed GitHub Actions quality job. |
| TD-007 | Architecture | Storage/restoration import rules are checked locally, but the new workflow has not run externally. | CI has not yet proved domain data cannot drift into restoration or Views. | Pass the MVVM boundary gate in the committed GitHub Actions quality job. |
| TD-008 | Authentication | No production OIDC provider, trusted backend role policy, or real Android/iOS/macOS device flow is verified. | Provider discovery, callbacks, secure storage, refresh, and logout can vary in production. | Verify a production-like provider and backend policy on the required real-device matrix without storing secrets in the repository. |
| TD-009 | Release | The read-only multi-platform CI workflow, signing, packaging, and store/release process have no external evidence. | Local builds cannot establish distributable release quality. | Pass the committed CI matrix, then validate signed release candidates and the required distribution channels. |

## Retired

| ID | Area | Retired by | Evidence |
| --- | --- | --- | --- |
| TD-001 | Architecture | Drift owns schema and migrations under `lib/core/database/`. | `test/core/database/app_database_test.dart`, `test/core/database/migration_test.dart` |
| TD-004 | Reliability | Auth/router smoke coverage for redirects, home, and logout. | `test/app/router_test.dart`, `test/features/home/presentation/home_view_test.dart` |
