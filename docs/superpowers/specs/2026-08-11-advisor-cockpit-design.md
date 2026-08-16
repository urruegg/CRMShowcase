# Sprint 3 — Advisor Cockpit (Sales Advisory Cockpit + Sales Leader Dashboard)

| Field | Value |
| --- | --- |
| **Status** | Draft — pending user approval |
| **Date** | 2026-08-11 |
| **Deciders** | Repo owner · AG-E-03 Enterprise Architect · AG-E-08 Dataverse Modeler · AG-E-06 Responsible-AI Officer |
| **Related** | [ADR-0006](../../adr/ADR-0006-account-centre-of-gravity.md) · [ADR-0007](../../adr/ADR-0007-portfolio-at-account.md) · [ADR-0008](../../adr/ADR-0008-thin-crm-over-systems-of-record.md) · [ADR-0009](../../adr/ADR-0009-lead-as-interest-on-existing-person.md) · [ADR-0014](../../adr/ADR-0014-agents-advisory-by-design.md) · [ADR-0018](../../adr/ADR-0018-analytics-split-crm-vs-databricks.md) · [ADR-0019](../../adr/ADR-0019-provisional-insurance-data-model-shape.md) · [ADR-0020](../../adr/ADR-0020-domain-ownership-within-six-solution-architecture.md) · [ADR-0021](../../adr/ADR-0021-multilingual-semantic-dataverse-metadata.md) · **new: ADR-0026, ADR-0027** · [contoso-insurance-data-model-extension](../../design/contoso-insurance-data-model-extension.md) · [ANALYTICS.md](../../ANALYTICS.md) · [INTEGRATION.md](../../INTEGRATION.md) |
| **Source** | BA rapid prototype in the Contoso Insurance prod tenant. **Pixel ground truth = the unpacked HTML web resources** `cr7e8_sharedpage01advisorcockpit` (cockpit) and `cr7e8_sharedpage12v2salessteeringcockpit` (steering) under `intake/contoso-insurance/source/WebResources/` — **local-only** (sourceOnly, customer-branded; not committed). Interim screenshots in `docs/ideas/uc-01-advisor-cockpit/` are superseded and may be removed. |
| **Licence** | 🧩 configuration / own build. Native Sales/Copilot Studio capabilities require capability-level validation. |
| **Maturity** | Design. No runtime AI capability is approved by this document; the NBA agent requires separate RAI review (AG-E-06). |

## Purpose

Rebuild the business analyst's HTML **Sales Advisory Cockpit** and **Sales Leader
Dashboard** as a governed, pixel-faithful **Model-Driven App "Advisor Cockpit"**
on the CRM Showcase six-solution architecture — proving the whole chain from
Dataverse data model → mocked data-platform analytics → React/Fluent PCF →
Copilot NBA agent → MDA app, end to end through the pipeline to TEST.

This sprint is **delivery slice 6** of the
[Contoso Insurance data-model design](../../design/contoso-insurance-data-model-extension.md); it
takes a dependency on slices 1–5 (the foundational insurance tables), which are
therefore **built as part of this sprint** (see §3).

## What "done" looks like

- The two source cockpits are reproduced **as closely as possible to the HTML
  mockups** by two React + Fluent UI v9 **PCF controls**, running in the MDA app
  "Advisor Cockpit" (Cockpit page + Sales Leader Dashboard page).
- The Dataverse data model (foundational insurance tables + cockpit tables) is
  implemented in the correct solutions, aligned to the CDM P&C semantic
  reference and the established insurance model.
- The mocked data-platform analytics are seeded via the pipeline into a Dataverse
  **measure-snapshot** projection; the PCF reads Dataverse, never a live
  Databricks.
- A **Copilot Studio NBA agent** (AG-F-01) reads Dataverse and writes advisory
  Next-Best-Action cards; every card is grounded, disclosed, and human-decided
  ([ADR-0014](../../adr/ADR-0014-agents-advisory-by-design.md)).
- ADR-0026 (inbound analytics projection pattern) and ADR-0027 (page-level PCF +
  the PCF Local-First Polish Loop) accepted; the polish-loop pattern is anchored
  and referenced by the `ux-designer` agent (AG-E-11).
- Deployed to DEV (unmanaged) and TEST (managed) through the existing
  `cd-solution-*` pipelines; smoke green. All sprint issues closed with linked PRs.

## Non-goals

- No plug-ins and no business rules this sprint. Behaviour that would otherwise
  be a plug-in/business-rule is described as **ADRs and options** and deferred.
- No live Azure/Databricks (no Azure subscription in the demo tenant) — the data
  platform is **mimicked** in Dataverse.
