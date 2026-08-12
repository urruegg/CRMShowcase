import {
  forecastActualCount,
  forecastMonths,
  forecastTargetChf,
  gaBenchmark,
  productHighlight,
  productOrder,
  radarDims,
  regionHighlight,
  regionOrder,
  scorecardMeta,
  scorecardOrder,
  funnelStages,
} from './presentation';
import type {
  BarDatum,
  ForecastPoint,
  FunnelStage,
  GaBenchmarkRow,
  MeasureRow,
  RadarDim,
  ScorecardKpi,
} from './types';

const GA_SUBJECT = 'GA-Bern-Mittelland';

function gaValue(measures: MeasureRow[], metric: string): number | undefined {
  return measures.find((m) => m.subjectType === 'ga' && m.subject === GA_SUBJECT && m.metric === metric)?.value;
}

function formatScorecard(metric: string, value: number): string {
  if (metric === 'NPS') return `${value}`;
  if (metric === 'GrowthYoY') return `+${value} %`;
  return `${value} %`;
}

export function buildScorecard(measures: MeasureRow[]): ScorecardKpi[] {
  const cards: ScorecardKpi[] = [];
  for (const metric of scorecardOrder) {
    const meta = scorecardMeta[metric];
    const value = gaValue(measures, metric);
    if (meta === undefined || value === undefined) continue;
    cards.push({
      key: metric,
      label: meta.label,
      valueText: formatScorecard(metric, value),
      targetText: meta.target,
      delta: meta.delta,
      deltaDir: meta.deltaDir,
      hint: meta.hint,
    });
  }
  return cards;
}

export function buildForecast(measures: MeasureRow[]): ForecastPoint[] {
  const rows = measures
    .filter((m) => m.subjectType === 'ga' && m.subject === GA_SUBJECT && m.metric === 'Forecast')
    .sort((a, b) => a.asOfDate.localeCompare(b.asOfDate));

  return rows.map((row, i) => {
    const isForecast = i >= forecastActualCount;
    const band = Math.round(row.value * 0.04);
    return {
      month: forecastMonths[i] ?? row.asOfDate.slice(0, 7),
      // Overlap the boundary point so the actual and forecast lines connect visually.
      actual: i <= forecastActualCount ? row.value : null,
      forecast: isForecast ? row.value : i === forecastActualCount - 1 ? row.value : null,
      low: isForecast ? row.value - band : null,
      high: isForecast ? row.value + band : null,
      target: forecastTargetChf,
    };
  });
}

function productLabelValues(measures: MeasureRow[]): BarDatum[] {
  const bySubject = new Map(
    measures
      .filter((m) => m.subjectType === 'product' && m.metric === 'Forecast')
      .map((m) => [m.subject, m.value] as const),
  );
  return productOrder
    .filter((label) => bySubject.has(label))
    .map((label) => ({ label, value: bySubject.get(label)!, highlight: label === productHighlight }));
}

export function buildProductBars(measures: MeasureRow[]): BarDatum[] {
  return productLabelValues(measures);
}

export function buildRegionBars(measures: MeasureRow[]): BarDatum[] {
  const bySubject = new Map(
    measures
      .filter((m) => m.subjectType === 'region' && m.metric === 'GrowthYoY')
      .map((m) => [m.subject, m.value] as const),
  );
  return regionOrder
    .filter((label) => bySubject.has(label))
    .map((label) => ({ label, value: bySubject.get(label)!, highlight: label === regionHighlight }));
}

export function buildRadar(): RadarDim[] {
  return radarDims;
}

export function buildFunnel(): FunnelStage[] {
  return funnelStages;
}

export function buildBenchmark(): GaBenchmarkRow[] {
  return gaBenchmark;
}
