# Handover Packet - tenant-user-inventory

- **Sprint:** sprint-004
- **Stream:** tenant-user-inventory
- **GitHub issue:** #129
- **Autonomy class:** DESIGN-SENSITIVE (attended — control-plane session implemented directly)
- **Branch:** feat/sprint-004-tenant-user-inventory
- **Worktree:** C:\Users\urruegg\source\urruegg\wt\sprint-004-tenant-user-inventory
- **Approved design ref:** docs/superpowers/specs/2026-08-17-advisor-cockpit-demo-data-design.md · docs/superpowers/plans/2026-08-17-advisor-cockpit-demo-data.md (Task 4)

## Goal / Definition of Done

`scripts/solution/Get-DemoPresenterUser.ps1` resolves the demo presenter
identity at runtime for a given Dataverse environment: the enabled,
interactive (`accessmode = 0`) `System Administrator`. Never a committed
personal identifier. Supports an explicit `-PresenterUserId` override.

Done: 6/6 Pester green (offline, mocked); live-confirmed against
`crmshowdev` — the sole enabled interactive user is
`admin@ABSx15847880.onmicrosoft.com` ("MOD Administrator",
`systemuserid 8b9ce77c-e38d-f111-ab0f-000d3a5bcb42`, roles `System
Administrator` + `Basic User`); the CI application user
`# crm-showcase-ci-dev` (`accessmode 4`) is correctly excluded.

## Allowed scope (paths)

- `scripts/solution/Get-DemoPresenterUser.ps1`
- `scripts/solution/tests/Get-DemoPresenterUser.Tests.ps1`

## Verification commands

```
Import-Module Pester -RequiredVersion 6.0.1 -Force
Invoke-Pester -Path scripts/solution/tests/Get-DemoPresenterUser.Tests.ps1 -Output Detailed
```

## Guardrails

Inherit SUPERPOWERS_CONTRACT.md section 1. No personal identifier (UPN,
e-mail, systemuserid of a specific human) is committed to source — the
script resolves it at runtime, every time, against the live environment.

## Escalation rule

If a new design decision is needed -> STOP, write `BLOCKED: needs design`,
surface the question to the control-plane chat. Never self-approve.

## Live verification note (2026-08-17)

Also confirmed the `accessmode` assumption directly: querying
`crmshowdev`'s enabled `systemusers` shows every built-in/CI application
user (e.g. `# crm-showcase-ci-dev`, `# OC Messaging Prod`,
`D365SalesAgentsWorkspace`, etc.) at `accessmode = 4`, while
`admin@ABSx15847880.onmicrosoft.com` is the **only** `accessmode = 0`
(interactive) user in the environment — the filter design holds without
adjustment.
