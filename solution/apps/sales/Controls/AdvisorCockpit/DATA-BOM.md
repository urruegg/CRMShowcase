# Advisor Cockpit — Visual BOM → data-model map

Every visual element of the control, mapped to **where its data comes from** so we
can prove CRM ↔ data-platform parity. Tab content verified by the component tests
(`AdvisorCockpit.test.tsx`, which switch tabs and assert their content).

## Data classes

| Class | Meaning | Fixture (local) → Dataverse (deployed) |
| --- | --- | --- |
| **CTX** | PCF `context` — signed-in user | `advisorProfile` → `systemuser` + `businessunit` |
| **CRM** | Live Dataverse transactional read | `leads/activities/accounts-contacts/claims.json` → Lead, Activity, Account/Contact, `crmshow_*projection` |
| **DBX** | Data-platform (Databricks) measure, materialized as a projection ([ADR-0026](../../../../docs/adr/ADR-0026-inbound-analytics-projection-pattern.md)) | `measures.json` → `crmshow_measuresnapshot` (measure-snapshot contract) |
| **NBA** | Advisory record produced by the NBA agent, grounded in CRM+DBX | `nba.json` → `crmshow_nextbestaction` (+ `crmshow_nbaprovenance`) |
| **RT** | Client runtime (clock) | `new Date()` |
| **STATIC** | Fixed presentation copy | in `kpis.ts` |

Status: ✅ bound to the correct source · ⚠ **presentation placeholder** in `kpis.ts` that should bind to the source in the last column.

## Header

| Visual | Class | Source | Status |
| --- | --- | --- | --- |
| "Guten Morgen" | RT | client time-of-day (currently fixed) | ⚠ derive from clock |
| Advisor name / role / GA | CTX | `systemuser.fullname` / `.title` / `businessunit.name` | ✅ `data.advisor` |
| Date | RT | client clock | ✅ |
| Breadcrumb | STATIC | — | ✅ |

## Ihr Fokus heute (hero)

| Visual | Class | Source | Status |
| --- | --- | --- | --- |
| Headline / body | STATIC | framing copy | ✅ |
| 5 Kundengespräche vorbereitet | DBX/CRM | Efficiency measure **or** count of prepared appointments | ⚠ `kpis.focusHero` |
| 2 Doppelkontakte vermieden | DBX/NBA | LeadCluster dedup outcome | ⚠ `kpis.focusHero` |
| 35 Min Fahrzeit gespart | DBX | route-optimization measure | ⚠ `kpis.focusHero` |

## Arbeitsvorrat & persönliche Ziele

| Visual | Class | Source | Status |
| --- | --- | --- | --- |
| Summary line | CRM+DBX | lead/termin counts (CRM) + Erstkontakt-SLA (DBX) | ⚠ `kpis` |
| KPI 1 · Leads heute kontaktieren (3) | **CRM** | Lead (owner=me, fällig=heute, offen) | ⚠ derive from `leads` |
| KPI 2 · Kundentermine heute (5) | **CRM** | appointment (heute) | ⚠ derive from `activities` |
| KPI 3 · Nachfassaktionen heute (6 · 2 überfällig) | **CRM** | task / follow-up | ⚠ derive from `activities` |
| KPI 4 · Angebote nachfassen (4) | **CRM** | Quote / Opportunity follow-up | ⚠ **no quote fixture yet** |
| KPI 5 · Lead → Beratung Q2 (28%) | **DBX** | `crmshow_measuresnapshot` metric `Conversion` | ⚠ `measures.json` **already has Conversion 28** — bind it |
| KPI 6 · Erstkontakt innert 24h (88%) | **DBX** | measuresnapshot (Efficiency / TFF SLA) | ⚠ add measure row |
| Progress 1 · Erstkontakt 44/50 88% | **DBX** | measuresnapshot (Efficiency) | ⚠ add measure row |
| Progress 2 · Lead → Beratung 14/50 28% | **DBX** | measuresnapshot (Conversion) | ⚠ bind to `measures.json` |
| Progress 3 · Nachfass fristgerecht 31/35 89% | **DBX/CRM** | measuresnapshot or CRM-derived | ⚠ decide + bind |
| Progress 4 · Neugeschäft Q2 CHF 82'000 82% | **DBX** | measuresnapshot (`externalSystem` = Abschluss-/Provisionssystem) | ⚠ add measure row |
| Disclaimer | STATIC | — | ✅ |

