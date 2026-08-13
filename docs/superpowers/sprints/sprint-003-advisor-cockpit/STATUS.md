# Sprint-003 — status board

Live status for the Advisor Cockpit (charter **#55**). See the
[charter](./sprint.md) and the
[Sprint Operating Model](../../SPRINT-OPERATING-MODEL.md).

| Stream | Issue | Class | Branch | PR | State | Evidence |
| --- | --- | --- | --- | --- | --- | --- |
| governance | #55 | DESIGN-SENSITIVE | feat/s3-phase0-adrs | #66 | ✅ merged | ADR-0026 (projection pattern, closes ADR-0018 TBD) + ADR-0027 (page-level PCF + polish loop) + pattern doc |
| measure-contract | #59 | EXECUTION-ONLY | feat/s3-phase4-measure-contract | #67 | ✅ merged | `api/advisor-cockpit/measure-snapshot.schema.json` + sample + Pester; suite green |
| seed-fixtures + loader | #60 | EXECUTION-ONLY | feat/s3-phase5-seed-fixtures | #68 | ✅ merged | 7 synthetic fixtures (exact mockup labels/KPIs) + `seed-advisor-cockpit.ps1` + tests; full suite 367 passed / 2 skipped |
| advisorcockpit-pcf | #62 | DESIGN-SENSITIVE | feat/sprint-003-advisorcockpit-pcf | #70 | ✅ merged | local-first PCF (React18/Fluent v9): faithful layout, Meine Leads Liste/Board/Cockpit, brand-kit tokens, data-source provenance (tint + legend, no badges), UX rubric v1.1 + scorecard; tsc clean, 24/24 vitest |
| salesleaderdashboard-pcf | #63 | DESIGN-SENSITIVE | feat/sprint-003-salesleaderdashboard-pcf | #74 | ✅ merged | local-first PCF (React18/Fluent v9 + Recharts): Führungsdashboard — scorecard KPIs + forecast confidence band + radar + product/region bars + funnel + GA benchmark; data-mapped to measures.json + provenance (measure vs not-yet-mapped) + DATA-BOM/rubric scorecard; tsc clean, 8/8 vitest |
| foundation-choices | #56 | EXECUTION-ONLY | feat/sprint-003-foundation-choices | #75 | ✅ merged | +5 cockpit choices (nbastatus/nbachannel/productline/region/metrictype) in 4 languages; contract 1.1.0; authored in DEV by the CD pipeline (2026-08-12) |
| foundational-tables | #57 | DESIGN-SENSITIVE | — | — | ⏳ DEV-gated | slices 1–5 (mobiliar-data-model-extension) |
| cockpit-tables | #58 | EXECUTION-ONLY | feat/s3-phase3-cockpit-tables | — | 🚧 WIP | type-system extension (Whole/Multiline) done + green (382/0/2); tables not yet authored - resume in `wt/s3-phase3-cockpit-tables` |
| seed-pipeline | #60 (follow-up) | EXECUTION-ONLY | — | — | ⏳ DEV-gated | task 5.3; needs the tables to exist for smoke |
| mda-app | #64 | DESIGN-SENSITIVE | — | — | ⏳ DEV-gated | app + two custom pages |
| e2e-verify | #65 | EXECUTION-ONLY | — | — | ⏳ DEV-gated | DEV→TEST evidence |
| nba-agent | #61 | DESIGN-SENSITIVE | — | — | ⏸ deferred | out of sprint; needs a use-case description |

## Run log

- Reconciled onto the operating model after Phases 0/4/5 had already merged
  under an ad-hoc milestone+epic+phase flow. Charter **#55**; streams mapped
  above; the model is now the default for the remaining streams.
- Next: streams **#62** and **#63** (the two PCF surfaces) run **attended**
  (DESIGN-SENSITIVE — pixel-perfect UI), each in its own `wt/` worktree off
  `main`, via the PCF local-first polish loop (ADR-0027) against the local HTML
  web-resource ground truth.
- DEV-gated streams (#56/#57/#58/#64/#65 + 5.3) wait on live Power Platform DEV.
- **2026-08-11** — stream **#62** (advisorcockpit-pcf) built via the PCF
  local-first polish loop and raised as **PR #70** (17 commits). Includes the
  ux-designer-ratified **PCF Review & UX-standardization rubric v1.1** + a
  conformance scorecard. Data-source provenance is carried by surface tint +
  per-tile accessible name + a persistent legend — **per-tile badges were
  removed** by product decision (anchored in the rubric §2). Awaiting **gate1**
  CI + human merge (never self-merge). Follow-up: ADR for adopting the
  customer-derived brand kit (token values only) into the public showcase.
- **2026-08-12** — #70 (#62) **merged** to main. Stream **#63**
  (salesleaderdashboard-pcf) built via the polish loop and raised as **PR #74**:
  the Führungsdashboard (scorecard + forecast band + radar + product/region bars
  + funnel + GA benchmark), **data-mapped to `measures.json`** with the
  data-source **provenance pattern applied** (measure-backed grey vs
  not-yet-mapped yellow, per-tile accessible name + 2-class legend, no badges) +
  a DATA-BOM and PCF Review rubric v1.1 scorecard. `tsc` clean, 8/8 vitest.
  Honest gap surfaced: several figures (radar/funnel/backlog/peer-GAs) are
  illustrative and **not yet in the Measure contract** — flagged in-UI + filed.

- **2026-08-12 (DEV bring-up)** - #75 (#56 foundation-choices) **merged**; the
  5 cockpit choices are authored in DEV by the CD pipeline. A full DEV bring-up
  push then exposed and cleared a chain of latent, never-before-run bugs:
  - **#80** root-role detection (self-referencing root-BU roles) - merged.
  - **#82** stop localizing security-role name/description (`SetLocLabels` is
    unsupported on the `role` entity) - merged.
  - **#83** `cd-bootstrap-roles.yml`: dispatch-only workflow to reconcile the
    reviewed roles on Ubuntu (local Windows `az.cmd` mangles parenthesised
    metadata URLs) - merged. Human granted **System Administrator** to the CI
    application user (role/metadata authoring needs it).
  - **#84** platform-baseline privileges out of role-contract scope (the
    SharePoint doc-management auto-grant is inert + unremovable; **ADR-0029**) -
    merged. Security roles now **bootstrap and verify Ready** in DEV.
  - **#81** corrected a bogus dependabot bump (`vite@^8.2.1` does not exist +
    `@vitejs/plugin-react@4`) in **both** PCF controls - merged. The
    **AdvisorCockpit local harness runs** at http://localhost:5173/ (vite 8.2.0).
  - CD-DEV now authors **everything** (5 choices + 3 tables + keys + views +
    forms + roles). Two items remain before the DEV/TEST evidence artifacts,
    both filed:
    - **#86** - the publisher must enforce `Delete=Restrict` on the Customer
      (`crmshow_partyid`) relationships (Dataverse creates them `RemoveLink`).
      Feasibility proven; both DEV relationships manually set to `Restrict`
      (correct now); the publisher code fix (fresh-org reproducibility) follows.
    - **#85** - CD-DEV *convergence* self-check 500s in CI on one
      attribute-metadata query that works everywhere locally; needs one
      instrumented run to capture the exact URL/status, then a targeted fix
      (and/or retry-hardening). DEV is otherwise fully provisioned.
  - Also open: **PCF multi-language i18n** (Phase 9 - both controls are
    German-only, no resx / `context.userSettings`); and a note that the local
    `main` working copy drifted behind `origin/main` during the session.

