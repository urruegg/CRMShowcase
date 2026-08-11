import * as React from 'react';
import {
  makeStyles,
  shorthands,
  Button,
  Tab,
  TabList,
  Checkbox,
  Dialog,
  DialogSurface,
  DialogBody,
  DialogTitle,
  DialogContent,
  DialogActions,
} from '@fluentui/react-components';
import type { CockpitData, ClaimRecord, LeadRecord, NbaRecord } from './types';
import { badge, font, nbaAccent, palette, priority } from './tokens';
import { appointments, boardBuckets, buildAccountIndex, filterLeads, groupLeads, openTasks, sortLeads, sortedNba } from './selectors';
import type { LeadSortKey } from './selectors';
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
  // Meine Leads — view switch + filters + board/cockpit
  viewTools: { display: 'flex', justifyContent: 'space-between', alignItems: 'center', ...shorthands.gap('12px'), flexWrap: 'wrap', marginBottom: '12px' },
  viewSwitch: { display: 'inline-flex', ...shorthands.border('1px', 'solid', palette.n30), ...shorthands.borderRadius('8px'), ...shorthands.overflow('hidden') },
  viewBtn: {
    ...shorthands.padding('6px', '14px'),
    backgroundColor: palette.n0,
    ...shorthands.borderWidth('0'),
    ...shorthands.borderRight('1px', 'solid', palette.n30),
    cursor: 'pointer',
    fontSize: '12px',
    fontWeight: 600,
    color: palette.n130,
    fontFamily: font,
  },
  viewBtnActive: { backgroundColor: palette.brand, color: palette.n0 },
  vtActions: { display: 'flex', ...shorthands.gap('8px'), flexWrap: 'wrap' },
  filters: { display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(175px, 1fr))', ...shorthands.gap('10px'), marginBottom: '12px' },
  filterField: { display: 'flex', flexDirection: 'column', ...shorthands.gap('4px') },
  filterLabel: { fontSize: '11px', color: palette.n130, fontWeight: 600 },
  filterInput: {
    ...shorthands.padding('6px', '8px'),
    ...shorthands.border('1px', 'solid', palette.n60),
    ...shorthands.borderRadius('6px'),
    fontSize: '13px',
    fontFamily: font,
    backgroundColor: palette.n0,
  },
  boardGrid: { display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(240px, 1fr))', ...shorthands.gap('12px'), alignItems: 'start' },
  boardGroup: { ...shorthands.border('1px', 'solid', palette.brand), ...shorthands.borderRadius('8px'), backgroundColor: '#eff6fc', ...shorthands.padding('8px') },
  boardGroupHead: { display: 'flex', alignItems: 'center', ...shorthands.gap('7px'), fontWeight: 700, fontSize: '13px', marginBottom: '8px', flexWrap: 'wrap' },
  boardGroupBody: { display: 'flex', flexDirection: 'column', ...shorthands.gap('8px') },
  boardCard: { backgroundColor: palette.n0, ...shorthands.border('1px', 'solid', palette.n30), ...shorthands.borderRadius('6px'), ...shorthands.padding('8px', '10px') },
  boardCardTitle: { fontWeight: 600, fontSize: '13px' },
  cockpitGrid: { display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(280px, 1fr))', ...shorthands.gap('12px'), alignItems: 'start' },
  clusterCard: { backgroundColor: palette.n0, ...shorthands.border('1px', 'solid', palette.n30), ...shorthands.borderRadius('10px'), ...shorthands.padding('12px', '14px') },
  clusterHead: { display: 'flex', alignItems: 'center', ...shorthands.gap('8px'), fontWeight: 600, marginBottom: '8px', flexWrap: 'wrap' },
  miniLead: { display: 'flex', alignItems: 'center', ...shorthands.gap('8px'), ...shorthands.padding('6px', 0), ...shorthands.borderTop('1px', 'solid', palette.n20) },
  miniScore: { marginLeft: 'auto', fontWeight: 700 },
  emptyNote: { ...shorthands.padding('16px'), color: palette.n130, fontSize: '13px' },
  tdCheck: { ...shorthands.padding('7px', '4px', '7px', '10px'), width: '34px', verticalAlign: 'top' },
  thCheck: { ...shorthands.padding('9px', '4px', '9px', '10px'), width: '34px', textAlign: 'left', ...shorthands.borderBottom('1px', 'solid', palette.n30) },
  selBar: {
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'space-between',
    ...shorthands.gap('12px'),
    flexWrap: 'wrap',
    ...shorthands.padding('8px', '12px'),
    marginBottom: '10px',
    backgroundColor: '#eff6fc',
    ...shorthands.border('1px', 'solid', palette.brand),
    ...shorthands.borderRadius('8px'),
  },
  selInfo: { fontWeight: 600, fontSize: '13px', color: palette.brandDark },
  selActions: { display: 'flex', alignItems: 'center', ...shorthands.gap('8px'), flexWrap: 'wrap' },
  demoNote: {
    ...shorthands.padding('8px', '12px'),
    marginBottom: '10px',
    backgroundColor: '#fff8e6',
    ...shorthands.border('1px', 'solid', palette.amber),
    ...shorthands.borderRadius('6px'),
    fontSize: '12px',
    color: palette.n160,
  },
  modalLead: { fontSize: '13px', color: palette.n130, ...shorthands.margin(0, 0, '12px') },
  modalList: { display: 'flex', flexDirection: 'column', ...shorthands.gap('2px'), marginBottom: '12px' },
  modalItem: { display: 'flex', alignItems: 'center', ...shorthands.gap('8px'), ...shorthands.padding('6px', 0), ...shorthands.borderTop('1px', 'solid', palette.n20) },
  sortBtn: { backgroundColor: 'transparent', ...shorthands.borderWidth('0'), ...shorthands.padding('0'), cursor: 'pointer', fontFamily: font, fontSize: '11px', fontWeight: 600, color: palette.n130, display: 'inline-flex', alignItems: 'center', whiteSpace: 'nowrap' },
  chevron: { backgroundColor: 'transparent', ...shorthands.borderWidth('0'), cursor: 'pointer', fontSize: '12px', color: palette.n130, ...shorthands.padding('0', '6px', '0', '0'), fontFamily: font },
  connector: { color: palette.n60, marginRight: '2px' },
  boardToolbar: { display: 'flex', alignItems: 'center', ...shorthands.gap('8px'), flexWrap: 'wrap', marginBottom: '10px' },
  boardHint: { fontSize: '11px', color: palette.n130 },
  boardColumns: { display: 'grid', gridTemplateColumns: 'repeat(3, minmax(0, 1fr))', ...shorthands.gap('12px'), alignItems: 'start' },
  boardCol: { backgroundColor: palette.n10, ...shorthands.border('1px', 'solid', palette.n30), ...shorthands.borderRadius('8px'), ...shorthands.padding('10px') },
  boardColHead: { display: 'flex', alignItems: 'center', ...shorthands.gap('6px'), fontWeight: 700, fontSize: '11px', letterSpacing: '0.04em', textTransform: 'uppercase', color: palette.n160 },
  boardColCount: { backgroundColor: palette.n30, color: palette.n160, ...shorthands.borderRadius('10px'), ...shorthands.padding('0', '7px'), fontSize: '11px' },
  boardColHint: { fontSize: '11px', color: palette.n130, marginTop: '2px', marginBottom: '10px' },
  boardColBody: { display: 'flex', flexDirection: 'column', ...shorthands.gap('8px') },
  boardCardTop: { display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '4px' },
  boardCardSel: { boxShadow: `0 0 0 2px ${palette.brand}` },
  boardClusterCard: { ...shorthands.border('1px', 'solid', palette.brand), ...shorthands.borderRadius('8px'), backgroundColor: '#eff6fc', ...shorthands.padding('8px'), display: 'flex', flexDirection: 'column', ...shorthands.gap('8px') },
  boardClusterHead: { display: 'flex', alignItems: 'center', ...shorthands.gap('7px'), fontWeight: 700, fontSize: '13px', flexWrap: 'wrap' },
  splitBtn: { marginLeft: 'auto' },
  boardEmpty: { color: palette.n60, fontSize: '12px', ...shorthands.padding('8px', '4px') },
});