## Tab · Tagesplan (KI)

| Visual | Class | Source | Status |
| --- | --- | --- | --- |
| "Ihr steuerbarer Tagesplan" text | STATIC | — | ✅ |
| Geplante Aktivitäten (6) | **CRM** | activity count / NBA plan | ⚠ derive |
| erwartete Abschlüsse (2.0) | **DBX** | propensity → expected closes | ⚠ measuresnapshot |
| Empfohlener Fokus — title / account | NBA+CRM | `crmshow_nextbestaction` (rank 1) + Account | ⚠ **sourced from `kpis.empfohlenerFokus`, should be `nba.json`** |
| Vorschlag badge / Aktiv badge | NBA | nextbestaction status | ⚠ from NBA |
| Warum jetzt (rationale) | NBA | `crmshow_nextbestaction.rationale` | ⚠ from NBA |
| Woher stammt das? (3 sources) | NBA | `crmshow_nbaprovenance` → external systems | ⚠ from NBA provenance |
| Top-Lead / Kanal / Wirkt auf / Ihr Nutzen | NBA+CRM | nextbestaction + Lead/Account | ⚠ from NBA |
| AI-Score (78% / 99) | **DBX** | propensity | (implied in rationale) |
| Action buttons | write-back | → CRM mutation via action layer | n/a |
| KI-unterstützt | RAI | disclosure | ✅ |

## Tab · Meine Leads

| Visual | Class | Source | Status |
| --- | --- | --- | --- |
| Lead rows (Lead / Kunde / Kanal / Urgency / SLA / Status) | **CRM** | Lead + Account | ✅ `leads.json` |
| Auto-Gruppe cluster | **CRM** | LeadCluster | ✅ `leads.json` (`leadCluster`) |
| Priorität score (99 / 87 / 81 …) | **DBX** | propensity surfaced on the lead (`msdyn_leadscore` / measure) | ✅ carried on `leads.json.score` |

## Tab · Termine & Aufgaben

| Visual | Class | Source | Status |
| --- | --- | --- | --- |
| Termine heute | **CRM** | appointment | ✅ `activities.json` |
| Offene Aufgaben | **CRM** | task | ✅ `activities.json` |

## Tab · Offene Fälle

| Visual | Class | Source | Status |
| --- | --- | --- | --- |
| Cases (Fall-ID / Typ / Kunde / Betreff / Kanal / Status / SLA) | **CRM** | `crmshow_claimprojection` (Schaden) · Case/incident (Anliegen) — external ref to claims-admin | ✅ `claims.json` |

## Tab · Copilot

| Visual | Class | Source | Status |
| --- | --- | --- | --- |
| NBA cards (category / title / rationale / disclosure / action) | NBA | `crmshow_nextbestaction` (+ provenance) | ✅ `nba.json` |
| Score behind card | **DBX** | propensity | ✅ `nba.json.score` |

## Interactions & write-backs

> Effect: **NAV** navigate/open (read-only) · **READ** fetch/generate context · **WRITE** mutate via the schema-validated action layer (free-text model output never writes to Dataverse directly — [docs/AI.md](../../../../docs/AI.md)) · **LOCAL** UI-only state.
> Guardrail: *agents recommend, humans decide* ([ADR-0014](../../../../docs/adr/ADR-0014-agents-advisory-by-design.md)). Accept / edit / dismiss **is** the learning signal. No autonomous outbound send; human approval before external comms, quote/pricing, or case close.

