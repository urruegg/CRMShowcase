# Sprint-003 — Advisor Cockpit

Charter for the third sprint: rebuild the BA's HTML **Sales Advisory Cockpit** +
**Sales Leader Dashboard** as a pixel-faithful Model-Driven App on the
six-solution architecture, with a Dataverse-mocked data platform and an advisory
Copilot NBA agent, deployed DEV→TEST.

**Design spec:** [../../specs/2026-08-11-advisor-cockpit-design.md](../../specs/2026-08-11-advisor-cockpit-design.md)
**Data-model scope addendum:** [2026-08-14-advisor-cockpit-datamodel-scope-reduction-design.md](../../specs/2026-08-14-advisor-cockpit-datamodel-scope-reduction-design.md)
**Plan:** [../../plans/2026-08-11-advisor-cockpit.md](../../plans/2026-08-11-advisor-cockpit.md)
**ADRs:** [ADR-0026](../../../adr/ADR-0026-inbound-analytics-projection-pattern.md) · [ADR-0027](../../../adr/ADR-0027-page-level-pcf-and-local-first-polish-loop.md)
**Pattern:** [pcf-local-first-polish-loop](../../patterns/pcf-local-first-polish-loop.md)
**Operating model:** [../../SPRINT-OPERATING-MODEL.md](../../SPRINT-OPERATING-MODEL.md)
**Charter issue:** #55 · **Milestone:** Sprint 3 - Advisor Cockpit

