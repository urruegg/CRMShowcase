// Design tokens adopted from the corporate brand kit (docs/brandkit/tokens/design-tokens.json):
// deep-red accent (accent-only, never status), warm neutrals, muted semantic colours.
// Values are ported under neutral names (no customer name/logo) per the public-repo
// no-customer-branding guardrail; fully adopting a customer-derived CD is ADR-worthy.
// The licensed brand webfont is unverified, so `font` uses the kit's safe Arial fallback.

export const palette = {
  brand: '#B80010',      // brand-60 — accessible accent for buttons/links/accents
  brandDark: '#920000',  // brand-40 — hover / emphasis
  // Neutral ramp n0..n190 (warm-tinted, from the brand kit)
  n0: '#ffffff',
  n10: '#fbfaf8',        // paper1 — app background
  n20: '#f6f5f2',        // paper2 — subtle fills
  n30: '#e4e1db',        // hairline / card borders
  n60: '#bcbbb9',        // neutral-76 — input borders
  n90: '#91918f',        // neutral-60 — muted
  n130: '#605e5e',       // neutral-40 — secondary text
  n160: '#323030',       // neutral-20
  n190: '#171717',       // ink — primary text
  green: '#0e6c41',      // success
  amber: '#8a6100',      // warning
  red: '#a4262c',        // danger
  purple: '#6b2fa0',
  teal: '#2b5b8c',       // info
} as const;

// Semantic badge colors (fill + text) from the brand kit tint pairs.
export const badge = {
  blue: { bg: '#f0f5fa', fg: '#2b5b8c' },
  green: { bg: '#eff7f1', fg: '#0e6c41' },
  amber: { bg: '#fdf6e3', fg: '#8a6100' },
  red: { bg: '#fdf3f4', fg: '#a4262c' },
  grey: { bg: '#f6f5f2', fg: '#605e5e' },
} as const;

import type { ProvenanceKind } from '@crmshow/advisor-cockpit-domain';

// Data-source provenance tints: CRM = standard (no tint), external/projected =
// light grey, and not-yet-mapped = light yellow.
export const provenance = {
  crm: 'transparent',
  external: '#eeedea',
  unmapped: '#fcf4d6',
} as const satisfies Record<ProvenanceKind, string>;

export type { ProvenanceKind } from '@crmshow/advisor-cockpit-domain';

export const provenanceLabel: Record<ProvenanceKind, string> = {
  crm: 'CRM (Dataverse)',
  external: 'Databricks (Mock)',
  unmapped: 'Noch nicht gemappt',
};

export const font =
  "Arial, 'Helvetica Neue', Helvetica, 'Segoe UI', system-ui, sans-serif";

// Priority dot colors
export const priority = {
  high: palette.red,
  med: palette.amber,
  low: palette.green,
} as const;

// NBA card category accent (left border) mirroring .cop-card variants.
export const nbaAccent: Record<string, string> = {
  Dringend: palette.red,
  Risiko: palette.amber,
  Chance: palette.green,
  Retention: palette.purple,
  Insight: palette.brand,
};
