// Presentation KPIs for the cockpit that are not (yet) in the transactional
// fixtures — outcome stats, Q2 targets and SLAs shown on the mockup's default
// "Tagesplan (KI)" view. Kept in the control (not data/scenarios) so the Phase-5
// seed stays untouched; these bind to crmshow_measuresnapshot / derived counts
// when the control is wired to Dataverse. All values synthetic (Contoso).

export interface OutcomeStat {
  value: string;
  label: string;
}

export interface KpiCard {
  label: string;
  value: string;
  sub: string;
  warn?: boolean;
}

export interface ProgressCard {
  label: string;
  current: string;
  percent: number;
  color: 'green' | 'amber';
  sub: string;
}

export const focusHero = {
  eyebrow: 'Ihr Fokus heute',
  headline: 'Mehr Zeit für vorbereitete Kundengespräche',
  body: 'Der Tagesplan bündelt Signale, hält offene Aufgaben sichtbar und erklärt seine Prioritäten. Sie entscheiden, was Sie übernehmen, ändern oder später erledigen.',
  stats: [
    { value: '5', label: 'Kundengespräche vorbereitet' },
    { value: '2', label: 'Doppelkontakte vermieden' },
    { value: '35 Min', label: 'Fahrzeit im Tagesplan gespart' },
  ] as OutcomeStat[],
};

export const arbeitsvorratSummary =
  '3 Leads heute fällig · 4/5 Termine vorbereitet · 2 Nachfassaktionen überfällig · Erstkontakt-SLA 88%';

export const kpiCards: KpiCard[] = [
  { label: 'Leads heute kontaktieren', value: '3', sub: '2 innert 4h · 1 bis Tagesende' },
  { label: 'Kundentermine heute', value: '5', sub: '4 vorbereitet · nächster 09:30' },
  { label: 'Nachfassaktionen heute', value: '6', sub: '2 überfällig', warn: true },
  { label: 'Angebote nachfassen', value: '4', sub: '3 Kundenrückmeldungen ausstehend' },
  { label: 'Lead → Beratung (Q2)', value: '28%', sub: '14 von 50 bearbeiteten Leads' },
  { label: 'Erstkontakt innert 24h', value: '88%', sub: '44 von 50 Leads · Ziel 90%' },
];

export const progressCards: ProgressCard[] = [
  { label: 'Erstkontakt innert 24h', current: '44 / 50', percent: 88, color: 'amber', sub: 'Q2 · persönliches Ziel 90%' },
  { label: 'Lead → Beratung', current: '14 / 50', percent: 28, color: 'green', sub: 'Q2 · Ziel 30% · GA-Schnitt 24%' },
  { label: 'Nachfassaktionen fristgerecht', current: '31 / 35', percent: 89, color: 'green', sub: 'Diese Woche · persönliches Ziel 95%' },
  { label: 'Neugeschäftsvolumen (Q2)', current: "CHF 82'000", percent: 82, color: 'green', sub: "Persönliches Ziel CHF 100'000 · Quelle: Abschluss-/Provisionssystem" },
];

export const disclaimer =
  'Illustrative Szenariowerte · KPI-Definitionen, Zielwerte, Datenquellen und Aktualisierung sind mit Contoso zu validieren.';

export const tagesplan = {
  title: 'Ihr steuerbarer Tagesplan',
  body: 'Vorschlag auf Basis von Potenzial, Dringlichkeit, Route und Kontaktpräferenz · Sie können jede Empfehlung ändern.',
  plannedActivities: '6',
  estimatedConversion: '2.0',
};

export interface FokusProvenance {
  label: string;
  detail: string;
}

export const empfohlenerFokus = {
  title: 'Empfohlener Fokus — Haushalt Brunner',
  suggestionBadge: 'Vorschlag · Sie entscheiden',
  whyNow:
    'Die Online-Offerte ist zu 78% abgeschlossen, der Rechtsschutz läuft in 38 Tagen aus und der Termin um 09:30 ist bereits bestätigt.',
  provenance: [
    { label: 'Online-Abbruch', detail: 'Online-Journey (Web) · Mi 21:14' },
    { label: 'Vertragsablauf', detail: 'Vertragssystem FLEX · Stand heute 06:00' },
    { label: 'Termin 09:30', detail: 'CRM Aktivität · live' },
  ] as FokusProvenance[],
  fields: [
    { k: 'Top-Lead', v: 'Haushalt Brunner · Hausrat-Offerte' },
    { k: 'Kanal', v: 'Click-to-call · Telefon bevorzugt' },
    { k: 'Wirkt auf', v: '3 gebündelte Leads + Termin 09:30' },
    { k: 'Ihr Nutzen', v: 'Ein vorbereitetes Gespräch statt drei Kontakte' },
  ],
  actions: ['Vorbereiten', 'Anpassen', 'Kundenkontext öffnen', 'Später planen', 'Vorschlag verwerfen'],
  statusBadge: 'Aktiv',
  disclosure: 'KI-unterstützt',
};
