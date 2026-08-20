import { describe, expect, it } from 'vitest';
import { mapCockpitRows } from './map-cockpit-rows';
import { emptyCockpitSourceRows, type CockpitSourceSnapshot } from './source-rows';
import { provenancePresentation } from './provenance';

const businessUnitId = '00000000-0000-0000-0000-000000000001';
const advisorId = '00000000-0000-0000-0000-000000000002';
const accountAId = '00000000-0000-0000-0000-000000000003';
const accountBId = '00000000-0000-0000-0000-000000000004';
const contactId = '00000000-0000-0000-0000-000000000005';
const leadId = '00000000-0000-0000-0000-000000000006';

function readySnapshot(): CockpitSourceSnapshot {
  return {
    rows: {
      ...emptyCockpitSourceRows(),
      advisors: [{ id: advisorId, fullName: 'Test Advisor', title: 'Advisor', businessUnitId }],
      businessUnits: [{ id: businessUnitId, name: 'GA Test' }],
      accounts: [
        {
          id: accountAId,
          name: 'Same display name',
          accountType: 'Household',
          segment: 'Private',
          region: 'Bern',
          ownerName: 'Test Advisor',
          city: 'Bern',
          postalCode: '3000',
        },
        {
          id: accountBId,
          name: 'Same display name',
          accountType: 'Business',
          segment: 'Commercial',
          region: 'Bern',
          ownerName: 'Test Advisor',
          city: 'Bern',
          postalCode: '3000',
        },
      ],
      contacts: [
        {
          id: contactId,
          accountId: accountBId,
          firstName: 'Taylor',
          lastName: 'Example',
          role: 'Owner',
          email: 'taylor@example.invalid',
          phone: '+41 00 000 00 00',
          consentEmail: true,
          consentPhone: true,
        },
      ],
      leads: [
        {
          id: leadId,
          topic: 'Test lead',
          accountId: accountBId,
          contactId,
          channel: 'Online',
          priority: 'Hoch',
          sla: 'Today',
          score: 91,
          status: 'Neu',
          source: 'Test',
          leadClusterId: null,
          clusterRole: 'single',
          ownerName: 'Test Advisor',
        },
      ],
    },
  };
}

describe('mapCockpitRows', () => {
  it('joins records only by primary GUID even when display names collide', () => {
    const result = mapCockpitRows(readySnapshot());

    expect(result.status).toBe('ready');
    if (result.status !== 'ready') return;
    expect(result.data.leads[0].accountKey).toBe(accountBId);
    expect(result.data.accountsContacts.find((row) => row.recordType === 'contact')?.accountKey).toBe(accountBId);
  });

  it('returns an unmapped state instead of hiding a missing lookup', () => {
    const snapshot = readySnapshot();
    snapshot.rows.leads[0] = { ...snapshot.rows.leads[0], accountId: '00000000-0000-0000-0000-000000000099' };

    const result = mapCockpitRows(snapshot);

    expect(result.status).toBe('unmapped');
    if (result.status !== 'unmapped') return;
    expect(result.metadata.unmappedFields).toContain(`leads.${leadId}.accountId`);
    expect(result.metadata.provenance[`leads.${leadId}.accountId`]).toBe('unmapped');
  });

  it('preserves a permission-denied source region', () => {
    const snapshot = readySnapshot();
    snapshot.issues = {
      claims: { status: 'denied', message: 'Claims access denied.' },
    };

    expect(mapCockpitRows(snapshot)).toEqual({
      status: 'denied',
      region: 'claims',
      message: 'Claims access denied.',
    });
  });

  it('classifies CRM, external projections, and unmapped values distinctly', () => {
    const result = mapCockpitRows(readySnapshot());

    expect(result.status).toBe('ready');
    if (result.status !== 'ready') return;
    expect(result.metadata.provenance.accountsContacts).toBe('crm');
    expect(result.metadata.provenance.policies).toBe('external');
    expect(result.metadata.provenance.claims).toBe('external');
    expect(result.metadata.provenance.measures).toBe('external');
    expect(provenancePresentation.crm.tone).toBe('normal');
    expect(provenancePresentation.external.tone).toBe('grey');
    expect(provenancePresentation.unmapped.tone).toBe('yellow');
  });
});