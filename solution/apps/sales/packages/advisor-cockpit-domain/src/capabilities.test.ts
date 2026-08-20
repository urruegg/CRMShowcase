import { describe, expect, it } from 'vitest';
import { isCapabilityExecutable, type CapabilityAvailability } from './capabilities';

describe('isCapabilityExecutable', () => {
  it.each<[CapabilityAvailability, boolean]>([
    ['supported', true],
    ['partial', true],
    ['blocked', false],
    ['unverified', false],
  ])('maps %s to %s', (availability, expected) => {
    expect(isCapabilityExecutable({ availability, reason: 'Test', target: 'test' })).toBe(expected);
  });
});