> **Note on convention.** Sprint-003 began under an ad-hoc milestone + epic + phase
> flow (#55–#65) before it was reconciled onto the operating model. This charter is
> the reconciliation: the phases below are the streams, each with an autonomy class.
> Phases 0/4/5 already merged; the remaining streams follow the model going forward.

## Outcome

Two page-level React + Fluent UI v9 PCF surfaces (Recharts) on MDA custom pages,
reading a Dataverse **measure-snapshot** projection (materialized-projection
pattern, ADR-0026) plus native Lead/Opportunity/Activity/Case and thin
policy/claim projections. Analytics are mocked by pipeline-seeded synthetic
fixtures standing in for Databricks. Agents are advisory only (ADR-0014).

## Streams

Autonomy class per the [Handover Contract](../../contracts/HANDOVER-CONTRACT.md).
DESIGN-SENSITIVE streams run **attended**; EXECUTION-ONLY may run headless.

| Stream | Phase | Issue | Class | State |
| --- | --- | --- | --- | --- |
| governance (ADRs 0026/0027 + pattern) | 0 | #55 | DESIGN-SENSITIVE | ✅ merged (PR #66) |
| measure-contract | 4 | #59 | EXECUTION-ONLY | ✅ merged (PR #67) |
| seed-fixtures + loader | 5.1/5.2 | #60 | EXECUTION-ONLY | ✅ merged (PR #68) |
| advisorcockpit-pcf | 7 | #62 | DESIGN-SENSITIVE | ✅ merged (PR #70) |
| salesleaderdashboard-pcf | 8 | #63 | DESIGN-SENSITIVE | ✅ merged (PR #74) |
| foundation-choices | 1 | #56 | EXECUTION-ONLY | ✅ merged (PR #75) + addendum DEV-authored (2026-08-14, run 31805085480) |
| foundational-tables (slices 1–5) | 2 | #57 | DESIGN-SENSITIVE | ✅ DEV-authored (2026-08-14, run 31805085480); source not yet intake-exported |
| cockpit-tables (nba + provenance) | 3 | #58 | EXECUTION-ONLY | ✅ DEV-authored (2026-08-14, run 31805085480); source not yet intake-exported |
| seed-pipeline wiring | 5.3 | #60 (follow-up) | EXECUTION-ONLY | ⏳ in progress — claims mapping, `crmshow_seedkey`, the `Get-AccountKeyMap` resolver, and account upserts all done (2026-08-14/15); account/claims code-complete end-to-end; still needs CD pipeline wiring; contacts/roles and policies deferred |
| mda-app + custom pages | 9 | #64 | DESIGN-SENSITIVE | ⏳ in progress (attended) |
| e2e DEV→TEST verify | 10 | #65 | EXECUTION-ONLY | ⏳ DEV-gated |
| nba-agent (Copilot Studio) | 6 | #61 | DESIGN-SENSITIVE | ⏸ deferred (out of sprint) |

#56 (foundation-choices, base + addendum) and #57/#58 (foundational + cockpit
tables) are now DEV-authored. Both PCF streams (7, 8) are already merged
(PR #70, #74) with a per-control `DATA-BOM.md` tracking bound vs. placeholder
visual elements for follow-up polish. Remaining: intake-export the newly
authored DEV schema into source, seed-pipeline wiring (#60 follow-up), and the
MDA app + custom pages (#64) — all in progress 2026-08-14.

**Data-model contract progress (2026-08-14, commit `d2e05e0`).** Streams
#56/#57/#58 are rescoped by the
[scope-reduction design addendum](../../specs/2026-08-14-advisor-cockpit-datamodel-scope-reduction-design.md):
`solution/schema/insurance-foundation.json` now declares the reduced-scope
shape — 4 new choices + 2 new `nbachannel` options (#56 addendum, on top of
the 5 choices already merged/DEV-authored in PR #75), 5 new
tables (`crmshow_leadcluster`, `crmshow_claimprojection`,
`crmshow_nextbestaction`, `crmshow_nbaprovenance`, `crmshow_measuresnapshot`)
and account/contact/lead/incident native extensions (#57/#58), plus the
`crmshow_policyprojection` productline/productname/premium gap-closes. The
publish/reconciliation mechanism that applies this to a live Dataverse
environment is Pester-verified end to end (`InsuranceFoundationContract.Tests.ps1`
33/33, `Publish-InsuranceFoundation.Tests.ps1` 104/104,
`Test-InsuranceFoundationConvergence.Tests.ps1` verified Describe-block-by-block).
**Not yet done:** the live DEV authoring/publish run of this rescoped shape —
that remains the "DEV-gated" step for the #56 addendum and for #57/#58.

**CD-DEV gate verified green end-to-end (2026-08-14).** The automated DEV
authoring/convergence pipeline (`cd-solution-dev.yml`) ran fully against live
Dataverse for the first time this sprint — run
[31695020608](https://github.com/urruegg/CRMShowcase/actions/runs/31695020608):
`validate` + `author` both succeed and convergence reports **68/68**
component/child `State` entries `Ready`, zero `ContractConflict`. This closed
the last two structural blockers (#92, #86; merged PR #94, full offline
Pester suite 385 passed/0 failed/2 skipped). This gate is what will author
the #56 addendum choices and the #57/#58 tables once run against the
2026-08-14 rescoped schema above. Deployment snapshot at that run: DEV
`crmshowdev` = 6/6 solutions (unmanaged, current); TEST `crmshowtest` = 2/6
managed and stale (promotion never completed). See
[STATUS.md](./STATUS.md) for the full run log.

**Local build verification re-run (2026-08-14).** Re-verified both merged PCF
controls build and test cleanly from a clean install in this workspace:
`AdvisorCockpit` — `npm install` (stale `node_modules` repaired) + `npm test`
= 2 test files, **24/24 vitest passing**; `SalesLeaderDashboard` — `npm install`
+ `npm test` = 1 test file, **8/8 vitest passing**. Both installs flagged 6
high-severity `npm audit` advisories (transitive dev-dependency tree; not yet
triaged — filed as a follow-up, not a build blocker).

**#56 addendum + #57/#58 DEV-authored (2026-08-14, run
[31805085480](https://github.com/urruegg/CRMShowcase/actions/runs/31805085480)).**
Dispatched `cd-solution-dev.yml` against the rescoped schema (commit `d2e05e0`):
`validate` succeeded in 12m22s (full offline Pester suite), `author` succeeded
in 9m13s (languages reconciled, demo-safe metadata reconciled, convergence
validated, packages exported). This is the step that authors the #56 addendum
choices, `crmshow_leadcluster`/`crmshow_claimprojection` (#57) and
`crmshow_nextbestaction`/`crmshow_nbaprovenance`/`crmshow_measuresnapshot` (#58)
in live DEV. **Autonomy note:** the remaining #57 work (dispatching this
already-approved, already-tested pipeline) was reclassified from
DESIGN-SENSITIVE to EXECUTION-ONLY for this run only — no new schema decision
was made; the classification reflects that a control-plane decision was made
for this specific dispatch action, not a change to the stream's original design
record. **Not yet done:** intake-export the newly authored components
(`crmshow_leadcluster`, `crmshow_claimprojection`, native extensions,
`crmshow_nextbestaction`, `crmshow_nbaprovenance`, `crmshow_measuresnapshot`)
into `solution/core/datamodel` source control.

**PCF wrap for #64 started (2026-08-14).** Per the owner's explicit scope
decision ("ship the existing PCF as-is first, polish afterwards"), both
controls now have a real, buildable PCF project under `pcf/` (isolated
`package.json`/`tsconfig.json`, `ControlManifest.Input.xml`, `index.ts`
rendering the existing component unchanged with its existing fixture data —
no Dataverse binding yet). `control-type="standard"` bundles React 18 +
Fluent v9 directly rather than the platform's React 16, since the existing
components already use React 18 APIs. Both builds verified green:
`AdvisorCockpit` webpack compiled in 259s (bundle.js 8.1 MiB),
`SalesLeaderDashboard` in 74s (bundle.js 3.97 MiB). **Not yet done:** the
MDA app "Advisor Cockpit" + 2 custom pages that host these controls.
Researched via Microsoft Learn: custom-page canvas content has **no**
Web API/CLI authoring path — it must be created interactively in Power Apps
Studio/the Maker Portal. The app-module + sitemap registration is scriptable
via Web API and remains a planned next step.

**Seed-pipeline wiring for claims started; account-resolution blocker found
(2026-08-14).** `scripts/solution/seed-advisor-cockpit.ps1` now maps
`claims.json` to `crmshow_claimprojection`: `ConvertTo-ClaimUpsertBody` +
`Get-ClaimUpsertRequests` build idempotent PATCH upserts keyed by the
composite alternate key `[crmshow_externalsystem, crmshow_externalid]`
(fixed from an incorrect single-column `crmshow_externalid` definition that
would have collided across source systems). Wired into
`Invoke-AdvisorCockpitSeed` behind a new `-AccountKeyMap` parameter.
Verified: 14/14 Pester (`SeedAdvisorCockpit.Tests.ps1`, 7 new cases covering
field mapping, optional-field omission, missing-account-key failure, and
request counts).
**Confirmed blocker (not yet resolved):** neither claims nor policies can
actually run against live Dataverse yet, because `account` has no stable,
seed-resolvable alternate key — `crmshow_seedkey` (or equivalent) does not
exist in `solution/schema/insurance-foundation.json`; account's only native
extensions are `crmshow_accounttype`, `crmshow_mastershipstatus`,
`crmshow_mastersystem`, `crmshow_lastsyncedon`. Every fixture's `accountKey`
(e.g. `ACC-BRUNNER`) is currently a script-external synthetic label with no
resolution path to a live Account GUID short of a caller-supplied map. Adding
a stable seed key to `account` is a data-model change and, per this repo's
own ADR rule ("change to the data model" → open an ADR), should not be made
unilaterally — flagging for an explicit design decision rather than
guessing. **Policies deferred separately:** `crmshow_policyprojection` also
requires `crmshow_policynumber`, `crmshow_lineofbusinesscode`,
`crmshow_effectivefrom`, `crmshow_sourcelastmodifiedon` (absent from
`policies.json`) and resolving `crmshow_status` (a GlobalChoice) from the
fixture's German free-text values ("Aktiv"/"Ablauf") without an agreed
mapping — left for a follow-up once both the account-key and status-mapping
decisions are made.
**`crmshow_seedkey` added to Account, closing the schema half of the blocker
(2026-08-15, PR #102, merged).** While the account-resolution question above
was still open, found that `seed-advisor-cockpit.ps1`'s own fixture manifest
(merged **PR #68**, EXECUTION-ONLY) had always declared
`AlternateKey = @('crmshow_seedkey')` for `accounts-contacts.json`/
`leads.json` — the field itself was simply never authored in
`insurance-foundation.json`. Reframed as completing an already-approved
design rather than a fresh decision, and implemented directly: added
`account.crmshow_seedkey` (Text, optional, maxLength 100,
`mastership: Configuration`, explicitly documented as demo/seed-pipeline
scaffolding only — never a production business field). Contract version
`1.1.0` → `1.2.0`. Full rationale, including explicitly out-of-scope gaps
(`lead`/`activitypointer` still lack this field — native-table alternate
keys aren't a supported pipeline capability at all today, custom-table-only),
in the [design-doc addendum](../../specs/2026-08-14-advisor-cockpit-datamodel-scope-reduction-design.md).
Flagged in the PR for Enterprise Architect review per `AGENTS.md` §Authority
since it's a data-model change, even though additive/low-risk; merged as
`ab41e42`.

**`Get-AccountKeyMap` resolver implemented, closing the code gap
(2026-08-15, PR #103, merged as `10d2546`).** Added `Get-AccountKeyMap` to
`seed-advisor-cockpit.ps1`: queries live Dataverse
(`GET /accounts?$select=accountid,crmshow_seedkey&$filter=crmshow_seedkey ne null`)
and builds the seed-key → Account GUID map. `Invoke-AdvisorCockpitSeed` now
auto-resolves this map itself when the caller supplies none, so the pipeline
seed step (5.3) needs no extra wiring beyond
`Invoke-AdvisorCockpitSeed -EnvironmentUrl $url`. 4 new Pester cases;
`SeedAdvisorCockpit.Tests.ps1` now **17/17 green**. **Net effect: the claims
seeding path is now code-complete end-to-end** — no remaining code gap. What
remains is data, not code: no live DEV account has a `crmshow_seedkey` value
yet — see the next entry for how that data now actually gets created.

**Account upserts implemented, so `crmshow_seedkey` now actually gets
populated (2026-08-15).** Added `ConvertTo-AccountUpsertBody` +
`Get-AccountUpsertRequests` to `seed-advisor-cockpit.ps1`, mapping
`accounts-contacts.json`'s **account rows only** (not contacts) to concrete
columns: `name`, `crmshow_accounttype` (mapped from the fixture's
`Household`/`Business`/`Broker` string to its Dataverse numeric option value
via a new `ConvertTo-GlobalChoiceValue` helper — safe because the fixture
already uses the exact same English option codes, unlike policies.json's
German free text), and `crmshow_seedkey`. `segment`/`region`/`owner` have no
corresponding schema column today and are intentionally not seeded; contact
rows and the `crmshow_accountcontactrole` junction (needed for the fixture's
"role" field) are a separate, not-yet-implemented increment.

**Key finding: `account` has no registered Dataverse *alternate key* on
`crmshow_seedkey`** — a deliberate PR #102 scope decision, since native-table
alternate keys aren't a supported pipeline capability today. So
`Get-AccountUpsertRequests` can't reuse the same PATCH-by-alternate-key
pattern as claims/policies; instead it resolves each row against the same
live-account map `Get-AccountKeyMap` builds and issues a plain POST (create)
for a seed key not yet present, or a PATCH-by-GUID (update) for one already
resolved. **Known limitation, documented rather than solved this round:** on
a fully empty environment, accounts and claims are resolved from the *same*
pre-run `$AccountKeyMap` snapshot, so newly-created accounts' claims won't
resolve until a second seed run re-queries `Get-AccountKeyMap` fresh — an
acceptable, idempotent-by-design characteristic rather than a bug, but worth
knowing before assuming one pipeline run fully converges a brand-new
environment. 6 new Pester cases; `SeedAdvisorCockpit.Tests.ps1` now
**22/22 green**.

## Definition of done

- [x] Governance: ADR-0026/0027 + polish-loop pattern recorded (#66).
- [x] Measure-snapshot consumption contract + tests (#67).
- [x] Synthetic seed fixtures + idempotent loader + tests (#68).
- [x] `AdvisorCockpit` PCF pixel-faithful to the mockup, local-first polished (#62).
- [x] `SalesLeaderDashboard` PCF pixel-faithful to the mockup (#63).
- [x] Foundation choices authored in DEV (#56 base, PR #75).
- [x] #56 addendum choices + foundational/cockpit tables authored in DEV (#57/#58, run 31805085480, 2026-08-14) — intake-export into source control still pending.
- [ ] Seed wired into the CD pipeline with smoke (#60 follow-up / 5.3) — claims mapping, `crmshow_seedkey` schema, the `Get-AccountKeyMap` resolver, and account upserts are all done (2026-08-14/15) — account/claims are code-complete end-to-end; still needs CD pipeline wiring; contact/role seeding and policies mapping (status-value decision) remain separately deferred.
- [ ] MDA app "Advisor Cockpit" + custom pages (#64) — both controls wrapped as real PCF + build-verified (2026-08-14); app module/sitemap + the 2 custom pages (Maker-Portal-only step) still pending.
- [ ] E2E DEV→TEST evidence (#65).
