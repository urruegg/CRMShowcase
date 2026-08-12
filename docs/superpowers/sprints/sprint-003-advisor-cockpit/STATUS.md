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
| cockpit-tables | #58 | EXECUTION-ONLY | — | — | ⏳ DEV-gated | crmshow_nextbestaction + provenance |
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
