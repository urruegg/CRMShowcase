# Handover Packet - shared-foundation

- **Sprint:** sprint-005
- **Stream:** shared-foundation
- **GitHub issue:** #141
- **Autonomy class:** DESIGN-SENSITIVE
- **Branch:** feat/sprint-005-shared-foundation
- **Worktree:** C:\Users\urruegg\source\urruegg\wt\sprint-005-shared-foundation
- **Approved design ref:** ADR-0033; docs/superpowers/specs/2026-08-19-power-apps-code-app-advisor-cockpit-parity-design.md; docs/superpowers/plans/2026-08-19-power-apps-code-app-advisor-cockpit-parity.md

## Goal / Definition of Done

- Extract shared domain/UI packages without behavior or pixel drift.
- Add the minimal typed host and write-capability contract.
- Capture approved desktop/mobile visual baselines from the local harness.

## Allowed scope (paths)

- `solution/apps/sales/package*.json`
- `solution/apps/sales/tsconfig*`
- `solution/apps/sales/packages/**`
- `solution/apps/sales/Controls/AdvisorCockpit/**`
- `solution/apps/sales/tests/visual/**`
- `solution/apps/sales/playwright.config.ts`

## Verification commands

```powershell
Push-Location solution/apps/sales
npm test
npm run build
npm run test:visual
Pop-Location
```

## Guardrails

Inherit SUPERPOWERS_CONTRACT.md section 1. Headless streams additionally deny
`shell(git push)`, `shell(rm)`, `shell(git reset)`.

## Escalation rule

If a new design decision is needed -> STOP, write `BLOCKED: needs design`,
surface the question to the control-plane chat. Never self-approve.
