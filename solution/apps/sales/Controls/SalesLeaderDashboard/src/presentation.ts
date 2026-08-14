// Presentation metadata for the Führungsdashboard — the mockup's labels, targets,
// deltas and the strategic-scorecard / funnel / GA-benchmark figures that are not (yet)
// individual rows in measures.json. Kept OUT of data/scenarios so the Phase-5 fixtures
// stay the seed contract. Contoso-rebranded, clearly-synthetic; every figure here is a
// Databricks-mock measure (data-source provenance = dbx) grounded in ADR-0018.

import type { GaBenchmarkRow, RadarDim } from './types';

// The strategic narrative shown under "Führungssicht".
export const fuehrungssicht =
  'Zielerreichung 96 %, Neugeschäft-Wachstum +7.2 % YoY, NPS 42. Wachstumstreiber: ' +
  'Motorfahrzeug KMU (CHF 148k) und Markt Mittelland (+7.2 %). Operativer Engpass im ' +
  'Erstkontakt. Jede Kennzahl ist nach Zeit, Produkt, Markt/Region und VB aufklappbar.';

// Scorecard KPI presentation config, keyed by measure metric (value comes from measures.json).
export const scorecardMeta: Record<
  string,
  { label: string; unit: 'percent' | 'nps'; target: string; delta: string; deltaDir: 'up' | 'down' | 'flat'; hint: string }
> = {
  GoalAttainment: { label: 'Zielerreichung', unit: 'percent', target: 'Ziel 100 %', delta: '▲ 3 Pp', deltaDir: 'up', hint: '→ Ziele' },
  GrowthYoY: { label: 'Wachstum YoY', unit: 'percent', target: 'Neugeschäft · Ziel +6 %', delta: '▲ 1.2 Pp', deltaDir: 'up', hint: '→ Produkte' },
  NPS: { label: 'NPS', unit: 'nps', target: 'Ziel ≥ 40', delta: '▲ 4', deltaDir: 'up', hint: '→ Feedback' },
  Automation: { label: 'Automatisierung', unit: 'percent', target: 'Ziel 75 %', delta: '▲ 6 Pp', deltaDir: 'up', hint: '→ Rerouting' },
};

// Order the four scorecard cards appear in.
export const scorecardOrder = ['GoalAttainment', 'GrowthYoY', 'NPS', 'Automation'];

// Forecast: the last two months are KI-Forecast; the ceiling target line is 430 (CHF Tsd).
export const forecastTargetChf = 430;
export const forecastMonths = ['Jan', 'Feb', 'Mär', 'Apr', 'Mai*', 'Jun*'];
export const forecastActualCount = 4; // Jan–Apr are actuals; Mai*/Jun* are forecast

// Strategic scorecard (Balanced) — five steering dimensions.
export const radarDims: RadarDim[] = [
  { dim: 'Wachstum', value: 78 },
  { dim: 'Conversion', value: 70 },
  { dim: 'Effizienz', value: 72 },
  { dim: 'Zufriedenheit', value: 82 },
  { dim: 'Qualität', value: 76 },
];

// German display labels for product lines (measure `subject` is already German, kept as-is).
export const productOrder = ['Motorfahrzeug', 'Hausrat', 'Gewerbe', 'Vorsorge', 'Rechtsschutz'];
export const productHighlight = 'Motorfahrzeug'; // largest value driver

export const regionOrder = ['Mittelland', 'Zürich', 'Romandie', 'Tessin'];
export const regionHighlight = 'Mittelland';

// Funnel (Übersicht bottleneck): stage volumes + phase-to-phase conversion.
// Bottleneck flagged where the drop is largest (Kontakt → Qualifiziert).
export const funnelStages = [
  { stage: 'Neu', volume: 480, conversion: null as number | null, bottleneck: false },
  { stage: 'Kontaktiert', volume: 372, conversion: 78, bottleneck: false },
  { stage: 'Qualifiziert', volume: 216, conversion: 58, bottleneck: true },
  { stage: 'Offerte', volume: 148, conversion: 69, bottleneck: false },
  { stage: 'Abschluss', volume: 96, conversion: 65, bottleneck: false },
];

// GA-Benchmark (GA-Steuerungsmatrix). Bern-Mittelland's Ziel/Conversion/Automation also
// exist as GA measures in measures.json; the peer GAs are mock benchmark rows.
export const gaBenchmark: GaBenchmarkRow[] = [
  { ga: 'Bern-Mittelland', ziel: 96, conversion: 28, backlog: 17, automation: 72, isCurrent: true },
  { ga: 'Luzern', ziel: 104, conversion: 33, backlog: 6, automation: 84, isCurrent: false },
  { ga: 'Basel', ziel: 101, conversion: 31, backlog: 8, automation: 79, isCurrent: false },
  { ga: 'Biel-Seeland', ziel: 89, conversion: 22, backlog: 29, automation: 61, isCurrent: false },
];
