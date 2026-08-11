import * as React from 'react';
import { makeStyles, shorthands, Button, Tab, TabList } from '@fluentui/react-components';
import type { CockpitData, ClaimRecord, LeadRecord, NbaRecord } from './types';
import { badge, font, nbaAccent, palette, priority } from './tokens';
import { appointments, buildAccountIndex, groupLeads, openTasks, sortedNba } from './selectors';
import {
  arbeitsvorratSummary,
  disclaimer,
  empfohlenerFokus,
  focusHero,
  kpiCards,
  progressCards,
  tagesplan,
} from './kpis';

const useStyles = makeStyles({
  root: {
    fontFamily: font,
    backgroundColor: palette.n10,
    color: palette.n190,
    minHeight: '100vh',
    fontSize: '13px',
  },
  header: {
    backgroundColor: palette.n0,
    ...shorthands.padding('18px', '24px', '16px'),
    ...shorthands.borderBottom('1px', 'solid', palette.n30),
  },
  breadcrumb: { fontSize: '11px', color: palette.n130, marginBottom: '8px' },
  title: { fontSize: '24px', fontWeight: 600, ...shorthands.margin(0), color: palette.n190 },
  subtitle: { fontSize: '13px', color: palette.n130, marginTop: '4px' },
  content: {
    display: 'flex',
    flexDirection: 'column',
    ...shorthands.gap('18px'),
    ...shorthands.padding('18px', '24px'),
  },
  hero: {
    display: 'grid',
    gridTemplateColumns: 'minmax(0, 1fr) auto',
    ...shorthands.gap('24px'),
    alignItems: 'center',
    backgroundColor: palette.n0,
    ...shorthands.border('1px', 'solid', palette.n30),
    ...shorthands.borderRadius('12px'),
    ...shorthands.padding('18px', '22px'),
  },
  heroEyebrow: {
    fontSize: '11px',
    fontWeight: 700,
    textTransform: 'uppercase',
    letterSpacing: '.06em',
    color: palette.brand,
  },
  heroHeadline: { fontSize: '18px', fontWeight: 600, ...shorthands.margin('6px', 0, '8px', 0) },
  heroBody: { fontSize: '13px', color: palette.n130, lineHeight: 1.55, ...shorthands.margin(0), maxWidth: '640px' },
  heroStats: { display: 'flex', ...shorthands.gap('26px'), alignItems: 'flex-start' },
  heroStatValue: { fontSize: '26px', fontWeight: 700, color: palette.brand, lineHeight: 1.1 },
  heroStatLabel: { fontSize: '11px', color: palette.n130, maxWidth: '120px', marginTop: '2px' },
  sectionHead: {
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'baseline',
    ...shorthands.gap('12px'),
    flexWrap: 'wrap',
    marginBottom: '8px',
  },
  sectionTitle: { fontSize: '15px', fontWeight: 600 },
  sectionSummary: { fontSize: '12px', color: palette.n130 },
  kpiGrid: {
    display: 'grid',
    gridTemplateColumns: 'repeat(auto-fit, minmax(155px, 1fr))',
    ...shorthands.gap('12px'),
  },
  progressGrid: {
    display: 'grid',
    gridTemplateColumns: 'repeat(auto-fit, minmax(215px, 1fr))',
    ...shorthands.gap('12px'),
    marginTop: '12px',
  },
  tile: {
    backgroundColor: palette.n0,
    ...shorthands.border('1px', 'solid', palette.n30),
    ...shorthands.borderRadius('10px'),
    ...shorthands.padding('12px', '14px'),
  },
  tileLabel: {
    fontSize: '11px',
    textTransform: 'uppercase',
    letterSpacing: '.02em',
    color: palette.n130,
    fontWeight: 600,
  },
  tileValue: { fontSize: '26px', fontWeight: 700, lineHeight: 1.1, marginTop: '4px' },
  tileSub: { fontSize: '11px', color: palette.n130, marginTop: '3px' },
  tileSubWarn: { color: palette.amber, fontWeight: 600 },
  barRow: { display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginTop: '4px' },
  barValue: { fontSize: '18px', fontWeight: 700 },
  barPct: { fontSize: '12px', fontWeight: 600, color: palette.n130 },
  barTrack: {
    height: '8px',
    ...shorthands.borderRadius('4px'),
    backgroundColor: palette.n20,
    marginTop: '8px',
    ...shorthands.overflow('hidden'),
  },
  barFill: { height: '100%', ...shorthands.borderRadius('4px') },
  disclaimerLine: { fontSize: '11px', color: palette.n90, fontStyle: 'italic', marginTop: '12px' },
  tabPanel: { marginTop: '14px' },
  card: {
    backgroundColor: palette.n0,
    ...shorthands.border('1px', 'solid', palette.n30),
    ...shorthands.borderRadius('10px'),
    ...shorthands.overflow('hidden'),
  },
  cardHead: {
    display: 'flex',
    alignItems: 'center',
    ...shorthands.gap('8px'),
    ...shorthands.padding('12px', '14px'),
    ...shorthands.borderBottom('1px', 'solid', palette.n30),
    fontWeight: 600,
    fontSize: '14px',
  },
  cardBody: { ...shorthands.padding('4px', '0') },
  table: { width: '100%', borderCollapse: 'collapse', fontSize: '13px' },
  th: {
    textAlign: 'left',
    ...shorthands.padding('8px', '14px'),
    color: palette.n130,
    fontWeight: 600,
    fontSize: '11px',
    textTransform: 'uppercase',
    letterSpacing: '.02em',
    ...shorthands.borderBottom('1px', 'solid', palette.n30),
  },
  td: {
    ...shorthands.padding('9px', '14px'),
    ...shorthands.borderBottom('1px', 'solid', palette.n20),
    verticalAlign: 'middle',
  },
  clusterRow: { backgroundColor: '#eff6fc', cursor: 'default' },
  childRow: { backgroundColor: palette.n10 },
  childIndent: { paddingLeft: '30px' },
  link: { color: palette.brand, textDecoration: 'none', fontWeight: 600, cursor: 'pointer' },
  muted: { color: palette.n130, fontSize: '11px' },
  dot: { display: 'inline-block', width: '8px', height: '8px', ...shorthands.borderRadius('50%'), marginRight: '6px' },
  score: { fontWeight: 700 },
  badge: {
    display: 'inline-block',
    ...shorthands.padding('2px', '8px'),
    ...shorthands.borderRadius('10px'),
    fontSize: '11px',
    fontWeight: 600,
  },
  agendaItem: {
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'center',
    ...shorthands.padding('10px', '14px'),
    ...shorthands.borderBottom('1px', 'solid', palette.n20),
  },
  time: { color: palette.brand, fontWeight: 600, fontSize: '12px' },
  // Tagesplan (KI)
  tpHead: { fontSize: '16px', fontWeight: 600 },
  tpBody: { fontSize: '13px', color: palette.n130, ...shorthands.margin('4px', 0, '14px', 0), maxWidth: '720px' },
  tpStats: { display: 'flex', ...shorthands.gap('28px'), marginBottom: '16px' },
  tpStatValue: { fontSize: '22px', fontWeight: 700 },
  tpStatLabel: { fontSize: '11px', color: palette.n130 },
  // Empfohlener Fokus
  fokus: {
    backgroundColor: palette.n0,
    ...shorthands.border('1px', 'solid', palette.n30),
    ...shorthands.borderLeft('4px', 'solid', palette.brand),
    ...shorthands.borderRadius('12px'),
    ...shorthands.padding('16px', '18px'),
  },
  fokusHeadRow: { display: 'flex', justifyContent: 'space-between', alignItems: 'center', ...shorthands.gap('8px'), flexWrap: 'wrap' },
  fokusTitleWrap: { display: 'flex', alignItems: 'center', ...shorthands.gap('10px'), flexWrap: 'wrap' },
  fokusTitle: { fontSize: '16px', fontWeight: 600 },
  fokusWhy: { marginTop: '12px', fontSize: '13px', lineHeight: 1.55 },
  fokusWhyLabel: { fontWeight: 600 },
  provBox: {
    backgroundColor: palette.n10,
    ...shorthands.border('1px', 'solid', palette.n30),
    ...shorthands.borderRadius('8px'),
    ...shorthands.padding('10px', '12px'),
    marginTop: '12px',
  },
  provTitle: {
    fontSize: '10px',
    fontWeight: 700,
    textTransform: 'uppercase',
    letterSpacing: '.05em',
    color: palette.n130,
    marginBottom: '6px',
  },
  provItem: { display: 'flex', ...shorthands.gap('8px'), fontSize: '12px', marginBottom: '4px' },
  provLabel: { fontWeight: 600, minWidth: '110px' },
  fokusFields: {
    display: 'grid',
    gridTemplateColumns: 'repeat(auto-fit, minmax(190px, 1fr))',
    ...shorthands.gap('10px'),
    marginTop: '14px',
  },
  fieldK: { fontSize: '11px', color: palette.n130, textTransform: 'uppercase', letterSpacing: '.02em' },
  fieldV: { fontSize: '13px', fontWeight: 600, marginTop: '2px' },
  fokusActions: { display: 'flex', ...shorthands.gap('8px'), flexWrap: 'wrap', marginTop: '16px' },
  disclosure: {
    display: 'inline-flex',
    alignItems: 'center',
    ...shorthands.gap('4px'),
    marginTop: '12px',
    fontSize: '11px',
    color: palette.purple,
    fontWeight: 600,
  },
  // Copilot tab
  copGrid: {
    display: 'grid',
    gridTemplateColumns: 'repeat(auto-fit, minmax(290px, 1fr))',
    ...shorthands.gap('12px'),
  },
  copCard: {
    backgroundColor: palette.n0,
    ...shorthands.border('1px', 'solid', palette.n30),
    ...shorthands.borderLeft('4px', 'solid', palette.brand),
    ...shorthands.borderRadius('10px'),
    ...shorthands.padding('12px', '14px'),
  },
  copTag: {
    fontSize: '10px',
    fontWeight: 700,
    textTransform: 'uppercase',
    letterSpacing: '.04em',
    color: palette.n130,
  },
  copTitle: { fontSize: '14px', fontWeight: 600, ...shorthands.margin('4px', 0, '4px', 0) },
  copText: { fontSize: '12px', color: palette.n130, lineHeight: 1.5 },
});

