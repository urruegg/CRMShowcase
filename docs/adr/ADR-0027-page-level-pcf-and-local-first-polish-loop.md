# ADR-0027 — Page-level PCF + the PCF Local-First Polish Loop

| Field | Value |
| --- | --- |
| **Status** | Superseded by ADR-0041 for bespoke full-page experiences; retained for embedded PCF controls and its local polish method |
| **Date** | 2026-08-11 |
| **Decision mode** | Committed decision |
| **Confidence** | High — grounded in the pcf-best-practices / pcf-alm instructions and the pixel-fidelity requirement |
| **Deciders** | UX Designer (AG-E-11) · Enterprise Architect (AG-E-03) · Developer (AG-E-02) |
| **Topic area** | A4 — Extensibility · UX |
| **Use case** | UC-01 · Advisor Cockpit ([spec](../superpowers/specs/2026-08-11-advisor-cockpit-design.md)) |
| **Licence** | 🧩 configuration / own build (pro-code PCF) |
| **Upgrade impact** | Medium — PCF controls carry an upgrade-impact declaration per pcf-alm; Fluent v9 + framework versions are pinned |
| **CAF methodology** | Adopt |
| **WAF pillar(s)** | Primary: Operational Excellence (tested, source-controlled UI) · Performance Efficiency. Trade-off: pro-code effort vs out-of-box config. |
| **Zero Trust** | Controls read Dataverse under the user's context and security roles. |
| **Responsible AI** | Transparency — AI-authored content (NBA cards) renders a visible provenance badge + "AI-assisted" disclosure. |

> **Scope after ADR-0041.** The page-level PCF default is superseded only for
> bespoke full-page CRM experiences. PCF remains the selected extension path
> for embedded controls requiring form, dataset or field context, and the PCF
> Local-First Polish Loop remains active for those controls.

## Context

The Advisor Cockpit must reproduce two dense, full-bleed HTML cockpits **as
close to pixel-perfect as possible** (ground truth: the unpacked Contoso Insurance HTML
web resources, local-only). Two questions: (1) how is each surface rendered, and
(2) how do we reliably reach pixel fidelity? This ADR settles both and anchors
the build method as a reusable pattern.

## Options

### Option A — One page-level PCF per surface (historical selection)

Each surface is a single React + Fluent UI v9 control rendering the whole page.
**Why:** full control of every pixel, 1:1 with the mockup, one focused build per
surface, clean local harness. The mockup already uses the Fluent palette, so
tokens port directly.

### Option B — Many small PCF tiles on an MDA custom page

Each region is its own PCF, arranged on the page. **Why not:** MDA page/section
layout fights pixel-perfect spacing; the dense header/KPI band is hard to match;
more controls to wire.

### Option C — Hybrid

Page-level PCF for the hero, native + small tiles elsewhere. **Why not:** mixes
two layout models on one page; harder to keep visually consistent for a
pixel-perfect target.

## Decision or working hypothesis

The original decision used **Option A — one page-level PCF per surface** for
`AdvisorCockpit` and `SalesLeaderDashboard`. ADR-0041 supersedes that default
for bespoke full-page CRM UX. It does not retire the controls, their fixture
harnesses or this polish method.

For embedded PCF controls that require model-driven form, dataset or field
context, continue to use the **PCF Local-First Polish Loop**:

1. Derive TypeScript types + mock fixtures from the data model.
2. Build the component in a **Vite** harness with fixtures (hot reload, full
   screen).
3. Serve on localhost, **open as a shared browser page in VS Code**, screenshot
   and diff against the ground-truth HTML web resource; **ux-designer** (AG-E-11)
   polishes tokens/spacing to fidelity.
4. Wrap as PCF, bind `context`/dataset to Dataverse (same component, swap the
   data source).
5. Pack into the app solution; CI (pcf-alm) → DEV → TEST.

The loop is documented in
[docs/superpowers/patterns/pcf-local-first-polish-loop.md](../superpowers/patterns/pcf-local-first-polish-loop.md)
and referenced by the `ux-designer` agent.

## Evidence and assumptions

- **Known:** the mockups are full-bleed custom layouts using the Fluent palette;
  pcf-best-practices mandates React + Fluent v9; pcf-alm governs packaging.
- **Inferred:** page-level controls are more maintainable here than many tiles.
- **Evidence still required:** none blocking; performance validated during build.

## Validation and review triggers

Reopen if a surface needs to be recomposed from independently-reusable tiles, or
if MDA native config can meet the fidelity bar for a future, simpler surface
(config → low-code → pro-code still applies). Route a new bespoke full-page
surface through ADR-0041 and the Code App parity evidence instead of treating
this ADR as authority for a new page-level PCF.

## Consequences

- **At the next release:** retained PCF controls and their pattern stay
  source-controlled and tested; new bespoke full-page work follows ADR-0041.
- **Operationally:** controls are Jest-tested and versioned; upgrade impact is
  declared per control.
- **For the customer's teams:** a repeatable, reviewable UX build method rather
  than ad-hoc pixel-pushing, without presenting embedded PCF as the default
  full-page host.
- **Reversibility:** medium — a control can be re-split into tiles later, but the
  component code is reusable either way.

## Competitive note

Forces the equivalent engagement to show a **repeatable** path to a
pixel-faithful, tested, source-controlled UI — not a one-off demo screen.
