# Handover Packet - b1-standalone

- **Sprint:** sprint-005
- **Stream:** b1-standalone
- **GitHub issue:** #142
- **Autonomy class:** DESIGN-SENSITIVE
- **Branch:** feat/sprint-005-b1-standalone
- **Worktree:** C:\Users\urruegg\source\urruegg\wt\sprint-005-b1-standalone
- **Approved design ref:** ADR-0033; docs/superpowers/specs/2026-08-19-power-apps-code-app-advisor-cockpit-parity-design.md; docs/superpowers/plans/2026-08-19-power-apps-code-app-advisor-cockpit-parity.md

## Goal / Definition of Done

- Build a distinct standalone B1 Code App identity.
- Use generated Dataverse services only and no fixture fallback.
- Prove record-aware native MDA navigation and supported write/reread behavior.

## Allowed scope (paths)

- `solution/apps/sales/code-apps/advisor-cockpit-b1/**`
- `solution/apps/sales/package-lock.json`

## Verification commands

```powershell
Push-Location solution/apps/sales
npm test --workspace @crmshow/advisor-cockpit-b1
npm run build --workspace @crmshow/advisor-cockpit-b1
Pop-Location
```

## Guardrails

Inherit SUPERPOWERS_CONTRACT.md section 1. Headless streams additionally deny
`shell(git push)`, `shell(rm)`, `shell(git reset)`.

## Escalation rule

If a new design decision is needed -> STOP, write `BLOCKED: needs design`,
surface the question to the control-plane chat. Never self-approve.