function Badge({ kind, children }: { kind: keyof typeof badge; children: React.ReactNode }) {
  const s = useStyles();
  const c = badge[kind];
  return <span className={s.badge} style={{ backgroundColor: c.bg, color: c.fg }}>{children}</span>;
}

function priorityKind(p: LeadRecord['priority']): keyof typeof priority {
  return p === 'Hoch' ? 'high' : p === 'Mittel' ? 'med' : 'low';
}

function statusBadgeKind(status: string): keyof typeof badge {
  if (/Überfällig|Risiko/i.test(status)) return 'red';
  if (/Primär|Neu/i.test(status)) return 'blue';
  if (/Gebündelt|Offen/i.test(status)) return 'green';
  if (/Verknüpfen|Arbeit/i.test(status)) return 'amber';
  return 'grey';
}

export interface AdvisorCockpitProps {
  data: CockpitData;
  advisorName?: string;
}

export function AdvisorCockpit({ data, advisorName = 'Rahel Moser' }: AdvisorCockpitProps): JSX.Element {
  const s = useStyles();
  const [tab, setTab] = React.useState<string>('tagesplan');
  const accounts = React.useMemo(() => buildAccountIndex(data.accountsContacts), [data]);
  const leadGroups = React.useMemo(() => groupLeads(data.leads), [data]);
  const nba = React.useMemo(() => sortedNba(data.nba), [data]);
  const appts = React.useMemo(() => appointments(data.activities), [data]);
  const tasks = React.useMemo(() => openTasks(data.activities), [data]);
  const accountName = (key: string) => accounts.get(key) ?? key;
  const today = new Date().toLocaleDateString('de-CH', { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' });

  const renderLead = (lead: LeadRecord, child: boolean) => (
    <tr key={lead.key} className={child ? s.childRow : undefined}>
      <td className={s.td}>
        <span className={s.dot} style={{ backgroundColor: priority[priorityKind(lead.priority)] }} />
        <span className={s.score} style={{ color: lead.score >= 90 ? palette.green : palette.n190 }}>{lead.score}</span>
      </td>
      <td className={`${s.td} ${child ? s.childIndent : ''}`}><span className={s.link}>{lead.topic}</span></td>
      <td className={s.td}><span className={s.link}>{accountName(lead.accountKey)}</span></td>
      <td className={s.td}>{lead.channel}</td>
      <td className={s.td}>{lead.priority}</td>
      <td className={s.td}>{lead.sla}</td>
      <td className={s.td}><Badge kind={statusBadgeKind(lead.status)}>{lead.status}</Badge></td>
    </tr>
  );

  const caseTypeKind = (t: ClaimRecord['caseType']): keyof typeof badge => (t === 'Schaden' ? 'amber' : 'blue');

  return (
    <div className={s.root}>
      <header className={s.header}>
        <div className={s.breadcrumb}>Contoso CRM › Advisor Cockpit</div>
        <h1 className={s.title}>Guten Morgen, {advisorName}</h1>
        <div className={s.subtitle}>Versicherungsberaterin · Generalagentur Bern-Mittelland · {today}</div>
      </header>

      <div className={s.content}>
        <section className={s.hero}>
          <div>
            <div className={s.heroEyebrow}>{focusHero.eyebrow}</div>
            <h2 className={s.heroHeadline}>{focusHero.headline}</h2>
            <p className={s.heroBody}>{focusHero.body}</p>
          </div>
          <div className={s.heroStats}>
            {focusHero.stats.map((st) => (
              <div key={st.label}>
                <div className={s.heroStatValue}>{st.value}</div>
                <div className={s.heroStatLabel}>{st.label}</div>
              </div>
            ))}
          </div>
        </section>

        <section>
          <div className={s.sectionHead}>
            <div className={s.sectionTitle}>Arbeitsvorrat &amp; persönliche Ziele</div>
            <div className={s.sectionSummary}>{arbeitsvorratSummary}</div>
          </div>
          <div className={s.kpiGrid}>
            {kpiCards.map((c) => (
              <div key={c.label} className={s.tile}>
                <div className={s.tileLabel}>{c.label}</div>
                <div className={s.tileValue}>{c.value}</div>
                <div className={`${s.tileSub} ${c.warn ? s.tileSubWarn : ''}`}>{c.sub}</div>
              </div>
            ))}
          </div>
          <div className={s.progressGrid}>
            {progressCards.map((c) => (
              <div key={c.label} className={s.tile}>
                <div className={s.tileLabel}>{c.label}</div>
                <div className={s.barRow}>
                  <span className={s.barValue}>{c.current}</span>
                  <span className={s.barPct}>{c.percent}%</span>
                </div>
                <div className={s.barTrack}>
                  <div className={s.barFill} style={{ width: `${c.percent}%`, backgroundColor: c.color === 'amber' ? palette.amber : palette.green }} />
                </div>
                <div className={s.tileSub}>{c.sub}</div>
              </div>
            ))}
          </div>
          <div className={s.disclaimerLine}>{disclaimer}</div>
        </section>

        <div>
          <TabList selectedValue={tab} onTabSelect={(_, d) => setTab(d.value as string)}>
            <Tab value="tagesplan">Tagesplan (KI)</Tab>
            <Tab value="leads">Meine Leads</Tab>
            <Tab value="termine">Termine &amp; Aufgaben</Tab>
            <Tab value="faelle">Offene Fälle</Tab>
            <Tab value="copilot">Copilot</Tab>
          </TabList>

          <div className={s.tabPanel}>
            {tab === 'tagesplan' && (
              <div>
                <div className={s.tpHead}>{tagesplan.title}</div>
                <p className={s.tpBody}>{tagesplan.body}</p>
                <div className={s.tpStats}>
                  <div>
                    <div className={s.tpStatValue}>{tagesplan.plannedActivities}</div>
                    <div className={s.tpStatLabel}>Geplante Aktivitäten</div>
                  </div>
                  <div>
                    <div className={s.tpStatValue}>{tagesplan.estimatedConversion}</div>
                    <div className={s.tpStatLabel}>erwartete Abschlüsse (Prognose)</div>
                  </div>
                </div>

                <div className={s.fokus}>
                  <div className={s.fokusHeadRow}>
                    <div className={s.fokusTitleWrap}>
                      <span className={s.fokusTitle}>{empfohlenerFokus.title}</span>
                      <Badge kind="blue">{empfohlenerFokus.suggestionBadge}</Badge>
                    </div>
                    <Badge kind="green">{empfohlenerFokus.statusBadge}</Badge>
                  </div>
                  <div className={s.fokusWhy}>
                    <span className={s.fokusWhyLabel}>Warum jetzt: </span>
                    {empfohlenerFokus.whyNow}
                  </div>
                  <div className={s.provBox}>
                    <div className={s.provTitle}>Woher stammt das?</div>
                    {empfohlenerFokus.provenance.map((p) => (
                      <div key={p.label} className={s.provItem}>
                        <span className={s.provLabel}>{p.label}</span>
                        <span className={s.muted}>{p.detail}</span>
                      </div>
                    ))}
                  </div>
                  <div className={s.fokusFields}>
                    {empfohlenerFokus.fields.map((f) => (
                      <div key={f.k}>
                        <div className={s.fieldK}>{f.k}</div>
                        <div className={s.fieldV}>{f.v}</div>
                      </div>
                    ))}
                  </div>
                  <div className={s.fokusActions}>
                    {empfohlenerFokus.actions.map((a, i) => (
                      <Button key={a} size="small" appearance={i === 0 ? 'primary' : 'secondary'} style={i === 0 ? { backgroundColor: palette.brand } : undefined}>
                        {a}
                      </Button>
                    ))}
                  </div>
                  <div className={s.disclosure} title="KI-unterstützt — im CRM-Kontext verankert">✦ {empfohlenerFokus.disclosure}</div>
                </div>
              </div>
            )}

            {tab === 'leads' && (
              <section className={s.card}>
                <div className={s.cardHead}>Meine Leads · Priorität (KI)</div>
                <div className={s.cardBody}>
                  <table className={s.table}>
                    <thead>
                      <tr>
                        <th className={s.th}>Priorität</th>
                        <th className={s.th}>Lead</th>
                        <th className={s.th}>Kunde</th>
                        <th className={s.th}>Kanal</th>
                        <th className={s.th}>Urgency</th>
                        <th className={s.th}>SLA</th>
                        <th className={s.th}>Status</th>
                      </tr>
                    </thead>
                    <tbody>
                      {leadGroups.map((group) =>
                        group.isCluster ? (
                          <React.Fragment key={group.clusterName ?? ''}>
                            <tr className={s.clusterRow}>
                              <td className={s.td} colSpan={7}>
                                <span className={s.link}>{group.clusterName}</span>{' '}
                                <Badge kind="amber">Auto-Gruppe · {group.leads.length}</Badge>
                                <div className={s.muted}>Redundanz vermeiden: ein Gespräch statt {group.leads.length} Kontakte</div>
                              </td>
                            </tr>
                            {group.leads.map((l) => renderLead(l, true))}
                          </React.Fragment>
                        ) : (
                          renderLead(group.leads[0], false)
                        ),
                      )}
                    </tbody>
                  </table>
                </div>
              </section>
            )}

            {tab === 'termine' && (
              <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
                <section className={s.card}>
                  <div className={s.cardHead}>Termine heute</div>
                  <div className={s.cardBody}>
                    {appts.map((a) => (
                      <div key={a.key} className={s.agendaItem}>
                        <div>
                          <div className={s.time}>{a.start?.slice(11, 16)} · {a.location}</div>
                          <div>{a.subject}</div>
                        </div>
                        <Button size="small" appearance="secondary">Vorbereiten</Button>
                      </div>
                    ))}
                  </div>
                </section>
                <section className={s.card}>
                  <div className={s.cardHead}>Offene Aufgaben</div>
                  <div className={s.cardBody}>
                    <table className={s.table}>
                      <thead>
                        <tr>
                          <th className={s.th}>Aufgabe</th>
                          <th className={s.th}>Bezug</th>
                          <th className={s.th}>Fällig</th>
                        </tr>
                      </thead>
                      <tbody>
                        {tasks.map((t) => (
                          <tr key={t.key}>
                            <td className={s.td}>{t.subject}</td>
                            <td className={s.td}><span className={s.link}>{accountName(t.accountKey)}</span></td>
                            <td className={s.td}>{t.status === 'Überfällig' ? <Badge kind="red">Überfällig</Badge> : t.due}</td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                </section>
              </div>
            )}

            {tab === 'faelle' && (
              <section className={s.card}>
                <div className={s.cardHead}>Anliegen &amp; Schäden</div>
                <div className={s.cardBody}>
                  <table className={s.table}>
                    <thead>
                      <tr>
                        <th className={s.th}>Fall-ID</th>
                        <th className={s.th}>Typ</th>
                        <th className={s.th}>Kunde</th>
                        <th className={s.th}>Betreff</th>
                        <th className={s.th}>Kanal</th>
                        <th className={s.th}>Status</th>
                        <th className={s.th}>SLA</th>
                      </tr>
                    </thead>
                    <tbody>
                      {data.claims.map((c) => (
                        <tr key={c.key}>
                          <td className={s.td}><span className={s.link}>{c.externalId}</span></td>
                          <td className={s.td}><Badge kind={caseTypeKind(c.caseType)}>{c.caseType}</Badge></td>
                          <td className={s.td}><span className={s.link}>{accountName(c.accountKey)}</span></td>
                          <td className={s.td}>{c.title}</td>
                          <td className={s.td}>{c.channel}</td>
                          <td className={s.td}><Badge kind={statusBadgeKind(c.status)}>{c.status}</Badge></td>
                          <td className={s.td}>{c.slaHours ? `${c.slaHours}h` : '—'}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </section>
            )}

            {tab === 'copilot' && (
              <div>
                <div className={s.sectionHead}>
                  <div className={s.sectionTitle}>Contoso Copilot · Next Best Actions</div>
                  <div className={s.sectionSummary}>Vorschläge · Sie entscheiden — priorisiert auf Basis Ihrer Leads, Termine und Fälle für heute</div>
                </div>
                <div className={s.copGrid}>
                  {nba.map((card: NbaRecord) => (
                    <div key={card.key} className={s.copCard} style={{ borderLeftColor: nbaAccent[card.category] ?? palette.brand }}>
                      <div className={s.copTag} style={{ color: nbaAccent[card.category] }}>{card.category}</div>
                      <div className={s.copTitle}>{card.title}</div>
                      <div className={s.copText}>{card.rationale}</div>
                      <div className={s.disclosure} title="KI-unterstützt — im CRM-Kontext verankert">✦ {card.disclosure}</div>
                      <div style={{ marginTop: '10px' }}>
                        <Button size="small" appearance="primary" style={{ backgroundColor: palette.brand }}>
                          {card.channel === 'Anruf' ? 'Anrufen' : card.channel === 'Termin' ? 'Termin öffnen' : 'Öffnen'}
                        </Button>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
