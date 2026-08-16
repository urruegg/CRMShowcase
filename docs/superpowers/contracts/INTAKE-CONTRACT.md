# Intake Contract — returning a stream to the trunk

| Field | Value |
| --- | --- |
| **Status** | Active contract |
| **Date** | 2026-08-11 |
| **Applies to** | Every delegated stream returning to `main` |
| **Enforced by** | [Complete-StreamIntake.ps1](../../../scripts/orchestration/Complete-StreamIntake.ps1) · [Remove-SprintWorktree.ps1](../../../scripts/orchestration/Remove-SprintWorktree.ps1) · branch protection + CODEOWNERS + CI + evals |
| **Related** | [SPRINT-OPERATING-MODEL.md](../SPRINT-OPERATING-MODEL.md) · [HANDOVER-CONTRACT.md](./HANDOVER-CONTRACT.md) · [ADR-0040](../../adr/ADR-0040-delegated-sprint-operating-model.md) · [ADR-0017](../../adr/ADR-0017-alm-everything-through-the-pipeline.md) · [design spec](../specs/2026-08-11-delegated-sprint-operating-model-design.md) |

---

## Purpose

Intake is how a delegated stream comes back to the trunk. It reuses — it does
not replace — the existing ALM gates
([ADR-0017](../../adr/ADR-0017-alm-everything-through-the-pipeline.md)). The
delegation toolchain prepares the return; a human completes it.

## The four intake conditions

A stream returns to the trunk only when all four hold:

1. **Local verification passes.** The packet's `Verification commands` pass
   locally inside the worktree, with the evidence appended to the sprint
   `STATUS.md`.
2. **A PR is opened, not a push to `main`.** The branch is pushed and a pull
   request is opened against protected `main` using the existing repo PR
   template (story + ADR + evidence checklist).
3. **The wrapper never merges and never pushes to `main`.** Merge is a human
   act, gated by branch protection, `CODEOWNERS`, CI and evals — the current
   mechanism, unchanged.
4. **The worktree is retired with a guard.** After merge, the worktree is
   removed with
   [Remove-SprintWorktree.ps1](../../../scripts/orchestration/Remove-SprintWorktree.ps1),
   which refuses to delete a worktree that still holds uncommitted or unpushed
   work.

## No script merges — merge is a human act

This is the load-bearing rule of the whole pattern.
[Complete-StreamIntake.ps1](../../../scripts/orchestration/Complete-StreamIntake.ps1)
plans and runs exactly two commands — `git push -u origin <branch>` and
`gh pr create --base main` — and **nothing else.** It has no code path that
merges, and headless streams additionally carry a `git push` deny-list so they
cannot even open the PR themselves.

Merge to `main` is therefore always performed by a named human, gated by:

- **Branch protection** on `main` — no direct pushes.
- **`CODEOWNERS`** — the required reviewers (including the Enterprise Architect
  and Responsible-AI Officer where their paths are touched).
- **CI** — the pipeline must be green.
- **Evals** — where AI behaviour changed, the eval gate must pass.

This keeps a human accountable for every change that lands on the trunk, which
is the [ADR-0040](../../adr/ADR-0040-delegated-sprint-operating-model.md)
accountability position and the answer to the A8 / A9 governance questions.

## Retirement rule — dirty trees are guarded

A worktree is only retired once its work is safely on the trunk.
[Remove-SprintWorktree.ps1](../../../scripts/orchestration/Remove-SprintWorktree.ps1)
inspects `git status --porcelain` for the worktree and **throws** if the tree is
dirty (uncommitted or unpushed work), unless the operator passes `-Force`. This
prevents a stream's work from being lost when a worktree is cleaned up, and it
keeps worktree sprawl under `wt/` bounded without risking in-progress work.

## Evidence trail

Every packet, branch, PR and `STATUS.md` row carries the stream issue number
`#N` and the sprint issue number `#S`, so a whole delegated run is auditable end
to end — from the trunk design decision through to the merged change on `main`.
