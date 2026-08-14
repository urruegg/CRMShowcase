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
| advisorcockpit-pcf | 7 | #62 | DESIGN-SENSITIVE | ▶ next (attended, local-first polish loop) |
| salesleaderdashboard-pcf | 8 | #63 | DESIGN-SENSITIVE | ▶ next (attended, local-first polish loop) |
| foundation-choices | 1 | #56 | EXECUTION-ONLY | ⏳ DEV-gated (contract authored + tests green) |
| foundational-tables (slices 1–5) | 2 | #57 | DESIGN-SENSITIVE | ⏳ DEV-gated (contract authored, reduced scope + tests green) |
| cockpit-tables (nba + provenance) | 3 | #58 | EXECUTION-ONLY | ⏳ DEV-gated (contract authored + tests green) |
| seed-pipeline wiring | 5.3 | #60 (follow-up) | EXECUTION-ONLY | ⏳ DEV-gated (needs tables) |
| mda-app + custom pages | 9 | #64 | DESIGN-SENSITIVE | ⏳ DEV-gated |
| e2e DEV→TEST verify | 10 | #65 | EXECUTION-ONLY | ⏳ DEV-gated |
| nba-agent (Copilot Studio) | 6 | #61 | DESIGN-SENSITIVE | ⏸ deferred (out of sprint) |

The two **next** streams (7, 8) are independent and parallelizable — run them as
two worktrees off `main` once the PCF prerequisites (contract + fixtures) are on
the trunk (they are, via #67/#68).

**Data-model contract progress (2026-08-14, commit `d2e05e0`).** Streams
#56/#57/#58 are rescoped by the
[scope-reduction design addendum](../../specs/2026-08-14-advisor-cockpit-datamodel-scope-reduction-design.md):
`solution/schema/insurance-foundation.json` now declares the reduced-scope
shape — 4 new choices + 2 new `nbachannel` options (#56 addendum), 5 new
tables (`crmshow_leadcluster`, `crmshow_claimprojection`,
`crmshow_nextbestaction`, `crmshow_nbaprovenance`, `crmshow_measuresnapshot`)
and account/contact/lead/incident native extensions (#57/#58), plus the
`crmshow_policyprojection` productline/productname/premium gap-closes. The
publish/reconciliation mechanism that applies this to a live Dataverse
environment is Pester-verified end to end (`InsuranceFoundationContract.Tests.ps1`
33/33, `Publish-InsuranceFoundation.Tests.ps1` 104/104,
`Test-InsuranceFoundationConvergence.Tests.ps1` verified Describe-block-by-block).
**Not yet done:** the live DEV authoring/publish run — that remains the
"DEV-gated" step for all three streams.

## Definition of done

- [x] Governance: ADR-0026/0027 + polish-loop pattern recorded (#66).
- [x] Measure-snapshot consumption contract + tests (#67).
- [x] Synthetic seed fixtures + idempotent loader + tests (#68).
- [ ] `AdvisorCockpit` PCF pixel-faithful to the mockup, local-first polished (#62).
- [ ] `SalesLeaderDashboard` PCF pixel-faithful to the mockup (#63).
- [ ] Foundation choices + foundational/cockpit tables authored in DEV (#56/#57/#58) — contract authored + Pester-verified, DEV authoring pending.
- [ ] Seed wired into the CD pipeline with smoke (#60 follow-up / 5.3).
- [ ] MDA app "Advisor Cockpit" + custom pages (#64).
- [ ] E2E DEV→TEST evidence (#65).
