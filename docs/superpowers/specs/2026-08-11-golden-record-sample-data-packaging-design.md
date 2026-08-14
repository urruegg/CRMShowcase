# Design Spec — Golden-Record Sample-Data Packaging

| Field | Value |
| --- | --- |
| Date | 2026-08-11 |
| Status | Draft (autonomous; awaiting human ratification) |
| Workstream | B (of two: A = PCF review/UX-standardization; B = this) |
| Related | [pattern: golden-record-sample-data-packaging](../patterns/golden-record-sample-data-packaging.md) · [manifest](../../../data/golden-record/manifest.json) · [seed script](../../../scripts/solution/seed-advisor-cockpit.ps1) · [ADR-0026](../../adr/ADR-0026-measure-snapshot-materialized-projection.md) · #62 |

## Problem

The mockup/scenario data lives as seven typed fixtures and an ad-hoc seed script.
We need a **standard pattern** to (a) gather the canonical "golden record" master
dataset and (b) pack + publish it into **DEV and SIT** as Power Platform
sample-data packages via the deployment workflow — so every ring validates the
controls against the same records, with no real customer data.

## Approach (chosen)

Three approaches considered:

1. **Manifest + two publish paths (chosen).** Keep the fixtures as the single
   source of truth; declare a `golden-record/manifest.json`; publish via (A) the
   existing idempotent `az rest` upsert for CI/DEV and (B) a Configuration
   Migration **data package** for portable DEV → SIT promotion. Reuses what
   exists, adds only the portable-package path.
2. **Consolidated single golden JSON.** One aggregated master file. Rejected —
   duplicates the fixtures and drifts from the typed source of truth.
3. **CMT package only.** Drop the API seed. Rejected — the API seed is the best
   fit for CI and works before the tables exist; both paths have distinct value.

**Decision:** (1). The fixtures stay canonical; the manifest is the contract;
both publish paths consume it and are idempotent by alternate key.

## Design

- **Golden record** = the Contoso Insurance book anchored on the Brunner
  household (UC-01), synthetic only (ADR-0026, copilot-instructions §3).
- **Manifest** ([data/golden-record/manifest.json](../../../data/golden-record/manifest.json))
  declares per entity: fixture, target entity-set, alternate key, records,
  lookups, and a dependency-safe **load order** (party root → projections →
  leads/activities → NBA → measures).
- **Path A** — [`seed-advisor-cockpit.ps1`](../../../scripts/solution/seed-advisor-cockpit.ps1):
  idempotent Web API upsert (OIDC, no secrets); pipeline seed (Phase 5.3).
- **Path B** — `Build-GoldenRecordPackage.ps1` (to implement): emits
  `data.zip` (data_schema.xml + data.xml + [Content_Types].xml) from the same
  manifest; imported via Package Deployer / CMT / `pac`; promoted with the
  solution DEV → SIT.
- **Integrity test** (to implement): a Pester test asserting the manifest and
  fixtures stay in sync — record counts, alternate keys present, and lookup
  referential integrity (every `accountKey`/`leadKey`/`contactKey` resolves).

## Error handling & idempotency

- Both paths upsert by **alternate key** → re-runs converge, never duplicate.
- Load order enforces referential order; missing parents fail fast.
- Live import is **DEV-gated** until Phases 1-3 author the tables; the manifest +
  seed plan validate offline in the meantime.

## Testing / validation

- Pester manifest-sync test (counts / keys / lookups) runs in `gate1`.
- Package build produces a schema-valid `data.zip` (validated on DEV import).

## Out of scope

- Authoring the DEV tables (Phases 1-3, DEV-gated).
- Non-advisor-cockpit scenarios (the pattern generalizes; each scenario declares
  its own manifest).