- No production environment. TEST is the highest environment targeted.
- No autonomous customer-facing action by any agent (ADR-0014).
- Rating, underwriting, policy administration remain in the systems of record
  (ADR-0008) — the CRM only projects.

---

## Design

### 1. Scope & decisions (from the brainstorm)

| # | Decision | Choice |
| --- | --- | --- |
| Scope | Surfaces this sprint | **Both** — Advisor Cockpit + Sales Leader Dashboard, full fidelity (a–f) |
| Data split | Transactional vs analytics | Transactional in Dataverse; analytics/AI numbers projected from the Databricks **mock** (read-only) |
| NBA | Recommendation delivery | **Copilot Studio agent** (AG-F-01) reads Dataverse, writes advisory NBA cards |
| Composition | How each surface renders | **One page-level PCF per surface** (2 controls total) |
| Data-model source | Reuse vs greenfield | **Hybrid** — native skeleton + established insurance model + only cockpit-specific additions |
| Mock mechanism | Getting analytics into the app | **Two-tier** — local JSON fixtures for the PCF build; a Dataverse `crmshow_measuresnapshot` projection seeded by pipeline for the deployed app |
| Mock location | Where it lives | Snapshot **schema in `crmshow_Integration`**; mock **rows as a seed package** in `data/scenarios/advisor-cockpit/`. No 7th solution. |
| Seed fidelity | Labels & numbers | **Exact** — reproduce the German labels and specific KPI numbers as clearly-synthetic data |
| Charts | Chart library | **Recharts** inside the PCF (line/radar/bar/gauge) |

### 2. Inbound analytics — the projection pattern (ADR-0026)

Three valid patterns for surfacing data-platform data in the app, captured as a
reusable catalogue in **ADR-0026** (this also closes the open `[TBD]` in
[ADR-0018](../../adr/ADR-0018-analytics-split-crm-vs-databricks.md)):

1. **Materialized projection** — a scheduled job (prod: Databricks → ADF /
   Synapse pipeline / Power Platform dataflow; **demo: synthetic fixtures → CD
   pipeline**) upserts aggregates into a Dataverse table keyed by *subject ·
   metric · as-of date*. **Chosen for the cockpit.**
2. **Virtual table** — Dataverse virtual table over an OData/SQL endpoint; live,
   no copy; read-only; needs a stable low-latency endpoint.
3. **Embedded Power BI / Fabric** — analytics stay in the lakehouse, surfaced via
   an embedded visual; best for heavy historical charts.

**Consumption contract (AG-E-09).** The PCF reads `crmshow_measuresnapshot`
from Dataverse (INTEGRATION.md *reference-lookup* + *bulk/scheduled analytical
provisioning*). The snapshot shape is a **versioned, contract-first schema in
`api/`**. Swapping the mock producer for a real Databricks feed changes the
producer only — the app contract is untouched. Effective-dating rides on every
row; the load is an idempotent upsert; Databricks stays authoritative
(ADR-0008).

### 3. Data model (reconciled with CDM + the insurance model)

Cross-checked against Microsoft's **Common Data Model — Property & Casualty**
(semantic reference per ADR-0019: Policy, Coverage, Claim, ClaimRevision,
Agency, PolicyAgency, InsuredAsset, AuthorizedJurisdiction) and the established
[insurance model](../../design/contoso-insurance-data-model-extension.md). CDM is used as
**canonical vocabulary at the contract layer, not one persisted table per
entity** (ADR-0019).

**3a. Foundational insurance tables — built this sprint (slices 1–5).**

| Table / extension | Solution | Notes |
| --- | --- | --- |
| `account` (`accountType`) · `contact` (lifecycle) | `crmshow_DataModel` | ADR-0006/0007 |
| `crmshow_contactrole` | `crmshow_DataModel` | effective-dated Contact participation |
| `crmshow_accountownership` | `crmshow_DataModel` | effective-dated GA / territory (≈ CDM Agency/PolicyAgency) — powers Sales Leader steering |
| `crmshow_consent` | `crmshow_DataModel` | per contact · channel · purpose (ADR-0010) |
| `lead` (+ parent) · `crmshow_leadcluster` | `crmshow_DataModel` / `crmshow_Sales` | ADR-0009 |
| `crmshow_policyprojection` (+ `crmshow_policypartyrole`) | `crmshow_DataModel` | thin, external-keyed (ADR-0008); CDM Policy/party roles |
| `crmshow_claimprojection` (+ `crmshow_claimpartyrole`) | `crmshow_DataModel` | thin, external-keyed; CDM Claim/party roles |
| `opportunity` · native `quote` (extended) | `crmshow_DataModel` | **Offer is native Opportunity + Quote** with `externalSystem`/`externalId` — no custom offer table |

