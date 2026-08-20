import { describe, expect, it } from 'vitest';
import { writeCapabilities } from './write-capabilities';

describe('writeCapabilities', () => {
  it('documents every visible write and never labels a blocked action supported', () => {
    expect(Object.keys(writeCapabilities).sort()).toEqual([
      'acceptNba',
      'assignLead',
      'bundleLeads',
      'call',
      'createAppointment',
      'createTask',
      'dismissNba',
      'editNba',
      'savePersonalView',
      'snoozeNba',
      'splitLeads',
      'updateLeadQueueStatus',
    ]);
    expect(writeCapabilities.assignLead.availability).toBe('blocked');
    expect(writeCapabilities.createTask.availability).toBe('blocked');
    expect(writeCapabilities.dismissNba.availability).toBe('partial');
  });
});