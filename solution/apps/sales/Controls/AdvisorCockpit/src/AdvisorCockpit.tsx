import * as React from 'react';
import { makeStyles, shorthands, Button } from '@fluentui/react-components';
import type { CockpitData, LeadRecord, NbaRecord } from './types';
import { badge, font, nbaAccent, palette, priority } from './tokens';
import {
  appointments,
  buildAccountIndex,
  groupLeads,
  headerKpis,
  openTasks,
  sortedNba,
} from './selectors';

const useStyles = makeStyles({
  root: {
    fontFamily: font,
    backgroundColor: palette.n10,
    color: palette.n190,
    minHeight: '100vh',
    fontSize: '13px',
  },
  header: {
    background: `linear-gradient(135deg, ${palette.brand}, ${palette.brandDark})`,
    color: palette.n0,
    ...shorthands.padding('18px', '24px'),
  },
  title: { fontSize: '22px', fontWeight: 600, ...shorthands.margin(0) },
  subtitle: { fontSize: '13px', opacity: 0.9, marginTop: '2px' },
  kpiRow: { display: 'flex', ...shorthands.gap('12px'), marginTop: '14px', flexWrap: 'wrap' },
  kpi: {
    backgroundColor: 'rgba(255,255,255,0.12)',
    ...shorthands.borderRadius('8px'),
    ...shorthands.padding('10px', '14px'),
    minWidth: '150px',
  },
  kpiLabel: { fontSize: '11px', textTransform: 'uppercase', opacity: 0.85, letterSpacing: '.03em' },
  kpiValue: { fontSize: '26px', fontWeight: 700, lineHeight: 1.1 },
  kpiSub: { fontSize: '11px', opacity: 0.85, marginTop: '2px' },
  body: {
    display: 'grid',
    gridTemplateColumns: 'minmax(0, 1fr) 360px',
    ...shorthands.gap('16px'),
    ...shorthands.padding('16px', '24px'),
    alignItems: 'start',
  },
  col: { display: 'flex', flexDirection: 'column', ...shorthands.gap('16px'), minWidth: 0 },
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
  copilot: { display: 'flex', flexDirection: 'column', ...shorthands.gap('12px') },
  copHead: {
    display: 'flex',
    alignItems: 'center',
    ...shorthands.gap('10px'),
    ...shorthands.padding('12px', '14px'),
    backgroundColor: palette.n0,
    ...shorthands.border('1px', 'solid', palette.n30),
    ...shorthands.borderRadius('10px'),
  },
  spark: {
    width: '32px',
    height: '32px',
    ...shorthands.borderRadius('8px'),
    background: `linear-gradient(135deg, ${palette.purple}, ${palette.brand})`,
    color: palette.n0,
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    fontWeight: 700,
  },
  copCard: {
    backgroundColor: palette.n0,
    ...shorthands.border('1px', 'solid', palette.n30),
    ...shorthands.borderRadius('10px'),
    ...shorthands.borderLeft('4px', 'solid', palette.brand),
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
  disclosure: {
    display: 'inline-flex',
    alignItems: 'center',
    ...shorthands.gap('4px'),
    marginTop: '8px',
    fontSize: '10px',
    color: palette.purple,
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
  const accounts = React.useMemo(() => buildAccountIndex(data.accountsContacts), [data]);
  const kpis = React.useMemo(() => headerKpis(data), [data]);
  const leadGroups = React.useMemo(() => groupLeads(data.leads), [data]);
  const nba = React.useMemo(() => sortedNba(data.nba), [data]);
  const appts = React.useMemo(() => appointments(data.activities), [data]);
  const tasks = React.useMemo(() => openTasks(data.activities), [data]);
  const accountName = (key: string) => accounts.get(key) ?? key;

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

  return (
    <div className={s.root}>
      <header className={s.header}>
        <h1 className={s.title}>Guten Morgen, {advisorName}</h1>
        <div className={s.subtitle}>GA Bern-Mittelland · {new Date().toLocaleDateString('de-CH', { weekday: 'long', day: 'numeric', month: 'long' })}</div>
        <div className={s.kpiRow}>
          <div className={s.kpi}>
            <div className={s.kpiLabel}>Termine heute</div>
            <div className={s.kpiValue}>{kpis.appointmentsToday}</div>
            <div className={s.kpiSub}>nächster {appts[0]?.start?.slice(11, 16) ?? '—'}</div>
          </div>
          <div className={s.kpi}>
            <div className={s.kpiLabel}>Offene Aufgaben</div>
            <div className={s.kpiValue}>{kpis.openTasks}</div>
            <div className={s.kpiSub}>{kpis.overdue} überfällig</div>
          </div>
          <div className={s.kpi}>
            <div className={s.kpiLabel}>Top-Lead Score</div>
            <div className={s.kpiValue}>{kpis.topLeadScore}</div>
            <div className={s.kpiSub}>Haushalt Brunner · Hausrat</div>
          </div>
        </div>
      </header>

      <div className={s.body}>
        <div className={s.col}>
          <section className={s.card}>
            <div className={s.cardHead}>Leads &amp; Priorität (KI)</div>
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
                      <td className={s.td}>
                        {t.status === 'Überfällig' ? <Badge kind="red">Überfällig</Badge> : t.due}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </section>
        </div>

        <aside className={s.copilot}>
          <div className={s.copHead}>
            <div className={s.spark} aria-hidden>✦</div>
            <div>
              <div style={{ fontWeight: 600 }}>Contoso Copilot</div>
              <div className={s.muted}>Next Best Actions, priorisiert für heute</div>
            </div>
          </div>
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
        </aside>
      </div>
    </div>
  );
}
