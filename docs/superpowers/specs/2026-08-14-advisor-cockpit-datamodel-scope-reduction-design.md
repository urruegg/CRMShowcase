# Sprint-003 — Advisor Cockpit data-model scope reduction

| Field | Value |
| --- | --- |
| **Status** | Draft v2 — pending owner review (produced autonomously; see "Open questions") |
| **Date** | 2026-08-14 |
| **Deciders** | Repo owner (async review pending) · cross-checked against the AG-E-03 Enterprise Architect and AG-E-08 Dataverse Modeler agent rule files (independent review round, see "Correction note") |
| **Related** | [ADR-0019](../../adr/ADR-0019-provisional-insurance-data-model-shape.md) · [ADR-0006](../../adr/ADR-0006-account-centre-of-gravity.md) · [ADR-0007](../../adr/ADR-0007-portfolio-at-account.md) · [ADR-0008](../../adr/ADR-0008-thin-crm-over-systems-of-record.md) · [ADR-0009](../../adr/ADR-0009-lead-as-interest-on-existing-person.md) · [ADR-0010](../../adr/ADR-0010-consent-per-contact-per-channel.md) · [mobiliar-data-model-extension](../../design/mobiliar-data-model-extension.md) · [2026-08-11-advisor-cockpit-design](./2026-08-11-advisor-cockpit-design.md) · [plan](../plans/2026-08-11-advisor-cockpit.md) · [STATUS](../sprints/sprint-003-advisor-cockpit/STATUS.md) |
| **Licence** | 🧩 configuration / own build |
| **Upgrade impact** | Low — every reduction below is a pure deferral (additive columns/tables later), not a breaking redesign |
| **Maturity** | Design addendum. Does not change any approved runtime AI capability. |

## Correction note (read this first)

The first draft of this document claimed "nothing is built yet" for the whole
data model. That was **wrong for 3 tables**: an independent review pass (run
against this draft, in the personas of the repo's own Enterprise Architect and
Dataverse Modeler agent rules) found that
[`solution/schema/insurance-foundation.json`](../../../solution/schema/insurance-foundation.json)
already contains a **complete, fully-localized, already-reviewed** schema
(columns, alternate keys, date-order business rules, admin/overlap views,
forms, and a security role) for three tables: `crmshow_accountcontactrole`,
`crmshow_policyprojection`, and `crmshow_policypartyrole`. That finding was
verified directly against the file (line 327 onward) before this revision was
written. This version corrects course: those three tables are **kept exactly
as already designed**, not simplified — simplifying finished, reviewed work
would be a net loss, not a scope reduction. The reduction below now applies
only to the genuinely unbuilt pieces, plus a small number of new gaps the
fixture cross-check surfaced that the original Phase 2/3 plan missed entirely.

## Owner-provided core-system context (2026-08-14)

Mid-review, the owner supplied the real core-system landscape (chat-captured;
not yet a written intake artefact). Summary, with what it changed here:

- **ARO** (Arbeits-Organisations-System) masters insurance offers, contracts,
  and claims — including general "Anliegen" case work. This is almost
  certainly the real system behind the fixtures' `"policy-admin-mock"`/
  `"claims-admin-mock"` placeholder names, and confirms both Schaden and
  Anliegen originate from the same system.
- **The real integration mechanism (virtual tables vs. Kafka/Confluent Cloud
  event-hub) against ARO is a separate, undecided design discussion.** For
  this demo, both are deliberately simulated **inside Dataverse with minimum
  effort** rather than building live integration — see the resolved
  "Anliegen" flag below.
- **PDV** (Partner Daten Verwaltung), hosted on the system referred to as
  "Host", masters party/customer identity. The owner confirmed a concrete
  mastership-lifecycle pattern: a new Account/Contact is born **CRM-owned**
  (prospect stage); once a contract exists, mastership **switches to PDV**
  and data syncs back to CRM. This is modeled below as three new fields on
  both `account` and `contact`, and is significant enough to also get a short
  note in [ADR-0008](../../adr/ADR-0008-thin-crm-over-systems-of-record.md)
  (added alongside this doc) since it extends the thin-CRM principle from
  Policy/Claim/Quote to party identity.
- **Kafka on Confluent Cloud** is the event backbone across these systems —
  noted as evidence in [ADR-0019](../../adr/ADR-0019-provisional-insurance-data-model-shape.md)
  (added alongside this doc); it does not force a mechanism decision.

## Purpose

