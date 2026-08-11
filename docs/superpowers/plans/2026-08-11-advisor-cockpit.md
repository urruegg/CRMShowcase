# Advisor Cockpit — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Commit after EVERY task — do not batch.

**Goal:** Rebuild the BA's HTML Sales Advisory Cockpit + Sales Leader Dashboard as a pixel-faithful Model-Driven App on the six-solution architecture, with a Dataverse-mocked data platform and an advisory Copilot NBA agent, deployed DEV→TEST.

**Architecture:** Foundational insurance tables + cockpit tables in `crmshow_DataModel`; the analytics projection (`crmshow_measuresnapshot`) + versioned contract in `crmshow_Integration`; two page-level React + Fluent UI v9 PCF controls (Recharts) + the MDA app in `crmshow_Sales`; a Copilot Studio NBA agent that writes advisory `crmshow_nextbestaction` rows. Analytics arrive via the **materialized-projection** pattern — synthetic fixtures seeded by the pipeline stand in for Databricks (ADR-0026).

**Tech Stack:** Power Platform (Dataverse, `pac` CLI, MDA custom pages), PCF (TypeScript, React 18, Fluent UI v9, Recharts), Copilot Studio, PowerShell + Pester, Jest + React Testing Library, GitHub Actions (`ci-solution.yml` / `cd-solution-*.yml`), Vite (local PCF harness).

**Spec:** [docs/superpowers/specs/2026-08-11-advisor-cockpit-design.md](../specs/2026-08-11-advisor-cockpit-design.md)

**Authoring convention (from Sprint 1–2):** Dataverse schema is authored in DEV via `make.powerapps.com`, then pulled to source through the intake workflow (`export → unpack → commit`), version-bumped, CI-checked (`ci-solution.yml`), and promoted DEV→TEST. Follow that loop for every schema task. PCF follows [.github/instructions/pcf-alm.instructions.md](../../../.github/instructions/pcf-alm.instructions.md) + [pcf-best-practices](../../../.github/instructions/pcf-best-practices.instructions.md). Everything lands via PR to protected `main`.

---

## Phase map (delegatable units)

| Phase | Produces | Depends on |
| --- | --- | --- |
| 0 | ADRs 0026/0027 + pattern doc + sprint tracking | — |
| 1 | 5 Foundation choices | 0 |
| 2 | Foundational insurance tables (slices 1–5) | 1 |
| 3 | Cockpit tables (NBA + provenance) | 2 |
| 4 | `crmshow_measuresnapshot` + `api/` contract | 1 |
| 5 | Seed data package + pipeline load | 3, 4 |
| 6 | Copilot NBA agent + RAI eval | 3, 5 |
| 7 | `AdvisorCockpit` PCF | 3, 4, 5 |
| 8 | `SalesLeaderDashboard` PCF | 4, 5 |
| 9 | MDA app "Advisor Cockpit" + custom pages | 7, 8 |
| 10 | E2E DEV→TEST verification + evidence | all |

Each phase is one epic/issue → one `wt/` worktree → PR to `main`.

## File structure

```
docs/adr/ADR-0026-inbound-analytics-projection-pattern.md
docs/adr/ADR-0027-page-level-pcf-and-local-first-polish-loop.md
docs/superpowers/patterns/pcf-local-first-polish-loop.md
solution/schema/insurance-foundation.json          (extend: 5 choices)
solution/core/datamodel/…                           (tables, unpacked)
solution/core/integration/…                         (measuresnapshot, unpacked)
api/advisor-cockpit/measure-snapshot.schema.json
api/advisor-cockpit/measure-snapshot.sample.json
data/scenarios/advisor-cockpit/*.json               (synthetic seed)
scripts/solution/seed-advisor-cockpit.ps1 (+ Tests) (Pester)
solution/apps/sales/Controls/AdvisorCockpit/…       (PCF)
solution/apps/sales/Controls/SalesLeaderDashboard/… (PCF)
solution/apps/sales/…                               (MDA app + 2 custom pages)
copilot-studio/advisor-nba-agent/…                  (agent export + eval)
```

---

