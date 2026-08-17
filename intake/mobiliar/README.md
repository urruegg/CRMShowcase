# Mobiliar prototype intake

This folder contains review artefacts derived from a local, unpacked snapshot
of the Mobiliar reference environment's CRM prototype (the same environment
referenced at the top of this sprint's design spec —
[2026-08-17-advisor-cockpit-demo-data-design.md](../../docs/superpowers/specs/2026-08-17-advisor-cockpit-demo-data-design.md)).

## Boundary

- Evidence only: nothing in this folder is deployable.
- No Dataverse records are exported or stored here.
- Raw solution ZIP files, the unpacked source snapshot, and scan logs remain
  in ignored `.raw/`, `source/`, and `.scan/` folders (see `.gitignore`'s
  `intake/**/.raw/`, `intake/**/source/`, `intake/**/.scan/` rules).
- The source snapshot remains local and ignored because this repository is
  public and the exported web resources contain customer-branded content
  (real Bot/BotComponent names carrying the literal customer name),
  e-mail-like values, and source-environment identifiers — confirmed below.
- Only sanitized structural metadata, counts, classifications, cross-
  references, and design decisions may be committed.
- Source components are reviewed and redesigned under the CRM Showcase
  publisher; they are never copied automatically into `solution/`.
- The literal customer name must never appear in committed content — this
  repository already enforces that as a hard test assertion (see
  `scripts/solution/tests/InsuranceFoundationContract.Tests.ps1`'s
  `Mobiliar identifier or customer data` scan). This README, `bom/`, and
  `mappings/` avoid it accordingly; see "Key finding" below for the one place
  the raw export itself contains it.

## Key finding — this is the same underlying export already governed as `intake/contoso-insurance/`

Generating a fresh BOM from this folder's `.raw/model` +`source/` snapshot
(`scripts/solution/New-SolutionBom.ps1 -SourceFolder intake/mobiliar/source
-MetadataModelFolder intake/mobiliar/.raw/model`) produces **exactly 941
items** — the identical count, and identical `componentType` breakdown, as
[`intake/contoso-insurance/bom/artefacts.csv`](../contoso-insurance/bom/artefacts.csv)'s
already-published BOM (43 root components, 11 tables, 6 custom tables, 605
missing dependencies, etc. — see
[`intake/contoso-insurance/bom/README.md`](../contoso-insurance/bom/README.md)).

Cross-checking every item's `componentType|logicalName|parent` key against
[`intake/contoso-insurance/mappings/domain-map.csv`](../contoso-insurance/mappings/domain-map.csv)
(the already-authored domain/disposition/rationale analysis) finds **920 of
941 items match exactly**. The remaining **21 unmatched items are all
`Bot`/`BotComponent` rows** (the prototype's Copilot/agent component: 1 bot +
its `.gpt.default`, `.settings.Ivr`, and 18 `.topic.*` components) whose
`logicalName` in this raw snapshot carries the real customer's name in place
of `ContosoInsurance` (e.g. `cr7e8_[CUSTOMER].topic.Escalate` here vs.
`cr7e8_ContosoInsurance.topic.Escalate` in the already-published mapping —
see [`bom/README.md`](./bom/README.md) for the full generalized diff; the
literal customer name is intentionally never written into this repository,
consistent with the enforced scan in
`scripts/solution/tests/InsuranceFoundationContract.Tests.ps1`). In other
words: **this folder's raw export is the un-anonymized twin of the exact
same solution snapshot**, and the generalization applied before publishing
`intake/contoso-insurance/` was precisely — and only — renaming the bot from
the real customer name to `ContosoInsurance`.

**Consequence:** this folder does not author a second, parallel
component-level BOM and domain-mapping analysis. That would duplicate
already-reviewed work and risks the two BOMs silently drifting apart over
time. Instead, [`bom/README.md`](./bom/README.md) records this equivalence
as the authoritative cross-reference, and
[`intake/contoso-insurance/bom/`](../contoso-insurance/bom/) +
[`intake/contoso-insurance/mappings/`](../contoso-insurance/mappings/)
remain the single source of truth for the component inventory and its
domain/disposition classification.

## What this folder adds that `intake/contoso-insurance/` does not

The genuinely new, non-duplicate value here is
[`ideas/`](./ideas/): four narrative architecture/design documents (HTML,
authored during the Mobiliar prototype review, already scanned for PII/
branding leaks below and found clean) that go beyond a flat component
inventory:

| File | Content |
| --- | --- |
| `Mobiliar - CRM Architecture Decisions.html` | ~50 architecture/UX decisions and platform gotchas. Cross-checked: already fully absorbed into this repo's ADRs (ADR-0006, ADR-0007, ADR-0008, ADR-0009, ADR-0010, ADR-0014, ADR-0015, ADR-0016) and into the `Known platform gotchas` section of `.github/copilot-instructions.md` (e.g. the `@odata.bind` casing gotcha is a near-verbatim match). No new decisions found. |
| `Mobiliar - Demo Curveballs & Architecture.html` | 8 concrete "curveball" demo scenarios (cross-canton relocation cascade, building-insurance jurisdiction eligibility, GA reassignment, motor re-rating, life-event triggers, property/object changes, bundle/discount unwinding, shared-phone identity ambiguity) plus 2 contact-center integration patterns. **This is the concrete, actionable source for Task 5's fixture enrichment** — see [`mappings/curveball-to-fixture-map.md`](./mappings/curveball-to-fixture-map.md). |
| `Mobiliar - Voice Integration Architecture.html` | Contact-center/voice architecture (Teams Phone, Mobi24/Luware Nimbus contact center, ACS). Already reflected in ADR-0015 (voice-channel-boundary) and ADR-0016 (governed-outbound); no new fixture-relevant content — Advisor Cockpit fixtures do not model voice/telephony state. |
| `00. ERD Visualizer.html` | Entity-relationship diagram tool over the prototype schema. Structural only — superseded by this repo's own `solution/schema/insurance-foundation.json` and ADR-0019 (provisional insurance data model shape). |

## PII / branding scan

Re-running `scripts/solution/Test-IntakeSnapshot.ps1 -Path intake/mobiliar/source
-ForbiddenEnvironmentHost <redacted>` reproduces the existing
[`.scan/source-scan.json`](./.scan/source-scan.json) exactly: 181 files
scanned, 13 matches (7 `EmailAddress`, 6 `SourceEnvironment`) — all inside the
ignored `source/` snapshot, none in anything committed here. The same scan
run against `ideas/*.html` found zero matches (the one apparent
`EmailAddress` regex hit in `Mobiliar - CRM Architecture Decisions.html` is a
false positive on the literal string `@odata.bind`, not a real address).

## Regeneration

1. Export with `scripts/solution/Export-Solution.ps1`, specifying the source
   environment and expected organization explicitly.
2. Unpack locally to the ignored `intake/mobiliar/source/` folder with
   `scripts/solution/Unpack-Solution.ps1`.
3. Validate with `scripts/solution/Test-IntakeSnapshot.ps1`.
4. Regenerate the cross-reference comparison documented in `bom/README.md`
   with `scripts/solution/New-SolutionBom.ps1` (no `-MappingPath` needed for
   this folder — see "Key finding" above).

The governing design is
[`docs/superpowers/specs/2026-08-17-advisor-cockpit-demo-data-design.md`](../../docs/superpowers/specs/2026-08-17-advisor-cockpit-demo-data-design.md)
(sprint-004, stream `mobiliar-intake-governance`, issue #128).