Sprint-003's two remaining data-model streams — **#57 foundational tables**
(slices 1–5, DESIGN-SENSITIVE) and **#58 cockpit tables** — are the last big
unbuilt piece of the sprint. Three of the foundational tables
(`crmshow_accountcontactrole`, `crmshow_policyprojection`,
`crmshow_policypartyrole`) already have a complete, reviewed, fully-localized
schema committed in `solution/schema/insurance-foundation.json`; the rest
(`crmshow_accountownership`, `crmshow_leadcluster`, `crmshow_claimprojection`,
`crmshow_claimpartyrole`, `crmshow_consent`, the cockpit tables, and
`crmshow_measuresnapshot`) are genuinely unbuilt and still shaped only by the
aspirational target in ADR-0019 Option C / `mobiliar-data-model-extension.md`.
This addendum proposes: **keep the already-authored tables exactly as
designed**, close two small gaps they have against the committed seed fixtures
(the productline/premium fields on `crmshow_policyprojection`), and for the
genuinely unbuilt remainder, build only what the **already-committed** seed
fixtures (`data/scenarios/advisor-cockpit/*.json`) and the two merged PCFs
actually exercise — deferring the rest to explicitly named follow-up slices.

This is not a reversal of ADR-0019. ADR-0019 already says: *"No insurance-context
entity is persisted merely because it exists in CDM... only Layer 1 foundations
and explicitly justified Layer 2 projections may enter the Dataverse solution."*
The finding below is that the original Phase 2/3 task breakdown included a few
undesigned tables that don't yet clear that bar — this addendum applies
ADR-0019's own discipline more strictly, using the fixtures as the "named
journey" evidence, while leaving already-justified, already-built work alone.

## Why now

1. **Most of it is genuinely unbuilt.** `solution/core/datamodel/` and
   `solution/core/integration/` each contain only an empty `Other/` folder —
   no `Entities/` directory exists, so none of this is yet exported to source
   or (as far as this review can tell from source control) live in DEV.
   **Exception:** the schema *contract* for `crmshow_accountcontactrole`,
   `crmshow_policyprojection`, and `crmshow_policypartyrole` already exists,
   fully designed, in `insurance-foundation.json` — this is very likely the
   "3 tables" STATUS.md's 2026-08-12 entry describes CD-DEV as already
   authoring. Whether they're physically live in DEV yet should be confirmed
   before implementation, but the *design* is settled either way.
