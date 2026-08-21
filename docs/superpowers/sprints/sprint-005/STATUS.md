# Sprint 005 Status - Power Apps Code Apps Parity

Live status for charter [#139](https://github.com/urruegg/CRMShowcase/issues/139).

| Stream | Issue | Autonomy | Branch | PR | Status |
| --- | --- | --- | --- | --- | --- |
| governance | #140 | DESIGN-SENSITIVE | `feat/sprint-005-governance` | #149 | merged |
| shared-foundation | #141 | DESIGN-SENSITIVE | `feat/sprint-005-shared-foundation` | [#150](https://github.com/urruegg/CRMShowcase/pull/150) | merged |
| b1-standalone | #142 | DESIGN-SENSITIVE | `feat/sprint-005-b1-standalone` | - | ready to start |
| b2-embedded | #143 | DESIGN-SENSITIVE | `feat/sprint-005-b2-embedded` | - | ready to start |
| quality-gates | #144 | EXECUTION-ONLY | `feat/sprint-005-quality-gates` | - | blocked by B1/B2 |
| dev-proof | #145 | DESIGN-SENSITIVE | `feat/sprint-005-dev-proof` | - | blocked by implementation |
| test-proof | #146 | DESIGN-SENSITIVE | `feat/sprint-005-test-proof` | - | blocked by DEV proof |
| decision-evidence | #147 | DESIGN-SENSITIVE | `feat/sprint-005-decision-evidence` | - | blocked by DEV/TEST proof |

## Baseline

- Control-plane design and plan merged through PR #138 at `1015ab7`.
- Code Apps governance merged through PR #149 at `5e3b87d`.
- Orchestration baseline: 12 passed, 0 failed, 0 skipped.
- Eight stream issues and isolated worktrees created on 2026-08-19.
- Local PCF harness is the visual baseline; no live PCF runtime claim.
- Shared workspace extraction committed at `0353642`; honest host-capability contract committed at `29a8578`.
- User-approved local visual baseline committed at `cd4dafd` and submitted in PR #150.
- Shared foundation merged through PR #150 at `6459c8c` after CI `gate1`
	passed; stream issue #141 is closed.
- Shared-foundation verification on 2026-08-21: 13 domain tests, 23 harness tests, 2 Playwright visual comparisons, TypeScript checks, Vite build, and PCF build passed; `npm audit` reported 0 vulnerabilities.

## Approved local visual baseline

| Viewport | Snapshot | Result | Approval |
| --- | --- | --- | --- |
| Desktop `1440 x 1000` | `advisor-cockpit-desktop-win32.png` (`1440 x 1186` full page) | passed without update mode | Approved by the user in the attended Copilot session on 2026-08-21. |
| Mobile `390 x 844` | `advisor-cockpit-mobile-win32.png` (`390 x 2625` full page) | passed without update mode; no horizontal overflow | Approved by the user in the attended Copilot session on 2026-08-21. |

## Restart checkpoint - 2026-08-21

- Post-merge status synchronization is tracked in PR
	[#151](https://github.com/urruegg/CRMShowcase/pull/151); confirm its state
	before refreshing the host worktrees.
- Work stopped after human merge of shared-foundation PR #150. No B1, B2,
	quality-gate, DEV, or TEST implementation started in this session.
- Tomorrow starts by refreshing the B1 and B2 worktrees from merged `main`
	(`6459c8c`) and verifying the shared workspace in each before Tasks 5-7.
- B1 and B2 may proceed in parallel only after their branches contain the
	shared-foundation merge. Neither host stream may edit shared packages.
- The quality-gates stream must capture Linux-specific Playwright snapshots on
	`ubuntu-latest` before enabling visual comparison in CI.

## Live DEV + TEST evidence

| Environment | Pipeline / session | Result | Tests / smoke | Notes |
| --- | --- | --- | --- | --- |
| DEV | pending | not run | pending | Requires attended maker publication after implementation gates. |
| TEST | pending | not run | pending | Requires managed promotion of the exact DEV artifact. |

## Decisions and Escalations

- The approved Task 4 snapshots are Win32-specific because the attended local
	refinement session runs on Windows. Task 8 targets `ubuntu-latest`; before
	enabling its visual CI step, the quality-gates stream must capture and review
	platform-specific Linux snapshots on that runner. Docker and WSL were not
	available locally, and no cross-platform pixel tolerance was introduced.
- New design questions must return to the control-plane chat.