## Phase 0 — Governance, ADRs, sprint tracking

### Task 0.1: Sprint milestone + epic issues

- [ ] **Step 1: Create the milestone and epic**

Run:
```powershell
gh api repos/urruegg/CRMShowcase/milestones -f title="Sprint 3 - Advisor Cockpit" -f state=open
gh issue create --title "[Epic] Sprint 3 - Advisor Cockpit" --body "Implements docs/superpowers/specs/2026-08-11-advisor-cockpit-design.md. Child issues per phase." --milestone "Sprint 3 - Advisor Cockpit"
```
Expected: milestone JSON returned; epic issue URL printed.

- [ ] **Step 2: Create one child issue per phase (1–10)** using `gh issue create --milestone "Sprint 3 - Advisor Cockpit"`, each titled `S3-0N: <phase name>` and linking the epic. (No commit — GitHub state only.)

### Task 0.2: ADR-0026 — inbound analytics projection pattern

**Files:** Create `docs/adr/ADR-0026-inbound-analytics-projection-pattern.md`

- [ ] **Step 1: Write the ADR** using the repo ADR template. Record the **catalogue of three patterns** (materialized projection · virtual table · embedded Power BI/Fabric), select **materialized projection** for the cockpit, state that it **closes the open `[TBD]`** in ADR-0018, and reference ADR-0008. Include the demo emulation (fixtures→pipeline) and the "swap producer, not contract" property.
- [ ] **Step 2: Update ADR-0018** — change its open item to "Resolved by ADR-0026" and add ADR-0026 to its Related row.
- [ ] **Step 3: Commit**
```powershell
git add docs/adr/ADR-0026-inbound-analytics-projection-pattern.md docs/adr/ADR-0018-analytics-split-crm-vs-databricks.md
git commit -F commitmsg.tmp   # message: "docs(adr): ADR-0026 inbound analytics projection pattern (closes ADR-0018 TBD)"
```

### Task 0.3: ADR-0027 + the anchored polish-loop pattern

**Files:** Create `docs/adr/ADR-0027-page-level-pcf-and-local-first-polish-loop.md`, `docs/superpowers/patterns/pcf-local-first-polish-loop.md`; Modify `.github/agents/ux-designer.agent.md`

- [ ] **Step 1: Write ADR-0027** — decision: one page-level PCF per surface (vs tiles); records the PCF Local-First Polish Loop as the UX build method.
- [ ] **Step 2: Write the pattern doc** `pcf-local-first-polish-loop.md` — the 5 steps (types+fixtures → Vite harness → shared-browser review with ux-designer → wrap+bind → ALM), with the exact commands used in Phase 7.
- [ ] **Step 3: Reference the pattern** from `ux-designer.agent.md` (add one line under "You may propose" pointing to the pattern doc).
- [ ] **Step 4: Commit** (`git commit -F` with message `docs(adr): ADR-0027 page-level PCF + local-first polish loop`).

---

## Phase 1 — Foundation choices

### Task 1.1: Add 5 choices to the foundation contract

**Files:** Modify `solution/schema/insurance-foundation.json`; Test: existing schema-validation test under `scripts/solution` (or `Get-Manifest` tests)

- [ ] **Step 1: Write/extend the failing validation** — add a Pester assertion that `insurance-foundation.json` contains `crmshow_nbastatus`, `crmshow_nbachannel`, `crmshow_productline`, `crmshow_region`, `crmshow_metrictype`, each with labels in `1033/1031/1036/1040`.

```powershell
It 'defines the advisor-cockpit choices in four languages' {
  $c = (Get-Content "$PSScriptRoot/../../solution/schema/insurance-foundation.json" -Raw | ConvertFrom-Json).choices.logicalName
  'crmshow_nbastatus','crmshow_nbachannel','crmshow_productline','crmshow_region','crmshow_metrictype' |
    ForEach-Object { $c | Should -Contain $_ }
}
```

