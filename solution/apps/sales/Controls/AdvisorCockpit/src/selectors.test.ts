import { describe, expect, it } from 'vitest';
import { cockpitFixtures } from './fixtures';
import { appointments, groupLeads, headerKpis, openTasks, sortedNba } from './selectors';

describe('cockpit selectors', () => {
  it('groups the Brunner household leads into one cluster and keeps singles standalone', () => {
    const groups = groupLeads(cockpitFixtures.leads);
    const cluster = groups.find((g) => g.isCluster);
    expect(cluster?.clusterName).toBe('Haushalt Brunner');
    expect(cluster?.leads.length).toBe(3);
    expect(groups.filter((g) => !g.isCluster).length).toBeGreaterThan(0);
  });

  it('derives header KPIs from activities and leads', () => {
    const kpis = headerKpis(cockpitFixtures);
    expect(kpis.appointmentsToday).toBe(appointments(cockpitFixtures.activities).length);
    expect(kpis.openTasks).toBe(openTasks(cockpitFixtures.activities).length);
    expect(kpis.topLeadScore).toBe(99);
  });

  it('sorts NBA cards by rank with the Brunner 4h card first', () => {
    const nba = sortedNba(cockpitFixtures.nba);
    expect(nba[0].rank).toBe(1);
    expect(nba[0].title).toContain('Brunner');
  });
});
