# ADR-0019 — Solution versioning strategy

| Field | Value |
| --- | --- |
| **Status** | Accepted |
| **Date** | 2026-08-06 |
| **Deciders** | Repo owner |
| **Topic area** | A4 · A8 |
| **CAF methodology** | Adopt · Govern |
| **WAF pillar(s)** | Primary: Operational Excellence · Trade-off: none material |
| **Zero Trust** | N/A (no identity/access change) |
| **Responsible AI** | N/A (no AI touched) |
| **Licence** | 🧩 configuration / own build |
| **Upgrade impact** | This *is* the upgrade impact declaration |

## Context

The showcase spans six Power Platform solutions with a dependency chain
(Foundation → DataModel/Integration → apps). A managed solution's version
can only ever increase in a target environment. Without a versioning
strategy, upgrades either break the fresh-redeploy path or accumulate silent
dependency conflicts.

## Options

### Option A — Free-form versioning per solution

Each maintainer sets versions manually. **Why not:** guaranteed drift; no
enforcement of monotonic increase; MAJOR/MINOR/PATCH become opinion.

### Option B — Calendar versioning YYYY.MM.DD.BUILD

Deterministic, but loses semantic meaning: "is this a breaking change?"
becomes a manual check on every upgrade.

### Option C — Semver four-part MAJOR.MINOR.PATCH.BUILD ✅ chosen

Dataverse-native (four parts). MAJOR = breaking; MINOR = additive; PATCH =
fix; BUILD = GitHub Actions run number for uniqueness. PATCH and BUILD are
automatic; MAJOR and MINOR require PR labels; a breaking-change heuristic
blocks merge without the `version-bump:major` label.

## Decision

Adopt Option C for all six solutions. Rules and bump mechanic captured in
[`solution/manifest.json`](../../solution/manifest.json) `.versioning` and
enforced by [`scripts/solution/Bump-Version.ps1`](../../scripts/solution/Bump-Version.ps1) +
[`scripts/solution/Test-BreakingChange.ps1`](../../scripts/solution/Test-BreakingChange.ps1),
exercised by [`.github/workflows/solution-ci.yml`](../../.github/workflows/solution-ci.yml).

## Consequences

- **At the next release:** solution upgrades and fresh redeploys use the
  same monotonic version sequence.
- **Operationally:** version drift between manifest and Solution.xml is
  impossible — Solution.xml is derived at pack time.
- **Reversibility:** high; the scheme is external to Dataverse.

## Known gaps

- `Test-BreakingChange` currently detects removed/added `<entity>`,
  `<attribute>`, `<relationship>`, `<optionvalue>` tokens. It does not yet
  detect `<SchemaName>` renames or type changes on already-published
  columns. Follow-up story to add those rules.

## Related

- [Sprint 1 spec](../superpowers/specs/2026-08-06-solution-containers-design.md)
- [Sprint 1 plan](../superpowers/plans/2026-08-06-solution-containers.md)
- [ADR-0017 — Everything through the pipeline](./ADR-0017-alm-everything-through-the-pipeline.md)
