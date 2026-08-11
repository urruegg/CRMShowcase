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

## Parity gaps (to close before Dataverse binding)

1. **CRM-derived counts are hardcoded.** Arbeitsvorrat KPIs 1–3, "Geplante Aktivitäten" should be **derived from the CRM fixtures** (`leads`/`activities`) via selectors — same pattern as `headerKpis` — not literals in `kpis.ts`.
2. **Databricks measures are hardcoded.** KPI 5–6, all 4 progress bars, the hero efficiency stats and "erwartete Abschlüsse" are DBX measures — they should bind to **`crmshow_measuresnapshot`** (`measures.json`). `Conversion 28` already exists there; the rest need advisor-scoped measure rows.
3. **Empfohlener Fokus is hand-authored.** The flagship card should be sourced from the **top-ranked `crmshow_nextbestaction`** (`nba.json` rank 1 = Brunner) + its `crmshow_nbaprovenance`, not `kpis.empfohlenerFokus`.
4. **No Quote/Opportunity fixture.** "Angebote nachfassen (4)" needs a Quote/Opportunity source that does not exist in the Phase-5 fixtures yet.
5. **Contract note.** Advisor-scoped measures need a `subjectType` the measure-snapshot contract doesn't have (`advisor`/`user`); today it stops at `ga`. Either add `advisor` to the contract enum or scope advisor KPIs under `ga` + a sub-key.
