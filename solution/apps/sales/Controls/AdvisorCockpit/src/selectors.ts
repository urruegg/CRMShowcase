// Pure selectors that shape the raw records into the cockpit view model.
// Kept side-effect free so they are unit-testable without a DOM.
import type {
  AccountOrContact,
  AccountRecord,
  ActivityRecord,
  CockpitData,
  LeadRecord,
  NbaRecord,
} from './types';

export function buildAccountIndex(records: AccountOrContact[]): Map<string, string> {
  const index = new Map<string, string>();
  for (const r of records) {
    if (r.recordType === 'account') index.set(r.key, (r as AccountRecord).name);
  }
  return index;
}

export function appointments(activities: ActivityRecord[]): ActivityRecord[] {
  return activities
    .filter((a) => a.activityType === 'appointment')
    .sort((a, b) => (a.start ?? '').localeCompare(b.start ?? ''));
}

export function openTasks(activities: ActivityRecord[]): ActivityRecord[] {
  return activities.filter((a) => a.activityType === 'task');
}

export function overdueTaskCount(activities: ActivityRecord[]): number {
  return openTasks(activities).filter((a) => a.status === 'Überfällig').length;
}

export interface LeadGroup {
  clusterName: string | null;
  leads: LeadRecord[];
  isCluster: boolean;
}

// Groups clustered leads (e.g. the Brunner household) and keeps singles standalone,
// preserving first-seen order.
export function groupLeads(leads: LeadRecord[]): LeadGroup[] {
  const groups: LeadGroup[] = [];
  const clusterIndex = new Map<string, LeadGroup>();
  for (const lead of leads) {
    if (lead.leadCluster) {
      let group = clusterIndex.get(lead.leadCluster);
      if (!group) {
        group = { clusterName: lead.leadCluster, leads: [], isCluster: true };
        clusterIndex.set(lead.leadCluster, group);
        groups.push(group);
      }
      group.leads.push(lead);
    } else {
      groups.push({ clusterName: null, leads: [lead], isCluster: false });
    }
  }
  return groups;
}

export function sortedNba(nba: NbaRecord[]): NbaRecord[] {
  return [...nba].sort((a, b) => a.rank - b.rank);
}

export interface HeaderKpis {
  appointmentsToday: number;
  openTasks: number;
  overdue: number;
  topLeadScore: number;
}

export function headerKpis(data: CockpitData): HeaderKpis {
  const topLead = data.leads.reduce(
    (max, l) => (l.score > max ? l.score : max),
    0,
  );
  return {
    appointmentsToday: appointments(data.activities).length,
    openTasks: openTasks(data.activities).length,
    overdue: overdueTaskCount(data.activities),
    topLeadScore: topLead,
  };
}
