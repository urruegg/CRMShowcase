// Typed mock data for the local harness. Imports the repo's synthetic Measure projection
// (data/scenarios/advisor-cockpit/measures.json) — the same seed the pipeline loader uses.
// Six levels up from this control folder to the repo root.
import measures from '../../../../../../data/scenarios/advisor-cockpit/measures.json';

import type { DashboardData, MeasureRow } from './types';

export const leaderProfile = {
  generalAgency: 'Generalagentur Bern-Mittelland',
  scopeLabel: 'VB, VS, Leads, NBA und Forecast im Überblick',
};

export const dashboardFixtures: DashboardData = {
  profile: leaderProfile,
  measures: measures as MeasureRow[],
};