### Empfohlener Fokus — Haushalt Brunner (the flagship decision point)

| Button | What it does | Effect | Data operation | HITL / guardrail |
| --- | --- | --- | --- | --- |
| **Anrufen** (accept · Kanal = Click-to-call) | Acts on the recommendation — starts the call | NAV+WRITE | telephony click-to-call + log a `phonecall` activity on the Lead/Contact | human places the call; no auto-send |
| **Vorbereiten** (primary) | Opens the 360° meeting-prep brief for the call | READ/NAV | read Account/Lead/Policy/Claim 360; optional AI prep summary (grounded + disclosed) | prep only, no mutation |
| **Anpassen** | Edit the proposal (channel, timing, scope) before acting | WRITE (on confirm) | update `crmshow_nextbestaction` (edited) — the **edit** branch | human edits before commit |
| **Kundenkontext öffnen** | Navigate to the household 360 | NAV | `Xrm.Navigation` → Account (Haushalt Brunner) | read-only |
| **Später planen** | Snooze / schedule for later | WRITE | `crmshow_nextbestaction.status = Snoozed` (+ snoozeUntil) or create a follow-up `task` | defers, not dismiss |
| **Vorschlag verwerfen** | Dismiss the recommendation | WRITE | `crmshow_nextbestaction.status = Dismissed` (+ reason) — the **dismiss** branch → learning signal | explicit human rejection |

_Harness state:_ all five render but are **no-ops** — the NAV/WRITE targets are DEV-gated on the Dataverse action layer + `Xrm` context.

### Other interactive elements

| Element | Action | Effect | Data operation | Harness state |
| --- | --- | --- | --- | --- |
| Tabs (5) | switch view | LOCAL | selected-tab state | ✅ works |
| Meine Leads · lead / customer link | open record | NAV | Lead form / Household 360 | ⚠ styled link, no nav |
| Meine Leads · status | change lead status | WRITE | `lead.statuscode` via action layer | ⚠ shown as badge (mockup = inline dropdown) |
| Meine Leads · Bündeln | bundle the 3 Brunner leads into one conversation | WRITE | LeadCluster link | ⚠ not implemented (mockup has it) |
| Termine · Vorbereiten | open meeting prep | READ/NAV | appointment 360 | ⚠ button renders, no-op |
| Termine / Aufgaben · Add | create activity | WRITE | create `appointment` / `task` | ⚠ not implemented |
| Offene Fälle · Fall-ID link | open case | NAV | `crmshow_claimprojection` / incident | ⚠ styled link, no nav |
| Copilot card · Anrufen / Termin öffnen / Öffnen | act on NBA | NAV+WRITE | call / open / navigate | ⚠ button renders, no-op |
| KPI & progress cards · drill | drill to detail | NAV | leads / measure detail | ⚠ static (mockup drills) |

## Per-tab presentation & view modes

How each tab lets the advisor *shape* the data (view modes, filters, bulk actions) — from the mockup ground truth. Only **Meine Leads** has multiple view modes.

### Tagesplan (KI) — single view
- Content: "Ihr steuerbarer Tagesplan" + 2 stats + **Empfohlener Fokus** card. (Older mockup also had a drag-to-reorder ranked plan table.)
- My PCF: ✅ Empfohlener Fokus · ⚠ no ranked plan table / reorder.