- **2026-08-13 (convergence gate: transport chain fixed; app-deploy status mapped)** -
  The CD-DEV `Validate complete demo convergence` gate now **runs fully
  end-to-end against live Dataverse** for the first time. It had never
  completed before - its Pester suite mocks every HTTP call, so a chain of
  live-only query bugs was never exercised. All three are now fixed:
  - **#85 / #88** (merged): typed attribute-metadata cast URL - unbraced
    `"$typeName?"` (in PowerShell `?` is a valid variable-name char) swallowed
    the cast type -> malformed URL -> Dataverse 500.
  - **#89** (merged): reverse-inventory selected `_rootsolutioncomponentid_value`,
    which does not exist (`rootsolutioncomponentid` is a Uniqueidentifier, not a
    lookup).
  - **#90 / #91** (merged): metadata OData supports **neither** `startswith`
    filtering **nor** derived-property selection inside `$expand` for any
    metadata entity. Reworked the reverse-inventory to drop the (redundant)
    server-side `startswith` filters and read relationships via **direct
    navigation** (`/EntityDefinitions(LogicalName='X')/ManyToOneRelationships`).
    Convergence Pester **52/52**.
  - **CD-DEV from `main` (run 31681039745)** confirms it live: `validate` +
    authoring (`Reconcile demo-safe metadata`) pass; convergence now runs
    completely with `languages`, `roles`, and **`unexpectedMetadata` = Ready**.
  - Two real **Publisher authoring-completeness** gaps remain before the gate is
    green (filed as **#92**): (A) per-**column** `IsAuditEnabled` not set (table
    audit is set; contract wants `column.auditing: true`); (B) custom
    views/forms exist in DEV but are not owned by the `crmshow_DataModel`
    solution. **Owner decision on #92: not needed** - resolve by **relaxing**
    the contract/convergence expectations at restart, not by adding Publisher
    enforcement. **#86** (publisher enforce `Delete=Restrict` on the Customer
    relationships) remains separately open.
  - **Deployment status (verified live):** DEV `crmshowdev` = **6/6** solutions
    (unmanaged, current) + 3 tables + 10 choices + 2 roles. TEST `crmshowtest` =
    **2/6** managed (`Foundation`+`DataModel` only) and **stale** (missing the 5
    cockpit choices, Data Steward, and the Sales/Service/Marketing/Integration
    solutions) - the DEV->TEST promotion never completed because the gate was
    blocked. **No model-driven app and no PCF code components in either
    environment yet** (Phase 9 #64 not started).
  - **Diagnostic tool:** a read-only local convergence probe (dot-source the gate
    against DEV with an `Invoke-RestMethod` transport override) surfaces all
    live-only gate bugs in one run instead of ~10-min CD-DEV round-trips.
  - **Remaining path to the advisory app end-to-end:** (1) relax #92 (+ decide
    #86) -> CD-DEV green -> DEV evidence artifact; (2) cockpit data model
    `crmshow_nextbestaction` + provenance (#58); (3) model-driven app + PCF ALM
    wrap in source (#64); (4) promote to TEST (#65).
  - Session paused here for a local system + VS Code update; resume from the
    "Remaining path" above.

- **2026-08-14 (blockers #92/#86 fixed via TDD in `wt/s3-cddev-green`)** -
  Both remaining CD-DEV convergence blockers implemented and green offline:
  - **#92 Blocker A** (column `IsAuditEnabled`): confirmed a systemic Dataverse
    quirk - `InitialTableCreate`/`CreateCustomerRelationships` never honor
    column-level auditing on Lookup/Customer attributes, even though
    table-level auditing is set correctly. Found **5** affected columns (the
    issue text named 4; a 5th, `crmshow_policyprojection.crmshow_accountid`,
    has the same shape) via `insurance-foundation.json`. Relaxed the contract
    to `auditing:false` on all 5 and locked it in with a new Pester regression
    test asserting Lookup/Customer columns are `false` and every other column
    stays `true`.
  - **#92 Blocker B** (view/form solution ownership): custom views/forms in
    DEV are not owned by `crmshow_DataModel`; enforcing that was decided out
    of scope for the demo. Removed the `Assert-ConvergenceSolutionOwnership`
    enforcement inside `Test-InsuranceFoundationView`/`Test-InsuranceFoundationForm`
    only (table/column/choice/native-extension ownership checks untouched) and
    added two regression tests proving a differently-owned view/form no longer
    reports `ContractConflict`.
  - **#86** (Customer-relationship cascade defaults to `RemoveLink`): fixed
    with (1) a best-effort `CascadeConfiguration` on the `CreateCustomerRelationships`
    create payload (Dataverse may still ignore it) and (2) a new
    `Repair-CustomerRelationshipCascade` function wired into
    `Invoke-ExistingCustomerRelationshipReconciliation` that detects an
    existing Customer relationship whose cascade doesn't match the contract
    and PUTs a fix via `/RelationshipDefinitions($metadataId)` instead of
    throwing. `Get-TableMetadataSnapshot`'s `ManyToOneRelationships` `$select`
    now also requests `MetadataId` so the repair path can address the right
    relationship. Ordinary (non-Customer) relationship cascade mismatches
    still throw, unchanged.
  - Full TDD red -> green cycle for all three fixes; caught and fixed a
    fixture-path regression along the way - `Get-ConvergenceTableMetadataPath`
    (the convergence test-fixture mock-key builder) hardcoded the *old*
    `ManyToOneRelationships` select string and had drifted out of sync with
    the real query built by `Get-TableMetadataSnapshot`, breaking 4 of the
    large end-to-end convergence fixtures with "Unexpected mocked path" until
    both builders were realigned.
  - **Full offline Pester suite (23 files, `scripts/solution/tests` +
    `infra/scripts/tests`): 385 passed, 0 failed, 2 skipped.** Merged as
    **PR #94** (labelled `autonomy:execution-only`; guardrail scan confirmed
    it touches no guarded path). Closes #92 and #86.
  - **CD-DEV gate confirmed green live** - `cd-solution-dev.yml` dispatched
    from `main` at `0ff50ff` (run
    [31695020608](https://github.com/urruegg/CRMShowcase/actions/runs/31695020608)):
    `validate` + `author` both succeed; the convergence result has **68/68
    component/child `State` entries = `Ready`**, zero `ContractConflict`.
    **CD-DEV is fully green for the first time this sprint.**
  - Worktree `wt/s3-cddev-green` removed; branch
    `fix/s3-cddev-green-blockers` deleted (local + remote) after merge.
  - **Remaining path to the advisory app end-to-end:** (1) ~~relax #92 (+
    decide #86) -> CD-DEV green~~ **done**; (2) cockpit data model
    `crmshow_nextbestaction` + provenance (#58); (3) model-driven app + PCF
    ALM wrap in source (#64); (4) promote to TEST (#65).

- **2026-08-13 (session paused - Phase 3 cockpit tables in progress, WIP checkpoint)** -
  Two flaky/blocking items from the prior session were closed first:
  - **#96** (new): a non-deterministic `ManyToOneRelationships` mock-resolution
    bug in the convergence test suite (ambiguous prefix match across two
    fixture builders sharing an `EntityDefinitions` URL prefix) - fixed by
    requiring the unique `Keys(` substring for deterministic resolution.
    Merged as **PR #97**. Full offline suite: 386 passed, 0 failed, 2 skipped.
  - **PR #95** (STATUS.md CD-DEV-green doc update, pending since 08-14 entry
    above) rebased onto the #96 fix and merged. `main` now at `741c9cc`.
  - Started **Phase 3 - cockpit tables (#58)** via a background
    `general-purpose` agent (`s3-phase3-cockpit-tables`), working in
    `wt/s3-phase3-cockpit-tables` on branch `feat/s3-phase3-cockpit-tables`.
    Scope: the contract's `column.type` enum only supported
    `Text | DateOnly | DateTime | GlobalChoice | Lookup | Customer` - no
    numeric or multi-line text type existed, but the plan's
    `crmshow_nextbestaction` table needs a `Whole` (AI score/rank) and a
    `Multiline` text (rationale) column. This makes Phase 3 a genuine
    schema + pipeline extension, not just new contract rows.
  - **Completed and verified today:** the type-system extension itself -
    `Whole` type (with `minValue`/`maxValue`) and `Multiline` text format
    added to `insurance-foundation.schema.json`, `Publish-InsuranceFoundation.ps1`,
    `Test-InsuranceFoundationConvergence.ps1`, and their Pester suites.
    **Full offline suite re-verified green: 382 passed, 0 failed, 2 skipped**
    (count differs slightly from the 386 baseline because table-authoring
    tests for #58 have not been added yet - see below). Committed as a WIP
    checkpoint (`c2eddbd`, message prefixed `wip(sprint-003):`) and **pushed
    to `origin/feat/s3-phase3-cockpit-tables` for backup - no PR opened yet**,
    since the tables themselves are not yet authored in the contract.
  - **Not yet done** (pick up here tomorrow, same branch/worktree):
    1. Author `crmshow_nextbestaction` (full 4-language metadata; subject
       carried by **three separate optional Lookups** - Lead/Account/Contact,
       not a polymorphic Customer, per ADR-0006/0007 and the
       `crmshow_accountcontactrole` precedent; references the already-live
       `crmshow_nbastatus`/`crmshow_nbachannel` choices from #56/PR #75 - no
       new choice authoring needed).
    2. Author `crmshow_nbaprovenance` (lookup child of
       `crmshow_nextbestaction`; check whether the contract already has a
       custom-table-to-custom-table Lookup precedent to mirror before wiring
       it up).
    3. Apply the `auditing:false` convention (from #92) to every new Lookup
       column (`crmshow_leadid`/`crmshow_accountid`/`crmshow_contactid` on
       the NBA table, `crmshow_nextbestactionid` on the provenance table) -
       all other new columns stay `auditing:true`.
    4. Bump the contract version (currently 1.1.0 -> 1.2.0) and re-run the
       **full** offline suite (target: 386+ passed, 0 failed, up to 2
       skipped) before opening a PR.
    5. Update this STATUS.md row for `cockpit-tables | #58` with the PR
       number once opened; **do not self-merge** - wait for `gate1`, then
       squash-merge + delete branch (worktree must be removed via
       `git worktree remove` from the main repo root first if the branch is
       checked out in one - see `#96`/`#97` session notes above for the
       exact sequence).
  - Sprint remains blocked on **live DEV authoring** of the new tables (via
    `cd-solution-dev.yml`, once #58 merges) before Phase 9 (**#64** - MDA
    app + PCF ALM wrap) and Phase 10 (**#65** - DEV->TEST promotion,
    closing charter **#55**) can start.
  - Session paused here for the day; resume tomorrow from step 1 above in
    `wt/s3-phase3-cockpit-tables`.
