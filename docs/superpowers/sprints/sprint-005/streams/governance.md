# Handover Packet - governance

- **Sprint:** sprint-005
- **Stream:** governance
- **GitHub issue:** #140
- **Autonomy class:** DESIGN-SENSITIVE
- **Branch:** feat/sprint-005-governance
- **Worktree:** C:\Users\urruegg\source\urruegg\wt\sprint-005-governance
- **Approved design ref:** ADR-0033; docs/superpowers/specs/2026-08-19-power-apps-code-app-advisor-cockpit-parity-design.md; docs/superpowers/plans/2026-08-19-power-apps-code-app-advisor-cockpit-parity.md

## Goal / Definition of Done

- ADR-0041 records Code Apps as primary for bespoke full-page CRM UX.
- The attended DEV publication exception is bounded and traceable.
- The local-first Code App polish loop and path-scoped instructions are tested.

## Allowed scope (paths)

- `docs/**`
- `.github/instructions/code-apps.instructions.md`
- `.github/agents/ux-designer.agent.md`
- `scripts/solution/tests/CodeAppsGovernance.Tests.ps1`

## Verification commands

```powershell
Invoke-Pester -Path scripts/solution/tests/CodeAppsGovernance.Tests.ps1 -Output Detailed
Invoke-Pester -Path scripts/solution/tests -Output Detailed
```

## Guardrails

Inherit SUPERPOWERS_CONTRACT.md section 1. Headless streams additionally deny
`shell(git push)`, `shell(rm)`, `shell(git reset)`.

## Escalation rule

If a new design decision is needed -> STOP, write `BLOCKED: needs design`,
surface the question to the control-plane chat. Never self-approve.