External-projection field policy (every projection): `externalSystem`,
`externalId`, alternate key over both, `retrievedAt`/`sourceUpdatedAt`, status
mapped through a versioned contract, minimum fields only.

**3b. New cockpit tables — the genuinely new build.**

| Table | Solution | Purpose |
| --- | --- | --- |
| `crmshow_nextbestaction` | `crmshow_DataModel` | the "Empfohlener Fokus" / Tagesplan rows the Copilot agent writes — subject (Lead/Account/Contact), title, rationale, recommended channel, AI-score, rank, time-window, effect, benefit, status, **human decision** (learning signal). Advisory (ADR-0014). Aligns with the NextBestAction entity named in ADR-0019. |
| `crmshow_nbaprovenance` | `crmshow_DataModel` | child of NBA — the "Woher stammt das?" citations: source system · signal · timestamp. Satisfies "every proposal carries provenance". |
| `crmshow_measuresnapshot` | `crmshow_Integration` | persisted CRM projection of enterprise **Measures** (ANALYTICS.md), keyed by *subject · metric · region · product · as-of date*: AI-Score, forecast series, scorecard, product-line, region growth, aggregate KPIs. |

**3c. New choices — `crmshow_Foundation` (multilingual 1033/1031/1036/1040, ADR-0021).**
`crmshow_nbastatus` · `crmshow_nbachannel` · `crmshow_productline` ·
`crmshow_region` · `crmshow_metrictype`.

> **EA sign-off (AG-E-03) required** on §3 before implementation — the data model
> is a non-delegable architecture decision. Where §3 refines ADR-0019/0020, the
> refinement is recorded in those ADRs' revision history.

### 4. The two surfaces & the PCF Local-First Polish Loop (ADR-0027)

Two page-level **React 18 + Fluent UI v9** PCF controls in
`solution/apps/sales/Controls/**`, Recharts for charts, each matched 1:1 to its
HTML mockup.

- **`AdvisorCockpit`** — greeting header · "Ihr Fokus heute" KPI banner ·
  Arbeitsvorrat bar · tabs (Tagesplan · Meine Leads · Termine & Aufgaben · Offene
  Fälle · Copilot) · "Empfohlener Fokus" NBA card with provenance · Tagesplan
  table. *Reads:* Lead · Activity · `crmshow_nextbestaction`(+provenance) ·
  policy/claim projections · Case · `crmshow_measuresnapshot` (advisor KPIs).
- **`SalesLeaderDashboard`** — Strategisches Lagebild banner · 4 gauge KPIs ·
  Neugeschäft/Prämien line + KI-Forecast · Scorecard radar · Produktlinie bar ·
  Region growth. *Reads:* `crmshow_measuresnapshot` aggregates +
  `crmshow_accountownership` / lead / opportunity rollups.

**The PCF Local-First Polish Loop** (anchored pattern, also written to a
reusable pattern doc + referenced by the `ux-designer` agent):

1. Derive TypeScript types + mock fixtures from the data model.
2. Build the component in a **Vite** harness with fixtures (hot reload, full
   screen).
3. Serve on localhost, **open as a shared browser page in VS Code**, screenshot
   and **diff against the mockup PNG**; `ux-designer` (AG-E-11) polishes
   spacing/type/colour to pixel fidelity.
4. Wrap as PCF, bind `context`/dataset to Dataverse (same component, swap the
   data source).
5. Pack into `crmshow_Sales`, CI (pcf-alm) → DEV → TEST.

Cross-cutting: Fluent v9 theme tokens · **WCAG 2.1 AA**, full keyboard nav ·
**DE primary**, EN/FR/IT · every AI-authored NBA card carries a visible
provenance badge + "AI-assisted" disclosure (RAI).

### 5. The Copilot NBA agent (AG-F-01)

A Copilot Studio agent that, grounded on Dataverse (leads, activities, contacts,
projections, consent, and the measure snapshot), produces the actionable NBA
recommendation and writes it into `crmshow_nextbestaction` for the cockpit to
render. **Advisory only** — the human accepts / edits / dismisses, and that
decision is the learning signal (ADR-0014). Requires **RAI review (AG-E-06)**:
grounded, disclosed, Content Safety on customer-visible text, no autonomous
send. Free-text model output never writes Dataverse directly — mutations go
through the schema-validated action layer.

### 6. Mock data platform & seed

