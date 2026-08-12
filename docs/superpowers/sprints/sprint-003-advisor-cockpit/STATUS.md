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
| salesleaderdashboard-pcf | #63 | DESIGN-SENSITIVE | feat/sprint-003-salesleaderdashboard-pcf | #74 | 🔜 in review | local-first PCF (React18/Fluent v9 + Recharts): Führungsdashboard — scorecard KPIs + forecast confidence band + radar + product/region bars + funnel + GA benchmark; data-mapped to measures.json + provenance (measure vs not-yet-mapped) + DATA-BOM/rubric scorecard; tsc clean, 8/8 vitest |
| foundation-choices | #56 | EXECUTION-ONLY | — | — | ⏳ DEV-gated | needs live DEV (make.powerapps.com authoring) |
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
