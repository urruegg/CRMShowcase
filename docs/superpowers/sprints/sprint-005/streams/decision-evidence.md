# Handover Packet - decision-evidence

- **Sprint:** sprint-005
- **Stream:** decision-evidence
- **GitHub issue:** #147
- **Autonomy class:** DESIGN-SENSITIVE
- **Branch:** feat/sprint-005-decision-evidence
- **Worktree:** C:\Users\urruegg\source\urruegg\wt\sprint-005-decision-evidence
- **Approved design ref:** ADR-0033; docs/superpowers/specs/2026-08-19-power-apps-code-app-advisor-cockpit-parity-design.md; docs/superpowers/plans/2026-08-19-power-apps-code-app-advisor-cockpit-parity.md

## Goal / Definition of Done

- Reconcile every visible action with live B1/B2 evidence.
- Score both hosts without computing an automatic winner.
- Recommend a host and close the sprint without selecting it autonomously.

## Allowed scope (paths)

- `docs/testing/US-301-code-app-host-parity.md`
- `docs/adr/ADR-0033-crm-ux-placement-in-b2e-landscape.md`
- `docs/superpowers/sprints/sprint-005/**`
- `docs/superpowers/sprints/README.md`

## Verification commands

```powershell
git diff --check
# Verify all evidence links and required DEV/TEST result tables are present.
```

## Guardrails

Inherit SUPERPOWERS_CONTRACT.md section 1. Headless streams additionally deny
`shell(git push)`, `shell(rm)`, `shell(git reset)`.

## Escalation rule

If a new design decision is needed -> STOP, write `BLOCKED: needs design`,
surface the question to the control-plane chat. Never self-approve.