### Meine Leads — 3 view modes + filters + bulk (the rich tab)
- **View switch** (segmented): **Liste** (table) · **Board** (kanban grouped by household cluster; drag/drop; *Splitten* / *Live-Bündelung*) · **Cockpit** (cluster-form cards: mini-lead list + *Wirkt auf* + *Leads bündeln* / *360° öffnen*).
- **View actions**: *Top 10 nach Priorität* (top-N by AI score) · *Ansicht speichern* (persist personal view: auto-grouping + column filters).
- **Column filters** (4): Kunde / Konto (text → account) · Kanal (Online/Telefon/Termin/Kampagne → `lead.channel`) · Status (Neu/In Arbeit/Qualifiziert/Gebündelt/Geplant/Geschlossen → `lead.statuscode`) · Kampagne / Quelle (Online-Offerte/Vertragsablauf/Advisory Appointment/Vorsorge 25 → `lead` source/campaign).
- **Selection / bulk bar**: multi-select → *Zuweisen an* (Rahel Moser / Thomas Vogt / Sina Keller / Pool Round-Robin / Makler-Desk) → *Zuweisen* (WRITE `lead.ownerid`) · *Auswahl aufheben*.
- **Live-Bündelung modal**: the “wow” moment — KI groups related leads in real time and suppresses double-contacts (LeadCluster).
- Data: CRM (Lead + LeadCluster + Account) + DBX (AI score).
- My PCF: ✅ **Liste** only (table + cluster). ⚠ missing Board, Cockpit, view-actions, 4 filters, bulk-reassign, Live-Bündelung.

### Termine & Aufgaben — single view
- Content: *Termine heute* (appointment list + *Vorbereiten* + add) · *Offene Aufgaben* (task table).
- My PCF: ✅ both lists · ⚠ no add-activity buttons, no meeting-prep drawer.

### Offene Fälle — single view
- Content: *Anliegen & Schäden* table (Fall-ID / Typ / Kunde / Betreff / Kanal / Status / SLA).
- My PCF: ✅ table · ⚠ no type filter / drill.

### Copilot — single view
- Content: NBA cards (Dringend/Risiko/Chance/Retention/Insight) + **alert row** (−Pp / überfällig / Top-Lead) + **Tageszusammenfassung** (day summary).
- My PCF: ✅ NBA cards · ⚠ no alert row, no day summary.

## Parity gaps (to close before Dataverse binding)

1. **CRM-derived counts are hardcoded.** Arbeitsvorrat KPIs 1–3, "Geplante Aktivitäten" should be **derived from the CRM fixtures** (`leads`/`activities`) via selectors — same pattern as `headerKpis` — not literals in `kpis.ts`.
2. **Databricks measures are hardcoded.** KPI 5–6, all 4 progress bars, the hero efficiency stats and "erwartete Abschlüsse" are DBX measures — they should bind to **`crmshow_measuresnapshot`** (`measures.json`). `Conversion 28` already exists there; the rest need advisor-scoped measure rows.
3. **Empfohlener Fokus is hand-authored.** The flagship card should be sourced from the **top-ranked `crmshow_nextbestaction`** (`nba.json` rank 1 = Brunner) + its `crmshow_nbaprovenance`, not `kpis.empfohlenerFokus`.
4. **No Quote/Opportunity fixture.** "Angebote nachfassen (4)" needs a Quote/Opportunity source that does not exist in the Phase-5 fixtures yet.
5. **Contract note.** Advisor-scoped measures need a `subjectType` the measure-snapshot contract doesn't have (`advisor`/`user`); today it stops at `ga`. Either add `advisor` to the contract enum or scope advisor KPIs under `ga` + a sub-key.
6. **Interaction layer not wired.** Every action button renders but is a no-op in the harness. Real effects (NAV via `Xrm`, WRITE via the schema-validated action layer) are DEV-gated. The accept / edit / dismiss branches on the NBA are the learning-loop signal (ADR-0014) and must never be autonomous. Also missing vs the mockup: inline lead-status dropdown, Bündeln, add-activity buttons, KPI drill, and the meeting-prep drawer.
7. **Presentation / view modes not built.** **Meine Leads** ships only the Liste — the Board + Cockpit view modes, the 4 column filters, *Top 10 / Ansicht speichern*, the bulk-reassign selection bar, and the Live-Bündelung modal are missing. **Copilot** is missing the alert row + Tageszusammenfassung. These are the biggest remaining fidelity items.
