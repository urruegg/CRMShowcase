# Sprint-004 — Advisor Cockpit demo data realism

Charter for the fourth sprint: make the Advisor Cockpit demo data set
realistic and presenter-personalized — evaluated from the Mobiliar reference
intake, seeded with `ownerid` resolved to the DEV/TEST System Administrator,
wired into both `cd-solution-dev.yml` and `cd-solution-test.yml` — after first
clearing the three sprint-003 carry-over blockers (#120, #121, #124) that
currently prevent a clean TEST promotion.

**Design spec:** [../../specs/2026-08-17-advisor-cockpit-demo-data-design.md](../../specs/2026-08-17-advisor-cockpit-demo-data-design.md)
**Plan:** [../../plans/2026-08-17-advisor-cockpit-demo-data.md](../../plans/2026-08-17-advisor-cockpit-demo-data.md)
**Operating model:** [../../SPRINT-OPERATING-MODEL.md](../../SPRINT-OPERATING-MODEL.md)
**Charter issue:** [#125](https://github.com/urruegg/CRMShowcase/issues/125) · **Carry-over from:** sprint-003 (#120, #121, #124)

## Outcome

A realistic, presenter-personalized Advisor Cockpit demo data set: Mobiliar
reference-environment findings evaluated into concrete fixture enrichments,
the CRM Showcase's own DEV/TEST tenant System Administrator resolved at
seed time (no personal identifiers committed to the repo), the enriched
fixtures seeded with that owner on both DEV and TEST, and full live DEV+TEST
evidence recorded — closing #120, #121 and #124 along the way.

## Streams

Autonomy class per the [Handover Contract](../contracts/HANDOVER-CONTRACT.md).

| Stream | Issue | Class | State |
| --- | --- | --- | --- |
| prereq-fixes (#120, #124) | [#126](https://github.com/urruegg/CRMShowcase/issues/126) | EXECUTION-ONLY | 🟡 #120 fix implemented + live DEV verify in progress; #124 needs re-authoring (see STATUS.md) |
| mcp-agent-decision (#121) | [#127](https://github.com/urruegg/CRMShowcase/issues/127) | DESIGN-SENSITIVE | 🟡 decision made (remove Copilot/AI-assistant feature); mechanical Maker-Portal step deferred to owner |
| mobiliar-intake-governance | [#128](https://github.com/urruegg/CRMShowcase/issues/128) | DESIGN-SENSITIVE | ✅ [PR #133](https://github.com/urruegg/CRMShowcase/pull/133) opened |
| tenant-user-inventory | [#129](https://github.com/urruegg/CRMShowcase/issues/129) | DESIGN-SENSITIVE | ✅ [PR #135](https://github.com/urruegg/CRMShowcase/pull/135) opened |
| fixture-enrichment | [#130](https://github.com/urruegg/CRMShowcase/issues/130) | DESIGN-SENSITIVE | ✅ [PR #134](https://github.com/urruegg/CRMShowcase/pull/134) opened |
| seed-owner-wiring | [#131](https://github.com/urruegg/CRMShowcase/issues/131) | EXECUTION-ONLY | ✅ [PR #136](https://github.com/urruegg/CRMShowcase/pull/136) opened |
| e2e-dev-test-verify | [#132](https://github.com/urruegg/CRMShowcase/issues/132) | EXECUTION-ONLY | ⬜ not started (blocked on prereq-fixes + mcp-agent-decision) |

## Dependencies

- `seed-owner-wiring` depends on `tenant-user-inventory` + `fixture-enrichment`.
- `fixture-enrichment` depends on `mobiliar-intake-governance`'s evaluation report.
- `e2e-dev-test-verify` depends on `prereq-fixes`, `mcp-agent-decision`, and `seed-owner-wiring`.

## Definition of done

- [ ] All 7 streams merged to `main` via PR (never self-merged).
- [ ] #120, #121, #124 closed.
- [ ] `intake/mobiliar/` governed to the same standard as `intake/contoso-insurance/`.
- [ ] `Get-DemoPresenterUser.ps1` resolves the DEV/TEST System Administrator at runtime — no personal identifiers committed.
- [ ] Enriched fixtures seeded with resolved owner on both DEV and TEST.
- [ ] `## Live DEV + TEST evidence` section in this sprint's `STATUS.md`.
