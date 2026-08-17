# Handover Packet - seed-owner-wiring

- **Sprint:** sprint-004
- **Stream:** seed-owner-wiring
- **GitHub issue:** #131
- **Autonomy class:** EXECUTION-ONLY
- **Branch:** feat/sprint-004-seed-owner-wiring
- **Worktree:** C:\Users\urruegg\source\urruegg\wt\sprint-004-seed-owner-wiring
- **Approved design ref:** docs/superpowers/specs/2026-08-17-advisor-cockpit-demo-data-design.md · docs/superpowers/plans/2026-08-17-advisor-cockpit-demo-data.md (Task 6)

## Goal / Definition of Done

Wire `Get-DemoPresenterUser` (Task 4) into `seed-advisor-cockpit.ps1`'s
account upserts (`ownerid@odata.bind`), auto-resolved when no
`-PresenterUserId` override is supplied — mirroring the existing
`Get-AccountKeyMap` auto-resolution pattern. Add the same "Seed Advisor
Cockpit demo data" + smoke-check steps to `cd-solution-test.yml` that
`cd-solution-dev.yml` already has.

**Bug found and fixed while implementing this:** `Get-DemoPresenterUser.ps1`
declares its own top-level `-EnvironmentUrl`/`-PresenterUserId` parameters.
Dot-sourcing it from `seed-advisor-cockpit.ps1` (which has the same
parameter names) silently clobbers those values back to empty — proven with
a minimal repro before writing the fix. Fixed by saving/restoring both
variables around the dot-source line.

Done: `SeedAdvisorCockpit.Tests.ps1` extended (6 new cases: owner set/omitted
on the account body, threading through `Get-AccountUpsertRequests`, presenter
auto-resolution vs. explicit override in `Invoke-AdvisorCockpitSeed`); full
offline `scripts/solution/tests` suite **433 passed, 0 failed, 2 skipped**
(Pester 6.0.1, matching CI exactly). `cd-solution-test.yml` YAML validated.

## Allowed scope (paths)

- `scripts/solution/seed-advisor-cockpit.ps1`
- `scripts/solution/tests/SeedAdvisorCockpit.Tests.ps1`
- `.github/workflows/cd-solution-test.yml`

(`scripts/solution/Get-DemoPresenterUser.ps1` and its test are Task 4's
output, merged in via that stream's own PR — not re-committed here.)

## Verification commands

```
Import-Module Pester -RequiredVersion 6.0.1 -Force
Invoke-Pester -Path scripts/solution/tests -Output Detailed
python -c "import yaml; yaml.safe_load(open('.github/workflows/cd-solution-test.yml'))"
```

## Guardrails

Inherit SUPERPOWERS_CONTRACT.md section 1. Headless streams additionally
deny `shell(git push)`, `shell(rm)`, `shell(git reset)`.

## Escalation rule

If a new design decision is needed -> STOP, write `BLOCKED: needs design`,
surface the question to the control-plane chat. Never self-approve.
