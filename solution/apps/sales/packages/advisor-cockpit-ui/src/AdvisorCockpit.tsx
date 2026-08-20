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
import {
  AddRegular,
  ArrowRightRegular,
  ArrowSwapRegular,
  BoardRegular,
  BranchRegular,
  CallRegular,
  CheckmarkRegular,
  ClockRegular,
  DismissRegular,
  EditRegular,
  FilterRegular,
  GridRegular,
  LinkMultipleRegular,
  OpenRegular,
  SaveRegular,
  TextBulletListLtrRegular,
} from '@fluentui/react-icons';
import {
  appointments,
  boardBuckets,
  buildAccountIndex,
  filterLeads,
  groupLeads,
  isCapabilityExecutable,
  openTasks,
  sortLeads,
  sortedNba,
  type ActivityRecord,
  type AdvisorCockpitHost,
  type ClaimRecord,
  type CockpitWriteCommand,
  type CommandResult,
  type ContactRecord,
  type CockpitData,
  type LeadRecord,
  type LeadSortKey,
  type NbaRecord,
} from '@crmshow/advisor-cockpit-domain';
import { CapabilityButton } from './CapabilityButton';
import { badge, font, nbaAccent, palette, priority, provenance, provenanceLabel } from './tokens';
import {
  arbeitsvorratSummary,
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
  clusterRow: { backgroundColor: '#ffedeb', cursor: 'default' },
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
  boardGroup: { ...shorthands.border('1px', 'solid', palette.brand), ...shorthands.borderRadius('8px'), backgroundColor: '#ffedeb', ...shorthands.padding('8px') },
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
    backgroundColor: '#ffedeb',
    ...shorthands.border('1px', 'solid', palette.brand),
    ...shorthands.borderRadius('8px'),
  },
  selInfo: { fontWeight: 600, fontSize: '13px', color: palette.brandDark },
  selActions: { display: 'flex', alignItems: 'center', ...shorthands.gap('8px'), flexWrap: 'wrap' },
  demoNote: {
    ...shorthands.padding('8px', '12px'),
    marginBottom: '10px',
    backgroundColor: '#fdf6e3',
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
  boardClusterCard: { ...shorthands.border('1px', 'solid', palette.brand), ...shorthands.borderRadius('8px'), backgroundColor: '#ffedeb', ...shorthands.padding('8px'), display: 'flex', flexDirection: 'column', ...shorthands.gap('8px') },
  boardClusterHead: { display: 'flex', alignItems: 'center', ...shorthands.gap('7px'), fontWeight: 700, fontSize: '13px', flexWrap: 'wrap' },
  splitBtn: { marginLeft: 'auto' },
  boardEmpty: { color: palette.n60, fontSize: '12px', ...shorthands.padding('8px', '4px') },
  provWrap: { ...shorthands.borderRadius('4px'), ...shorthands.padding('4px', '10px') },
  legend: { display: 'flex', alignItems: 'center', ...shorthands.gap('14px'), flexWrap: 'wrap', marginTop: '4px', paddingTop: '12px', ...shorthands.borderTop('1px', 'solid', palette.n30), fontSize: '11px', color: palette.n130 },
  legendTitle: { fontWeight: 700, textTransform: 'uppercase', letterSpacing: '0.04em' },
  legendItem: { display: 'inline-flex', alignItems: 'center', ...shorthands.gap('6px') },
  legendSwatch: { width: '12px', height: '12px', ...shorthands.borderRadius('3px'), ...shorthands.border('1px', 'solid', palette.n60), display: 'inline-block' },
  cockpitPanes: { display: 'grid', gridTemplateColumns: 'minmax(0, 1.1fr) minmax(0, 0.9fr)', ...shorthands.gap('12px'), alignItems: 'start' },
  cockpitFocus: { backgroundColor: palette.n0, ...shorthands.border('1px', 'solid', palette.brand), ...shorthands.borderRadius('10px'), ...shorthands.padding('14px') },
  cockpitQueue: { backgroundColor: palette.n0, ...shorthands.border('1px', 'solid', palette.n30), ...shorthands.borderRadius('10px'), ...shorthands.padding('14px') },
  cockpitPaneHead: { display: 'flex', alignItems: 'center', ...shorthands.gap('8px'), fontWeight: 700, fontSize: '11px', letterSpacing: '0.04em', textTransform: 'uppercase', color: palette.n160, marginBottom: '10px' },
  focusBody: { display: 'flex', flexDirection: 'column', ...shorthands.gap('10px') },
  focusTopline: { display: 'flex', alignItems: 'center', ...shorthands.gap('8px') },
  focusTopic: { fontWeight: 700, fontSize: '15px' },
  focusScore: { marginLeft: 'auto', fontWeight: 700, fontSize: '15px' },
  focusAccount: { fontSize: '13px' },
  focusGrid: { display: 'grid', gridTemplateColumns: 'repeat(2, minmax(0, 1fr))', ...shorthands.gap('8px', '14px'), ...shorthands.padding('10px', 0), ...shorthands.borderTop('1px', 'solid', palette.n20), ...shorthands.borderBottom('1px', 'solid', palette.n20) },
  fLabel: { fontSize: '10px', color: palette.n130, textTransform: 'uppercase', letterSpacing: '0.03em', marginBottom: '2px' },
  queueBody: { display: 'flex', flexDirection: 'column', ...shorthands.gap('2px') },
  queueItem: { display: 'flex', alignItems: 'center', ...shorthands.gap('10px'), ...shorthands.padding('8px', '2px'), ...shorthands.borderTop('1px', 'solid', palette.n20) },
  queueScore: { fontWeight: 700, minWidth: '26px' },
  queueMain: { display: 'flex', flexDirection: 'column', minWidth: 0, flexGrow: 1 },
  queueTopic: { fontWeight: 600, fontSize: '13px' },
  viewBtnInner: { display: 'inline-flex', alignItems: 'center', ...shorthands.gap('5px') },
  srOnly: { position: 'absolute', width: '1px', height: '1px', ...shorthands.overflow('hidden'), clip: 'rect(0 0 0 0)', whiteSpace: 'nowrap', ...shorthands.borderWidth('0'), ...shorthands.padding('0'), ...shorthands.margin('-1px') },
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

const ACTION_ICON: Record<string, React.ReactElement> = {
  Vorbereiten: <EditRegular />,
  Anpassen: <EditRegular />,
  'Kundenkontext öffnen': <OpenRegular />,
  'Später planen': <ClockRegular />,
  'Vorschlag verwerfen': <DismissRegular />,
};
const VIEW_ICON: Record<'list' | 'board' | 'cockpit', React.ReactElement> = {
  list: <TextBulletListLtrRegular />,
  board: <BoardRegular />,
  cockpit: <GridRegular />,
};

function statusBadgeKind(status: string): keyof typeof badge {
  if (/Überfällig|Risiko/i.test(status)) return 'red';
  if (/Primär|Neu/i.test(status)) return 'blue';
  if (/Gebündelt|Offen/i.test(status)) return 'green';
  if (/Verknüpfen|Arbeit/i.test(status)) return 'amber';
  return 'grey';
}

interface SortState {
  key: string;
  dir: 'asc' | 'desc';
}

// Generic column sort shared by the non-lead grids (Aufgaben, Fälle) so every
// grid in the control sorts the same way.
function sortRows<T>(rows: T[], sort: SortState, val: (r: T, key: string) => string | number): T[] {
  const sign = sort.dir === 'asc' ? 1 : -1;
  return [...rows].sort((a, b) => {
    const va = val(a, sort.key);
    const vb = val(b, sort.key);
    if (va < vb) return -1 * sign;
    if (va > vb) return 1 * sign;
    return 0;
  });
}

export interface AdvisorCockpitProps {
  data: CockpitData;
  host: AdvisorCockpitHost;
}

export function AdvisorCockpit({ data, host }: AdvisorCockpitProps): JSX.Element {
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
  const [bundle, setBundle] = React.useState<{
    title: string;
    leads: LeadRecord[];
    clusterId: string | null;
  } | null>(null);
  const [sortKey, setSortKey] = React.useState<LeadSortKey>('score');
  const [sortDir, setSortDir] = React.useState<'asc' | 'desc'>('desc');
  const [collapsed, setCollapsed] = React.useState<Set<string>>(() => new Set());
  const [splitClusters, setSplitClusters] = React.useState<Set<string>>(() => new Set());
  const [autoGroup, setAutoGroup] = React.useState(true);
  const [activityNote, setActivityNote] = React.useState<string | null>(null);
  const [taskSort, setTaskSort] = React.useState<SortState>({ key: 'faellig', dir: 'asc' });
  const [claimSort, setClaimSort] = React.useState<SortState>({ key: 'sla', dir: 'asc' });
  const [focusKey, setFocusKey] = React.useState<string | null>(null);
  const [live, setLive] = React.useState('');
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
  const cockpitQueue = React.useMemo(() => sortLeads(filteredLeads, 'score', 'desc', (k) => accounts.get(k) ?? k), [filteredLeads, accounts]);
  const cockpitFocus = React.useMemo(() => cockpitQueue.find((l) => l.key === focusKey) ?? cockpitQueue[0] ?? null, [cockpitQueue, focusKey]);
  const cockpitRest = React.useMemo(() => cockpitQueue.filter((l) => l.key !== cockpitFocus?.key), [cockpitQueue, cockpitFocus]);
  const focusCluster = React.useMemo(() => {
    if (!cockpitFocus?.leadCluster) return null;
    const leads = filteredLeads.filter((l) => l.leadCluster === cockpitFocus.leadCluster);
    return leads.length > 1 ? { clusterName: cockpitFocus.leadCluster, leads } : null;
  }, [cockpitFocus, filteredLeads]);
  const nba = React.useMemo(() => sortedNba(data.nba), [data]);
  const appts = React.useMemo(() => appointments(data.activities), [data]);
  const tasks = React.useMemo(() => openTasks(data.activities), [data]);
  const contacts = React.useMemo(
    () => new Map(
      data.accountsContacts
        .filter((row): row is ContactRecord => row.recordType === 'contact')
        .map((row) => [row.key, row]),
    ),
    [data.accountsContacts],
  );
  const topNba = nba[0] ?? null;
  const defaultAccountId = topNba?.accountKey
    ?? data.accountsContacts.find((row) => row.recordType === 'account')?.key
    ?? '';
  const accountName = (key: string) => accounts.get(key) ?? key;
  const today = new Date().toLocaleDateString('de-CH', { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' });

  const runCommand = async (
    command: CockpitWriteCommand,
    setNote?: React.Dispatch<React.SetStateAction<string | null>>,
  ): Promise<CommandResult> => {
    try {
      const result = await host.execute(command);
      setLive(result.message);
      setNote?.(result.message);
      return result;
    } catch (error) {
      const message = error instanceof Error ? error.message : 'The command failed.';
      setLive(message);
      setNote?.(message);
      return { ok: false, message };
    }
  };

  const navigate = async (
    table: 'account' | 'lead' | 'crmshow_claimprojection',
    id: string,
  ): Promise<void> => {
    try {
      await host.navigate(table, id);
    } catch (error) {
      setLive(error instanceof Error ? error.message : 'Navigation failed.');
    }
  };

  const callLead = async (lead: LeadRecord): Promise<void> => {
    const phoneNumber = contacts.get(lead.contactKey)?.phone;
    if (!phoneNumber) {
      setLive('No mapped phone number is available for this lead.');
      return;
    }

    await runCommand({ type: 'call', phoneNumber }, setAssignNote);
  };

  const runFocusAction = async (action: string): Promise<void> => {
    if (action === 'Vorbereiten') {
      setLive('Gesprächsvorbereitung ist in diesem Host nicht verfügbar.');
      return;
    }
    if (!topNba) {
      setLive('No recommendation is available for this action.');
      return;
    }

    switch (action) {
      case 'Anpassen':
        await runCommand({
          type: 'editNba',
          nbaId: topNba.key,
          changes: { channel: topNba.channel, rank: topNba.rank },
        });
        break;
      case 'Kundenkontext öffnen':
        await navigate('account', topNba.accountKey);
        break;
      case 'Später planen':
        await runCommand({ type: 'snoozeNba', nbaId: topNba.key });
        break;
      case 'Vorschlag verwerfen':
        await runCommand({ type: 'dismissNba', nbaId: topNba.key });
        break;
    }
  };

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
  const applyAssignment = async () => {
    if (!assignTo || selected.size === 0) return;
    const result = await runCommand({
      type: 'assignLead',
      leadIds: [...selected],
      ownerId: assignTo,
    }, setAssignNote);
    if (result.ok) {
      setSelected(new Set());
      setAssignTo('');
    }
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
    const nextDir = sortKey === key ? (sortDir === 'asc' ? 'desc' : 'asc') : key === 'score' || key === 'priority' ? 'desc' : 'asc';
    setSortKey(key);
    setSortDir(nextDir);
    setLive(`Sortiert nach ${key} (${nextDir === 'asc' ? 'aufsteigend' : 'absteigend'})`);
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
  const splitCluster = async (name: string, leads: readonly LeadRecord[]) => {
    const result = await runCommand({
      type: 'splitLeads',
      leadIds: leads.map((lead) => lead.key),
    }, setAssignNote);
    if (result.ok) setSplitClusters((prev) => new Set(prev).add(name));
  };
  const saveView = async () => {
    await runCommand({ type: 'savePersonalView', name: 'Advisor Cockpit - Meine Leads' }, setAssignNote);
  };
  const applyTop10 = () => {
    setLeadView('list');
    setSortKey('score');
    setSortDir('desc');
    setAssignNote('Top 10 nach Priorität · Liste nach KI-Score sortiert (Preset).');
  };
  const confirmBundle = async (): Promise<void> => {
    if (!bundle) return;
    if (!bundle.clusterId) {
      setLive('No mapped Lead Cluster target is available.');
      return;
    }
    const result = await runCommand({
      type: 'bundleLeads',
      leadIds: bundle.leads.map((lead) => lead.key),
      clusterId: bundle.clusterId,
    }, setAssignNote);
    if (result.ok) {
      setBundle(null);
      setSelected(new Set());
    }
  };

  const createActivity = async (type: 'createAppointment' | 'createTask'): Promise<void> => {
    if (!defaultAccountId) {
      setLive('No mapped Account is available for this activity.');
      return;
    }
    await runCommand({ type, accountId: defaultAccountId }, setActivityNote);
  };

  const hostBundleCapability = host.capability('bundleLeads');
  const bundleCapability = bundle?.clusterId || !isCapabilityExecutable(hostBundleCapability)
    ? hostBundleCapability
    : {
        availability: 'blocked' as const,
        reason: 'No mapped Lead Cluster target is available.',
        target: hostBundleCapability.target,
      };
  React.useEffect(() => {
    setLive(selected.size > 0 ? `${selected.size} Lead${selected.size > 1 ? 's' : ''} ausgewählt` : '');
  }, [selected]);
  React.useEffect(() => {
    if (leadView === 'cockpit' && cockpitFocus) setLive(`Fokus-Lead: ${cockpitFocus.topic}`);
  }, [cockpitFocus, leadView]);
  const arrowFor = (st: SortState, key: string) => (st.key === key ? (st.dir === 'asc' ? ' ▲' : ' ▼') : '');
  const ariaSortFor = (st: SortState, key: string): 'ascending' | 'descending' | 'none' =>
    st.key === key ? (st.dir === 'asc' ? 'ascending' : 'descending') : 'none';
  const toggleRowSort = (set: React.Dispatch<React.SetStateAction<SortState>>, key: string) => {
    set((prev) => (prev.key === key ? { key, dir: prev.dir === 'asc' ? 'desc' : 'asc' } : { key, dir: 'asc' }));
    setLive(`Sortiert nach ${key}`);
  };
  const taskVal = (t: ActivityRecord, key: string): string =>
    key === 'bezug' ? accountName(t.accountKey).toLowerCase() : key === 'faellig' ? (t.due ?? t.status ?? '') : t.subject.toLowerCase();
  const sortedTasks = React.useMemo(() => sortRows(tasks, taskSort, taskVal), [tasks, taskSort]);
  const claimVal = (c: ClaimRecord, key: string): string | number => {
    switch (key) {
      case 'typ': return c.caseType.toLowerCase();
      case 'kunde': return accountName(c.accountKey).toLowerCase();
      case 'betreff': return c.title.toLowerCase();
      case 'kanal': return c.channel.toLowerCase();
      case 'status': return c.status.toLowerCase();
      case 'sla': return c.slaHours ?? 0;
      default: return c.externalId.toLowerCase();
    }
  };
  const sortedClaims = React.useMemo(() => sortRows(data.claims, claimSort, claimVal), [data.claims, claimSort]);

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
        <div className={s.srOnly} role="status" aria-live="polite">{live}</div>
        <section className={s.hero}>
          <div>
            <div className={s.heroEyebrow}>{focusHero.eyebrow}</div>
            <h2 className={s.heroHeadline}>{focusHero.headline}</h2>
            <p className={s.heroBody}>{focusHero.body}</p>
          </div>
          <div className={s.heroStats}>
            {focusHero.stats.map((st) => (
              <div key={st.label} className={s.provWrap} style={st.prov !== 'crm' ? { backgroundColor: provenance[st.prov] } : undefined} title={provenanceLabel[st.prov]}>
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
              <div key={c.label} className={s.tile} style={c.prov !== 'crm' ? { backgroundColor: provenance[c.prov] } : undefined} title={provenanceLabel[c.prov]}>
                <div className={s.tileLabel}>{c.label}</div>
                <div className={s.tileValue}>{c.value}</div>
                <div className={`${s.tileSub} ${c.warn ? s.tileSubWarn : ''}`}>{c.sub}</div>
              </div>
            ))}
          </div>
          <div className={s.progressGrid}>
            {progressCards.map((c) => (
              <div key={c.label} className={s.tile} style={c.prov !== 'crm' ? { backgroundColor: provenance[c.prov] } : undefined} title={provenanceLabel[c.prov]}>
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
                  <div className={s.provWrap} title={provenanceLabel.crm}>
                    <div className={s.tpStatValue}>{tagesplan.plannedActivities}</div>
                    <div className={s.tpStatLabel}>Geplante Aktivitäten</div>
                  </div>
                  <div className={s.provWrap} style={{ backgroundColor: provenance.external }} title={provenanceLabel.external}>
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
                    {empfohlenerFokus.actions.map((a, i) => {
                      const commandType: CockpitWriteCommand['type'] | null =
                        a === 'Anpassen' ? 'editNba'
                          : a === 'Später planen' ? 'snoozeNba'
                            : a === 'Vorschlag verwerfen' ? 'dismissNba'
                              : null;
                      const buttonProps = {
                        size: 'small' as const,
                        icon: ACTION_ICON[a],
                        appearance: i === 0 ? 'primary' as const : 'secondary' as const,
                        style: i === 0 ? { backgroundColor: palette.brand } : undefined,
                      };
                      return commandType ? (
                        <CapabilityButton
                          key={a}
                          {...buttonProps}
                          capability={host.capability(commandType)}
                          onClick={() => void runFocusAction(a)}
                        >
                          {a}
                        </CapabilityButton>
                      ) : (
                        <Button key={a} {...buttonProps} onClick={() => void runFocusAction(a)}>
                          {a}
                        </Button>
                      );
                    })}
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
                        {v === 'list' ? <span className={s.viewBtnInner}>{VIEW_ICON.list}Liste</span> : v === 'board' ? <span className={s.viewBtnInner}>{VIEW_ICON.board}Board</span> : <span className={s.viewBtnInner}>{VIEW_ICON.cockpit}Cockpit</span>}
                      </button>
                    ))}
                  </div>
                  <div className={s.vtActions}>
                    <Button size="small" icon={<FilterRegular />} appearance="secondary" onClick={applyTop10}>Top 10 nach Priorität</Button>
                    <CapabilityButton
                      size="small"
                      icon={<SaveRegular />}
                      appearance="secondary"
                      capability={host.capability('savePersonalView')}
                      onClick={() => void saveView()}
                    >
                      Ansicht speichern
                    </CapabilityButton>
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
                      <CapabilityButton
                        size="small"
                        icon={<ArrowSwapRegular />}
                        appearance="primary"
                        style={{ backgroundColor: palette.brand }}
                        capability={host.capability('assignLead')}
                        disabled={!assignTo}
                        onClick={() => void applyAssignment()}
                      >
                        Zuweisen
                      </CapabilityButton>
                      <Button
                        size="small"
                        icon={<LinkMultipleRegular />}
                        appearance="secondary"
                        disabled={selected.size < 2}
                        onClick={() => setBundle({
                          title: 'Ausgewählte Leads',
                          leads: selectedLeads,
                          clusterId: selectedLeads.find((lead) => lead.leadClusterId)?.leadClusterId ?? null,
                        })}
                      >
                        Bündeln
                      </Button>
                      <Button size="small" icon={<DismissRegular />} appearance="transparent" onClick={clearSelection}>Auswahl aufheben</Button>
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
                        icon={<BranchRegular />}
                        appearance={autoGroup ? 'primary' : 'secondary'}
                        style={autoGroup ? { backgroundColor: palette.brand } : undefined}
                        onClick={() => setAutoGroup((v) => !v)}
                      >
                        Auto-Gruppierung: {autoGroup ? 'An' : 'Aus'}
                      </Button>
                      <Button
                        size="small"
                        icon={<LinkMultipleRegular />}
                        appearance="secondary"
                        disabled={selected.size < 2}
                        onClick={() => setBundle({
                          title: 'Ausgewählte Leads',
                          leads: selectedLeads,
                          clusterId: selectedLeads.find((lead) => lead.leadClusterId)?.leadClusterId ?? null,
                        })}
                      >
                        Auswahl gruppieren
                      </Button>
                      <span className={s.boardHint}>Karten auswählen und gruppieren oder eine Gruppe per «Splitten» auflösen · Auswahl steuert Zuweisung &amp; Bündelung.</span>
                    </div>
                    <div className={s.boardColumns}>
                      <div className={s.boardCol}>
                        <div className={s.boardColHead}><span>Neu</span> <span className={s.boardColCount}>{boards.neu.length}</span></div>
                        <div
                          className={s.boardColHint}
                          aria-description={host.capability('updateLeadQueueStatus').reason}
                        >
                          Karten hierher ziehen, um Status zu ändern
                        </div>
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
                                <CapabilityButton
                                  size="small"
                                  icon={<BranchRegular />}
                                  appearance="secondary"
                                  className={s.splitBtn}
                                  capability={host.capability('splitLeads')}
                                  onClick={() => void splitCluster(g.clusterName ?? '', g.leads)}
                                >
                                  Splitten
                                </CapabilityButton>
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
                  <div className={s.cockpitPanes}>
                    <section className={s.cockpitFocus}>
                      <div className={s.cockpitPaneHead}>Fokus-Lead</div>
                      {cockpitFocus ? (
                        <div className={s.focusBody}>
                          <div className={s.focusTopline}>
                            <span className={s.dot} style={{ backgroundColor: priority[priorityKind(cockpitFocus.priority)] }} />
                            <span className={s.focusTopic}>{cockpitFocus.topic}</span>
                            <span className={s.focusScore} style={{ color: cockpitFocus.score >= 90 ? palette.green : palette.n190 }}>{cockpitFocus.score}</span>
                          </div>
                          <div className={s.focusAccount}><span className={s.link}>{accountName(cockpitFocus.accountKey)}</span></div>
                          <div className={s.focusGrid}>
                            <div><div className={s.fLabel}>Kanal</div><div>{cockpitFocus.channel}</div></div>
                            <div><div className={s.fLabel}>Urgency</div><div>{cockpitFocus.priority}</div></div>
                            <div><div className={s.fLabel}>SLA</div><div>{cockpitFocus.sla}</div></div>
                            <div><div className={s.fLabel}>Status</div><div><Badge kind={statusBadgeKind(cockpitFocus.status)}>{cockpitFocus.status}</Badge></div></div>
                          </div>
                          {focusCluster && (
                            <div className={s.muted}>Teil der Auto-Gruppe „{focusCluster.clusterName}" · wirkt auf {focusCluster.leads.length} Leads</div>
                          )}
                          <div className={s.fokusActions}>
                            <CapabilityButton
                              size="small"
                              icon={<CallRegular />}
                              appearance="primary"
                              style={{ backgroundColor: palette.brand }}
                              capability={host.capability('call')}
                              onClick={() => void callLead(cockpitFocus)}
                            >
                              Anrufen
                            </CapabilityButton>
                            <Button size="small" icon={<EditRegular />} appearance="secondary" onClick={() => setLive('Meeting preparation is not available in this host.')}>Vorbereiten</Button>
                            {focusCluster && (
                              <Button
                                size="small"
                                icon={<LinkMultipleRegular />}
                                appearance="secondary"
                                onClick={() => setBundle({
                                  title: focusCluster.clusterName ?? 'Gruppe',
                                  leads: focusCluster.leads,
                                  clusterId: focusCluster.leads.find((lead) => lead.leadClusterId)?.leadClusterId ?? null,
                                })}
                              >
                                Leads bündeln
                              </Button>
                            )}
                            <Button size="small" icon={<OpenRegular />} appearance="secondary" onClick={() => void navigate('account', cockpitFocus.accountKey)}>360° öffnen</Button>
                            <Button size="small" icon={<ArrowRightRegular />} appearance="subtle" disabled={cockpitRest.length === 0} onClick={() => setFocusKey(cockpitRest[0]?.key ?? null)}>Nächster Lead →</Button>
                          </div>
                        </div>
                      ) : (
                        <div className={s.emptyNote}>Kein Lead in der Auswahl.</div>
                      )}
                    </section>
                    <section className={s.cockpitQueue}>
                      <div className={s.cockpitPaneHead}>Priorisierte Warteschlange <span className={s.boardColCount}>{cockpitRest.length}</span></div>
                      <div className={s.queueBody}>
                        {cockpitRest.map((l) => (
                          <div key={l.key} className={s.queueItem}>
                            <span className={s.dot} style={{ backgroundColor: priority[priorityKind(l.priority)] }} />
                            <span className={s.queueScore} style={{ color: l.score >= 90 ? palette.green : palette.n190 }}>{l.score}</span>
                            <div className={s.queueMain}>
                              <div className={s.queueTopic}>{l.topic}</div>
                              <div className={s.muted}>{accountName(l.accountKey)} · {l.channel}</div>
                            </div>
                            <Button size="small" icon={<ArrowRightRegular />} appearance="secondary" onClick={() => setFocusKey(l.key)}>In Fokus</Button>
                          </div>
                        ))}
                        {cockpitRest.length === 0 && <div className={s.emptyNote}>Warteschlange leer.</div>}
                      </div>
                    </section>
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
                          Hinweis: Diese Schreibaktion ist noch nicht freigegeben. {bundleCapability.reason}
                        </div>
                      </DialogContent>
                      <DialogActions>
                        <Button appearance="secondary" icon={<DismissRegular />} onClick={() => setBundle(null)}>Abbrechen</Button>
                        <CapabilityButton
                          icon={<CheckmarkRegular />}
                          appearance="primary"
                          style={{ backgroundColor: palette.brand }}
                          capability={bundleCapability}
                          onClick={() => void confirmBundle()}
                        >
                          Bündelung bestätigen
                        </CapabilityButton>
                      </DialogActions>
                    </DialogBody>
                  </DialogSurface>
                </Dialog>
              </div>
            )}

            {tab === 'termine' && (
              <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
                {activityNote && <div className={s.demoNote}>{activityNote}</div>}
                <section className={s.card}>
                  <div className={s.cardHead}>
                    <span>Termine heute</span>
                    <CapabilityButton
                      size="small"
                      icon={<AddRegular />}
                      appearance="primary"
                      style={{ marginLeft: 'auto', backgroundColor: palette.brand }}
                      capability={host.capability('createAppointment')}
                      onClick={() => void createActivity('createAppointment')}
                    >
                      + Termin
                    </CapabilityButton>
                  </div>
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
                  <div className={s.cardHead}>
                    <span>Offene Aufgaben</span>
                    <CapabilityButton
                      size="small"
                      icon={<AddRegular />}
                      appearance="secondary"
                      style={{ marginLeft: 'auto' }}
                      capability={host.capability('createTask')}
                      onClick={() => void createActivity('createTask')}
                    >
                      + Aufgabe
                    </CapabilityButton>
                  </div>
                  <div className={s.cardBody}>
                    <table className={s.table}>
                      <thead>
                        <tr>
                          <th className={s.th} aria-sort={ariaSortFor(taskSort, 'aufgabe')}><button type="button" className={s.sortBtn} onClick={() => toggleRowSort(setTaskSort, 'aufgabe')}>Aufgabe{arrowFor(taskSort, 'aufgabe')}</button></th>
                          <th className={s.th} aria-sort={ariaSortFor(taskSort, 'bezug')}><button type="button" className={s.sortBtn} onClick={() => toggleRowSort(setTaskSort, 'bezug')}>Bezug{arrowFor(taskSort, 'bezug')}</button></th>
                          <th className={s.th} aria-sort={ariaSortFor(taskSort, 'faellig')}><button type="button" className={s.sortBtn} onClick={() => toggleRowSort(setTaskSort, 'faellig')}>Fällig{arrowFor(taskSort, 'faellig')}</button></th>
                        </tr>
                      </thead>
                      <tbody>
                        {sortedTasks.map((t) => (
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
                        <th className={s.th} aria-sort={ariaSortFor(claimSort, 'fallid')}><button type="button" className={s.sortBtn} onClick={() => toggleRowSort(setClaimSort, 'fallid')}>Fall-ID{arrowFor(claimSort, 'fallid')}</button></th>
                        <th className={s.th} aria-sort={ariaSortFor(claimSort, 'typ')}><button type="button" className={s.sortBtn} onClick={() => toggleRowSort(setClaimSort, 'typ')}>Typ{arrowFor(claimSort, 'typ')}</button></th>
                        <th className={s.th} aria-sort={ariaSortFor(claimSort, 'kunde')}><button type="button" className={s.sortBtn} onClick={() => toggleRowSort(setClaimSort, 'kunde')}>Kunde{arrowFor(claimSort, 'kunde')}</button></th>
                        <th className={s.th} aria-sort={ariaSortFor(claimSort, 'betreff')}><button type="button" className={s.sortBtn} onClick={() => toggleRowSort(setClaimSort, 'betreff')}>Betreff{arrowFor(claimSort, 'betreff')}</button></th>
                        <th className={s.th} aria-sort={ariaSortFor(claimSort, 'kanal')}><button type="button" className={s.sortBtn} onClick={() => toggleRowSort(setClaimSort, 'kanal')}>Kanal{arrowFor(claimSort, 'kanal')}</button></th>
                        <th className={s.th} aria-sort={ariaSortFor(claimSort, 'status')}><button type="button" className={s.sortBtn} onClick={() => toggleRowSort(setClaimSort, 'status')}>Status{arrowFor(claimSort, 'status')}</button></th>
                        <th className={s.th} aria-sort={ariaSortFor(claimSort, 'sla')}><button type="button" className={s.sortBtn} onClick={() => toggleRowSort(setClaimSort, 'sla')}>SLA{arrowFor(claimSort, 'sla')}</button></th>
                      </tr>
                    </thead>
                    <tbody>
                      {sortedClaims.map((c) => (
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
                        {card.channel === 'Anruf' && card.leadKey ? (
                          <CapabilityButton
                            size="small"
                            icon={<CallRegular />}
                            appearance="primary"
                            style={{ backgroundColor: palette.brand }}
                            capability={host.capability('call')}
                            onClick={() => {
                              const lead = data.leads.find((candidate) => candidate.key === card.leadKey);
                              if (lead) void callLead(lead);
                            }}
                          >
                            Anrufen
                          </CapabilityButton>
                        ) : (
                          <Button
                            size="small"
                            icon={<OpenRegular />}
                            appearance="primary"
                            style={{ backgroundColor: palette.brand }}
                            onClick={() => void navigate(card.leadKey ? 'lead' : 'account', card.leadKey ?? card.accountKey)}
                          >
                            {card.channel === 'Termin' ? 'Termin öffnen' : 'Öffnen'}
                          </Button>
                        )}
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </div>
        </div>

        <div className={s.legend}>
          <span className={s.legendTitle}>Datenquelle</span>
          <span className={s.legendItem}><span className={s.legendSwatch} style={{ backgroundColor: palette.n0 }} />{provenanceLabel.crm}</span>
          <span className={s.legendItem}><span className={s.legendSwatch} style={{ backgroundColor: provenance.external }} />{provenanceLabel.external}</span>
          <span className={s.legendItem}><span className={s.legendSwatch} style={{ backgroundColor: provenance.unmapped }} />{provenanceLabel.unmapped}</span>
        </div>
      </div>
    </div>
  );
}