- [ ] **Step 2: Run it, verify it fails** — `Invoke-Pester -Path scripts/solution/tests -Tag advisor` → FAIL (choices missing).
- [ ] **Step 3: Add the 5 choice definitions** to `insurance-foundation.json`, following the exact shape of `crmshow_accounttype` (logicalName, schemaName, solution `crmshow_Foundation`, metadata.label/description in 4 langs, options with 4-lang labels). Option sets:
  - `crmshow_nbastatus`: Active/Planned/Accepted/Dismissed
  - `crmshow_nbachannel`: Call/PhoneAppointment/Email/Teams/OnSite/ClickToCall
  - `crmshow_productline`: MotorVehicle/HouseholdContents/CommercialProperty/Pension3a/LegalProtection
  - `crmshow_region`: Mittelland/Zurich/Romandie/Ticino
  - `crmshow_metrictype`: GoalAttainment/GrowthYoY/NPS/Automation/Forecast/Conversion/Efficiency/Satisfaction/Quality
- [ ] **Step 4: Run tests, verify pass.**
- [ ] **Step 5: Author the choices in DEV**, then intake-export `crmshow_Foundation` (`gh workflow run solution-intake-on-demand.yml -f solution=crmshow_Foundation -f reason="advisor-cockpit choices"`), and merge the intake PR.
- [ ] **Step 6: Commit** the schema change (`feat(foundation): advisor-cockpit choices (nba/product/region/metric)`).

---

## Phase 2 — Foundational insurance tables (slices 1–5)

> Author each table in DEV per the mobiliar-data-model-extension "custom tables proposed" section, then intake-export/unpack into `solution/core/datamodel`. One table (or tightly-coupled pair) per task, each its own commit. Reference ADR-0006/0007/0008/0009.

### Task 2.1: `crmshow_contactrole`
**Files:** author in DEV → `solution/core/datamodel/…`

- [ ] **Step 1:** Create `crmshow_contactrole` (Account N:1, Contact N:1, `crmshow_role`, `crmshow_validfrom`, `crmshow_validto`, `crmshow_source`) in **one `create_table` call with all lookups** (platform gotcha — never add lookups incrementally).
- [ ] **Step 2:** Intake-export `crmshow_DataModel`; unpack; confirm the table + relationships are present in source.
- [ ] **Step 3:** Add a Pester assertion that `Entities/crmshow_contactrole/Entity.xml` exists with both lookups.
- [ ] **Step 4:** Run `pac solution check` locally (or via CI) → 0 High.
- [ ] **Step 5: Commit** (`feat(datamodel): crmshow_contactrole effective-dated contact participation`).

### Task 2.2: `crmshow_accountownership`
- [ ] Create (Account N:1, owning user/team ref, `crmshow_territory` [lookup to region choice value or text], `crmshow_validfrom`, `crmshow_validto`, `crmshow_role` = GA/Agency/BrokerManager). Steps mirror 2.1. Commit `feat(datamodel): crmshow_accountownership dated GA/territory`.

### Task 2.3: `crmshow_consent`
- [ ] Create (Contact N:1, `crmshow_channel`, `crmshow_purpose`, `crmshow_source`, `crmshow_capturedon`, `crmshow_granted`). ADR-0010. Steps mirror 2.1. Commit `feat(datamodel): crmshow_consent per contact/channel/purpose`.

### Task 2.4: `crmshow_leadcluster` + `lead` parent enforcement
- [ ] Create `crmshow_leadcluster` (Account N:1, Lead 1:N). Extend native `lead` with `crmshow_leadcluster` lookup and ensure `parentcontactid`/`parentaccountid` are on the form (ADR-0009). Steps mirror 2.1. Commit `feat(datamodel): crmshow_leadcluster + lead parent enforcement`.

### Task 2.5: `crmshow_policyprojection` + `crmshow_policypartyrole`
- [ ] Create both in coordinated `create_table` calls: `crmshow_policyprojection` (Account N:1, `crmshow_externalsystem`, `crmshow_externalid`, **alternate key** on the pair, `crmshow_productline` [choice], `crmshow_status`, `crmshow_startdate`, `crmshow_enddate`, `crmshow_annualpremium`, `crmshow_retrievedon`); `crmshow_policypartyrole` (Policy N:1, Contact N:1, `crmshow_role`, dated). ADR-0008 projection field policy. Commit `feat(datamodel): policy projection + party role (CDM P&C aligned)`.

