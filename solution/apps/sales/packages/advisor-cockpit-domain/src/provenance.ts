export type ProvenanceKind = 'crm' | 'external' | 'unmapped';

export const provenancePresentation = {
  crm: { tone: 'normal' },
  external: { tone: 'grey' },
  unmapped: { tone: 'yellow' },
} as const satisfies Record<ProvenanceKind, { tone: 'normal' | 'grey' | 'yellow' }>;