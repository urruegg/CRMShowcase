import {
  writeCapabilities,
  type AdvisorCockpitHost,
  type HostKind,
} from '@crmshow/advisor-cockpit-domain';

type FixtureHostKind = Extract<HostKind, 'fixture-harness' | 'pcf-artifact'>;

export function createFixtureHost(hostKind: FixtureHostKind = 'fixture-harness'): AdvisorCockpitHost {
  return {
    context: {
      hostKind,
      appId: null,
      environmentId: null,
      sessionId: null,
      userObjectId: null,
      locale: 'de-CH',
    },
    capability: (command) => writeCapabilities[command],
    execute: async (command) => ({
      ok: false,
      message: `Fixture mode did not execute ${command.type}. ${writeCapabilities[command.type].reason}`,
    }),
    navigate: async () => {
      throw new Error('Fixture mode cannot navigate to Dataverse records.');
    },
  };
}

export const fixtureHost = createFixtureHost();