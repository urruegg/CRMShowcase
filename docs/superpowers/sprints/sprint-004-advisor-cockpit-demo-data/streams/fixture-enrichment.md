# Handover Packet - fixture-enrichment

- **Sprint:** sprint-004
- **Stream:** fixture-enrichment
- **GitHub issue:** #130
- **Autonomy class:** DESIGN-SENSITIVE (attended — control-plane session implemented directly)
- **Branch:** feat/sprint-004-fixture-enrichment
- **Worktree:** C:\Users\urruegg\source\urruegg\wt\sprint-004-fixture-enrichment
- **Approved design ref:** docs/superpowers/specs/2026-08-17-advisor-cockpit-demo-data-design.md · docs/superpowers/plans/2026-08-17-advisor-cockpit-demo-data.md (Task 5) · intake/mobiliar/mappings/curveball-to-fixture-map.md (Task 3 output)

## Goal / Definition of Done

Enrich `data/scenarios/advisor-cockpit/*.json` per Task 3's curveball map.
Implemented 7 of 8 curveballs (see commit message for the full list);
curveball #2 (building insurance) explicitly excluded — it needs a 6th
`crmshow_productline` choice option, a schema change out of scope here.

Done: all 5 touched fixture files parse as valid JSON;
`SeedAdvisorCockpit.Tests.ps1` 22/22 green (no regressions); every new
`productLine` value used (`MotorVehicle`, `LegalProtection`,
`HouseholdContents`) is one of the 5 already-defined
`crmshow_productline` GlobalChoice options.

## Allowed scope (paths)

- `data/scenarios/advisor-cockpit/**`

## Verification commands

```
Import-Module Pester -RequiredVersion 6.0.1 -Force
Invoke-Pester -Path scripts/solution/tests/SeedAdvisorCockpit.Tests.ps1 -Output Detailed
```

## Guardrails

Inherit SUPERPOWERS_CONTRACT.md section 1 rule 3 (synthetic data only — all
new records use the existing Contoso Insurance / Bern-Mittelland / Rahel
Moser convention, `.example` e-mail domain, `555` phone marker). No schema
change (confirmed the 5-option `crmshow_productline` GlobalChoice covers
every new record; curveball #2 was excluded for exactly this reason).

## Escalation rule

If a new design decision is needed -> STOP, write `BLOCKED: needs design`,
surface the question to the control-plane chat. Never self-approve.
