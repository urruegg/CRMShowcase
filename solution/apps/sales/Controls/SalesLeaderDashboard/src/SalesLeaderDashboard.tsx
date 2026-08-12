import * as React from 'react';
import { makeStyles, shorthands, Tab, TabList } from '@fluentui/react-components';
import type { SelectTabEventHandler } from '@fluentui/react-components';
import {
  Area,
  Bar,
  BarChart,
  CartesianGrid,
  Cell,
  ComposedChart,
  Legend,
  Line,
  PolarAngleAxis,
  PolarGrid,
  PolarRadiusAxis,
  Radar,
  RadarChart,
  ReferenceLine,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from 'recharts';
import { fuehrungssicht } from './presentation';
import {
  buildBenchmark,
  buildForecast,
  buildFunnel,
  buildProductBars,
  buildRadar,
  buildRegionBars,
  buildScorecard,
} from './selectors';
import { font, palette, provenance, provenanceLabel } from './tokens';
import type { DashboardData } from './types';

const useStyles = makeStyles({
  root: { fontFamily: font, color: palette.n190, backgroundColor: palette.n10, minHeight: '100vh' },
  header: { backgroundColor: palette.n0, ...shorthands.borderBottom('1px', 'solid', palette.n30), ...shorthands.padding('16px', '24px') },
  breadcrumb: { fontSize: '12px', color: palette.n130, marginBottom: '6px' },
  crumbSep: { ...shorthands.margin('0', '6px'), color: palette.n90 },
  title: { fontSize: '20px', fontWeight: 700, ...shorthands.margin('0') },
  sub: { fontSize: '13px', color: palette.n130, marginTop: '4px' },
  content: { ...shorthands.padding('16px', '24px', '40px') },
  band: {
    backgroundColor: palette.n0,
    ...shorthands.border('1px', 'solid', palette.n30),
    ...shorthands.borderLeft('4px', 'solid', palette.brand),
    ...shorthands.borderRadius('8px'),
    ...shorthands.padding('12px', '14px'),
    marginBottom: '16px',
  },
  bandEyebrow: { fontSize: '11px', fontWeight: 700, letterSpacing: '0.04em', textTransform: 'uppercase', color: palette.brand, marginBottom: '4px' },
  bandText: { fontSize: '13px', color: palette.n160, lineHeight: '1.5' },
  kpiGrid: { display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', ...shorthands.gap('12px'), marginBottom: '16px' },
  kpi: {
    backgroundColor: palette.n0,
    ...shorthands.border('1px', 'solid', palette.n30),
    ...shorthands.borderRadius('8px'),
    ...shorthands.padding('14px'),
    display: 'flex',
    flexDirection: 'column',
    ...shorthands.gap('2px'),
  },
  kpiValueRow: { display: 'flex', alignItems: 'baseline', ...shorthands.gap('8px') },
  kpiValue: { fontSize: '26px', fontWeight: 700, lineHeight: '1.1' },
  kpiDelta: { fontSize: '12px', fontWeight: 700 },
  deltaUp: { color: palette.green },
  deltaDown: { color: palette.red },
  deltaFlat: { color: palette.n130 },
  kpiLabel: { fontSize: '13px', fontWeight: 600, color: palette.n190 },
  kpiMeta: { fontSize: '11px', color: palette.n130 },
  tabs: { marginBottom: '12px' },
  grid2: { display: 'grid', gridTemplateColumns: 'repeat(2, minmax(0, 1fr))', ...shorthands.gap('16px') },
  card: {
    backgroundColor: palette.n0,
    ...shorthands.border('1px', 'solid', palette.n30),
    ...shorthands.borderRadius('8px'),
    ...shorthands.padding('14px', '16px'),
    marginBottom: '16px',
  },
  cardHead: { marginBottom: '10px' },
  eyebrow: { fontSize: '11px', fontWeight: 700, letterSpacing: '0.04em', textTransform: 'uppercase', color: palette.n90, display: 'flex', alignItems: 'center', ...shorthands.gap('6px') },
  cardTitle: { fontSize: '15px', fontWeight: 700, marginTop: '2px' },
  cardSub: { fontSize: '12px', color: palette.n130, marginTop: '4px', lineHeight: '1.4' },
  chart: { width: '100%', height: '220px' },
  funnel: { display: 'flex', flexDirection: 'column', ...shorthands.gap('8px') },
  fnRow: { display: 'flex', alignItems: 'center', ...shorthands.gap('12px') },
  fnLabel: { width: '96px', fontSize: '12px', color: palette.n130, textAlign: 'right', flexShrink: 0 },
  fnTrack: { flexGrow: 1, backgroundColor: palette.n20, ...shorthands.borderRadius('5px'), height: '26px', position: 'relative', ...shorthands.overflow('hidden') },
  fnFill: { height: '100%', ...shorthands.borderRadius('5px'), display: 'flex', alignItems: 'center', ...shorthands.padding('0', '8px'), color: palette.n0, fontSize: '12px', fontWeight: 700 },
  fnConv: { width: '112px', fontSize: '12px', flexShrink: 0 },
  fnBottleneck: { color: palette.amber, fontWeight: 700 },
  table: { width: '100%', borderCollapse: 'collapse', fontSize: '13px' },
  th: { textAlign: 'left', fontSize: '11px', fontWeight: 700, letterSpacing: '0.03em', textTransform: 'uppercase', color: palette.n130, ...shorthands.borderBottom('1px', 'solid', palette.n30), ...shorthands.padding('8px', '10px') },
  thNum: { textAlign: 'right' },
  td: { ...shorthands.borderBottom('1px', 'solid', palette.n20), ...shorthands.padding('8px', '10px') },
  tdNum: { textAlign: 'right', fontVariantNumeric: 'tabular-nums' },
  rowCurrent: { backgroundColor: palette.n10, fontWeight: 700 },
  gaName: { fontWeight: 600 },
  legend: {
    display: 'flex',
    alignItems: 'center',
    flexWrap: 'wrap',
    ...shorthands.gap('6px', '14px'),
    marginTop: '8px',
    paddingTop: '12px',
    ...shorthands.borderTop('1px', 'solid', palette.n30),
    fontSize: '12px',
    color: palette.n130,
  },
  legendLabel: { fontWeight: 700, color: palette.n160 },
  legendItem: { display: 'inline-flex', alignItems: 'center', ...shorthands.gap('6px') },
  legendSwatch: { width: '12px', height: '12px', ...shorthands.borderRadius('3px'), ...shorthands.border('1px', 'solid', palette.n30), display: 'inline-block' },
  legendMuted: { color: palette.n90 },
  srOnly: { position: 'absolute', width: '1px', height: '1px', ...shorthands.padding('0'), ...shorthands.margin('-1px'), ...shorthands.overflow('hidden'), clip: 'rect(0,0,0,0)', whiteSpace: 'nowrap', ...shorthands.borderWidth('0') },
});

type TabValue = 'overview' | 'products' | 'funnel' | 'benchmark';

function benchTone(kind: 'ziel' | 'conversion' | 'backlog' | 'automation', v: number): string {
  switch (kind) {
    case 'ziel':
      return v >= 100 ? palette.green : v >= 95 ? palette.amber : palette.red;
    case 'conversion':
      return v >= 30 ? palette.green : v >= 25 ? palette.amber : palette.red;
    case 'backlog':
      return v <= 10 ? palette.green : v <= 20 ? palette.amber : palette.red;
    case 'automation':
      return v >= 75 ? palette.green : v >= 65 ? palette.amber : palette.red;
    default:
      return palette.n130;
  }
}

export function SalesLeaderDashboard({ data }: { data: DashboardData }) {
  const s = useStyles();
  const [tab, setTab] = React.useState<TabValue>('overview');

  const scorecard = React.useMemo(() => buildScorecard(data.measures), [data.measures]);
  const forecast = React.useMemo(() => buildForecast(data.measures), [data.measures]);
  const products = React.useMemo(() => buildProductBars(data.measures), [data.measures]);
  const regions = React.useMemo(() => buildRegionBars(data.measures), [data.measures]);
  const radar = React.useMemo(() => buildRadar(), []);
  const funnel = React.useMemo(() => buildFunnel(), []);
  const benchmark = React.useMemo(() => buildBenchmark(), []);

  const onTab: SelectTabEventHandler = (_e, d) => setTab(d.value as TabValue);
  const maxFunnel = Math.max(...funnel.map((f) => f.volume));

  return (
    <div className={s.root}>
      <header className={s.header}>
        <div className={s.breadcrumb}>
          Contoso CRM<span className={s.crumbSep}>›</span>Analytics<span className={s.crumbSep}>›</span>Sales Steering Cockpit
        </div>
        <h1 className={s.title}>Führungsdashboard / Sales Steering</h1>
        <div className={s.sub}>
          GA-Führung {data.profile.generalAgency} · {data.profile.scopeLabel}
        </div>
      </header>

      <div className={s.content}>
        <section className={s.band} aria-label="Führungssicht">
          <div className={s.bandEyebrow}>Strategisches Lagebild · GA Bern-Mittelland</div>
          <div className={s.bandText}>{fuehrungssicht}</div>
        </section>

        <div className={s.kpiGrid}>
          {scorecard.map((k) => (
            <div key={k.key} className={s.kpi} style={{ backgroundColor: provenance.dbx }} title={provenanceLabel.dbx}>
              <div className={s.kpiValueRow}>
                <span className={s.kpiValue}>{k.valueText}</span>
                <span
                  className={`${s.kpiDelta} ${k.deltaDir === 'up' ? s.deltaUp : k.deltaDir === 'down' ? s.deltaDown : s.deltaFlat}`}
                >
                  {k.delta}
                </span>
              </div>
              <div className={s.kpiLabel}>{k.label}</div>
              <div className={s.kpiMeta}>
                {k.targetText} · {k.hint}
              </div>
            </div>
          ))}
        </div>

        <TabList className={s.tabs} selectedValue={tab} onTabSelect={onTab}>
          <Tab value="overview">Übersicht</Tab>
          <Tab value="products">Produkte & Regionen</Tab>
          <Tab value="funnel">Funnel</Tab>
          <Tab value="benchmark">GA-Vergleich</Tab>
        </TabList>

        {tab === 'overview' && (
          <div className={s.grid2}>
            <section className={s.card} style={{ backgroundColor: provenance.dbx }} title={provenanceLabel.dbx}>
              <div className={s.cardHead}>
                <div className={s.eyebrow}>Forecast</div>
                <div className={s.cardTitle}>Neugeschäft & Prämienvolumen über Zeit</div>
                <div className={s.cardSub}>CHF Tsd · Ist Jan–Apr, KI-Forecast Mai*/Jun* mit Konfidenzband · Ziellinie 430</div>
              </div>
              <div className={s.chart}>
                <ResponsiveContainer width="100%" height="100%">
                  <ComposedChart data={forecast} margin={{ top: 8, right: 12, bottom: 4, left: -8 }}>
                    <CartesianGrid stroke={palette.n30} vertical={false} />
                    <XAxis dataKey="month" tick={{ fontSize: 11, fill: palette.n130 }} axisLine={{ stroke: palette.n30 }} tickLine={false} />
                    <YAxis domain={[280, 460]} tick={{ fontSize: 11, fill: palette.n130 }} axisLine={false} tickLine={false} width={40} />
                    <Tooltip formatter={(v: number) => `${v} CHF Tsd`} />
                    <Area type="monotone" dataKey="high" stroke="none" fill={palette.brand} fillOpacity={0.12} connectNulls={false} legendType="none" isAnimationActive={false} />
                    <Area type="monotone" dataKey="low" stroke="none" fill={provenance.dbx} fillOpacity={1} connectNulls={false} legendType="none" isAnimationActive={false} />
                    <ReferenceLine y={430} stroke={palette.teal} strokeDasharray="4 4" label={{ value: 'Ziel 430', position: 'insideTopRight', fontSize: 11, fill: palette.teal }} />
                    <Line type="monotone" dataKey="actual" name="Ist" stroke={palette.brand} strokeWidth={2.5} dot={{ r: 3 }} connectNulls={false} isAnimationActive={false} />
                    <Line type="monotone" dataKey="forecast" name="KI-Forecast" stroke={palette.brand} strokeWidth={2.5} strokeDasharray="5 4" dot={{ r: 3 }} connectNulls={false} isAnimationActive={false} />
                    <Legend wrapperStyle={{ fontSize: 11 }} />
                  </ComposedChart>
                </ResponsiveContainer>
              </div>
            </section>

            <section className={s.card} style={{ backgroundColor: provenance.unmapped }} title={provenanceLabel.unmapped}>
              <div className={s.cardHead}>
                <div className={s.eyebrow}>Balanced</div>
                <div className={s.cardTitle}>Strategischer Scorecard</div>
                <div className={s.cardSub}>Ausgewogene Steuerung über 5 strategische Dimensionen (0–100)</div>
              </div>
              <div className={s.chart}>
                <ResponsiveContainer width="100%" height="100%">
                  <RadarChart data={radar} outerRadius="72%">
                    <PolarGrid stroke={palette.n30} />
                    <PolarAngleAxis dataKey="dim" tick={{ fontSize: 11, fill: palette.n130 }} />
                    <PolarRadiusAxis domain={[0, 100]} tick={{ fontSize: 10, fill: palette.n90 }} axisLine={false} />
                    <Radar name="Score" dataKey="value" stroke={palette.brand} fill={palette.brand} fillOpacity={0.18} isAnimationActive={false} />
                  </RadarChart>
                </ResponsiveContainer>
              </div>
            </section>
          </div>
        )}

        {tab === 'products' && (
          <div className={s.grid2}>
            <section className={s.card} style={{ backgroundColor: provenance.dbx }} title={provenanceLabel.dbx}>
              <div className={s.cardHead}>
                <div className={s.eyebrow}>Produkte</div>
                <div className={s.cardTitle}>Neugeschäft je Produktlinie</div>
                <div className={s.cardSub}>CHF Tsd · Motorfahrzeug KMU grösster Werttreiber</div>
              </div>
              <div className={s.chart}>
                <ResponsiveContainer width="100%" height="100%">
                  <BarChart data={products} margin={{ top: 8, right: 12, bottom: 4, left: -8 }}>
                    <CartesianGrid stroke={palette.n30} vertical={false} />
                    <XAxis dataKey="label" tick={{ fontSize: 11, fill: palette.n130 }} axisLine={{ stroke: palette.n30 }} tickLine={false} interval={0} />
                    <YAxis tick={{ fontSize: 11, fill: palette.n130 }} axisLine={false} tickLine={false} width={40} />
                    <Tooltip formatter={(v: number) => `${v} CHF Tsd`} />
                    <Bar dataKey="value" radius={[5, 5, 0, 0]} isAnimationActive={false}>
                      {products.map((p) => (
                        <Cell key={p.label} fill={p.highlight ? palette.brand : palette.teal} />
                      ))}
                    </Bar>
                  </BarChart>
                </ResponsiveContainer>
              </div>
            </section>

            <section className={s.card} style={{ backgroundColor: provenance.dbx }} title={provenanceLabel.dbx}>
              <div className={s.cardHead}>
                <div className={s.eyebrow}>Markt / Region</div>
                <div className={s.cardTitle}>Wachstum je Markt / Region (YoY)</div>
                <div className={s.cardSub}>% · Mittelland Wachstumsführer</div>
              </div>
              <div className={s.chart}>
                <ResponsiveContainer width="100%" height="100%">
                  <BarChart data={regions} margin={{ top: 8, right: 12, bottom: 4, left: -8 }}>
                    <CartesianGrid stroke={palette.n30} vertical={false} />
                    <XAxis dataKey="label" tick={{ fontSize: 11, fill: palette.n130 }} axisLine={{ stroke: palette.n30 }} tickLine={false} interval={0} />
                    <YAxis tick={{ fontSize: 11, fill: palette.n130 }} axisLine={false} tickLine={false} width={40} unit="%" />
                    <Tooltip formatter={(v: number) => `${v} %`} />
                    <Bar dataKey="value" radius={[5, 5, 0, 0]} isAnimationActive={false}>
                      {regions.map((r) => (
                        <Cell key={r.label} fill={r.highlight ? palette.brand : palette.teal} />
                      ))}
                    </Bar>
                  </BarChart>
                </ResponsiveContainer>
              </div>
            </section>
          </div>
        )}

        {tab === 'funnel' && (
          <section className={s.card} style={{ backgroundColor: provenance.unmapped }} title={provenanceLabel.unmapped}>
            <div className={s.cardHead}>
              <div className={s.eyebrow}>Funnel-Engpass</div>
              <div className={s.cardTitle}>Volumen & Conversion je Phase</div>
              <div className={s.cardSub}>Grösster Drop zwischen Kontakt → Qualifiziert. Verletzte Time-to-First-Contact bei Team Bern.</div>
            </div>
            <div className={s.funnel}>
              {funnel.map((f) => (
                <div key={f.stage} className={s.fnRow}>
                  <div className={s.fnLabel}>{f.stage}</div>
                  <div className={s.fnTrack}>
                    <div
                      className={s.fnFill}
                      style={{ width: `${Math.round((f.volume / maxFunnel) * 100)}%`, backgroundColor: f.bottleneck ? palette.amber : palette.brand }}
                    >
                      {f.volume}
                    </div>
                  </div>
                  <div className={s.fnConv}>
                    {f.conversion === null ? (
                      '—'
                    ) : (
                      <span className={f.bottleneck ? s.fnBottleneck : undefined}>
                        {f.conversion}% {f.bottleneck ? '· Engpass' : ''}
                      </span>
                    )}
                  </div>
                </div>
              ))}
            </div>
          </section>
        )}

        {tab === 'benchmark' && (
          <section className={s.card} style={{ backgroundColor: provenance.unmapped }} title={provenanceLabel.unmapped}>
            <div className={s.cardHead}>
              <div className={s.eyebrow}>GA-Steuerungsmatrix</div>
              <div className={s.cardTitle}>GA-Benchmark & Best-Practice</div>
              <div className={s.cardSub}>Top-Performer Luzern (104 % Ziel, tiefster Backlog). Biel-Seeland kritisch (89 %, Backlog 29).</div>
            </div>
            <table className={s.table}>
              <thead>
                <tr>
                  <th className={s.th}>Generalagentur</th>
                  <th className={`${s.th} ${s.thNum}`}>Ziel</th>
                  <th className={`${s.th} ${s.thNum}`}>Conversion</th>
                  <th className={`${s.th} ${s.thNum}`}>Backlog</th>
                  <th className={`${s.th} ${s.thNum}`}>Automation</th>
                </tr>
              </thead>
              <tbody>
                {benchmark.map((g) => (
                  <tr key={g.ga} className={g.isCurrent ? s.rowCurrent : undefined}>
                    <td className={`${s.td} ${s.gaName}`}>
                      {g.ga}
                      {g.isCurrent ? ' (Ihre GA)' : ''}
                    </td>
                    <td className={`${s.td} ${s.tdNum}`} style={{ color: benchTone('ziel', g.ziel) }}>{g.ziel}%</td>
                    <td className={`${s.td} ${s.tdNum}`} style={{ color: benchTone('conversion', g.conversion) }}>{g.conversion}%</td>
                    <td className={`${s.td} ${s.tdNum}`} style={{ color: benchTone('backlog', g.backlog) }}>{g.backlog}</td>
                    <td className={`${s.td} ${s.tdNum}`} style={{ color: benchTone('automation', g.automation) }}>{g.automation}%</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </section>
        )}

        <div className={s.legend} role="note">
          <span className={s.legendLabel}>Datenquelle:</span>
          <span className={s.legendItem} title={provenanceLabel.dbx}>
            <span className={s.legendSwatch} style={{ backgroundColor: provenance.dbx }} />
            {provenanceLabel.dbx} — Measure-Projektion (crmshow_measuresnapshot)
          </span>
          <span className={s.legendItem} title={provenanceLabel.unmapped}>
            <span className={s.legendSwatch} style={{ backgroundColor: provenance.unmapped }} />
            {provenanceLabel.unmapped} — illustrativ, noch nicht im Measure-Kontrakt
          </span>
          <span className={s.legendMuted}>read-only · ADR-0018/0026</span>
        </div>
      </div>
    </div>
  );
}