function Badge({ kind, children }: { kind: keyof typeof badge; children: React.ReactNode }) {
  const s = useStyles();
  const c = badge[kind];
  return <span className={s.badge} style={{ backgroundColor: c.bg, color: c.fg }}>{children}</span>;
}

function priorityKind(p: LeadRecord['priority']): keyof typeof priority {
  return p === 'Hoch' ? 'high' : p === 'Mittel' ? 'med' : 'low';
}

const CHANNEL_OPTIONS = ['Alle Kanäle', 'Online', 'Telefon', 'Termin', 'Kampagne'];
const STATUS_OPTIONS = ['Alle Status', 'Neu', 'In Arbeit', 'Qualifiziert', 'Gebündelt', 'Geplant', 'Geschlossen'];
const SOURCE_OPTIONS = ['Alle Quellen', 'Online-Offerte', 'Vertragsablauf', 'Advisory Appointment', 'Vorsorge 25'];
const OWNER_OPTIONS = ['Rahel Moser', 'Thomas Vogt', 'Sina Keller', 'Pool (Round-Robin)', 'Makler-Desk'];

function statusBadgeKind(status: string): keyof typeof badge {
  if (/Überfällig|Risiko/i.test(status)) return 'red';
  if (/Primär|Neu/i.test(status)) return 'blue';
  if (/Gebündelt|Offen/i.test(status)) return 'green';
  if (/Verknüpfen|Arbeit/i.test(status)) return 'amber';
  return 'grey';
}

