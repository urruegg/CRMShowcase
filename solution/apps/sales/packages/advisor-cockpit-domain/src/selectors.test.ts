import { describe, expect, it } from 'vitest';
import type { CockpitData } from './types';
import { appointments, buildAccountIndex, filterLeads, groupLeads, headerKpis, openTasks, sortedNba } from './selectors';

const cockpitFixtures: CockpitData = {
  advisor: { fullName: 'Test Advisor', role: 'Advisor', generalAgency: 'GA Test' },
  accountsContacts: [
    {
      recordType: 'account',
      key: 'ACC-BRUNNER',
      name: 'Haushalt Brunner',
      accountType: 'Household',
      segment: 'Private',
      region: 'Bern',
      owner: 'Test Advisor',
      city: 'Bern',
      postalCode: '3000',
    },
    {
      recordType: 'account',
      key: 'ACC-KELLER',
      name: 'Haushalt Keller',
      accountType: 'Household',
      segment: 'Private',
      region: 'Bern',
      owner: 'Test Advisor',
      city: 'Bern',
      postalCode: '3000',
    },
  ],
  leads: [
    {
      key: 'LEAD-BRUNNER-1', topic: 'Brunner offer', accountKey: 'ACC-BRUNNER', contactKey: 'CONTACT-1',
      channel: 'Online', priority: 'Hoch', sla: 'Today', score: 99, status: 'Neu', source: 'Online',
      leadCluster: 'Haushalt Brunner', leadClusterId: 'CLUSTER-BRUNNER', clusterRole: 'child', owner: 'Test Advisor',
    },
    {
      key: 'LEAD-BRUNNER-2', topic: 'Brunner renewal', accountKey: 'ACC-BRUNNER', contactKey: 'CONTACT-1',
      channel: 'Phone', priority: 'Hoch', sla: 'Today', score: 87, status: 'In Arbeit', source: 'Retention',
      leadCluster: 'Haushalt Brunner', leadClusterId: 'CLUSTER-BRUNNER', clusterRole: 'child', owner: 'Test Advisor',
    },
    {
      key: 'LEAD-BRUNNER-3', topic: 'Brunner appointment', accountKey: 'ACC-BRUNNER', contactKey: 'CONTACT-1',
      channel: 'Appointment', priority: 'Hoch', sla: 'Today', score: 81, status: 'Gebündelt', source: 'Appointment',
      leadCluster: 'Haushalt Brunner', leadClusterId: 'CLUSTER-BRUNNER', clusterRole: 'child', owner: 'Test Advisor',
    },
    {
      key: 'LEAD-KELLER-1', topic: 'Keller pension', accountKey: 'ACC-KELLER', contactKey: 'CONTACT-2',
      channel: 'Kampagne', priority: 'Mittel', sla: 'Tomorrow', score: 74, status: 'Neu', source: 'Vorsorge 25',
      leadCluster: null, leadClusterId: null, clusterRole: 'single', owner: 'Test Advisor',
    },
    {
      key: 'LEAD-KELLER-2', topic: 'Keller life event', accountKey: 'ACC-KELLER', contactKey: 'CONTACT-2',
      channel: 'Appointment', priority: 'Mittel', sla: 'Tomorrow', score: 68, status: 'Neu', source: 'Life Event',
      leadCluster: null, leadClusterId: null, clusterRole: 'single', owner: 'Test Advisor',
    },
  ],
  activities: [
    { key: 'APPT-1', activityType: 'appointment', subject: 'Appointment', accountKey: 'ACC-BRUNNER', start: '2026-08-20T09:00:00Z', channel: 'Phone', status: 'Open', owner: 'Test Advisor' },
    { key: 'TASK-1', activityType: 'task', subject: 'Follow up', accountKey: 'ACC-KELLER', due: '2026-08-20', channel: 'Task', status: 'Überfällig', owner: 'Test Advisor' },
  ],
  nba: [
    { key: 'NBA-2', rank: 2, category: 'Chance', title: 'Keller follow-up', accountKey: 'ACC-KELLER', leadKey: 'LEAD-KELLER-1', channel: 'Phone', score: 74, status: 'Active', disclosure: 'AI-assisted', rationale: 'Test', provenance: [] },
    { key: 'NBA-1', rank: 1, category: 'Dringend', title: 'Brunner 4h focus', accountKey: 'ACC-BRUNNER', leadKey: 'LEAD-BRUNNER-1', channel: 'Phone', score: 99, status: 'Active', disclosure: 'AI-assisted', rationale: 'Test', provenance: [] },
  ],
  policies: [],
  claims: [],
  measures: [],
};

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

  it('filters leads by customer, channel, status and source', () => {
    const idx = buildAccountIndex(cockpitFixtures.accountsContacts);
    const name = (k: string) => idx.get(k) ?? k;
    const none = { customer: '', channel: 'Alle Kanäle', status: 'Alle Status', source: 'Alle Quellen' };
    expect(filterLeads(cockpitFixtures.leads, none, name).length).toBe(cockpitFixtures.leads.length);
    expect(filterLeads(cockpitFixtures.leads, { ...none, customer: 'Brunner' }, name).length).toBe(3);
    expect(filterLeads(cockpitFixtures.leads, { ...none, channel: 'Kampagne' }, name).length).toBe(1);
    expect(filterLeads(cockpitFixtures.leads, { ...none, status: 'Neu' }, name).length).toBe(3);
    expect(filterLeads(cockpitFixtures.leads, { ...none, source: 'Vorsorge 25' }, name).length).toBe(1);
  });
});
