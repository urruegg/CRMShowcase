# Pattern — PCF Local-First Polish Loop

> Anchored by [ADR-0027](../../adr/ADR-0027-page-level-pcf-and-local-first-polish-loop.md). Referenced by the `ux-designer` agent (AG-E-11).

A repeatable method for building **pixel-faithful, tested, Dataverse-bound PCF
controls** by developing locally against mock data first, polishing against a
visual ground truth with an agent in the loop, and only then wiring to Dataverse.

## When to use

Any PCF surface that must match a visual ground truth (a mockup, an existing
HTML web resource, a brand spec) closely. Prefer **configuration → low-code →
pro-code**: only reach for this once out-of-box MDA config cannot meet the bar.

## The loop

### 1. Model-first types + fixtures
Derive TypeScript interfaces from the Dataverse columns the control will bind to,
and author **mock JSON fixtures** typed to them. Fixtures are the same shape the
real `context` will provide, so the component never knows it's on mock data.

```
src/types.ts        // interfaces mirroring the data model
src/fixtures.ts     // typed mock data (import repo JSON where seed exists)
```

### 2. Local Vite harness (hot reload, full screen)
Render the component in a standalone Vite app with the fixtures — fast HMR, full
viewport, no Power Platform round-trip.

```
harness/index.html
harness/main.tsx    // renders <Control data={fixtures} />
npm run dev         // http://localhost:5173
```

### 3. Agent-in-the-loop polish against the ground truth
Serve locally, then **share the browser page with the VS Code agent** and compare
to the ground truth:

- `open_browser_page http://localhost:5173` (the PCF harness)
- open the ground-truth artifact too (e.g. the local HTML web resource)
- `screenshot_page` both, diff, and have the **ux-designer** agent (AG-E-11) tune
  Fluent v9 theme tokens, spacing, and typography until it matches.
- Port CSS variables from the ground truth into Fluent tokens where the palette
  already aligns (Fluent-based mockups map almost 1:1).

Iterate here until fidelity is reached — this is cheap because it's local.

### 4. Wrap as PCF + bind Dataverse
Keep the **same** component; swap the data source from fixtures to `context`
(dataset / WebAPI). Jest tests use a mocked `context`.

```
ControlManifest.Input.xml
index.ts            // maps context → the component's props
```

### 5. ALM
Controls live under `solution/**/Controls/**` per
[pcf-alm](../../../.github/instructions/pcf-alm.instructions.md); packed into the
app solution; CI → DEV → TEST. Declare upgrade impact + licensing per control.

## Guardrails

- Tests first (Jest + React Testing Library) for each subcomponent.
- WCAG 2.1 AA: keyboard nav, roles, contrast via Fluent tokens.
- Multilingual strings (repo standard: EN/DE/FR/IT — 1033/1031/1036/1040).
- AI-authored content renders a visible provenance badge + "AI-assisted"
  disclosure (Responsible AI).
- No real customer data in fixtures — synthetic only.

## Why local-first

The expensive part of pixel work is iteration. Doing it against a live MDA form
is slow (publish + reload) and couples layout debugging to Dataverse. Local Vite
+ shared-browser review collapses the loop to seconds and lets an agent compare
against the ground truth directly. Dataverse binding is the *last*, small step.
