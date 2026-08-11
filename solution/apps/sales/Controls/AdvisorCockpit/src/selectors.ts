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

export type LeadSortKey = 'score' | 'topic' | 'customer' | 'channel' | 'priority' | 'sla' | 'status';

const PRIORITY_RANK: Record<string, number> = { Hoch: 3, Mittel: 2, Tief: 1 };

// Sorts leads by a column. Cluster grouping is applied afterwards on the sorted list,
// so children stay ordered and each cluster floats to its strongest child's position.
export function sortLeads(
  leads: LeadRecord[],
  key: LeadSortKey,
  dir: 'asc' | 'desc',
  accountName: (k: string) => string,
): LeadRecord[] {
  const sign = dir === 'asc' ? 1 : -1;
  const val = (l: LeadRecord): number | string => {
    switch (key) {
      case 'score': return l.score;
      case 'priority': return PRIORITY_RANK[l.priority] ?? 0;
      case 'customer': return accountName(l.accountKey).toLowerCase();
      case 'channel': return l.channel.toLowerCase();
      case 'sla': return l.sla.toLowerCase();
      case 'status': return l.status.toLowerCase();
      default: return l.topic.toLowerCase();
    }
  };
  return [...leads].sort((a, b) => {
    const va = val(a);
    const vb = val(b);
    if (va < vb) return -1 * sign;
    if (va > vb) return 1 * sign;
    return b.score - a.score;
  });
}

export interface BoardBuckets {
  neu: LeadRecord[];
  inArbeit: LeadRecord[];
  gebuendeltClusters: LeadGroup[];
  gebuendeltSingles: LeadRecord[];
}

// Buckets leads into the three board pipeline columns. Clusters always live in
// Gebündelt / Geplant; single leads fall into a column by their status.
export function boardBuckets(groups: LeadGroup[]): BoardBuckets {
  const b: BoardBuckets = { neu: [], inArbeit: [], gebuendeltClusters: [], gebuendeltSingles: [] };
  for (const g of groups) {
    if (g.isCluster) {
      b.gebuendeltClusters.push(g);
      continue;
    }
    const l = g.leads[0];
    if (/gebündelt|geplant/i.test(l.status)) b.gebuendeltSingles.push(l);
    else if (/^neu$/i.test(l.status)) b.neu.push(l);
    else b.inArbeit.push(l);
  }
  return b;
}

export interface LeadFilters {
  customer: string;
  channel: string; // 'Alle Kanäle' means no channel filter
  status: string; // 'Alle Status' means no status filter
  source: string; // 'Alle Quellen' means no source filter
}

// Applies the Meine-Leads column filters. Channel/source use a tolerant contains match
// because a lead's channel/source is finer-grained than the coarse filter vocabulary.
export function filterLeads(
  leads: LeadRecord[],
  f: LeadFilters,
  accountName: (key: string) => string,
): LeadRecord[] {
  const cust = f.customer.trim().toLowerCase();
  return leads.filter((l) => {
    if (cust && !accountName(l.accountKey).toLowerCase().includes(cust) && !l.topic.toLowerCase().includes(cust)) {
      return false;
    }
    if (f.channel !== 'Alle Kanäle' && !l.channel.toLowerCase().includes(f.channel.toLowerCase())) return false;
    if (f.status !== 'Alle Status' && l.status !== f.status) return false;
    if (f.source !== 'Alle Quellen' && !l.source.toLowerCase().includes(f.source.toLowerCase())) return false;
    return true;
  });
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
