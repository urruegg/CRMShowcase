# Sprint-002 — status board

Live status for the Insurance Foundation promotion (Proof #2). See the
[charter](./sprint.md) and the
[Sprint Operating Model](../../SPRINT-OPERATING-MODEL.md).

| Stream | Issue | Class | Branch | PR | State | Evidence |
| --- | --- | --- | --- | --- | --- | --- |
| adr | #TBD | DESIGN-SENSITIVE | docs/insurance-foundation-promotion | proof-#2 PR | built (attended) | ADR-0024 authored in the control plane and human-reviewed; OR-001 re-pointed |
| promote | #TBD | EXECUTION-ONLY | docs/insurance-foundation-promotion | proof-#2 PR | built (delegated) | `Get-PromotionComponents` 4/4 green; real schema excludes 3 business rules + 2 overlap views; `solution-promote-test.yml` two-job DEV→TEST with exclusion gate |
| smoke | #TBD | EXECUTION-ONLY | docs/insurance-foundation-promotion | proof-#2 PR | built (delegated) | `Get-PromotionSmokeResult` 3/3 green; full solution suite 139/139 |

## Run log

- Stream A (ADR-0024) authored **attended** in the control plane — DESIGN-SENSITIVE
  work is never launched headless.
- Streams B and C delegated to fresh implementer subagents (TDD, commit-per-task),
  each control-plane verified and two-stage reviewed.
- Full solution Pester suite: **139 passed, 0 failed**.
- **Gated next:** create sprint-charter + stream issues; trigger the live DEV→TEST
  managed promotion under the `test` protected-environment approval; open the
  proof-#2 PR to `main`.
