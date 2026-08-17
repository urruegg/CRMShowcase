# Handover Packet - mobiliar-intake-governance

- **Sprint:** sprint-004
- **Stream:** mobiliar-intake-governance
- **GitHub issue:** #128
- **Autonomy class:** DESIGN-SENSITIVE (attended — control-plane session implemented directly)
- **Branch:** feat/sprint-004-mobiliar-intake-governance
- **Worktree:** C:\Users\urruegg\source\urruegg\wt\sprint-004-mobiliar-intake-governance
- **Approved design ref:** docs/superpowers/specs/2026-08-17-advisor-cockpit-demo-data-design.md · docs/superpowers/plans/2026-08-17-advisor-cockpit-demo-data.md (Task 3)

## Goal / Definition of Done

`intake/mobiliar/` governed to the `intake/contoso-insurance/` standard.

**Key finding that reshaped this stream's actual deliverable:** generating a
fresh BOM from `intake/mobiliar/source` (via `New-SolutionBom.ps1`) produces
byte-identical component counts/shape to the already-published
`intake/contoso-insurance/bom/` (941 items each), and 920/941 items match
`intake/contoso-insurance/mappings/domain-map.csv` exactly by
`componentType|logicalName|parent` key. The 21 unmatched items are all
`Bot`/`BotComponent` rows carrying the real customer name where
contoso-insurance's already-published mapping has `ContosoInsurance`
instead — i.e. `intake/mobiliar/` is the un-anonymized twin of the exact
same solution export already fully governed. Re-authoring a second,
parallel 941-row domain-map would duplicate reviewed work and risk drift;
instead this stream's `bom/README.md` cross-references the existing map.

The genuinely new contribution is `mappings/curveball-to-fixture-map.md`:
8 concrete demo curveball scenarios (from `ideas/Mobiliar - Demo Curveballs
& Architecture.html`) mapped to concrete Advisor Cockpit fixture
enrichments — this is Task 5's actual input.

Done: `intake/mobiliar/README.md`, `bom/README.md`,
`mappings/curveball-to-fixture-map.md`, and the 4 `ideas/*.html` documents
committed; validated clean via `Test-IntakeSnapshot.ps1` (1 confirmed
false-positive, zero real PII/branding leaks).

## Allowed scope (paths)

- `intake/mobiliar/**` (excluding gitignored `.raw/`, `.scan/`, `source/`)

## Verification commands

```
. scripts/solution/Test-IntakeSnapshot.ps1
Test-IntakeSnapshot -Path intake/mobiliar -ForbiddenEnvironmentHost <redacted> -ReportOnly
```

## Guardrails

Inherit SUPERPOWERS_CONTRACT.md section 1 rules 1 and 3. The real customer
name is never written into any committed file (verified via grep before
commit) — this repo already enforces this as a hard test assertion in
`scripts/solution/tests/InsuranceFoundationContract.Tests.ps1`.

## Escalation rule

If a new design decision is needed -> STOP, write `BLOCKED: needs design`,
surface the question to the control-plane chat. Never self-approve.
