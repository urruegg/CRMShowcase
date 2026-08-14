# SalesLeaderDashboard — Data BOM & PCF Review conformance

> Visual bill-of-materials for the `SalesLeaderDashboard` page-level PCF, mapped
> to its data source, plus the honest parity gaps vs the ground-truth mockup and
> the PCF Review rubric conformance scorecard. Companion to the AdvisorCockpit
> [DATA-BOM](../AdvisorCockpit/DATA-BOM.md). Ground truth: local web resource
> `intake/mobiliar/source/WebResources/cr7e8_sharedpage12v2salessteeringcockpit`.

## Data-source provenance legend

| Tag | Meaning | UI cue |
| --- | --- | --- |
| **DBX** | Databricks measure projection (`crmshow_measuresnapshot`, ADR-0018/0026) — the local `data/scenarios/advisor-cockpit/measures.json` | grey tile tint + accessible name "Databricks (Mock)" |
| **TBD** | Not-yet-mapped: illustrative presentation figure **not in the measure contract** | yellow tile tint + accessible name "Noch nicht gemappt" |

Provenance is carried by **surface tint + per-tile accessible name (`title`) + a
persistent 2-class legend** — no per-tile badges (anchored decision, rubric §2).

## Visual BOM → data map

| Element | Prov | Mapping | Status |
| --- | --- | --- | --- |
| Header identity (GA, scope) | — | `DashboardData.profile` (PCF `context`: business-unit name) | ✅ bound to data |
| Führungssicht narrative | TBD | `presentation.fuehrungssicht` (static copy) | ⚠ illustrative |
| KPI · Zielerreichung 96 % | **DBX** | measure `GoalAttainment` (GA-Bern-Mittelland) | ✅ `measures.json` |
| KPI · Wachstum YoY +7.2 % | **DBX** | measure `GrowthYoY` | ✅ `measures.json` |
| KPI · NPS 42 | **DBX** | measure `NPS` | ✅ `measures.json` |
| KPI · Automatisierung 72 % | **DBX** | measure `Automation` | ✅ `measures.json` |
| KPI deltas (▲3 Pp …) + targets + "→" hints | TBD | `presentation.scorecardMeta` | ⚠ illustrative; no delta/target measure |
| Forecast line (320→412, 6 mo) | **DBX** | measure `Forecast` (GA, 6 asOfDate rows) | ✅ `measures.json` |
| Forecast target line 430 + confidence band | TBD | `presentation.forecastTargetChf` + ±4 % band | ⚠ target/band not in contract |
| Strategischer Scorecard (radar, 5 dims) | TBD | `presentation.radarDims` | ⚠ no measure rows |
| Neugeschäft je Produktlinie (5 bars) | **DBX** | measure `Forecast` where `subjectType=product` | ✅ `measures.json` |
| Wachstum je Markt/Region (4 bars) | **DBX** | measure `GrowthYoY` where `subjectType=region` | ✅ `measures.json` |
| Funnel stages + phase conversion | TBD | `presentation.funnelStages` | ⚠ no funnel measures |
| GA-Steuerungsmatrix · Bern-Mittelland (Ziel/Conv/Autom.) | **DBX** | measures `GoalAttainment`/`Conversion`/`Automation` | ✅ current GA cells grounded |
| GA-Steuerungsmatrix · Backlog + peer GAs (Luzern/Basel/Biel-Seeland) | TBD | `presentation.gaBenchmark` | ⚠ peers + backlog illustrative |

**Grounded in the measure contract:** the four scorecard KPIs, the forecast
series, the product-line and region bars, and the current GA's Ziel/Conversion/
Automation. **Not yet in the contract (flagged yellow):** KPI deltas/targets/
hint links, the forecast 430 target + band, the strategic radar, the funnel, and
the peer-GA + backlog benchmark cells.

## Parity gaps vs the mockup

The ground-truth mockup is a ~15-section steering cockpit. This slice ships the
core Führungssicht: **Übersicht** (scorecard + forecast + radar), **Produkte &
Regionen** (bars), **Funnel** (bottleneck), and **GA-Vergleich** (benchmark
matrix). Not implemented (backlog):

