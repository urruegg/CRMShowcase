import type { CockpitWriteCommand, CommandCapability } from './capabilities';

export const writeCapabilities = {
  acceptNba: { availability: 'unverified', reason: 'Generated-service update and reread must pass live verification.', target: 'crmshow_nextbestaction.crmshow_status' },
  call: { availability: 'partial', reason: 'Phone launch only; activity logging is not supported.', target: 'tel:' },
  dismissNba: { availability: 'partial', reason: 'Status can be stored; no dismissal-reason field exists.', target: 'crmshow_nextbestaction.crmshow_status' },
  snoozeNba: { availability: 'partial', reason: 'Maps to Planned; no snooze-until field exists.', target: 'crmshow_nextbestaction.crmshow_status' },
  editNba: { availability: 'partial', reason: 'Only existing allowlisted NBA fields can change.', target: 'crmshow_nextbestaction' },
  updateLeadQueueStatus: { availability: 'unverified', reason: 'Generated-service update must pass live verification.', target: 'lead.crmshow_leadqueuestatus' },
  bundleLeads: { availability: 'unverified', reason: 'Lookup association must pass generated-service verification.', target: 'lead.crmshow_leadclusterid' },
  splitLeads: { availability: 'unverified', reason: 'Lookup disassociation must pass generated-service verification.', target: 'lead.crmshow_leadclusterid' },
  assignLead: { availability: 'blocked', reason: 'Generated services do not support the polymorphic owner lookup required here.', target: 'lead.ownerid' },
  createAppointment: { availability: 'blocked', reason: 'The regarding relationship is polymorphic.', target: 'appointment.regardingobjectid' },
  createTask: { availability: 'blocked', reason: 'The regarding relationship is polymorphic.', target: 'task.regardingobjectid' },
  savePersonalView: { availability: 'blocked', reason: 'No governed roaming preference contract exists.', target: 'user preference' },
} as const satisfies Record<CockpitWriteCommand['type'], CommandCapability>;