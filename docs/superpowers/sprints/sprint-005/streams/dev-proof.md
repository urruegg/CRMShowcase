# Handover Packet - dev-proof

- **Sprint:** sprint-005
- **Stream:** dev-proof
- **GitHub issue:** #145
- **Autonomy class:** DESIGN-SENSITIVE
- **Branch:** feat/sprint-005-dev-proof
- **Worktree:** C:\Users\urruegg\source\urruegg\wt\sprint-005-dev-proof
- **Approved design ref:** ADR-0033; docs/superpowers/specs/2026-08-19-power-apps-code-app-advisor-cockpit-parity-design.md; docs/superpowers/plans/2026-08-19-power-apps-code-app-advisor-cockpit-parity.md

## Goal / Definition of Done

- Publish reviewed B1/B2 assets through an attended maker action.
- Configure sharing, environment URLs, and exact DEV CSP without secrets.
- Capture least-privilege advisor evidence for both hosts.

## Allowed scope (paths)

- `scripts/solution/Publish-CodeAppsDev.ps1`
- `scripts/solution/tests/Publish-CodeAppsDev.Tests.ps1`
- `docs/runbooks/publish-code-apps-dev.md`
- `.github/workflows/cd-solution-dev.yml`
- `docs/superpowers/sprints/sprint-005/**`

## Verification commands

```powershell
Invoke-Pester -Path scripts/solution/tests/Publish-CodeAppsDev.Tests.ps1 -Output Detailed
# Then run the attended live DEV journey from the approved plan.
```

## Guardrails

Inherit SUPERPOWERS_CONTRACT.md section 1. Headless streams additionally deny
`shell(git push)`, `shell(rm)`, `shell(git reset)`.

## Escalation rule

If a new design decision is needed -> STOP, write `BLOCKED: needs design`,
surface the question to the control-plane chat. Never self-approve.