- Schema: `crmshow_measuresnapshot` in `crmshow_Integration` + the versioned
  contract in `api/`.
- Data: synthetic "gold" fixtures in `data/scenarios/advisor-cockpit/` (exact
  German labels + KPI numbers from the mockups — Contoso Insurance · GA
  Bern-Mittelland · Rahel Moser · Haushalt Brunner …), loaded by the pipeline
  (idempotent upsert). Clearly synthetic; no real data.
- To go real later: swap "fixtures → pipeline" for "Databricks → ADF/dataflow";
  the app contract is unchanged.

### 7. Build, ALM & governance

- **Solution placement:** choices → `crmshow_Foundation`; foundational +
  cockpit tables → `crmshow_DataModel`; measure-snapshot + contract →
  `crmshow_Integration`; 2 PCF controls + MDA app + custom pages →
  `crmshow_Sales`; NBA agent in Copilot Studio.
- **Test:** PCF Jest + React Testing Library · Pester for seed/scripts · Solution
  Checker 0 High · NBA-agent eval (grounding + Content Safety).
- **Deploy:** DEV unmanaged → TEST managed via `cd-solution-dev.yml` /
  `cd-solution-test.yml`; seed loaded by pipeline; smoke checks the snapshot +
  controls render.
- **ADRs:** ADR-0026 (inbound analytics projection catalogue) · ADR-0027
  (page-level PCF + PCF Local-First Polish Loop). NBA agent under ADR-0014 + RAI.
- **Gates:** EA (AG-E-03) for the data model + ADRs · RAI (AG-E-06) for the NBA
  agent · licensing + upgrade-impact flags per component · synthetic data only.
- **Execution:** Sprint 3 — GitHub milestone + epic + issues → `wt/` worktrees →
  local Copilot CLI → PR to protected main (the delegated model from Sprint 1).

### 8. Definition of done

Every change has an ADR · lives in `solution/` · has a test · declares upgrade
impact + licensing · pipeline green · deployed to sandbox (DEV + TEST). The
scope excludes plug-ins and business rules — those are captured as ADRs/options.

---

## What lands in the repo when this sprint closes

```
solution/
  core/foundation/        + 5 choices
  core/datamodel/         + contactrole, accountownership, consent, leadcluster,
                            policyprojection(+partyrole), claimprojection(+partyrole),
                            nextbestaction(+nbaprovenance); account/contact/lead/
                            opportunity/quote extensions
  core/integration/       + crmshow_measuresnapshot
  apps/sales/
    Controls/AdvisorCockpit/         (React + Fluent v9 + Recharts PCF)
    Controls/SalesLeaderDashboard/   (React + Fluent v9 + Recharts PCF)
    (MDA app "Advisor Cockpit" + 2 custom pages)
api/
  advisor-cockpit/measure-snapshot.schema.json   (versioned consumption contract)
data/scenarios/advisor-cockpit/                  (synthetic seed fixtures)
docs/
  adr/ADR-0026-inbound-analytics-projection-pattern.md
  adr/ADR-0027-page-level-pcf-and-local-first-polish-loop.md
  superpowers/patterns/pcf-local-first-polish-loop.md   (anchored pattern)
```

## Framework alignment

- **CAF**: Adopt (source-controlled, pipeline-promoted) · Govern (ADR + RAI gates).
- **WAF**: Operational Excellence (everything through the pipeline) · Reliability
  (idempotent seed, contract compatibility) · trade-off Cost vs richer local
  context (ADR-0019).
- **Zero Trust**: least-privilege projections; no insurance data copied without a
  named purpose/persona; OIDC-only CI.
- **Responsible AI**: NBA agent grounded, disclosed, Content-Safety-gated,
  advisory-only; provenance on every agent-authored row.

## Authoritative references

- [Common Data Model — Property & Casualty](https://learn.microsoft.com/common-data-model/schema/core/industrycommon/financialservices/propertyandcasualtydatamodel/overview)
- [Power Apps component framework](https://learn.microsoft.com/power-apps/developer/component-framework/overview)
- [Fluent UI React v9](https://react.fluentui.dev/)
- [Copilot Studio](https://learn.microsoft.com/microsoft-copilot-studio/) · [Responsible AI standard](https://learn.microsoft.com/azure/machine-learning/concept-responsible-ai)
- [contoso-insurance-data-model-extension](../../design/contoso-insurance-data-model-extension.md) · [ADR-0019](../../adr/ADR-0019-provisional-insurance-data-model-shape.md) · [ANALYTICS.md](../../ANALYTICS.md) · [INTEGRATION.md](../../INTEGRATION.md)