### Task 2.6: `crmshow_claimprojection` + `crmshow_claimpartyrole`
- [ ] Create both: `crmshow_claimprojection` (Account N:1, optional Policy N:1, `crmshow_externalsystem`, `crmshow_externalid`, alternate key, `crmshow_claimtype`, `crmshow_dateofloss`, `crmshow_estimatedamount`, `crmshow_status`, `crmshow_retrievedon`); `crmshow_claimpartyrole` (Claim N:1, Contact N:1, `crmshow_role`, dated). Commit `feat(datamodel): claim projection + party role`.

### Task 2.7: `opportunity` + native `quote` extension (Offer = native)
- [ ] Extend `opportunity` with `crmshow_externalcorrelationid` where needed; extend native `quote` with `crmshow_externalsystem`, `crmshow_externalid`, `crmshow_enginestatus`, `crmshow_retrievedon`. **No custom offer table** (per cross-check). Commit `feat(datamodel): quote external-projection extension (offer = native)`.

### Task 2.8: Version bump + CI + deploy DEV
- [ ] Add PR label `version-bump:minor` (new tables). Ensure `ci-solution.yml` green (manifest, pack, checker 0 High, tests). Merge → `cd-solution-dev.yml` imports to DEV. Verify smoke. (No new commit; label + merge.)

---

## Phase 3 — Cockpit tables

### Task 3.1: `crmshow_nextbestaction`
**Files:** author in DEV → `solution/core/datamodel/…`; Test: Pester entity assertion

- [ ] **Step 1: Failing test** — assert `Entities/crmshow_nextbestaction/Entity.xml` exists with attributes `crmshow_title, crmshow_rationale, crmshow_channel, crmshow_aiscore, crmshow_rank, crmshow_timewindow, crmshow_effect, crmshow_benefit, crmshow_status, crmshow_humandecision` and lookups to Lead/Account/Contact.
- [ ] **Step 2: Run, verify fails.**
- [ ] **Step 3: Create the table in DEV** (single `create_table` with all lookups): subject lookups (Lead N:1, Account N:1, Contact N:1), `crmshow_title` (text), `crmshow_rationale` (multiline), `crmshow_channel` (`crmshow_nbachannel`), `crmshow_aiscore` (whole 0–100), `crmshow_rank` (whole), `crmshow_timewindow` (text), `crmshow_effect` (text), `crmshow_benefit` (text), `crmshow_status` (`crmshow_nbastatus`), `crmshow_humandecision` (text), `crmshow_disclosure` (text, default "AI-assisted"). Intake-export/unpack.
- [ ] **Step 4: Run test, verify pass.**
- [ ] **Step 5: Commit** (`feat(datamodel): crmshow_nextbestaction advisory NBA card (ADR-0014)`).

### Task 3.2: `crmshow_nbaprovenance` (child)
- [ ] Create (`crmshow_nextbestaction` N:1, `crmshow_sourcesystem`, `crmshow_signal`, `crmshow_signaltimestamp`). Steps mirror 3.1. Commit `feat(datamodel): crmshow_nbaprovenance citations`.

---

## Phase 4 — Measure snapshot + contract

### Task 4.1: The versioned consumption contract
**Files:** Create `api/advisor-cockpit/measure-snapshot.schema.json`, `api/advisor-cockpit/measure-snapshot.sample.json`; Test: `scripts/solution/tests/MeasureSnapshotContract.Tests.ps1`

- [ ] **Step 1: Failing test** — validate `measure-snapshot.sample.json` against `measure-snapshot.schema.json` using `Test-Json`.

```powershell
It 'sample validates against the measure-snapshot contract' {
  $schema = Get-Content api/advisor-cockpit/measure-snapshot.schema.json -Raw
  $sample = Get-Content api/advisor-cockpit/measure-snapshot.sample.json -Raw
  Test-Json -Json $sample -Schema $schema | Should -BeTrue
}
```

