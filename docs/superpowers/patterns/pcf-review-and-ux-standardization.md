# Pattern — PCF Review & UX-Standardization Rubric

> Companion to [PCF Local-First Polish Loop](./pcf-local-first-polish-loop.md).
> Owned/ratified by the **ux-designer** agent (AG-E-11). Referenced by
> [pcf-best-practices.instructions.md](../../../.github/instructions/pcf-best-practices.instructions.md).
> **v1.1** — reviewed and amended by the ux-designer agent (2026-08-11); see
> [changelog](#ux-designer-review-changelog-v11) at the foot.

A repeatable **review rubric** that standardizes the user experience across every
PCF control — visuals, cards, grids, actions, and data provenance — so each
control looks and behaves like one product, not a collection of one-offs.

> **Guiding correction from the ux review:** a control is only "standardized" if
> it stays consistent *inside the host app* (dark theme, high contrast, MDA
> theme) and *for every user* (keyboard, colour-blind, non-EN, touch). Colour,
> light-theme tokens, and hover tooltips are necessary but never sufficient.

## When to run it

Run this rubric as a **batch conformance pass BEFORE the pixel-polish loop**, not
after. Polishing an already-standardized control is cheap; retrofitting a
standard onto a hand-tuned control is expensive. Sequence per control:

```
scaffold → [THIS RUBRIC — batch conformance] → local-first polish loop → PCF wrap + bind → ALM
```

The rubric is also re-run before every intake PR as a regression gate.

## How to run it (batch process)

1. **Self-check**: the implementing agent scores the control against every MUST
   item below and records a conformance table (✅ / ⚠ / ❌ + note).
2. **ux-designer review**: the `ux-designer` agent (AG-E-11) reviews the
   conformance table **and** the running harness, and either ratifies or files
   gap items. UX standardization across controls is the ux-designer's call.
3. **Gate**: every **MUST** passes (or has a linked, accepted deviation). SHOULD
   items are tracked as polish backlog. Record the result in the control's
   `DATA-BOM.md` (or a `REVIEW.md`) and link it from the intake PR.

## The rubric

Legend: **MUST** = release gate · **SHOULD** = standardize when touched.

### 1. Theming & tokens
- **MUST** `tokens.ts` **extends the Fluent v9 theme via a `BrandVariants` ramp**
  (`createLightTheme`/`createDarkTheme`); component styles reference `tokens.*`
  and custom tokens **bridge** to the theme, never replace it. No literal
  hex/px palette values in component files.
- **MUST** Brand accent is **accent-only, never a status colour**. Status uses
  the muted semantic set (danger/warning/success/info).
- **MUST** Fluent v9 `makeStyles` + `shorthands.*`; partial borders use
  `shorthands.borderWidth('0')` + specific side.
- **MUST** The uppercase "kicker" eyebrow is CSS `text-transform` on a real
  heading level (+ letter-spacing) — **never an uppercased string** (German
  compounds overflow; all-caps strings mis-read by screen readers).
- **SHOULD** Enforce "no literal hex/px" with a lint rule (stylelint/eslint),
  not convention. Tight corporate radii (2–4px); warm neutral ramp; type scale.

### 2. Data-source provenance (the "where's this from?" contract)
- **MUST** Every data-bearing tile/field is classifiable as **CRM (Dataverse)**,
  **Databricks (mock/measure)**, or **not-yet-mapped**, via a **closed enum**
  (`prov`), not a free string.
- **MUST** Provenance is **not carried by colour alone** — every tile carries a
  **textual/accessible cue** for its source: the tile's **accessible name
  (`title`/tooltip)** *and* a **persistent, always-visible legend**. Colour
  (grey / yellow) is only the secondary, at-a-glance cue.
  - **A per-tile visible badge is OPTIONAL, not required.** Anchored project
    decision (Advisor Cockpit, 2026-08-11): per-tile "DBX"/"TBD" badges were
    **removed** — the surface tint + accessible name + legend already satisfy
    the non-colour requirement, and per-tile badges added visual noise across
    the many measure tiles. Do **not** re-introduce per-tile source badges
    unless a control lacks a persistent legend.
- **MUST** Provenance is reachable **without hover** — surfaced on focus and in
  the tile's **accessible name** (keyboard/touch users included).
- **MUST** The "Datenquelle" legend and all provenance labels are **localized**
  (1033 base + 1031/1036/1040), not hard-coded German.
- **SHOULD** "not-yet-mapped" is **filterable/countable** so it is a tracked
  backlog signal, not just a yellow fill.

### 3. Layout, cards & sections
- **MUST** One card primitive (border + radius + head/body) reused everywhere;
  section heads use eyebrow + title + summary.
- **MUST** The card primitive declares **loading/skeleton, error, empty/"—",
  and permission-denied (field-level-security)** states.
- **MUST** The **AI-assisted disclosure badge is a shared component** with fixed
  wording + placement (tied to §6), not per-control freehand.
- **MUST** Consistent spacing scale from tokens; no scattered magic numbers.
- **SHOULD** A **responsive/reflow spec**: the same card set survives form
  section vs. side pane vs. dashboard vs. narrow width.

### 4. Grids (CRM parity)
- **MUST** **Pro-code tier-justification** — a custom grid documents *why it is
  not a native subgrid/editable grid* (config→low-code→pro-code, per
  [copilot-instructions §5](../../../.github/copilot-instructions.md)). Prefer a
  **native MDA subgrid** where full parity (resize/per-column filter/saved
  views) is required.
- **MUST** Every grid behaves the same: **sortable headers** with `aria-sort`,
  a shared sort utility, and a consistent sort-arrow affordance.
- **MUST** Full **keyboard grid model** (roving `tabindex` / arrow keys), not
  only `aria-sort` — parity means *operable*, not just labelled.
- **MUST** Parent/child uses the same **collapse + connector** affordance;
  multi-select uses the same checkbox + selection-bar pattern.
- **SHOULD** Column filter + view presets follow one vocabulary. Personal saved
  views persist via a **governed user-setting / native personal view** — NOT
  device-bound `localStorage` (no roaming, no security trim, breaks CRM parity);
  if `localStorage` is used it is **labelled demo-only session preference**.
- **SHOULD** Announce filtered-row / selection counts via `aria-live`.

### 5. Actions & icons
- **MUST** A **central verb→icon→label map** is a shared artifact, so the same
  verb (call/edit/open/add/merge/split/assign/save/next) is identical across
  controls.
- **MUST** Every action button carries a **lightweight Fluent `react-icons`**
  glyph via **per-icon named imports** (tree-shaken) — never a barrel/`* as`
  import.
- **MUST** **One primary/brand CTA per card/section** — lead with the agent's
  recommended next-best-action; demote the rest to secondary/subtle. (Avoid the
  "5 equal buttons" anti-pattern.)
- **MUST** **Destructive/irreversible** actions (split, reassign, merge) get a
  distinct treatment + confirmation (tied to §6).
- **MUST** Appearance vocabulary is consistent: `primary`=brand CTA,
  `secondary`=standard, `subtle`/`transparent`=tertiary; `size="small"` in dense
  surfaces.

### 6. Human-in-the-loop & write safety
- **MUST** No free-text/model output writes to Dataverse directly. The **safety
  boundary is the schema-validated action layer + human approval**, NOT the
  DEV-gate — a reviewer must never ship a demo where "flip the DEV flag" =
  "writes to Dataverse" ([docs/AI.md](../../AI.md),
  [ADR-0014](../../adr/ADR-0014-agents-advisory-by-design.md)).
- **MUST** Customer-facing acts (send, reassign, bundle, price, close) are
  **advisory + a named human decides**; in the harness they are DEV-gated demo
  notes.
- **MUST** AI-assisted output is disclosed and its **grounding citation (what was
  retrieved) is visible/inspectable**, not just a ✦ badge.
- **SHOULD** Undo/confirm on human-decided actions; agent-contributed field
  values carry a visible provenance marker (matches AG-F-03 / AG-F-04).

### 7. Accessibility
- **MUST** Icon-only / checkbox / sort controls have `aria-label` / `aria-sort`;
  keyboard reachable with visible focus (don't remove Fluent outlines).
- **MUST** **forced-colors / Windows High Contrast** supported.
- **MUST** **Non-text contrast 3:1** (WCAG 1.4.11) for icons, focus rings, UI
  borders — in addition to 4.5:1 text. Brand red is never the sole carrier of
  meaning.
- **MUST** **Reflow at 320px / 400%** (WCAG 1.4.10).
- **MUST** **`aria-live`** announces sort-applied, rows-filtered, selection
  count, and "In Fokus" set.
- **MUST** **Modal focus management** (trap, return focus, Esc) for dialogs.
- **SHOULD** Per-content `lang` so DE/FR/IT pronounce correctly.

### 8. Testing & build health
- **MUST** `tsc --noEmit` clean; **vitest + RTL** cover every interactive
  behavior; pure selectors are unit-tested.
- **MUST** **Automated a11y test** (axe/jest-axe) in CI — RTL behavior tests do
  not catch contrast/aria regressions.
- **MUST** **virtual** control sharing platform React + Fluent; no bundled second
  Fluent registry.
- **MUST** **Bundle-size budget as a hard CI threshold** (a number), not
  "watched"; per-icon imports, no heavy barrels.
- **SHOULD** Visual-regression snapshot of the pixel-faithful surface (ties to
  [ADR-0027](../../adr/ADR-0027-page-level-pcf-and-local-first-polish-loop.md));
  localization smoke render in a non-EN locale without truncation.

### 9. Host-theme bridging (the #1 addition)
- **MUST** Consume the MDA host theme via `FluentProvider`; the control renders
  correctly in **light, dark, and high-contrast** without forcing a theme.
- **MUST** Brand tokens derive from a **`BrandVariants` ramp** so accent/neutrals
  recolour correctly per theme (see §1).
- **SHOULD** Transparent provider background so the control lines up with the
  host form section (no visible rectangle).

### 10. States, responsiveness & performance
- **MUST** **Virtualize** long lists (lead book / ranked queue / NBA) — whole-
  book scoring + a non-virtualized queue will not survive real volume.
- **MUST** Loading/async/error/permission states exist for every data region
  (see §3).
- **SHOULD** **Density** system (comfortable/compact) matching MDA density;
  `size="small"` alone is not a density system.
- **SHOULD** Respect `prefers-reduced-motion` (progress bars, collapse, board).

### 11. Localization, formatting & content
- **MUST** Number/date/currency formatted via `context.userSettings` — never
  hard-coded; full DE/FR/IT string coverage over the 1033 base.
- **SHOULD** RTL readiness; pseudo-loc test; a consistent tone standard
  (Sie-form German + terminology glossary + EN base parity) so labels don't
  drift control-to-control.

## Conformance table template

Copy into the control's `DATA-BOM.md` / `REVIEW.md`:

```
| #  | Category                    | MUST result | Note |
|----|-----------------------------|-------------|------|
| 1  | Theming & tokens            | ✅ / ⚠ / ❌ |      |
| 2  | Data-source provenance      |             |      |
| 3  | Layout, cards & states      |             |      |
| 4  | Grids (CRM parity)          |             |      |
| 5  | Actions & icons             |             |      |
| 6  | HITL & write safety         |             |      |
| 7  | Accessibility               |             |      |
| 8  | Testing & build             |             |      |
| 9  | Host-theme bridging         |             |      |
| 10 | States/responsive/perf      |             |      |
| 11 | Localization & content      |             |      |
```

Gate: all MUST = ✅ (or ⚠ with a linked, ux-designer-accepted deviation) before
the polish loop and before the intake PR.

## ux-designer review changelog (v1.1)

Amendments folded in from the AG-E-11 review (2026-08-11):

- **§1** tokens must extend a Fluent `BrandVariants` theme (not a parallel system);
  kicker is `text-transform`, not an uppercased string; lint-enforce no-hex.
- **§2** provenance not colour-alone (icon+label), reachable without hover, closed
  enum, localized legend, unmapped countable.
- **§3** card states (loading/error/permission), shared AI badge, responsive spec.
- **§4** pro-code tier-justification MUST; full keyboard grid model; `localStorage`
  saved-view breaks CRM parity → governed persistence or labelled demo-only;
  `aria-live` counts.
- **§5** central verb→icon→label artifact; one primary CTA per card; destructive
  action treatment + confirmation.
- **§6** DEV-gate is a harness affordance, **not** the safety boundary; grounding
  citation visible; undo/confirm.
- **§7** forced-colors/HC, non-text 3:1, reflow 320px/400%, `aria-live`, modal
  focus trap, per-content `lang`.
- **§8** jest-axe MUST; bundle budget as a hard CI number; visual-regression +
  loc smoke.
- **New §9 Host-theme bridging** (the single most important addition), **§10
  states/responsive/perf (incl. virtualization)**, **§11 localization/formatting/
  content**.

**Verdict (AG-E-11):** *Fit to standardize, with these amendments — it already
nails provenance, HITL and icon discipline better than most enterprise rubrics.
The single most important addition is host-theme bridging on a Fluent
`BrandVariants` ramp; the highest-severity fix in the current control is making
provenance/status non-colour-dependent.*
