# Handover Packet - quality-gates

- **Sprint:** sprint-005
- **Stream:** quality-gates
- **GitHub issue:** #144
- **Autonomy class:** EXECUTION-ONLY
- **Branch:** feat/sprint-005-quality-gates
- **Worktree:** C:\Users\urruegg\source\urruegg\wt\sprint-005-quality-gates
- **Approved design ref:** ADR-0033; docs/superpowers/specs/2026-08-19-power-apps-code-app-advisor-cockpit-parity-design.md; docs/superpowers/plans/2026-08-19-power-apps-code-app-advisor-cockpit-parity.md

## Goal / Definition of Done

- Add deterministic workspace build, unit, accessibility, and visual gates.
- Reject fixture fallback, literal environment URLs, and unsafe B2 messaging.
- Preserve read-only GitHub permissions and existing OIDC deployment posture.

## Allowed scope (paths)

- `.github/workflows/ci-solution.yml`
- `scripts/solution/Test-CodeAppsRelease.ps1`
- `scripts/solution/tests/Test-CodeAppsRelease.Tests.ps1`
- `solution/apps/sales/package*.json`
- `solution/apps/sales/Controls/AdvisorCockpit/src/AdvisorCockpit.test.tsx`

## Verification commands

```powershell
Push-Location solution/apps/sales
npm ci
npm test
npm run build
npm run test:visual
npm run release:check
Pop-Location
Invoke-Pester -Path scripts/solution/tests/Test-CodeAppsRelease.Tests.ps1 -Output Detailed
```

## Guardrails

Inherit SUPERPOWERS_CONTRACT.md section 1. Headless streams additionally deny
`shell(git push)`, `shell(rm)`, `shell(git reset)`.

## Escalation rule

If a new design decision is needed -> STOP, write `BLOCKED: needs design`,
surface the question to the control-plane chat. Never self-approve.
