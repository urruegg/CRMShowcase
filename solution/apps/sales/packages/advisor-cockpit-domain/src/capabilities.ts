export type HostKind = 'fixture-harness' | 'pcf-artifact' | 'standalone-code-app' | 'embedded-code-app';

export type CapabilityAvailability = 'supported' | 'partial' | 'blocked' | 'unverified';

export type CockpitWriteCommand =
  | { type: 'acceptNba'; nbaId: string }
  | { type: 'assignLead'; leadIds: string[]; ownerId: string }
  | { type: 'bundleLeads'; leadIds: string[]; clusterId: string }
  | { type: 'splitLeads'; leadIds: string[] }
  | { type: 'updateLeadQueueStatus'; leadId: string; status: string }
  | { type: 'dismissNba'; nbaId: string }
  | { type: 'snoozeNba'; nbaId: string }
  | { type: 'editNba'; nbaId: string; changes: Readonly<{ channel?: string; rank?: number }> }
  | { type: 'createAppointment'; accountId: string }
  | { type: 'createTask'; accountId: string }
  | { type: 'call'; phoneNumber: string }
  | { type: 'savePersonalView'; name: string };

export interface RuntimeContext {
  hostKind: HostKind;
  appId: string | null;
  environmentId: string | null;
  sessionId: string | null;
  userObjectId: string | null;
  locale: string;
}

export interface CommandCapability {
  availability: CapabilityAvailability;
  reason: string;
  target: string;
}

export function isCapabilityExecutable(capability: CommandCapability): boolean {
  return capability.availability === 'supported' || capability.availability === 'partial';
}

export interface CommandResult {
  ok: boolean;
  message: string;
}

export interface AdvisorCockpitHost {
  context: RuntimeContext;
  capability(command: CockpitWriteCommand['type']): CommandCapability;
  execute(command: CockpitWriteCommand): Promise<CommandResult>;
  navigate(table: 'account' | 'lead' | 'crmshow_claimprojection', id: string): Promise<void>;
}