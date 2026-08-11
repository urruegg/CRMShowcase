# Plan — PCF UX-Standardization + Golden-Record Packaging

| Field | Value |
| --- | --- |
| Date | 2026-08-11 |
| Status | Draft (autonomous) |
| Specs | [A: PCF review/UX-standardization](../specs/2026-08-11-pcf-review-ux-standardization-design.md) · [B: golden-record packaging](../specs/2026-08-11-golden-record-sample-data-packaging-design.md) |

Ordered, reviewable slices. Each task is small, testable, and DEV-gated where it
touches an environment. `[done]` = landed in this worktree branch;
`[ ]` = next.

## Workstream A — PCF review & UX-standardization

- [done] A0 — Rubric pattern doc (11 categories), ux-designer-ratified (v1.1).
- [done] A1 — Design spec.
- [done] A2 — AdvisorCockpit conformance scorecard in DATA-BOM + remediation backlog.
- [ ] A3 — **Host-theme bridging** (rubric §9, top item): derive `tokens.ts`
  from a Fluent v9 `BrandVariants` ramp; render via `FluentProvider` inheriting
  the MDA host theme; verify light / dark / high-contrast. *(Lands with PCF wrap.)*
- [ ] A4 — **Non-colour provenance** (§2): per-source icon+label, focus-reachable
  tooltip + accessible name, localized legend, unmapped countable/filterable.
- [ ] A5 — **A11y + test gates** (§7/§8): jest-axe MUST, `aria-live` for
  sort/filter/selection/In-Fokus, modal focus-trap check, forced-colors pass,
  bundle-size CI budget (a number).
- [ ] A6 — **Shared artifacts** (§3/§5): extract the card primitive states
  (loading/error/permission) and the verb→icon→label map into shared modules.
- [ ] A7 — **Perf/loc** (§10/§11): virtualize long lists; `context.userSettings`
  number/date/currency; DE/FR/IT strings over 1033 base.
- [ ] A8 — Lint enforcement of no-hex/px (stylelint/eslint) in CI.

## Workstream B — golden-record sample-data packaging

- [done] B0 — Golden-record `manifest.json` (entities, keys, lookups, load order,
  publish targets).
- [done] B1 — Pattern doc + design spec.
- [ ] B2 — `scripts/solution/Build-GoldenRecordPackage.ps1`: emit a Configuration
  Migration `data.zip` (data_schema.xml + data.xml + [Content_Types].xml) from the
  manifest + fixtures; reuse `Get-FixtureManifest`.
- [ ] B3 — `scripts/solution/tests/GoldenRecordManifest.Tests.ps1` (Pester):
  manifest ↔ fixtures in sync (counts, alternate keys present, lookup referential
  integrity). Runs in `gate1`.
- [ ] B4 — Wire package build as a CI artifact step; DEV-gated import (Package
  Deployer / `pac`) per environment ring in the deploy workflow.
- [ ] B5 — Generalize: document how a new scenario adds its own manifest + reuses
  both publish paths.

## Sequencing

B2–B3 are independent of A and safe to land next (data/tooling, CI-testable).
A3 (host-theme) + A4 (provenance) are the highest-value UX items but A3 lands
with the PCF wrap/bind phase (DEV-gated), so A4/A5 (harness-local) come first.

## Non-delegable / gates

- Env authoring (DEV tables, Phases 1-3) and any environment import stay
  **DEV-gated** and human-run.
- Merge to protected `main` is human-gated (never self-merge) per the operating
  model; these specs await human ratification.
