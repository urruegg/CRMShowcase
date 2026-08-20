// Typed mock data — imports the repo's synthetic seed fixtures directly
// (data/scenarios/advisor-cockpit/), the single source of truth also used by the
// pipeline seed loader. Six levels up from this control folder to the repo root.
import accountsContacts from '../../../../../../data/scenarios/advisor-cockpit/accounts-contacts.json';
import leads from '../../../../../../data/scenarios/advisor-cockpit/leads.json';
import activities from '../../../../../../data/scenarios/advisor-cockpit/activities.json';
import nba from '../../../../../../data/scenarios/advisor-cockpit/nba.json';
import policies from '../../../../../../data/scenarios/advisor-cockpit/policies.json';
import claims from '../../../../../../data/scenarios/advisor-cockpit/claims.json';
import measures from '../../../../../../data/scenarios/advisor-cockpit/measures.json';

import type {
  AccountOrContact,
  ActivityRecord,
  AdvisorProfile,
  ClaimRecord,
  CockpitData,
  LeadRecord,
  MeasureRow,
  NbaRecord,
  PolicyRecord,
} from '@crmshow/advisor-cockpit-domain';

// The signed-in advisor. In the PCF this is mapped from `context` — userSettings.userName plus a
// WebAPI retrieve of systemuser.title and the user's businessunit.name — it is not seeded data.
export const advisorProfile: AdvisorProfile = {
  fullName: 'Rahel Moser',
  role: 'Versicherungsberaterin',
  generalAgency: 'Generalagentur Bern-Mittelland',
};

export const cockpitFixtures: CockpitData = {
  advisor: advisorProfile,
  accountsContacts: accountsContacts as AccountOrContact[],
  leads: leads as LeadRecord[],
  activities: activities as ActivityRecord[],
  nba: nba as NbaRecord[],
  policies: policies as PolicyRecord[],
  claims: claims as ClaimRecord[],
  measures: measures as MeasureRow[],
};