2. **Neither PCF binds to Dataverse yet.** Both `advisorcockpit-pcf` (#62) and
   `salesleaderdashboard-pcf` (#63) handover packets explicitly scope
   "Binding to Dataverse is a later DEV-gated step (not in this stream)" — so
   closing gaps or simplifying the *unbuilt* part of the schema now doesn't
   touch any merged code.
3. **The DEV-bootstrap chain already burned real time on metadata mechanics**,
   not business logic: #86 (Customer-relationship **cascade** defaults on a
   polymorphic `Customer`-type field), #92 (column-level audit on lookups),
   #85/#88/#89/#90/#91 (metadata-query edge cases). Notably, **plain alternate
   keys on plain text columns were never the source of any of these bugs** —
   `crmshow_policyprojection`'s existing `externalsystem`+`externalid`
   alternate key hasn't caused any incident. The actual risk area is
   `Customer`-type polymorphic relationships (used only by
   `crmshow_policypartyrole.crmshow_partyid`), and #86 already fixed the
   publisher's handling of that going forward. This changes an earlier draft's
   over-broad conclusion — see the corrected recommendations below.
4. **The seed fixtures are already a factual contract.** They were written
   and merged (PR #68) before the remaining tables exist, and
   `data/scenarios/advisor-cockpit/README.md` says target entity names are
   "provisional until Phases 1–3 author the tables" — this is the moment to
   reconcile the two before, not after, authoring the rest in DEV.

## Evidence: what the committed fixtures actually use

Cross-checked all 7 fixture files against both the Phase 2/3 planned schema
and the **already-authored** contract in `insurance-foundation.json`:

| Fixture | Target | What the rows actually contain |
| --- | --- | --- |
| `accounts-contacts.json` | `account` / `contact` / `crmshow_accountcontactrole` | Account: flat fields only (`accountType`, `segment`, `region`, `owner` **as a plain name string** → native `ownerid`, `city`/`postalCode` → native address fields, no schema work needed). Contact: `role` as a **plain string per contact** ("Haushaltvorstand"/"Geschäftsführer"/"Inhaber") that needs mapping onto the *already-defined* `crmshow_accountcontactroletype` values (HouseholdMember/BusinessContact/BrokerContact/DecisionMaker/AuthorizedRepresentative/BeneficialOwner) — **flagged below, not obvious**; `consentEmail`/`consentPhone` as two booleans, no purpose/source/capturedOn dimension anywhere (no consent table exists in the contract at all). |
| `leads.json` | `lead` | `leadCluster` as a **name string** (or `null`) → minimal `crmshow_leadcluster`. **Also present and NOT covered by any planned schema:** `channel`, `priority` (Hoch/Mittel), `sla` ("4h"/"Heute"/"Morgen" — a display label), `score` (68–99), `status` (Primär/Verknüpfen/Gebündelt/In Arbeit/Neu — a cluster/queue position, distinct from native lead `statuscode`), `source`. This is a **real gap the original Phase-2 plan missed entirely** — flagged below as a new native-`lead`-extension row. |
| `policies.json` | `crmshow_policyprojection` (**already authored**) | Every field maps cleanly **except**: `product` (a source-specific display name like "Motorfahrzeug Flotte", more granular than the `crmshow_productline` choice's 5 values — needs an additive column) and `premiumChf` — which directly **conflicts** with the already-authored contract's `excludedConcepts: ["premium", ...]`. **Flagged as the top open question.** No party/role reference in any row — `crmshow_policypartyrole` (already authored) is simply not seeded yet, not unneeded. |
| `claims.json` | `crmshow_claimprojection` (not yet authored) | Contains **both** `"caseType": "Schaden"` (an actual claim) and `"caseType": "Anliegen"` (a general concern, not a claim) rows, Account-scoped only. Recommendation revised after review: **do not** fold "Anliegen" into `crmshow_claimprojection` — use native `incident` (Case) for it instead (see Flag 2). No party-role reference in any row — `crmshow_claimpartyrole` genuinely has zero fixture usage and zero prior art. |
| `nba.json` | `crmshow_nextbestaction` + `crmshow_nbaprovenance` (not yet authored) | Fields actually present: `rank`, `category` (Dringend/Risiko/Chance/Retention/Insight — **not in the Phase-1 choice list at all**), `title`, `accountKey`, `leadKey` (nullable — **no Contact reference anywhere**), `channel`, `score`, `status`, `disclosure`, `rationale`. `timewindow`/`effect`/`benefit`/`humandecision` from the plan **appear in zero rows**. Provenance is `{source, ref}` pairs, and at least one `ref` (`"GA-Bern-Mittelland\|Conversion\|2026-06-30"`) is a **composite business key, not a row GUID** — confirms a typed lookup couldn't represent this even if we wanted one. |
| `activities.json` | native `appointment`/`task` | Native activity types; only a `channel` text field would be new. No custom table. |
| `measures.json` | `crmshow_measuresnapshot` (not yet authored) | Matches the already-committed contract (`api/advisor-cockpit/measure-snapshot.schema.json`) exactly — no change needed. |

**No fixture, anywhere, exercises:** `crmshow_accountownership`, `crmshow_claimpartyrole`,
or an Offer/Quote projection. `crmshow_policypartyrole` **is** exercised by ADR-0007's
model (policyholder role) even though no fixture row currently populates it —
that's a seed-data gap, not a schema gap (see below).

## Approaches considered

### Approach A — Trim depth only, keep full breadth
Build all originally-planned custom tables and all native extensions
(including the ones with zero fixture evidence), stripping only alternate
keys and effective-dating *validation*.

- **Pros:** Zero divergence from `mobiliar-data-model-extension.md` as
  written; every future scenario already has a home.
- **Cons:** Still means authoring/testing `crmshow_accountownership`,
  `crmshow_claimpartyrole`, and a `quote` extension with **zero** sample data
  or PCF surface exercising them — exactly the speculative schema the ask is
  trying to avoid. Also, "strip alternate keys" turns out to be the wrong
  lever (see "Why now" #3) — it would mean *undoing* a working, already-built
  alternate key on `crmshow_policyprojection` for no benefit.

### Approach B — Evidence-driven minimal slice (recommended)
Keep the 3 already-authored tables exactly as designed. For the genuinely
unbuilt remainder, build only what the 7 committed fixtures exercise; close
the 2 small gaps the fixtures reveal against the already-authored
`crmshow_policyprojection`; defer the rest to named follow-up slices.

- **Pros:** Every table/field this slice ships has a matching sample-data row
  *and* a PCF surface reading it — no speculative schema, and no reopening of
  finished, reviewed work. Smallest realistic DEV-authoring surface for the
  *new* tables. Fully additive later: every deferral is a new nullable column
  or a new table, never a breaking change.
- **Cons:** Needs an explicit ADR-0019 note so the deferrals aren't silently
  lost, and needs explicit sign-off on two items that touch existing
  architecture decisions: the Consent shape (close to the ADR-0010
  non-negotiable position) and the `excludedConcepts` premium exclusion on
  `crmshow_policyprojection` (an existing, deliberate boundary) — both
  flagged below.

### Approach C — Radical minimal: one generic projection table
Replace `crmshow_policyprojection` / `crmshow_claimprojection` /
`crmshow_measuresnapshot` with a single generic `crmshow_externalprojection`
table plus a `recordtype` discriminator and generic value columns.

- **Pros:** Fewest possible tables (1 instead of 3).
- **Cons:** Directly contradicts the Dataverse Modeler agent's standing rule —
  *"Invent a table when a CDM entity already covers the concept... is a
  review reject."* Loses typed, reportable columns (no clean "premium by
  product line" view), and works against the metadata-completeness rule that
  every column needs a precise, non-generic business-meaning description.
  **Not recommended.**

**Recommendation: Approach B.**

## The reduced target schema

### Already-authored — keep exactly as designed, close 2 gaps

| Table | Status | Gap vs. fixtures | Recommendation |
| --- | --- | --- | --- |
| `crmshow_accountcontactrole` | Fully authored (columns, alternate key, date-order rule, overlap view, admin form) | Fixture's free-text `role` ("Haushaltvorstand"/"Geschäftsführer"/"Inhaber") needs mapping onto the existing `crmshow_accountcontactroletype` values (HouseholdMember/BusinessContact/BrokerContact/DecisionMaker/AuthorizedRepresentative/BeneficialOwner) | No schema change. Value-mapping decision only — **flagged below**. |
| `crmshow_policyprojection` | Fully authored (columns, alternate key, date-order rule, admin view, admin form, `excludedConcepts` boundary) | (1) No column carries the fixture's source-specific `product` display name (e.g. "Motorfahrzeug Flotte"), more granular than the `crmshow_productline` choice. (2) `premiumChf` directly conflicts with the existing `excludedConcepts: ["premium", ...]` boundary. | (1) **Add** two small additive columns: `crmshow_productline` (GlobalChoice, reusing the already-defined `crmshow_productline` choice — distinct purpose from the existing `crmshow_lineofbusinesscode` text field, which is a raw source code, not a CRM-facing category) and `crmshow_productname` (Text, optional, SourceProjection) for the specific source display name. (2) **Flagged below as the top open question** — do not silently override `excludedConcepts`. |
| `crmshow_policypartyrole` | Fully authored (columns, alternate key, date-order rule, overlap view, admin form) | No fixture currently populates it — this is a **seed-data gap, not a schema gap**. | **Use it now**, don't defer it: extend the seed loader to write one `Policyholder` role row per seeded policy (via the existing `Customer`-type `crmshow_partyid`, pointing at the household/business's primary contact). Exercises finished, reviewed work instead of leaving it dark. |

### Genuinely unbuilt — build the minimal evidence-driven shape

| Table | Fields (this slice) | Relationships | Notes |
| --- | --- | --- | --- |
| `crmshow_leadcluster` | `crmshow_name` (text) | Lead 1:N | Minimal; matches fixture exactly. |
| `crmshow_claimprojection` | `crmshow_externalid`, `crmshow_externalsystem` (text, **alternate key on both** — mirrors the already-working pattern on `crmshow_policyprojection`), `crmshow_productline` (choice, existing), `crmshow_title` (text), `crmshow_channel` (text), `crmshow_status` (text), `crmshow_openeddate` (date), `crmshow_slahours` (whole, optional) | Account N:1 | **Claims only** (`"caseType":"Schaden"` rows) — see the "Anliegen" flag below for why the concern rows go elsewhere. `crmshow_claimpartyrole` deferred entirely (zero fixture use, zero prior art). |
| `crmshow_nextbestaction` | `crmshow_title`, `crmshow_rationale` (multiline), `crmshow_channel` (choice, existing), `crmshow_category` (choice — **new**: Dringend/Risiko/Chance/Retention/Insight), `crmshow_aiscore` (whole 0–100), `crmshow_rank` (whole), `crmshow_status` (choice, existing), `crmshow_disclosure` (text, default "AI-assisted") | Account N:1 (required), Lead N:1 (optional) | Contact lookup dropped (no fixture row uses it — also reduces exposure to the multi-lookup surface the "one `create_table` call" gotcha warns about). `crmshow_timewindow`/`effect`/`benefit`/`humandecision` deferred — none populated by any current fixture; `humandecision` in particular matters for the ADR-0014 learning-loop story and must return as a **tracked Definition-of-Done item**, not just a prose promise. |
| `crmshow_nbaprovenance` | `crmshow_sourcetype` (text/small choice: lead/measure/task/claim/policy/activity), `crmshow_reference` (text, natural/business key) | `crmshow_nextbestaction` N:1 | Confirmed sound, not just acceptable: at least one real fixture provenance reference is a **composite business key** (`"GA-Bern-Mittelland\|Conversion\|2026-06-30"`), not a row GUID — a typed lookup could not represent it. Dataverse also has no native 6-way polymorphic lookup; plain text is the right call, likely permanently. |
| `crmshow_measuresnapshot` | As already contracted in `api/advisor-cockpit/measure-snapshot.schema.json` (`subject`, `subjecttype`, `metric`, `region`, `productline`, `asofdate`, `value`, `unit`, `externalsystem`), **alternate key on subject+metric+asofdate+region+productline** (kept — see "Why now" #3) | none (flat) | Matches the Phase-4 plan as originally written. |

### Native extensions — `lead` needs more than originally scoped

`leads.json` carries fields the original Phase-2 plan never mentioned at all
(only `crmshow_leadcluster` was scoped). Closing this gap:

| Field | Source | Recommendation |
| --- | --- | --- |
| `leadCluster` | fixture | `crmshow_leadcluster` lookup (as already planned). |
| `priority` (Hoch/Mittel) | fixture | Native `prioritycode` — no new column. |
| `source` (Online Journey/Retention/Appointment/...) | fixture | Native `leadsourcecode` — extend its option set rather than adding a custom field. |
| `channel`, `sla` (display label, e.g. "4h"/"Heute"), `score` (68–99) | fixture | New: `crmshow_channel` (text), `crmshow_slalabel` (text — a **display label, not a computed SLA engine**), `crmshow_score` (whole). |
| `status` (Primär/Verknüpfen/Gebündelt/In Arbeit/Neu — a cluster/queue position, distinct from native `statuscode`) | fixture | New choice, name TBD (e.g. `crmshow_leadqueuestatus`) — needs an owner naming/value decision, not a technical one — **flagged below**. |

Also native `account`/`contact` extensions (`crmshow_accounttype`,
`crmshow_contactlifecyclestage`, both already defined) plus
`crmshow_consentemail`/`crmshow_consentphone` (new — see the Consent flag
below) are unchanged from the first draft.

### Native extensions — Account/Contact mastership lifecycle (new, owner-directed)

Not from a fixture — directly specified by the owner (see "Owner-provided
core-system context" above). A new Account/Contact is born CRM-owned
(prospect stage, per the existing `crmshow_contactlifecyclestage`); once a
contract exists, mastership switches to the core system (PDV) and data syncs
back to CRM. On **both** `account` and `contact`:

| Field | Type | Notes |
| --- | --- | --- |
| `crmshow_mastershipstatus` | GlobalChoice (**new**: CRMOwned / SourceMastered) | Required; defaults to `CRMOwned` at creation. |
| `crmshow_mastersystem` | GlobalChoice (**new**: PDV, extensible later) | Optional; blank while CRMOwned, populated once `SourceMastered`. |
| `crmshow_lastsyncedon` | DateTime (UTC) | Optional; blank until the first sync from the master system. |

**Placement — owner-confirmed (2026-08-14):** these 3 fields live on the
**standard/main form** of `account` and `contact` (out-of-box Dataverse form,
grouped as technical integration information), **not** wired into the
Advisor Cockpit PCF. They're for whoever looks at the record directly
(steward/admin visibility of "who masters this right now"), not part of the
advisor-facing cockpit surface — that keeps this slice's PCF scope untouched
and answers the earlier open question about whether "multi-source at runtime"
needed a PCF change: for now, it doesn't.

Cross-cutting beyond this sprint — also noted in
[ADR-0008](../../adr/ADR-0008-thin-crm-over-systems-of-record.md) since it
extends the thin-CRM principle from Policy/Claim/Quote to party identity.

### Deferred entirely this slice (no table authored; add when a named scenario needs it)

| Deferred item | Revisit trigger |
| --- | --- |
| `crmshow_accountownership` (dated GA/territory/broker-manager) | A GA-handover or territory-reassignment scenario is actually being built (ADR-0011/0013 territory). Meanwhile `ownerid` + `crmshow_region` on Account cover today's "owner"/"region" display. |
| `crmshow_claimpartyrole` | A scenario needs to show *who specifically* (beyond the Account) is claimant/injured-party on a given claim. (`crmshow_policypartyrole` is **not** deferred — see above.) |
| Native `quote` external-key extension + `opportunity` correlation id | An "Offers" tab actually renders sample data — no fixture references a Quote/Offer today even though it's in the Phase-9 nav plan. |
| Full `crmshow_consent` (per contact · channel · **purpose** · source · capturedOn) | A real consent-gated send/campaign scenario needs the purpose dimension — see the Consent flag below. |

## Small addendum needed to the already-merged foundation choices (#56)

Gaps surfaced by the fixtures that weren't in the original Phase-1 list —
additive only, does not reopen #56:

- **Add** `crmshow_nbacategory`: Dringend / Risiko / Chance / Retention /
  Insight (4 languages).
- **Add** a new lead-queue-status choice (name TBD, e.g. `crmshow_leadqueuestatus`):
  Neu / In Arbeit / Gebündelt / Verknüpfen / Primär (4 languages) — **flagged
  below**, this is a naming/value decision, not a technical one.
- **Review** `crmshow_nbachannel` values against fixture usage — `"Anruf"`
  maps cleanly to `Call`; `"Termin"` and `"Aufgabe"` need a mapping decision
  (map to existing values or add one); `"Insight"` belongs in the new
  `crmshow_nbacategory` field, not channel.
- No new `crmshow_casetype` choice is needed — see the "Anliegen" flag below
  (the first draft proposed this; corrected after review).
- **Add** `crmshow_mastershipstatus`: CRMOwned / SourceMastered (4 languages)
  — new, for the Account/Contact mastership lifecycle above.
- **Add** `crmshow_mastersystem`: PDV (4 languages, extensible as more source
  systems are named) — new, same purpose.

## Flagged for explicit owner confirmation before implementation

1. **Premium vs. the existing `excludedConcepts` boundary.**
   `crmshow_policyprojection` is already authored with
   `"excludedConcepts":["premium","tariff","underwriting","coverageLimit","paymentBalance"]`
   — a deliberate ADR-0008-aligned boundary against pulling financial
   administration into CRM. The seed fixture needs `premiumChf` displayed on
   the cockpit. **Recommendation:** narrow the exclusion to drop only
   "premium" (keep tariff/underwriting/coverageLimit/paymentBalance excluded —
   those really are calculation/administration concepts; premium here is not),
   and add `crmshow_annualpremiumamount` (Money, optional, `SourceProjection`)
   with metadata explicit that it is "a source-reported display amount for CRM
   context; CRM does not calculate, quote, or administer premium." This
   reverses part of an already-accepted exclusion list and should not ship
   without a look from whoever plays the Enterprise Architect role.
2. **"Anliegen" (non-claim concern) handling — RESOLVED 2026-08-14.** The
   first draft of this doc proposed folding "Anliegen" into
   `crmshow_claimprojection` via a new discriminator. Independent review
   objected: native `incident` is zero-authoring-cost (already OOB) versus
   adding a choice + discriminator to a CDM-`Claim`-aligned table,
   `mobiliar-data-model-extension.md` already assigns this split ("Rebuild in
   `crmshow_Service` on native Case plus ClaimProjection"), and mixing the two
   creates a permanent reporting-correctness trap (every "claims by product
   line" view must remember to exclude non-claim rows). **Owner-confirmed:**
   use native `incident` for `ANL-204902`-style rows, keep `crmshow_claimprojection`
   for Schaden as designed — a minimal `crmshow_externalsystem`/`crmshow_externalid`
   pair on `incident` is a small, native-table-only addition, not a new custom
   table. The owner also confirmed both Schaden and Anliegen ultimately
   originate in the same external system (ARO); the real integration
   mechanism (virtual tables vs. Kafka event-hub) is a separate, undecided
   design discussion, and this demo deliberately simulates both inside
   Dataverse with minimum effort rather than building live integration now.
3. **Consent reduction touches a non-negotiable ADR position.**
   `copilot-instructions.md` §2.5 states consent is "per contact, per channel,
   with source and capture date, enforced as a gate" as a position not to
   relitigate without an ADR. This slice ships two plain booleans
   (`crmshow_consentemail`/`crmshow_consentphone`) with no purpose dimension,
   no source, no capture date, and no gate — a real, temporary reduction, not
   a redefinition. Recommend proceeding (nothing in this sprint sends
   anything gated by consent yet), **on condition** that both columns'
   metadata descriptions explicitly state they do **not** implement ADR-0010
   and must never gate a real send — tracked as its own Definition-of-Done
   line, not left to prose.
4. **Value-mapping decisions need a domain call, not a technical one.**
   (a) Contact `role` ("Haushaltvorstand"/"Geschäftsführer"/"Inhaber") →
   `crmshow_accountcontactroletype` (HouseholdMember/BusinessContact/
   BrokerContact/DecisionMaker/AuthorizedRepresentative/BeneficialOwner);
   (b) the new lead-queue-status choice's name and values; (c)
   `crmshow_nbachannel`'s "Termin"/"Aufgabe" fixture values against the
   existing option set.

## Next step (not a design question)

Whether to relabel GitHub issues #57/#58, rewrite `STATUS.md`, or edit
`docs/superpowers/plans/2026-08-11-advisor-cockpit.md` to match this reduced
scope is an implementation-planning step (writing-plans), to happen only
after this design is approved — this doc intentionally leaves the plan and
issues untouched.

## Governance

- This is recorded as a delivery-slice refinement of ADR-0019 Option C, per
  that ADR's own instruction that Layer 2 projections require a named journey
  — see the note added to ADR-0019 alongside this doc. That note explicitly
  discloses that 3 tables are already authored and unaffected, and names the
  journey/source/freshness/reconciliation basis for each newly-justified
  projection (table below).
- Every table/column/choice above — including the newly added ones — still
  ships complete EN/DE/FR/IT metadata labels and non-tautological
  descriptions. **Localization is not a lever this reduction touches**; both
  the Enterprise Architect and Dataverse Modeler agent rules treat it as a
  hard gate ("reject a schema design that cannot demonstrate complete EN
  metadata and reviewable DE/FR/IT translations"), not documentation polish.
- No plug-ins, no Dataverse business rules beyond simple same-record
  date-order checks (already the pattern used on the 3 authored tables), no
  workflows — unchanged from the sprint's existing non-goals.
- CDM alignment is preserved and, for the 3 already-authored tables, was
  already reviewed. Nothing here invents a parallel table where a CDM entity
  fits — the "Anliegen" flag above corrects the one place an earlier draft
  came close to doing that.

| Table | Journey / persona | Source | Freshness | Why not virtual/live | Reconciliation |
| --- | --- | --- | --- | --- | --- |
| `crmshow_claimprojection` | Advisor Cockpit "Anliegen & Schäden" tab, Advisor persona | `claims-admin-mock` (demo stand-in) | Daily seed refresh (demo) | No live claims-admin endpoint in the demo tenant | `externalsystem`+`externalid` alternate key, upsert on seed |
| `crmshow_nextbestaction` / `crmshow_nbaprovenance` | Advisor Cockpit NBA cards, Advisor persona (ADR-0014 advisory) | Copilot NBA agent (deferred, #61) / seed fixtures meanwhile | Real-time once the agent ships; seed-refresh meanwhile | Advisory rows are CRM-authored, not a source projection — N/A | CRM-owned; no reconciliation needed |
| `crmshow_measuresnapshot` | Sales Leader Dashboard, GA/broker-manager persona | Databricks (demo: synthetic fixtures per ADR-0026) | Scheduled/batch (materialized-projection pattern) | Already established in ADR-0026 | Alternate key on subject+metric+asofdate+region+productline |

## Definition of done (this reduced slice)

- [ ] `docs/adr/ADR-0019-provisional-insurance-data-model-shape.md` carries a
      short note pointing to this doc, explicitly naming which 3 tables are
      already authored and unaffected (done alongside this file).
- [ ] Owner has reviewed all 4 flags above, in particular the premium/
      `excludedConcepts` decision.
- [ ] `crmshow_policyprojection` gets its 2 additive columns
      (`crmshow_productline`, `crmshow_productname`) plus the premium
      decision resolved one way or the other.
- [ ] Seed loader extended to write a `Policyholder` `crmshow_policypartyrole`
      row per seeded policy.
- [ ] `crmshow_claimprojection` scoped to Schaden rows only; `ANL-204902`-style
      rows go to native `incident` instead.
- [ ] Genuinely-new tables (`crmshow_leadcluster`, `crmshow_claimprojection`,
      `crmshow_nextbestaction`, `crmshow_nbaprovenance`,
      `crmshow_measuresnapshot`) authored in DEV exactly per the schema above
      — single `create_table` call per table, all lookups included,
      **alternate keys kept** where specified (reversing the first draft's
      "drop alternate keys" call — see "Why now" #3).
- [ ] `crmshow_nbacategory` choice added; new lead-queue-status choice added
      (name/values per the value-mapping flag); `crmshow_nbachannel`
      reviewed/adjusted.
- [ ] `crmshow_mastershipstatus` + `crmshow_mastersystem` choices added;
      `account` and `contact` extended with both plus `crmshow_lastsyncedon`
      (owner-confirmed mastership lifecycle), placed on the **standard form**
      only (technical integration info, not the Advisor Cockpit PCF).
- [ ] The 2 consent columns' metadata descriptions explicitly state they do
      not implement ADR-0010 and must never gate a real send.
- [ ] `crmshow_humandecision` on `crmshow_nextbestaction` tracked as a
      follow-up item triggered by "before the accept/dismiss UI interaction
      ships" — not just a prose promise.
- [ ] Every table/column/choice has complete EN/DE/FR/IT metadata.
- [ ] A dedicated automated metadata-completeness test (non-blank,
      non-duplicate-of-logical-name, no TBD/TODO, all 4 languages present) —
      distinct from the per-table entity-assertion tests.
- [ ] Pester entity-assertion tests per table (existing convention).
- [ ] `pac solution check` — 0 High.
- [ ] Deferred-items table above copied into the backlog (or the relevant
      follow-up issues) so it isn't lost.

## Framework alignment

- **CAF:** Govern (applies ADR-0019's own "named journey" bar more strictly,
  and corrects a draft that would have undone already-governed work) · Plan
  (defers implementation until a fixture/scenario exists).
- **WAF:** Operational Excellence (smaller authoring surface for the
  *genuinely new* tables → fewer metadata-mechanic incidents like #86/#92)
  traded off against Performance Efficiency/richness some future journeys
  will need back (claim party-role granularity, GA/territory history, full
  consent). **Reliability is preserved, not traded away, on the 3
  already-authored tables** — this revision corrects a draft that would have
  dropped a working alternate key and effective-dating for no benefit.
- **Zero Trust:** Unaffected — every projection still carries least-privilege,
  purpose-named fields; nothing here widens access.
- **Responsible AI:** `crmshow_nextbestaction` keeps `crmshow_disclosure` and
  provenance; deferring `crmshow_humandecision` is time-boxed and tracked in
  the Definition of Done, not just prose, so the ADR-0014 learning loop isn't
  silently lost.

## Resolved this round (2026-08-14)

- ✅ Approach B (evidence-driven minimal slice) confirmed as the target.
- ✅ "Anliegen" handling confirmed: native `incident` for Anliegen,
  `crmshow_claimprojection` for Schaden — see the resolved flag above.
- ✅ Kafka/Confluent noted as evidence in ADR-0019 (no mechanism decision
  forced).
- ✅ Account/Contact mastership lifecycle fields confirmed
  (`crmshow_mastershipstatus`, `crmshow_mastersystem`, `crmshow_lastsyncedon`)
  — see the new schema subsection and the ADR-0008 update.

## Addendum: `crmshow_seedkey` on Account (2026-08-14, produced autonomously)

While implementing claims seeding (#60 follow-up, PR #101), found that the
seed loader's own fixture manifest (`Get-FixtureManifest` in
`seed-advisor-cockpit.ps1`, merged in **PR #68**, EXECUTION-ONLY) has
**always** declared `AlternateKey = @('crmshow_seedkey')` for
`accounts-contacts.json` (and also `leads.json`) — but the field itself was
never authored in `insurance-foundation.json`. This is a completion of an
already-approved design intent, not a new decision, so it's implemented
directly (additive, non-controversial) rather than added to "Open questions"
below.

- **Added:** `account.crmshow_seedkey` (Text, optional, maxLength 100,
  `mastership: Configuration` — the same category already used for every
  other natural/idempotency key in this contract, e.g.
  `crmshow_policyprojectionexternalkey`'s columns). Metadata is explicit that
  this is demo/seed-pipeline scaffolding only — never a production business
  field, never shown on a form, never used in a business decision. Contract
  version bumped `1.1.0` → `1.2.0` (additive).
- **Scope deliberately kept narrow:** this unblocks resolving a claims/policy
  fixture's `accountKey` (e.g. `"ACC-BRUNNER"`) to a live Account GUID via a
  plain OData `$filter` query — sufficient for `seed-advisor-cockpit.ps1`'s
  already-built `-AccountKeyMap` parameter (PR #101). It is **not** wired up
  as a true Dataverse alternate key: this contract's `alternateKeys` array
  (used for `crmshow_policyprojectionexternalkey` etc.) is a **custom-table
  ­only** mechanism today — `nativeExtensions` (account/contact/lead/incident)
  have no equivalent schema/pipeline support for declaring an alternate key
  on a native table's own column. Building that is a separable, larger
  pipeline capability, not required to unblock the confirmed problem, and is
  **not** attempted here.
- **Not resolved / explicitly out of scope this round:** the seed manifest
  also references `crmshow_seedkey` on `lead` (native — same missing-pipeline
  gap as account) and on `activitypointer` (native, and not even in this
  contract's `table` enum for native extensions at all — `["account",
  "contact", "lead", "incident"]`) and on the custom
  `crmshow_nextbestaction` table (which, being custom, *could* get a real
  alternate key today via the existing mechanism, but doing so wasn't needed
  to unblock claims/policies and is left for whoever picks up `nba.json`
  seeding). None of `accounts-contacts.json`/`leads.json`/`activities.json`/
  `nba.json` seeding is implemented yet at all (only `Get-FixtureManifest`
  declares their intended shape — no `Get-XUpsertRequests` builder exists for
  any of them), so nothing here regresses a working capability.
- **Still needed as a follow-up, not done here:** a `Get-AccountKeyMap`-style
  resolver in `seed-advisor-cockpit.ps1` that queries
  `GET /accounts?$select=accountid,crmshow_seedkey&$filter=crmshow_seedkey ne null`
  and builds the hashtable PR #101's `-AccountKeyMap` parameter expects.
  Deliberately not added in this PR to avoid touching the already-green,
  already-reviewable `feat/s3-seed-claims-mapping` branch while it's pending
  human merge.

## Open questions for the owner

1. Resolve the premium vs. `excludedConcepts` conflict — narrow the exclusion
   and add a display-only premium column (recommended), or keep the exclusion
   and find another way to satisfy the fixture/mockup?
2. Sign off on the Consent reduction, conditioned on the metadata disclaimer
   described above.
3. Decide the 3 value-mapping questions (contact role codes, new
   lead-queue-status choice name/values, `crmshow_nbachannel` Termin/Aufgabe
   mapping) — or delegate them to whoever plays Dataverse Modeler/CRM Domain
   Expert.
4. Once approved: should the plan doc / `STATUS.md` / issues #57 and #58 be
   rewritten to match this reduced scope (a follow-up writing-plans pass), or
   does the owner want to do that split themselves?
