# Handover Packet - b2-embedded

- **Sprint:** sprint-005
- **Stream:** b2-embedded
- **GitHub issue:** #143
- **Autonomy class:** DESIGN-SENSITIVE
- **Branch:** feat/sprint-005-b2-embedded
- **Worktree:** C:\Users\urruegg\source\urruegg\wt\sprint-005-b2-embedded
- **Approved design ref:** ADR-0033; docs/superpowers/specs/2026-08-19-power-apps-code-app-advisor-cockpit-parity-design.md; docs/superpowers/plans/2026-08-19-power-apps-code-app-advisor-cockpit-parity.md

## Goal / Definition of Done

- Build a distinct embedded B2 Code App identity.
- Add the environment-bound full-page MDA sitemap host.
- Enforce exact-origin, allowlisted, schema-validated host navigation.

## Allowed scope (paths)

- `solution/apps/sales/code-apps/advisor-cockpit-b2/**`
- `solution/apps/sales/code-app-host/**`
- `solution/schema/advisor-cockpit*.json`
- `scripts/solution/*CodeApp*`
- `scripts/solution/publish-advisor-cockpit-app.ps1`
- `scripts/solution/tests/*CodeApp*`
- `scripts/solution/tests/PublishAdvisorCockpitApp.Tests.ps1`

## Verification commands

```powershell
Push-Location solution/apps/sales
npm test --workspace @crmshow/advisor-cockpit-b2
npm run build --workspace @crmshow/advisor-cockpit-b2
Pop-Location
Invoke-Pester -Path scripts/solution/tests/*CodeApp*.Tests.ps1 -Output Detailed
```

## Guardrails

Inherit SUPERPOWERS_CONTRACT.md section 1. Headless streams additionally deny
`shell(git push)`, `shell(rm)`, `shell(git reset)`.

## Escalation rule

If a new design decision is needed -> STOP, write `BLOCKED: needs design`,
surface the question to the control-plane chat. Never self-approve.
