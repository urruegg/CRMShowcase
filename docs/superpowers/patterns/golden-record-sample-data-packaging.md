# Pattern — Golden-Record Sample-Data Packaging

> Referenced by [ADR-0026](../../adr/ADR-0026-measure-snapshot-materialized-projection.md)
> (materialized-projection seed) and the deployment workflow
> ([ci-solution.yml](../../../.github/workflows/ci-solution.yml)).
> Manifest: [data/golden-record/manifest.json](../../../data/golden-record/manifest.json).

A repeatable method for turning the **mockup / scenario data** into a governed
**golden-record master dataset** and publishing it into **DEV and SIT** as
Power Platform **sample-data packages**, so every environment ring validates the
controls against the same canonical records.

## Why "golden record"

A golden record is the **one canonical, synthetic instance** of each business
object the demo tells a story with — the Contoso Insurance book anchored on the
**Brunner household** (UC-01 relocation golden thread). It is the fixed truth the
PCF controls, agents, and reviews are validated against: change it in one place,
every environment converges to it.

Non-negotiable: **synthetic only, no real customer data** (ADR-0026,
copilot-instructions §3). Keys are **alternate keys** so loads are idempotent.

## The method

### 1. Extract once, from the typed fixtures (single source of truth)
The scenario fixtures under `data/scenarios/<scenario>/*.json` *are* the extracted
dataset — typed to the same interfaces the control binds to. Do **not** duplicate
them into a second copy; declare them in a **manifest** instead.

### 2. Declare the golden-record manifest
[`data/golden-record/manifest.json`](../../../data/golden-record/manifest.json)
indexes the set: for each entity — fixture file, **target table/entity-set**,
**alternate key**, record count, **lookups**, and a **load order** that respects
referential dependencies (party root → projections → leads/activities → NBA →
measures). This is the machine-readable contract both publish paths consume.

### 3. Publish path A — idempotent Web API upsert (CI + DEV)
[`seed-advisor-cockpit.ps1`](../../../scripts/solution/seed-advisor-cockpit.ps1)
builds upsert requests keyed by alternate key and applies them via `az rest`
(OIDC, **no secrets**). Best for the **pipeline seed step** (Phase 5.3):
re-runnable, converges to the golden state, easy to gate. It validates the seed
plan even before the DEV tables exist.

### 4. Publish path B — Configuration Migration data package (portable DEV → SIT)
`Build-GoldenRecordPackage.ps1` (planned) emits a Power Platform **Configuration
Migration** data package from the same manifest:

```
data.zip
 ├─ data_schema.xml     # entities + fields + alternate-key compare
 ├─ data.xml            # the golden records
 └─ [Content_Types].xml
```

Imported via **Package Deployer / Configuration Migration Tool / `pac`**, it is a
**single reviewable artifact promoted with the solution** through each
environment ring (DEV → SIT). Use this when you want the data to travel *with*
the solution package rather than as a separate API seed.

### 5. Wire into the deployment workflow
The package build is an artifact step in [ci-solution.yml](../../../.github/workflows/ci-solution.yml);
the import is a **DEV-gated** deploy step (per environment, human-approved for
protected rings). Both paths are idempotent, so promotion never duplicates
golden records.

## When to use which path

| | Path A — az rest upsert | Path B — CMT data package |
| --- | --- | --- |
| Best for | CI / DEV pipeline seed | promoting sample data DEV → SIT with the solution |
| Artifact | none (live requests) | `data.zip` (reviewable, versioned) |
| Idempotent | ✅ alternate key | ✅ updateCompare on alternate key |
| Secrets | none (OIDC) | none (Package Deployer auth) |

## Standard checklist (per scenario)

- [ ] Fixtures typed to the control's interfaces; **synthetic only**.
- [ ] `manifest.json` declares target tables, alternate keys, lookups, load order.
- [ ] Path A seed script builds + validates a plan (works pre-table).
- [ ] Path B package builds a `data.zip` from the same manifest.
- [ ] Both publish paths are DEV-gated and idempotent; promotion is one artifact
      per ring.
- [ ] A Pester test asserts the manifest and each fixture stay in sync (counts,
      keys, referential integrity of lookups).