export interface AdvisorCockpitProps {
  data: CockpitData;
}

export function AdvisorCockpit({ data }: AdvisorCockpitProps): JSX.Element {
  const s = useStyles();
  const [tab, setTab] = React.useState<string>('tagesplan');
  const [leadView, setLeadView] = React.useState<'list' | 'board' | 'cockpit'>('list');
  const [fCustomer, setFCustomer] = React.useState('');
  const [fChannel, setFChannel] = React.useState('Alle Kanäle');
  const [fStatus, setFStatus] = React.useState('Alle Status');
  const [fSource, setFSource] = React.useState('Alle Quellen');
  const [selected, setSelected] = React.useState<Set<string>>(() => new Set());
  const [assignTo, setAssignTo] = React.useState('');
  const [assignNote, setAssignNote] = React.useState<string | null>(null);
  const [bundle, setBundle] = React.useState<{ title: string; leads: LeadRecord[] } | null>(null);
  const [sortKey, setSortKey] = React.useState<LeadSortKey>('score');
  const [sortDir, setSortDir] = React.useState<'asc' | 'desc'>('desc');
  const [collapsed, setCollapsed] = React.useState<Set<string>>(() => new Set());
  const [splitClusters, setSplitClusters] = React.useState<Set<string>>(() => new Set());
  const [autoGroup, setAutoGroup] = React.useState(true);
  const accounts = React.useMemo(() => buildAccountIndex(data.accountsContacts), [data]);
  const filteredLeads = React.useMemo(
    () => filterLeads(data.leads, { customer: fCustomer, channel: fChannel, status: fStatus, source: fSource }, (k) => accounts.get(k) ?? k),
    [data, fCustomer, fChannel, fStatus, fSource, accounts],
  );
  const sortedLeads = React.useMemo(
    () => sortLeads(filteredLeads, sortKey, sortDir, (k) => accounts.get(k) ?? k),
    [filteredLeads, sortKey, sortDir, accounts],
  );
  const displayLeads = React.useMemo(
    () => sortedLeads.map((l) => (l.leadCluster && (!autoGroup || splitClusters.has(l.leadCluster)) ? { ...l, leadCluster: null } : l)),
    [sortedLeads, autoGroup, splitClusters],
  );
  const leadGroups = React.useMemo(() => groupLeads(displayLeads), [displayLeads]);
  const boards = React.useMemo(() => boardBuckets(leadGroups), [leadGroups]);
  const nba = React.useMemo(() => sortedNba(data.nba), [data]);
  const appts = React.useMemo(() => appointments(data.activities), [data]);
  const tasks = React.useMemo(() => openTasks(data.activities), [data]);
  const accountName = (key: string) => accounts.get(key) ?? key;
  const today = new Date().toLocaleDateString('de-CH', { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' });

  const visibleKeys = React.useMemo(() => filteredLeads.map((l) => l.key), [filteredLeads]);
  const allSelected = visibleKeys.length > 0 && visibleKeys.every((k) => selected.has(k));
  const selectedLeads = React.useMemo(() => filteredLeads.filter((l) => selected.has(l.key)), [filteredLeads, selected]);
  const toggleLead = (key: string) =>
    setSelected((prev) => {
      const next = new Set(prev);
      if (next.has(key)) next.delete(key);
      else next.add(key);
      return next;
    });
  const toggleAll = () => setSelected((prev) => (visibleKeys.every((k) => prev.has(k)) ? new Set<string>() : new Set(visibleKeys)));
  const clearSelection = () => {
    setSelected(new Set());
    setAssignNote(null);
  };
  const applyAssignment = () => {
    if (!assignTo || selected.size === 0) return;
    const n = selected.size;
    setAssignNote(`${n} Lead${n > 1 ? 's' : ''} an ${assignTo} zugewiesen · Demo — Schreibzugriff über die Aktionsschicht (DEV-gated).`);
    setSelected(new Set());
    setAssignTo('');
  };
  const toggleGroup = (leads: LeadRecord[]) =>
    setSelected((prev) => {
      const next = new Set(prev);
      const allIn = leads.every((l) => next.has(l.key));
      for (const l of leads) {
        if (allIn) next.delete(l.key);
        else next.add(l.key);
      }
      return next;
    });
  const toggleSort = (key: LeadSortKey) => {
    if (sortKey === key) setSortDir((d) => (d === 'asc' ? 'desc' : 'asc'));
    else {
      setSortKey(key);
      setSortDir(key === 'score' || key === 'priority' ? 'desc' : 'asc');
    }
  };
  const ariaSort = (key: LeadSortKey): 'ascending' | 'descending' | 'none' =>
    sortKey === key ? (sortDir === 'asc' ? 'ascending' : 'descending') : 'none';
  const sortArrow = (key: LeadSortKey) => (sortKey === key ? (sortDir === 'asc' ? ' ▲' : ' ▼') : '');
  const toggleCollapse = (name: string) =>
    setCollapsed((prev) => {
      const next = new Set(prev);
      if (next.has(name)) next.delete(name);
      else next.add(name);
      return next;
    });
  const splitCluster = (name: string) => {
    setSplitClusters((prev) => new Set(prev).add(name));
    setAssignNote(`Gruppe „${name}" aufgelöst · Leads einzeln bearbeitbar (Demo — Schreibzugriff über die Aktionsschicht, DEV-gated).`);
  };

  const renderLead = (lead: LeadRecord, child: boolean) => (
    <tr key={lead.key} className={child ? s.childRow : undefined}>
      <td className={s.tdCheck}>
        <Checkbox checked={selected.has(lead.key)} onChange={() => toggleLead(lead.key)} aria-label={`Lead ${lead.topic} auswählen`} />
      </td>
      <td className={s.td}>
        <span className={s.dot} style={{ backgroundColor: priority[priorityKind(lead.priority)] }} />
        <span className={s.score} style={{ color: lead.score >= 90 ? palette.green : palette.n190 }}>{lead.score}</span>
      </td>
      <td className={`${s.td} ${child ? s.childIndent : ''}`}>
        {child && <span className={s.connector} aria-hidden="true">↳ </span>}
        <span className={s.link}>{lead.topic}</span>
      </td>
      <td className={s.td}><span className={s.link}>{accountName(lead.accountKey)}</span></td>
      <td className={s.td}>{lead.channel}</td>
      <td className={s.td}>{lead.priority}</td>
      <td className={s.td}>{lead.sla}</td>
      <td className={s.td}><Badge kind={statusBadgeKind(lead.status)}>{lead.status}</Badge></td>
    </tr>
  );

  const renderBoardCard = (l: LeadRecord) => (
    <div key={l.key} className={`${s.boardCard} ${selected.has(l.key) ? s.boardCardSel : ''}`}>
      <div className={s.boardCardTop}>
        <Checkbox checked={selected.has(l.key)} onChange={() => toggleLead(l.key)} label="auswählen" aria-label={`Lead ${l.topic} auswählen`} />
        <span className={s.score} style={{ color: l.score >= 90 ? palette.green : palette.n190 }}>{l.score}</span>
      </div>
      <div className={s.boardCardTitle}>{l.topic}</div>
      <div className={s.muted}>{l.source} · {l.status}</div>
    </div>
  );

  const caseTypeKind = (t: ClaimRecord['caseType']): keyof typeof badge => (t === 'Schaden' ? 'amber' : 'blue');

  return (
    <div className={s.root}>
      <header className={s.header}>
        <div className={s.breadcrumb}>Contoso CRM › Advisor Cockpit</div>
        <h1 className={s.title}>Guten Morgen, {data.advisor.fullName}</h1>
        <div className={s.subtitle}>{data.advisor.role} · {data.advisor.generalAgency} · {today}</div>
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
              <div>
                <div className={s.viewTools}>
                  <div className={s.viewSwitch} role="group" aria-label="Lead-Ansicht">
                    {(['list', 'board', 'cockpit'] as const).map((v) => (
                      <button
                        key={v}
                        type="button"
                        className={`${s.viewBtn} ${leadView === v ? s.viewBtnActive : ''}`}
                        aria-pressed={leadView === v}
                        onClick={() => setLeadView(v)}
                      >
                        {v === 'list' ? 'Liste' : v === 'board' ? 'Board' : 'Cockpit'}
                      </button>
                    ))}
                  </div>
                  <div className={s.vtActions}>
                    <Button size="small" appearance="secondary">Top 10 nach Priorität</Button>
                    <Button size="small" appearance="secondary">Ansicht speichern</Button>
                  </div>
                </div>

                <div className={s.filters}>
                  <div className={s.filterField}>
                    <label className={s.filterLabel} htmlFor="f-customer">Kunde / Konto</label>
                    <input id="f-customer" className={s.filterInput} placeholder="z.B. Haushalt Brunner" value={fCustomer} onChange={(e) => setFCustomer(e.target.value)} />
                  </div>
                  <div className={s.filterField}>
                    <label className={s.filterLabel} htmlFor="f-channel">Kanal</label>
                    <select id="f-channel" className={s.filterInput} value={fChannel} onChange={(e) => setFChannel(e.target.value)}>
                      {CHANNEL_OPTIONS.map((o) => <option key={o}>{o}</option>)}
                    </select>
                  </div>
                  <div className={s.filterField}>
                    <label className={s.filterLabel} htmlFor="f-status">Status</label>
                    <select id="f-status" className={s.filterInput} value={fStatus} onChange={(e) => setFStatus(e.target.value)}>
                      {STATUS_OPTIONS.map((o) => <option key={o}>{o}</option>)}
                    </select>
                  </div>
                  <div className={s.filterField}>
                    <label className={s.filterLabel} htmlFor="f-source">Kampagne / Quelle</label>
                    <select id="f-source" className={s.filterInput} value={fSource} onChange={(e) => setFSource(e.target.value)}>
                      {SOURCE_OPTIONS.map((o) => <option key={o}>{o}</option>)}
                    </select>
                  </div>
                </div>

                {selected.size > 0 && (
                  <div className={s.selBar}>
                    <div className={s.selInfo}>{selected.size} Lead{selected.size > 1 ? 's' : ''} ausgewählt</div>
                    <div className={s.selActions}>
                      <label className={s.filterLabel} htmlFor="assign-to">Zuweisen an</label>
                      <select id="assign-to" className={s.filterInput} value={assignTo} onChange={(e) => setAssignTo(e.target.value)}>
                        <option value="">Bearbeiter/in wählen …</option>
                        {OWNER_OPTIONS.map((o) => <option key={o}>{o}</option>)}
                      </select>
                      <Button size="small" appearance="primary" style={{ backgroundColor: palette.brand }} disabled={!assignTo} onClick={applyAssignment}>Zuweisen</Button>
                      <Button size="small" appearance="secondary" disabled={selected.size < 2} onClick={() => setBundle({ title: 'Ausgewählte Leads', leads: selectedLeads })}>Bündeln</Button>
                      <Button size="small" appearance="transparent" onClick={clearSelection}>Auswahl aufheben</Button>
                    </div>
                  </div>
                )}
                {assignNote && <div className={s.demoNote}>{assignNote}</div>}

                {leadGroups.length === 0 && <div className={s.emptyNote}>Keine Leads für die aktuelle Filterung.</div>}

                {leadView === 'list' && leadGroups.length > 0 && (
                  <section className={s.card}>
                    <div className={s.cardBody}>
                      <table className={s.table}>
                        <thead>
                          <tr>
                            <th className={s.thCheck}>
                              <Checkbox checked={allSelected} onChange={toggleAll} aria-label="Alle Leads auswählen" />
                            </th>
                            <th className={s.th} aria-sort={ariaSort('score')}><button type="button" className={s.sortBtn} onClick={() => toggleSort('score')}>Priorität{sortArrow('score')}</button></th>
                            <th className={s.th} aria-sort={ariaSort('topic')}><button type="button" className={s.sortBtn} onClick={() => toggleSort('topic')}>Lead{sortArrow('topic')}</button></th>
                            <th className={s.th} aria-sort={ariaSort('customer')}><button type="button" className={s.sortBtn} onClick={() => toggleSort('customer')}>Kunde{sortArrow('customer')}</button></th>
                            <th className={s.th} aria-sort={ariaSort('channel')}><button type="button" className={s.sortBtn} onClick={() => toggleSort('channel')}>Kanal{sortArrow('channel')}</button></th>
                            <th className={s.th} aria-sort={ariaSort('priority')}><button type="button" className={s.sortBtn} onClick={() => toggleSort('priority')}>Urgency{sortArrow('priority')}</button></th>
                            <th className={s.th} aria-sort={ariaSort('sla')}><button type="button" className={s.sortBtn} onClick={() => toggleSort('sla')}>SLA{sortArrow('sla')}</button></th>
                            <th className={s.th} aria-sort={ariaSort('status')}><button type="button" className={s.sortBtn} onClick={() => toggleSort('status')}>Status{sortArrow('status')}</button></th>
                          </tr>
                        </thead>
                        <tbody>
                          {leadGroups.map((group) =>
                            group.isCluster ? (
                              <React.Fragment key={group.clusterName ?? ''}>
                                <tr className={s.clusterRow}>
                                  <td className={s.tdCheck}>
                                    <Checkbox
                                      checked={group.leads.every((l) => selected.has(l.key))}
                                      onChange={() => toggleGroup(group.leads)}
                                      aria-label={`Gruppe ${group.clusterName} auswählen`}
                                    />
                                  </td>
                                  <td className={s.td} colSpan={7}>
                                    <button
                                      type="button"
                                      className={s.chevron}
                                      aria-label={collapsed.has(group.clusterName ?? '') ? 'Gruppe ausklappen' : 'Gruppe einklappen'}
                                      aria-expanded={!collapsed.has(group.clusterName ?? '')}
                                      onClick={() => toggleCollapse(group.clusterName ?? '')}
                                    >
                                      {collapsed.has(group.clusterName ?? '') ? '▸' : '▾'}
                                    </button>
                                    <span className={s.link}>{group.clusterName}</span>{' '}
                                    <Badge kind="amber">Auto-Gruppe · {group.leads.length}</Badge>
                                    <div className={s.muted}>Redundanz vermeiden: ein Gespräch statt {group.leads.length} Kontakte</div>
                                  </td>
                                </tr>
                                {!collapsed.has(group.clusterName ?? '') && group.leads.map((l) => renderLead(l, true))}
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

                {leadView === 'board' && leadGroups.length > 0 && (
                  <div>
                    <div className={s.boardToolbar}>
                      <Button
                        size="small"
                        appearance={autoGroup ? 'primary' : 'secondary'}
                        style={autoGroup ? { backgroundColor: palette.brand } : undefined}
                        onClick={() => setAutoGroup((v) => !v)}
                      >
                        Auto-Gruppierung: {autoGroup ? 'An' : 'Aus'}
                      </Button>
                      <Button
                        size="small"
                        appearance="secondary"
                        disabled={selected.size < 2}
                        onClick={() => setBundle({ title: 'Ausgewählte Leads', leads: selectedLeads })}
                      >
                        Auswahl gruppieren
                      </Button>
                      <span className={s.boardHint}>Karten auswählen und gruppieren oder eine Gruppe per «Splitten» auflösen · Auswahl steuert Zuweisung &amp; Bündelung.</span>
                    </div>
                    <div className={s.boardColumns}>
                      <div className={s.boardCol}>
                        <div className={s.boardColHead}><span>Neu</span> <span className={s.boardColCount}>{boards.neu.length}</span></div>
                        <div className={s.boardColHint}>Karten hierher ziehen, um Status zu ändern</div>
                        <div className={s.boardColBody}>
                          {boards.neu.map((l) => renderBoardCard(l))}
                          {boards.neu.length === 0 && <div className={s.boardEmpty}>—</div>}
                        </div>
                      </div>
                      <div className={s.boardCol}>
                        <div className={s.boardColHead}><span>In Arbeit</span> <span className={s.boardColCount}>{boards.inArbeit.length}</span></div>
                        <div className={s.boardColHint}>Drag &amp; Drop aktualisiert die Pipeline</div>
                        <div className={s.boardColBody}>
                          {boards.inArbeit.map((l) => renderBoardCard(l))}
                          {boards.inArbeit.length === 0 && <div className={s.boardEmpty}>—</div>}
                        </div>
                      </div>
                      <div className={s.boardCol}>
                        <div className={s.boardColHead}><span>Gebündelt / Geplant</span> <span className={s.boardColCount}>{boards.gebuendeltClusters.reduce((n, g) => n + g.leads.length, 0) + boards.gebuendeltSingles.length}</span></div>
                        <div className={s.boardColHint}>Gebündelte Leads bleiben verknüpft</div>
                        <div className={s.boardColBody}>
                          {boards.gebuendeltClusters.map((g) => (
                            <div key={g.clusterName ?? ''} className={s.boardClusterCard}>
                              <div className={s.boardClusterHead}>
                                <span className={s.link}>{g.clusterName}</span>
                                <Badge kind="amber">Auto-Gruppe · {g.leads.length}</Badge>
                                <Button size="small" appearance="secondary" className={s.splitBtn} onClick={() => splitCluster(g.clusterName ?? '')}>Splitten</Button>
                              </div>
                              {g.leads.map((l) => renderBoardCard(l))}
                            </div>
                          ))}
                          {boards.gebuendeltSingles.map((l) => renderBoardCard(l))}
                          {boards.gebuendeltClusters.length === 0 && boards.gebuendeltSingles.length === 0 && <div className={s.boardEmpty}>—</div>}
                        </div>
                      </div>
                    </div>
                  </div>
                )}

                {leadView === 'cockpit' && leadGroups.length > 0 && (
                  <div className={s.cockpitGrid}>
                    {leadGroups.map((group) => (
                      <div key={group.clusterName ?? group.leads[0].key} className={s.clusterCard}>
                        <div className={s.clusterHead}>
                          <span className={s.link}>{group.isCluster ? group.clusterName : accountName(group.leads[0].accountKey)}</span>
                          {group.isCluster && <Badge kind="amber">Auto-Gruppe · {group.leads.length}</Badge>}
                        </div>
                        <div className={s.muted}>Wirkt auf: {group.leads.length} Lead{group.leads.length > 1 ? 's' : ''}</div>
                        {group.leads.map((l) => (
                          <div key={l.key} className={s.miniLead}>
                            <span className={s.dot} style={{ backgroundColor: priority[priorityKind(l.priority)] }} />
                            <span>{l.topic}</span>
                            {l.score === Math.max(...group.leads.map((x) => x.score)) && <Badge kind="blue">Fokus-Lead</Badge>}
                            <span className={s.miniScore} style={{ color: l.score >= 90 ? palette.green : palette.n190 }}>{l.score}</span>
                          </div>
                        ))}
                        <div className={s.fokusActions}>
                          <Button
                            size="small"
                            appearance="primary"
                            style={{ backgroundColor: palette.brand }}
                            onClick={() => setBundle({ title: group.isCluster ? (group.clusterName ?? 'Gruppe') : accountName(group.leads[0].accountKey), leads: group.leads })}
                          >
                            Leads bündeln
                          </Button>
                          <Button
                            size="small"
                            appearance="secondary"
                            onClick={() => setAssignNote(`360°-Kundenkontext „${group.isCluster ? group.clusterName : accountName(group.leads[0].accountKey)}" öffnen · Navigation zur Dynamics-Kontaktform (DEV-gated).`)}
                          >
                            360° öffnen
                          </Button>
                        </div>
                      </div>
                    ))}
                  </div>
                )}

                <Dialog open={bundle !== null} onOpenChange={(_, d) => { if (!d.open) setBundle(null); }}>
                  <DialogSurface>
                    <DialogBody>
                      <DialogTitle>Live-Bündelung — {bundle?.title}</DialogTitle>
                      <DialogContent>
                        <p className={s.modalLead}>
                          Ein vorbereitetes Gespräch statt {bundle?.leads.length ?? 0} Einzelkontakten. Die Leads werden zu
                          einem gebündelten Kontaktvorschlag zusammengefasst — Sie entscheiden, ob Sie ihn übernehmen.
                        </p>
                        <div className={s.modalList}>
                          {bundle?.leads.map((l) => (
                            <div key={l.key} className={s.modalItem}>
                              <span className={s.dot} style={{ backgroundColor: priority[priorityKind(l.priority)] }} />
                              <span>{l.topic}</span>
                              <span className={s.miniScore} style={{ color: l.score >= 90 ? palette.green : palette.n190 }}>{l.score}</span>
                            </div>
                          ))}
                        </div>
                        <div className={s.demoNote}>
                          Hinweis: Die Bündelung wird über die Aktionsschicht geschrieben (DEV-gated). In dieser lokalen
                          Ansicht ist der Schritt eine Demonstration.
                        </div>
                      </DialogContent>
                      <DialogActions>
                        <Button appearance="secondary" onClick={() => setBundle(null)}>Abbrechen</Button>
                        <Button
                          appearance="primary"
                          style={{ backgroundColor: palette.brand }}
                          onClick={() => {
                            const n = bundle?.leads.length ?? 0;
                            const t = bundle?.title ?? '';
                            setAssignNote(`${n} Leads gebündelt · ${t} · Demo — Schreibzugriff über die Aktionsschicht (DEV-gated).`);
                            setBundle(null);
                            setSelected(new Set());
                          }}
                        >
                          Bündelung bestätigen
                        </Button>
                      </DialogActions>
                    </DialogBody>
                  </DialogSurface>
                </Dialog>
              </div>
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
