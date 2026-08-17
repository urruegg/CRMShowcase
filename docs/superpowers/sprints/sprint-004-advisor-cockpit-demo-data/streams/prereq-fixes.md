# Handover Packet - prereq-fixes

- **Sprint:** sprint-004
- **Stream:** prereq-fixes
- **GitHub issue:** #126
- **Autonomy class:** EXECUTION-ONLY
- **Branch:** feat/sprint-004-prereq-fixes
- **Worktree:** C:\Users\urruegg\source\urruegg\wt\sprint-004-prereq-fixes
- **Approved design ref:** docs/superpowers/specs/2026-08-17-advisor-cockpit-demo-data-design.md · docs/superpowers/plans/2026-08-17-advisor-cockpit-demo-data.md (Task 1)

## Goal / Definition of Done

Fix #120: `Invoke-NativeExtensionReconciliation` in
`scripts/solution/Publish-InsuranceFoundation.ps1` unconditionally checks
existence via `Get-PicklistAttributeMetadata` and creates via a plain
`POST /EntityDefinitions(...)/Attributes` — which Dataverse rejects for
Lookup-typed attributes (`crmshow_leadclusterid`, lead -> crmshow_leadcluster).
Add a `type -eq 'Lookup'` branch that checks existence via
`ManyToOneRelationships` and creates via `POST /RelationshipDefinitions`
with `OneToManyRelationshipMetadata`, mirroring the existing custom-table
pattern in `Invoke-ExistingOrdinaryRelationshipReconciliation` /
`New-OrdinaryRelationshipMetadata` (same file, ~line 365-415, ~2180).
Follow TDD: write the failing Pester test first.

Then close #124: export the DEV-authored schema
(`crmshow_leadcluster`, `crmshow_claimprojection`, `crmshow_nextbestaction`,
`crmshow_nbaprovenance`, `crmshow_measuresnapshot`, native extensions) back
into `solution/core/datamodel` source control via
`Export-Solution.ps1` + `Unpack-Solution.ps1` against the live `crmshowdev`
environment (`pac auth` profile `crmshowdev` is already configured in this
machine; `az rest`/`az account show` confirms `admin@ABSx15847880.onmicrosoft.com`
has live access).

Done when: the new Pester test passes, the full `scripts/solution/tests`
suite is green, and `solution/core/datamodel` reflects the live DEV schema
with a diff containing only the expected new components (nothing
unexpected — stop and escalate if the diff contains anything else).

## Allowed scope (paths)

- `scripts/solution/Publish-InsuranceFoundation.ps1`
- `scripts/solution/tests/Publish-InsuranceFoundation.Tests.ps1`
- `solution/core/datamodel/**` (intake-export only, via the scripted export/unpack — do not hand-edit)

## Verification commands

```
Invoke-Pester -Path scripts/solution/tests -Output Detailed
```

## Guardrails

Inherit SUPERPOWERS_CONTRACT.md section 1. Headless streams additionally deny
`shell(git push)`, `shell(rm)`, `shell(git reset)`. Do not touch any other
schema/table beyond what the live DEV export already contains — no
speculative schema changes.

## Escalation rule

If a new design decision is needed -> STOP, write `BLOCKED: needs design`,
surface the question to the control-plane chat. Never self-approve.
