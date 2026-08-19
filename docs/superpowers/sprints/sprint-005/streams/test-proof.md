# Handover Packet - test-proof

- **Sprint:** sprint-005
- **Stream:** test-proof
- **GitHub issue:** #146
- **Autonomy class:** DESIGN-SENSITIVE
- **Branch:** feat/sprint-005-test-proof
- **Worktree:** C:\Users\urruegg\source\urruegg\wt\sprint-005-test-proof
- **Approved design ref:** ADR-0033; docs/superpowers/specs/2026-08-19-power-apps-code-app-advisor-cockpit-parity-design.md; docs/superpowers/plans/2026-08-19-power-apps-code-app-advisor-cockpit-parity.md

## Goal / Definition of Done

- Promote the exact managed Sales artifact from DEV to TEST.
- Run the unchanged least-privilege B1/B2 journey in TEST.
- Demonstrate previous-version rollback and candidate restoration.

## Allowed scope (paths)

- `scripts/solution/Get-CodeAppsPromotionFacts.ps1`
- `scripts/solution/Get-PromotionSmokeResult.ps1`
- `scripts/solution/tests/Get-CodeAppsPromotionFacts.Tests.ps1`
- `scripts/solution/tests/Get-PromotionSmokeResult.Tests.ps1`
- `.github/workflows/cd-solution-test.yml`
- `docs/superpowers/sprints/sprint-005/**`

## Verification commands

```powershell
Invoke-Pester -Path scripts/solution/tests/Get-CodeAppsPromotionFacts.Tests.ps1,scripts/solution/tests/Get-PromotionSmokeResult.Tests.ps1 -Output Detailed
# Then run the managed TEST journey and rollback from the approved plan.
```

## Guardrails

Inherit SUPERPOWERS_CONTRACT.md section 1. Headless streams additionally deny
`shell(git push)`, `shell(rm)`, `shell(git reset)`.

## Escalation rule

If a new design decision is needed -> STOP, write `BLOCKED: needs design`,
surface the question to the control-plane chat. Never self-approve.