- [ ] **Step 2: Run, verify fails** (files absent).
- [ ] **Step 3: Write the JSON Schema** — object array; each row: `subject` (string), `subjectType` (enum lead/account/contact/ga/region/product/portfolio), `metric` (matches `crmshow_metrictype` codes), `region` (nullable), `productLine` (nullable), `asOfDate` (date), `value` (number), `unit` (string), `externalSystem` (const "databricks-mock"). Write a matching `sample.json` with 3 rows.
- [ ] **Step 4: Run test, verify pass.**
- [ ] **Step 5: Commit** (`feat(integration): measure-snapshot consumption contract (api/)`).

### Task 4.2: `crmshow_measuresnapshot` table
- [ ] Create in DEV → `solution/core/integration/…`: `crmshow_subject` (text), `crmshow_subjecttype` (choice), `crmshow_metric` (`crmshow_metrictype`), `crmshow_region` (`crmshow_region`, optional), `crmshow_productline` (`crmshow_productline`, optional), `crmshow_asofdate` (date), `crmshow_value` (decimal), `crmshow_unit` (text), `crmshow_externalsystem` (text), **alternate key** on `subject+metric+asofdate+region+productline`. Pester entity assertion. Commit `feat(integration): crmshow_measuresnapshot projection table`.

---

## Phase 5 — Seed data + pipeline load

### Task 5.1: Synthetic seed fixtures
**Files:** Create `data/scenarios/advisor-cockpit/measures.json`, `leads.json`, `activities.json`, `nba.json`, `policies.json`, `claims.json`, `accounts-contacts.json`

- [ ] **Step 1:** Author fixtures reproducing the **exact** German labels + KPI numbers from the two mockups (Contoso Insurance · GA Bern-Mittelland · Rahel Moser · Haushalt Brunner; measures: Zielerreichung 96, GrowthYoY 7.2, NPS 42, Automation 72, product-line Motorfahrzeug 148 / Hausrat 108 / Gewerbe 89 / Vorsorge 79 / Rechtsschutz 69; regions Mittelland +7.2 / Zürich +5.1 / Romandie +3.8 / Tessin +1.2; forecast 320→430 Jan–Jun). `measures.json` must validate against the Phase-4 contract. All clearly synthetic; no real data.
- [ ] **Step 2:** Add a Pester test asserting `measures.json` validates against `measure-snapshot.schema.json` and contains no real-looking emails/phones (regex guard).
- [ ] **Step 3: Commit** (`feat(data): advisor-cockpit synthetic seed fixtures`).

### Task 5.2: Seed loader script (Pester-tested)
**Files:** Create `scripts/solution/seed-advisor-cockpit.ps1`, `scripts/solution/tests/SeedAdvisorCockpit.Tests.ps1`

- [ ] **Step 1: Failing test** — dot-source the script (non-mandatory top-level `param()` per repo convention), assert `Get-SeedPlan` returns one upsert group per fixture keyed by alternate key.
- [ ] **Step 2: Run, verify fails.**
- [ ] **Step 3: Implement** `seed-advisor-cockpit.ps1` — reads fixtures, builds idempotent upsert requests against the Web API using the alternate keys (measure snapshot, NBA+provenance, projections, accounts/contacts/leads/activities). Auth via the CI service principal (OIDC); no connection strings. Include `[CmdletBinding()]`, `Get-SeedPlan` function, trailing auto-invoke guard.
- [ ] **Step 4: Run tests, verify pass.**
- [ ] **Step 5: Commit** (`feat(scripts): idempotent advisor-cockpit seed loader`).

### Task 5.3: Wire seed into the pipeline
**Files:** Modify `.github/workflows/cd-solution-dev.yml` and `cd-solution-test.yml`

- [ ] **Step 1:** Add a post-import "Seed advisor-cockpit scenario" step that runs `seed-advisor-cockpit.ps1` after the solutions import (guarded by an input/flag so other sprints are unaffected).
- [ ] **Step 2:** Extend the smoke step to assert `crmshow_measuresnapshot` row count > 0 and at least one `crmshow_nextbestaction` exists.
- [ ] **Step 3: Commit** (`ci(cd): seed advisor-cockpit scenario + smoke on measures/NBA`).

