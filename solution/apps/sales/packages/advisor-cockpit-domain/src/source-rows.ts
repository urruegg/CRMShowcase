import type {
  AccountType,
  ActivityRecord,
  ClaimRecord,
  LeadRecord,
  MeasureRow,
  NbaCategory,
  NbaProvenance,
} from './types';

export type DataverseId = string;

export interface AdvisorSourceRow {
  id: DataverseId;
  fullName: string;
  title: string;
  businessUnitId: DataverseId;
}

export interface BusinessUnitSourceRow {
  id: DataverseId;
  name: string;
}

export interface AccountSourceRow {
  id: DataverseId;
  name: string;
  accountType: AccountType;
  segment: string;
  region: string;
  ownerName: string;
  city: string;
  postalCode: string;
}

export interface ContactSourceRow {
  id: DataverseId;
  accountId: DataverseId;
  firstName: string;
  lastName: string;
  role: string;
  email: string;
  phone: string;
  consentEmail: boolean;
  consentPhone: boolean;
}

export interface LeadClusterSourceRow {
  id: DataverseId;
  name: string;
}

export interface LeadSourceRow {
  id: DataverseId;
  topic: string;
  accountId: DataverseId;
  contactId: DataverseId;
  channel: string;
  priority: LeadRecord['priority'];
  sla: string;
  score: number;
  status: string;
  source: string;
  leadClusterId: DataverseId | null;
  clusterRole: LeadRecord['clusterRole'];
  ownerName: string;
}

export interface ActivitySourceRow {
  id: DataverseId;
  activityType: ActivityRecord['activityType'];
  subject: string;
  accountId: DataverseId;
  start?: string;
  due?: string;
  location?: string;
  channel: string;
  status: string;
  ownerName: string;
}

export interface NextBestActionSourceRow {
  id: DataverseId;
  rank: number;
  category: NbaCategory;
  title: string;
  accountId: DataverseId;
  leadId: DataverseId | null;
  channel: string;
  score: number;
  status: string;
  disclosure: string;
  rationale: string;
}

export interface NbaProvenanceSourceRow {
  id: DataverseId;
  nextBestActionId: DataverseId;
  source: NbaProvenance['source'];
  reference: string;
}

export interface PolicySourceRow {
  id: DataverseId;
  externalId: string;
  accountId: DataverseId;
  productLine: string;
  product: string;
  status: string;
  premiumChf: number;
  startDate: string;
  endDate: string;
  externalSystem: string;
}

export interface ClaimSourceRow {
  id: DataverseId;
  externalId: string;
  caseType: ClaimRecord['caseType'];
  accountId: DataverseId;
  productLine: string;
  title: string;
  channel: string;
  status: string;
  openedDate: string;
  slaHours?: number;
  externalSystem: string;
}

export interface MeasureSourceRow extends MeasureRow {
  id: DataverseId;
}

export interface CockpitSourceRows {
  advisors: AdvisorSourceRow[];
  businessUnits: BusinessUnitSourceRow[];
  accounts: AccountSourceRow[];
  contacts: ContactSourceRow[];
  leadClusters: LeadClusterSourceRow[];
  leads: LeadSourceRow[];
  activities: ActivitySourceRow[];
  nextBestActions: NextBestActionSourceRow[];
  nbaProvenance: NbaProvenanceSourceRow[];
  policies: PolicySourceRow[];
  claims: ClaimSourceRow[];
  measures: MeasureSourceRow[];
}

export const cockpitSourceRegions = [
  'advisors',
  'businessUnits',
  'accounts',
  'contacts',
  'leadClusters',
  'leads',
  'activities',
  'nextBestActions',
  'nbaProvenance',
  'policies',
  'claims',
  'measures',
] as const;

export type CockpitSourceRegion = typeof cockpitSourceRegions[number];

export interface SourceRegionIssue {
  status: 'denied' | 'error' | 'unsupported';
  message: string;
}

export interface CockpitSourceSnapshot {
  rows: CockpitSourceRows;
  issues?: Partial<Record<CockpitSourceRegion, SourceRegionIssue>>;
}

export function emptyCockpitSourceRows(): CockpitSourceRows {
  return {
    advisors: [],
    businessUnits: [],
    accounts: [],
    contacts: [],
    leadClusters: [],
    leads: [],
    activities: [],
    nextBestActions: [],
    nbaProvenance: [],
    policies: [],
    claims: [],
    measures: [],
  };
}