- **Ziele / Ziel-Allokation** — attainment hierarchy (Direktion→GA→Team→VB),
  Zielarten-Mix donut, Ist-vs-Soll activity goals, Zielerreichung-über-Zeit.
- **Backlog & SLA** — phase volume/Verweildauer/TFF drilldowns.
- **Multi-Lead reporting** (UC-MB1 Schritt 9) and **Kampagnen-Effektivität**
  matrix (UC-MB3 Schritt 10) with the Copilot-Insight rule cards.
- **Mehr** tabs — Rerouting & Alerts, Provision, VB & Coaching, Journeys,
  Feedback Loops.
- **Interactions** — click-to-drill / explode-by-dimension, Zeitraum/VB/Produkt/
  Segment/Kanal filters, Export (Lead-Einzelebene).

## PCF Review conformance (rubric v1.1)

| # | Category | Result | Note |
|----|----------|--------|------|
| 1 | Theming & tokens | ⚠ | Reuses the brand-kit `tokens.ts`; chart colours from `palette`, no literal hex in JSX. Deviation: tokens are **copied**, not a shared package (rubric A6) nor a Fluent `BrandVariants` ramp (§9). |
| 2 | Data-source provenance | ✅ | Closed `prov` enum, surface tint + per-tile accessible name + 2-class legend (DBX/TBD), no badges. Honestly separates measure-backed vs not-yet-mapped. Gap: legend DE-only; "not-yet-mapped" not yet filterable/countable. |
| 3 | Layout, cards & states | ⚠ | One card primitive + eyebrow/title/sub; responsive `grid2`. Gap: no loading/skeleton, error, empty or permission states. |
| 4 | Grids (CRM parity) | ⚠ | GA-Steuerungsmatrix is a semantic `<table>` (th/columnheader). Gap: not sortable, no `aria-sort`, no roving-tabindex (read-only analytics, lighter bar — but sort is expected). |
| 5 | Actions & icons | ⚠ | Read-only analytics surface: **no** action buttons by design. Gap: the mockup's click-to-drill / filters / export are not implemented (backlog). |
| 6 | HITL & write safety | ✅ | No Dataverse writes at all; provenance disclosed; no free-text/AI output on this surface (ADR-0014 n/a). |
| 7 | Accessibility | ⚠ | Fluent tab keyboard model; per-tile `title`; `region`/`note` landmarks; table semantics. Gap: charts are `img` with no data-table fallback; benchmark status is **colour-only** (needs non-colour cue); no `aria-live` on tab change; forced-colors/HC untested. |
| 8 | Testing & build | ⚠ | `tsc` clean; 8 vitest+RTL (render, identity binding, all four tabs, provenance legend); ResizeObserver polyfill for Recharts. Gap: no selectors unit test, no jest-axe, no bundle budget, no visual-regression. |
| 9 | Host-theme bridging | ❌ | Light-only; no `FluentProvider` host-theme inheritance / dark / high-contrast. **Top remediation** (lands in the PCF-wrap/bind phase). |
| 10 | States / responsive / perf | ⚠ | Responsive grids + `ResponsiveContainer`. Gap: no loading/skeleton; KPI 4-col / card 2-col grids not reflow-specified for narrow widths. |
| 11 | Localization & content | ⚠ | Consistent German. Gap: strings hard-coded (no 1033 base + DE/FR/IT); `CHF Tsd`/`%` not via `context.userSettings` number/currency formatting (lands at bind). |

**Remediation backlog (filed):** (2/data-map) extend the **measure contract**
so the yellow tiles become grounded — add radar dimensions, funnel stages,
SLA-backlog and peer-GA / goal-hierarchy measure rows · (4/7) sortable benchmark
+ **non-colour** status cue + chart data-table fallback + `aria-live` on tab ·
(9) BrandVariants ramp + host-theme bridging (dark/HC) at bind · (5) drilldown /
filter / export interactions (post-bind) · (11) localization + `userSettings`
formatting · (1) shared tokens package. Structural items land in the
**PCF-wrap/bind phase** (DEV-gated), not the local harness.