---

## Phase 6 — Copilot NBA agent (AG-F-01)

### Task 6.1: Agent design + grounding
**Files:** Create `copilot-studio/advisor-nba-agent/README.md`, `topics/*.yaml` (exported), `prompt.md`

- [ ] **Step 1:** Author the agent in Copilot Studio: grounds on Dataverse (Lead, Activity, Contact, projections, consent, measuresnapshot); for a given advisor/day it composes the "Empfohlener Fokus" and writes `crmshow_nextbestaction` (+provenance) via the schema-validated action layer — **never free-text into Dataverse**. Advisory only; status defaults `Active`; disclosure "AI-assisted".
- [ ] **Step 2:** Export the agent + topics into `copilot-studio/advisor-nba-agent/` and commit the versioned prompt/topics (`feat(agent): advisor NBA agent grounded on Dataverse (advisory)`).

### Task 6.2: RAI eval (AG-E-06 gate)
**Files:** Create `copilot-studio/advisor-nba-agent/eval/*.json`, `eval/README.md`

- [ ] **Step 1:** Define an eval set: groundedness (every card cites retrieved rows), disclosure present, Content Safety pass on generated German text, no autonomous send.
- [ ] **Step 2:** Run the eval; capture the run link/artifact.
- [ ] **Step 3: Commit** eval + result (`test(agent): NBA agent RAI eval (grounding + content safety)`). **RAI reviewer (AG-E-06) approval required on the PR.**

---

## Phase 7 — `AdvisorCockpit` PCF (local-first polish loop)

> Follow `docs/superpowers/patterns/pcf-local-first-polish-loop.md`. Controls live under `solution/apps/sales/Controls/AdvisorCockpit/` per pcf-alm.

### Task 7.1: Scaffold the control + Vite harness
**Files:** Create `solution/apps/sales/Controls/AdvisorCockpit/` (pcfproj, ControlManifest.Input.xml, index.ts), `harness/` (Vite), `src/types.ts`, `src/fixtures.ts`

- [ ] **Step 1:** `pac pcf init --namespace crmshow --name AdvisorCockpit --template field` (or dataset); `npm install react@18 react-dom@18 @fluentui/react-components recharts`; add a Vite harness that renders `<AdvisorCockpit data={fixtures}/>` full-screen.
- [ ] **Step 2:** Define `src/types.ts` (TS interfaces mirroring the data model: `NbaCard`, `NbaProvenance`, `PlanActivity`, `LeadRow`, `MeasureRow`) and `src/fixtures.ts` (import the Phase-5 JSON, typed).
- [ ] **Step 3:** `npm run build` succeeds; `npm run dev` serves the harness. Commit (`feat(pcf): scaffold AdvisorCockpit + Vite harness + typed fixtures`).

### Task 7.2: Component build + pixel polish (iterative)
**Files:** `src/AdvisorCockpit.tsx` + subcomponents (`FokusBanner`, `ArbeitsvorratBar`, `TabStrip`, `EmpfohlenerFokusCard`, `ProvenanceBadge`, `TagesplanTable`)

- [ ] **Step 1: Jest tests first** — render each subcomponent with a fixture, assert key text/roles (e.g. NBA card shows title + provenance badge + "AI-assisted"; table renders 6 rows with AI-Score). `npm test` FAIL → implement → PASS.
- [ ] **Step 2: Polish loop** — the **pixel ground truth is the actual HTML web resource** `intake/mobiliar/source/WebResources/cr7e8_sharedpage01advisorcockpit` (local-only). Open it in a browser page alongside the PCF harness (`npm run dev` → `open_browser_page http://localhost:5173`), `screenshot_page` both, and diff. Port the web resource's CSS variables/layout directly into Fluent v9 tokens (the mockup already uses the Fluent palette `--brand:#0078d4`, Segoe UI, `n0…n190`). Dispatch the `ux-designer` agent to tune until it matches. Iterate.
- [ ] **Step 3:** WCAG pass (keyboard nav, roles, contrast); DE strings primary with EN/FR/IT resx.
- [ ] **Step 4: Commit** after each stable iteration (`feat(pcf): AdvisorCockpit surface pixel-matched to mockup`).

