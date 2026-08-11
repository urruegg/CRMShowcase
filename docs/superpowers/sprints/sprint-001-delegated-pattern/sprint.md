# Sprint-001 — Delegated pattern (charter)

| Field | Value |
| --- | --- |
| **Sprint ID** | sprint-001 |
| **GitHub issue** | #TBD |
| **Status** | In progress |
| **Design spec** | [2026-08-11-delegated-sprint-operating-model-design.md](../../specs/2026-08-11-delegated-sprint-operating-model-design.md) |
| **Plan** | [2026-08-11-delegated-sprint-operating-model.md](../../plans/2026-08-11-delegated-sprint-operating-model.md) |
| **ADR** | [ADR-0023](../../../adr/ADR-0023-delegated-sprint-operating-model.md) |
| **Operating model** | [SPRINT-OPERATING-MODEL.md](../../SPRINT-OPERATING-MODEL.md) |
| **Status board** | [STATUS.md](./STATUS.md) |

---

## Outcome

Deliver **proof #1** of the delegated sprint pattern: the pattern building
itself. The sprint ships the Sprint Operating Model, the handover and intake
contracts, the GitHub issue templates, and a tested PowerShell orchestration
toolchain that turns an approved sprint plan into parallel Copilot CLI worktree
streams and re-integrates them through the existing PR-to-protected-`main`
gates. Its end-to-end validation is the **mechanism running once**: a smoke
stream is created in a worktree, dispatched through the real wrapper, produces a
commit, opens a PR, is merged to `main`, and the worktree is retired — with
evidence captured.

Proof #1 ships documentation and scripts only, so it has **no Power Platform
Test/PROD deploy**. Proof #2 (Insurance Foundation to Test/PROD through this
pattern) gets its own spec and plan.

## Streams

Each stream becomes a stream-handover issue and carries a
[handover packet](../../contracts/HANDOVER-CONTRACT.md).

| Stream | Autonomy class | Branch | Goal |
| --- | --- | --- | --- |
| toolchain | EXECUTION-ONLY | feat/sprint-001-toolchain | Build the operating-model docs, handover/intake contracts, issue templates, sprint-001 charter, and the tested `scripts/orchestration/*` toolchain. |
| smoke | EXECUTION-ONLY | feat/sprint-001-smoke | Prove the mechanism end to end: worktree → dispatch → commit → PR → merge → retire, with evidence in `STATUS.md`, plus the `DESIGN-SENSITIVE` headless-refusal demonstration. |

## Definition of done (sprint)

- [ ] `SPRINT-OPERATING-MODEL.md`, `HANDOVER-CONTRACT.md`, `INTAKE-CONTRACT.md`
      and the packet template committed via PR to `main`.
- [ ] All `scripts/orchestration/*` covered by green Pester tests.
- [ ] `ADR-0023-delegated-sprint-operating-model.md` recorded.
- [ ] Sprint Charter issue `#S` and at least one Stream issue `#N` created.
- [ ] One **smoke stream** dispatched end to end through the real wrapper
      (worktree → dispatch → commit → PR → merge → retire), evidence in
      [STATUS.md](./STATUS.md).
- [ ] Autopilot guardrail demonstrated: a `DESIGN-SENSITIVE` packet is refused a
      headless launch.
