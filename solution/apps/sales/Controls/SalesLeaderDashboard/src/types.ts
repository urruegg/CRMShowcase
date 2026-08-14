// Interfaces the SalesLeaderDashboard binds to. The dashboard reads the enterprise
// Measure projection (crmshow_measuresnapshot, ADR-0018/0026) — locally the Phase-5
// data/scenarios/advisor-cockpit/measures.json. Same shape the real PCF context provides.

export interface MeasureRow {
  subject: string;
  subjectType: 'lead' | 'account' | 'contact' | 'ga' | 'region' | 'product' | 'portfolio';
  metric: string;
  region: string | null;
  productLine: string | null;
  asOfDate: string;
  value: number;
  unit: string;
  externalSystem: string;
}

export interface LeaderProfile {
  generalAgency: string; // the GA in scope (business unit)
  scopeLabel: string; // e.g. "VB, VS, Leads, NBA und Forecast im Überblick"
}

export interface DashboardData {
  profile: LeaderProfile;
  measures: MeasureRow[];
}

// ---- View models derived in selectors.ts ----

export type DeltaDir = 'up' | 'down' | 'flat';

export interface ScorecardKpi {
  key: string;
  label: string;
  valueText: string;
  targetText: string;
  delta: string;
  deltaDir: DeltaDir;
  hint: string;
}

export interface ForecastPoint {
  month: string; // "Jan"…"Jun*"
  actual: number | null;
  forecast: number | null;
  low: number | null;
  high: number | null;
  target: number;
}

export interface RadarDim {
  dim: string;
  value: number;
}

export interface BarDatum {
  label: string;
  value: number;
  highlight: boolean;
}

export interface FunnelStage {
  stage: string;
  volume: number;
  conversion: number | null; // conversion from the previous stage, in %
  bottleneck: boolean;
}

export interface GaBenchmarkRow {
  ga: string;
  ziel: number; // GoalAttainment %
  conversion: number; // Lead-Conversion %
  backlog: number; // SLA backlog count
  automation: number; // Automation %
  isCurrent: boolean;
}