### Task 7.3: Bind to Dataverse
- [ ] Replace fixture source with `context` dataset/WebAPI reads (Lead, Activity, `crmshow_nextbestaction`+provenance, projections, Case, `crmshow_measuresnapshot`); keep the same component. Jest tests use a mocked `context`. `pac solution check` 0 High. Commit (`feat(pcf): bind AdvisorCockpit to Dataverse`).

---

## Phase 8 — `SalesLeaderDashboard` PCF

### Task 8.1: Scaffold + harness
- [ ] Same as 7.1 for `SalesLeaderDashboard`. Commit.

### Task 8.2: Component + charts + polish
**Files:** `src/SalesLeaderDashboard.tsx` + `LagebildBanner`, `GaugeKpis`, `NeugeschaeftLine` (Recharts LineChart + forecast), `ScorecardRadar` (RadarChart), `ProduktlinieBar` (BarChart), `RegionGrowth`

- [ ] **Step 1: Jest tests** — each chart renders from a `MeasureRow[]` fixture; gauges show 96/7.2/42/72; bar has 5 product lines.
- [ ] **Step 2: Polish loop** vs the actual HTML web resource `intake/mobiliar/source/WebResources/cr7e8_sharedpage12v2salessteeringcockpit` (local-only) rendered in a browser page; port its CSS tokens into Fluent v9 + Recharts; tune with the `ux-designer` agent.
- [ ] **Step 3: Commit** (`feat(pcf): SalesLeaderDashboard pixel-matched to mockup`).

### Task 8.3: Bind to Dataverse
- [ ] Read `crmshow_measuresnapshot` (filtered by metric/region/product) + `crmshow_accountownership`/lead/opportunity rollups. Commit (`feat(pcf): bind SalesLeaderDashboard to Dataverse`).

---

## Phase 9 — MDA app + custom pages

### Task 9.1: App + pages
**Files:** author in DEV → `solution/apps/sales/…`

- [ ] **Step 1:** Create MDA app "Advisor Cockpit"; add custom page **Cockpit** hosting `AdvisorCockpit`, custom page **Sales Leader Dashboard** hosting `SalesLeaderDashboard`; left nav groups (Home: Cockpit, Sales Leader Dashboard · Business: Leads, Anfragen, Claims, Policys, Offers · Relationships: Kontakte, Households) matching the mockup.
- [ ] **Step 2:** Add both PCF controls to `crmshow_Sales`; intake-export/unpack the app + pages.
- [ ] **Step 3:** Version bump `version-bump:minor`; `ci-solution.yml` green.
- [ ] **Step 4: Commit** (`feat(sales): Advisor Cockpit MDA app + custom pages`).

---

## Phase 10 — End-to-end verification

### Task 10.1: DEV→TEST promotion + evidence
- [ ] **Step 1:** Merge all phase PRs → `cd-solution-dev.yml` imports everything to DEV + seeds; verify the app renders both surfaces with seeded data.
- [ ] **Step 2:** `workflow_dispatch cd-solution-test.yml` with the commit sha; approve the `test` environment; managed import + seed + smoke.
- [ ] **Step 3:** Capture evidence (run links, screenshots of both surfaces in TEST) into the epic issue and close it.
- [ ] **Step 4:** Update `docs/BACKLOG.md` (Sprint 3 stories done) and `AGENTS.md` NBA maturity if warranted. Commit (`docs: Sprint 3 evidence + backlog close-out`).

---

## Definition of done (per change)

ADR linked · lives in `solution/` (schema) or `api/`/`data/`/`scripts/` · has a test (Pester/Jest/checker/eval) · upgrade-impact + licensing flags set · pipeline green · deployed to DEV+TEST. No plug-ins/business rules (captured as ADRs/options). Synthetic data only; no secrets; OIDC-only CI. EA (AG-E-03) sign-off on Phases 2–4; RAI (AG-E-06) sign-off on Phase 6.
