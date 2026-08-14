# Design Spec — PCF Review & UX-Standardization Pattern

| Field | Value |
| --- | --- |
| Date | 2026-08-11 |
| Status | Draft (autonomous; awaiting human ratification) |
| Workstream | A (of two: A = this; B = golden-record sample-data packaging) |
| Related | [pattern: pcf-review-and-ux-standardization](../patterns/pcf-review-and-ux-standardization.md) · [pattern: pcf-local-first-polish-loop](../patterns/pcf-local-first-polish-loop.md) · [ADR-0027](../../adr/ADR-0027-page-level-pcf-and-local-first-polish-loop.md) · #62 |

## Problem

We polished the Advisor Cockpit PCF ad-hoc (brand tokens, data-source colour
coding, grid behaviours, action icons, HITL demo notes). Those learnings are not
yet a **repeatable standard**, so the next control (Sales Leader Dashboard, #63)
and every future control risk diverging. We need a review standard that makes UX
consistent *across* controls, ratified by the ux-designer agent, and run as a
**batch conformance pass before** the pixel-polish loop.

## Approach (chosen)

Three approaches were considered:

1. **Rubric doc + ux-agent gate (chosen).** A checklist pattern doc, run per
   control, ratified by AG-E-11, recorded as a conformance table in the
   control's docs and linked from the intake PR. Low friction, high leverage,
   fits the existing pattern-doc + agent-review model.
2. **Lint/CI-only enforcement.** Encode everything as eslint/stylelint + CI
   gates. Stronger guarantee but only covers the mechanical rules (no-hex,
   bundle budget, jest-axe); can't judge "is this the same card language."
   → adopted as a *subset* of the rubric's MUSTs, not the whole.
3. **Shared component library.** Extract a `@crmshow/pcf-ui` kit. Highest
   consistency but premature after one control; revisit once ≥3 controls share
   primitives (YAGNI for now).

**Decision:** (1) as the governing standard, with (2)'s lint/CI gates named as
MUST items so they harden over time, and (3) explicitly deferred until pattern
repetition justifies a library.

## The standard

The rubric lives in
[pcf-review-and-ux-standardization.md](../patterns/pcf-review-and-ux-standardization.md)
(v1.1, ux-ratified). Eleven categories, MUST = release gate:

1 Theming & tokens · 2 Data-source provenance · 3 Layout/cards/states ·
4 Grids (CRM parity) · 5 Actions & icons · 6 HITL & write safety ·
7 Accessibility · 8 Testing & build · 9 Host-theme bridging ·
10 States/responsive/perf · 11 Localization & content.

**Batch process:** scaffold → **run rubric (self-score + ux-designer ratify)** →
polish loop → PCF wrap + bind → ALM. Re-run as a regression gate at intake PR.

## ux-designer ratification (AG-E-11)

Reviewed 2026-08-11. Verdict: *fit to standardize, with amendments folded into
v1.1.* Headline additions: **host-theme bridging on a Fluent `BrandVariants`
ramp** (§9, the single most important addition) and **provenance/status must not
be colour-only** (§2, the highest-severity fix in the current control). Full
changelog in the pattern doc.

## Applying it to the Advisor Cockpit (Workstream A, item 2)

Run the rubric against the existing control → conformance scorecard recorded in
[DATA-BOM.md](../../../solution/apps/sales/Controls/AdvisorCockpit/DATA-BOM.md).
Quick wins fixed inline; structural items (host-theme bridging, list
virtualization, jest-axe, full localization) tracked as a remediation backlog
because they are larger and partly land in the PCF-wrap/bind phase (DEV-gated),
not the local harness.

## Testing / validation

- The rubric's own §8 is the test standard: `tsc` clean, vitest+RTL per
  behavior, + the new jest-axe / bundle-budget / visual-regression MUSTs adopted
  incrementally.
- "Done" for this workstream = pattern doc committed + ux-ratified + Advisor
  Cockpit conformance scorecard recorded + quick-win fixes applied + backlog
  filed.

## Out of scope

- Building a shared component library (deferred, YAGNI).
- Retrofitting the rubric onto non-PCF surfaces.
- The golden-record data packaging (Workstream B — separate spec).
