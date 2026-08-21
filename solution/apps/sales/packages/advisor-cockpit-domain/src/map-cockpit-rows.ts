import type { DataState, DataStateMetadata } from './data-state';
import type { ProvenanceKind } from './provenance';
import { cockpitSourceRegions, type CockpitSourceSnapshot, type DataverseId } from './source-rows';
import type { AccountOrContact, CockpitData, NbaProvenance } from './types';

const baseProvenance: Record<string, ProvenanceKind> = {
  advisor: 'crm',
  accountsContacts: 'crm',
  leads: 'crm',
  'leads.score': 'external',
  activities: 'crm',
  nba: 'crm',
  'nba.score': 'external',
  'nba.provenance': 'crm',
  policies: 'external',
  claims: 'external',
  measures: 'external',
};

export function mapCockpitRows(snapshot: CockpitSourceSnapshot): DataState<CockpitData> {
  for (const region of cockpitSourceRegions) {
    const issue = snapshot.issues?.[region];
    if (issue) return { status: issue.status, region, message: issue.message };
  }

  const rows = snapshot.rows;
  const rowCount = cockpitSourceRegions.reduce((count, region) => count + rows[region].length, 0);
  if (rowCount === 0) return { status: 'empty', message: 'No Advisor Cockpit records were returned.' };

  const accountIds = new Set(rows.accounts.map((row) => row.id));
  const contactIds = new Set(rows.contacts.map((row) => row.id));
  const leadIds = new Set(rows.leads.map((row) => row.id));
  const leadClusters = new Map(rows.leadClusters.map((row) => [row.id, row.name]));
  const businessUnits = new Map(rows.businessUnits.map((row) => [row.id, row.name]));
  const nextBestActionIds = new Set(rows.nextBestActions.map((row) => row.id));
  const provenance: Record<string, ProvenanceKind> = { ...baseProvenance };
  const unmappedFields: string[] = [];

  const markMissingLookup = (
    region: string,
    rowId: DataverseId,
    field: string,
    lookupId: DataverseId | null,
    targetIds: ReadonlySet<DataverseId> | ReadonlyMap<DataverseId, string>,
  ) => {
    if (lookupId === null || targetIds.has(lookupId)) return;
    const path = `${region}.${rowId}.${field}`;
    unmappedFields.push(path);
    provenance[path] = 'unmapped';
  };

  const advisorRow = rows.advisors[0];
  if (!advisorRow) {
    unmappedFields.push('advisor');
    provenance.advisor = 'unmapped';
  } else {
    markMissingLookup('advisors', advisorRow.id, 'businessUnitId', advisorRow.businessUnitId, businessUnits);
  }

  for (const row of rows.contacts) markMissingLookup('contacts', row.id, 'accountId', row.accountId, accountIds);
  for (const row of rows.leads) {
    markMissingLookup('leads', row.id, 'accountId', row.accountId, accountIds);
    markMissingLookup('leads', row.id, 'contactId', row.contactId, contactIds);
    markMissingLookup('leads', row.id, 'leadClusterId', row.leadClusterId, leadClusters);
  }
  for (const row of rows.activities) markMissingLookup('activities', row.id, 'accountId', row.accountId, accountIds);
  for (const row of rows.nextBestActions) {
    markMissingLookup('nextBestActions', row.id, 'accountId', row.accountId, accountIds);
    markMissingLookup('nextBestActions', row.id, 'leadId', row.leadId, leadIds);
  }
  for (const row of rows.nbaProvenance) {
    markMissingLookup('nbaProvenance', row.id, 'nextBestActionId', row.nextBestActionId, nextBestActionIds);
  }
  for (const row of rows.policies) markMissingLookup('policies', row.id, 'accountId', row.accountId, accountIds);
  for (const row of rows.claims) markMissingLookup('claims', row.id, 'accountId', row.accountId, accountIds);

  const accountsContacts: AccountOrContact[] = [
    ...rows.accounts.map((row) => ({
      recordType: 'account' as const,
      key: row.id,
      name: row.name,
      accountType: row.accountType,
      segment: row.segment,
      region: row.region,
      owner: row.ownerName,
      city: row.city,
      postalCode: row.postalCode,
    })),
    ...rows.contacts.map((row) => ({
      recordType: 'contact' as const,
      key: row.id,
      accountKey: row.accountId,
      firstName: row.firstName,
      lastName: row.lastName,
      role: row.role,
      email: row.email,
      phone: row.phone,
      consentEmail: row.consentEmail,
      consentPhone: row.consentPhone,
    })),
  ];

  const data: CockpitData = {
    advisor: {
      fullName: advisorRow?.fullName ?? '',
      role: advisorRow?.title ?? '',
      generalAgency: advisorRow ? (businessUnits.get(advisorRow.businessUnitId) ?? '') : '',
    },
    accountsContacts,
    leads: rows.leads.map((row) => ({
      key: row.id,
      topic: row.topic,
      accountKey: row.accountId,
      contactKey: row.contactId,
      channel: row.channel,
      priority: row.priority,
      sla: row.sla,
      score: row.score,
      status: row.status,
      source: row.source,
      leadCluster: row.leadClusterId ? (leadClusters.get(row.leadClusterId) ?? null) : null,
      leadClusterId: row.leadClusterId,
      clusterRole: row.clusterRole,
      owner: row.ownerName,
    })),
    activities: rows.activities.map((row) => ({
      key: row.id,
      activityType: row.activityType,
      subject: row.subject,
      accountKey: row.accountId,
      start: row.start,
      due: row.due,
      location: row.location,
      channel: row.channel,
      status: row.status,
      owner: row.ownerName,
    })),
    nba: rows.nextBestActions.map((row) => ({
      key: row.id,
      rank: row.rank,
      category: row.category,
      title: row.title,
      accountKey: row.accountId,
      leadKey: row.leadId,
      channel: row.channel,
      score: row.score,
      status: row.status,
      disclosure: row.disclosure,
      rationale: row.rationale,
      provenance: rows.nbaProvenance
        .filter((citation) => citation.nextBestActionId === row.id)
        .map((citation): NbaProvenance => ({ source: citation.source, ref: citation.reference })),
    })),
    policies: rows.policies.map((row) => ({
      key: row.id,
      externalId: row.externalId,
      accountKey: row.accountId,
      productLine: row.productLine,
      product: row.product,
      status: row.status,
      premiumChf: row.premiumChf,
      startDate: row.startDate,
      endDate: row.endDate,
      externalSystem: row.externalSystem,
    })),
    claims: rows.claims.map((row) => ({
      key: row.id,
      externalId: row.externalId,
      caseType: row.caseType,
      accountKey: row.accountId,
      productLine: row.productLine,
      title: row.title,
      channel: row.channel,
      status: row.status,
      openedDate: row.openedDate,
      slaHours: row.slaHours,
      externalSystem: row.externalSystem,
    })),
    measures: rows.measures.map(({ id: _id, ...row }) => row),
  };

  const metadata: DataStateMetadata = { provenance, unmappedFields };
  return unmappedFields.length > 0
    ? { status: 'unmapped', data, metadata, message: 'One or more source values could not be mapped.' }
    : { status: 'ready', data, metadata };
}