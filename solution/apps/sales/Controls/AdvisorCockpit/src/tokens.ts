// Palette ported verbatim from the ground-truth web resource
// (intake/mobiliar/source/WebResources/cr7e8_sharedpage01advisorcockpit) so the
// control matches pixel-for-pixel. Fluent v9 components provide structure + a11y;
// these tokens drive the exact colors/spacing.

export const palette = {
  brand: '#0078d4',
  brandDark: '#005a9e',
  // Neutral ramp n0..n190
  n0: '#ffffff',
  n10: '#faf9f8',
  n20: '#f3f2f1',
  n30: '#edebe9',
  n60: '#c8c6c4',
  n90: '#a19f9d',
  n130: '#605e5c',
  n160: '#323130',
  n190: '#201f1e',
  green: '#107c10',
  amber: '#9c5700',
  red: '#a4262c',
  purple: '#6b2fa0',
  teal: '#038387',
} as const;

// Semantic badge colors (fill + text) mirroring the mockup .badge classes.
export const badge = {
  blue: { bg: '#deecf9', fg: '#005a9e' },
  green: { bg: '#dff6dd', fg: '#107c10' },
  amber: { bg: '#fff4ce', fg: '#9c5700' },
  red: { bg: '#fde7e9', fg: '#a4262c' },
  grey: { bg: '#f3f2f1', fg: '#605e5c' },
} as const;

export const font =
  "'Segoe UI', -apple-system, BlinkMacSystemFont, system-ui, sans-serif";

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
