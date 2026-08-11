# Sprint-002 — status board

Live status for the Insurance Foundation promotion (Proof #2, charter **#46**).
See the [charter](./sprint.md) and the
[Sprint Operating Model](../../SPRINT-OPERATING-MODEL.md).

| Stream | Issue | Class | Branch | PR | State | Evidence |
| --- | --- | --- | --- | --- | --- | --- |
| adr | #47 | DESIGN-SENSITIVE | docs/insurance-foundation-promotion | proof-#2 PR | built (attended) | ADR-0024 authored in the control plane and human-reviewed; OR-001 re-pointed |
| promote | #48 | EXECUTION-ONLY | docs/insurance-foundation-promotion | proof-#2 PR | built (delegated) | `Get-PromotionComponents` 4/4 green; real schema excludes 3 business rules + 2 overlap views; `solution-promote-test.yml` two-job DEV→TEST with exclusion gate |
| smoke | #49 | EXECUTION-ONLY | docs/insurance-foundation-promotion | proof-#2 PR | built (delegated) | `Get-PromotionSmokeResult` 3/3 green; full solution suite 139/139 |

## Run log

- Stream A (ADR-0024) authored **attended** in the control plane — DESIGN-SENSITIVE
  work is never launched headless.
- Streams B and C delegated to fresh implementer subagents (TDD, commit-per-task),
  each control-plane verified and two-stage reviewed.
- Full solution Pester suite: **139 passed, 0 failed**.
- Proof #1 (PR #45) merged to `main`; Proof #2 rebased onto `main` (clean 7 commits).
- Sprint-charter **#46** and stream issues **#47/#48/#49** created; proof-#2 **PR #50** opened to `main`.
- **Live TEST promotion is a post-merge step:** `workflow_dispatch` requires the
  workflow on the default branch (confirmed HTTP 404 pre-merge). After PR #50
  merges, run `solution-promote-test.yml` and approve the `test` protected
  environment; link the run + version + smoke evidence here.
