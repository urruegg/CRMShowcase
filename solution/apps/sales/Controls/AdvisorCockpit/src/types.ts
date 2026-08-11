// Interfaces mirroring the Dataverse columns the AdvisorCockpit binds to.
// Same shape the real PCF `context` will provide, so the component is data-source agnostic.
// Fixtures under data/scenarios/advisor-cockpit/ are typed to these.

export type AccountType = 'Household' | 'Business' | 'Broker';

export interface AccountRecord {
  recordType: 'account';
  key: string;
  name: string;
  accountType: AccountType;
  segment: string;
  region: string;
  owner: string;
  city: string;
  postalCode: string;
}

export interface ContactRecord {
  recordType: 'contact';
  key: string;
  accountKey: string;
  firstName: string;
  lastName: string;
  role: string;
  email: string;
  phone: string;
  consentEmail: boolean;
  consentPhone: boolean;
}

export type AccountOrContact = AccountRecord | ContactRecord;

export interface LeadRecord {
  key: string;
  topic: string;
  accountKey: string;
  contactKey: string;
  channel: string;
  priority: 'Hoch' | 'Mittel' | 'Tief';
  sla: string;
  score: number;
  status: string;
  source: string;
  leadCluster: string | null;
  clusterRole: 'child' | 'single' | 'parent';
  owner: string;
}

export interface ActivityRecord {
  key: string;
  activityType: 'appointment' | 'task';
  subject: string;
  accountKey: string;
  start?: string;
  due?: string;
  location?: string;
  channel: string;
  status: string;
  owner: string;
}

export interface NbaProvenance {
  source: 'lead' | 'measure' | 'task' | 'activity' | 'policy' | 'claim';
  ref: string;
}

export type NbaCategory = 'Dringend' | 'Risiko' | 'Chance' | 'Retention' | 'Insight';

export interface NbaRecord {
  key: string;
  rank: number;
  category: NbaCategory;
  title: string;
  accountKey: string;
  leadKey: string | null;
  channel: string;
  score: number;
  status: string;
  disclosure: string;
  rationale: string;
  provenance: NbaProvenance[];
}

export interface PolicyRecord {
  key: string;
  externalId: string;
  accountKey: string;
  productLine: string;
  product: string;
  status: string;
  premiumChf: number;
  startDate: string;
  endDate: string;
  externalSystem: string;
}

export interface ClaimRecord {
  key: string;
  externalId: string;
  caseType: 'Schaden' | 'Anliegen';
  accountKey: string;
  productLine: string;
  title: string;
  channel: string;
  status: string;
  openedDate: string;
  slaHours?: number;
  externalSystem: string;
}

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

export interface CockpitData {
  accountsContacts: AccountOrContact[];
  leads: LeadRecord[];
  activities: ActivityRecord[];
  nba: NbaRecord[];
  policies: PolicyRecord[];
  claims: ClaimRecord[];
  measures: MeasureRow[];
}
