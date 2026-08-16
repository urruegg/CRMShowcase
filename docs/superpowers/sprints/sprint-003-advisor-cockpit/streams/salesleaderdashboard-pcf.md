# Handover Packet — salesleaderdashboard-pcf

- **Sprint:** sprint-003
- **Stream:** salesleaderdashboard-pcf
- **GitHub issue:** #63
- **Autonomy class:** DESIGN-SENSITIVE (pixel-perfect UI — run attended)
- **Branch:** feat/sprint-003-salesleaderdashboard-pcf
- **Worktree:** C:\Users\urruegg\source\urruegg\wt\sprint-003-salesleaderdashboard-pcf
- **Approved design ref:** [ADR-0027](../../../../adr/ADR-0027-page-level-pcf-and-local-first-polish-loop.md) · [spec](../../../specs/2026-08-11-advisor-cockpit-design.md) · [pcf-local-first-polish-loop](../../../patterns/pcf-local-first-polish-loop.md)

## Goal / Definition of Done

Build the `SalesLeaderDashboard` page-level PCF (React 18 + Fluent UI v9 +
Recharts), pixel-faithful to the local HTML ground truth
`intake/contoso-insurance/source/WebResources/cr7e8_sharedpage12v2salessteeringcockpit`
(git-ignored, local-only), reading the Phase-5 `measures.json` projection for
local development.

Done when: the control renders the Führungsdashboard (scorecard gauges
Zielerreichung 96 % / Wachstum YoY 7.2 % / NPS 42 / Automation 72 %, forecast
confidence band 320→412 vs target 430, product-line + region drill, funnel,
GA benchmark) from `data/scenarios/advisor-cockpit/measures.json`; the local Vite
harness runs at `localhost:5173`; a screenshot diff against the web resource is
within tolerance (ux-designer reviewed); Fluent v9 tokens ported from the mockup
CSS; Jest + RTL tests pass; the PCF builds. Binding to Dataverse is a later
DEV-gated step (not in this stream).

## Allowed scope (paths)

- `solution/apps/sales/Controls/SalesLeaderDashboard/**`
- local harness + fixtures wiring only under that control folder
- **read-only** reference: `data/scenarios/advisor-cockpit/measures.json`, the local web resource

Do not touch the six-solution manifests, other controls, or the seed loader.

## Verification commands

```
npm ci
npm run build        # PCF/tsc build is clean
npm test             # Jest + React Testing Library green
npm run start         # Vite harness on localhost:5173 for screenshot diff
```

## Guardrails

Inherit SUPERPOWERS_CONTRACT.md section 1 and the PCF instructions
(`.github/instructions/pcf-alm.instructions.md`, `pcf-best-practices.instructions.md`).
Synthetic data only. Headless streams additionally deny `shell(git push)`,
`shell(rm)`, `shell(git reset)` — but this stream is DESIGN-SENSITIVE, so run it
attended, not headless.

## Escalation rule

If a new design decision is needed → STOP, write `BLOCKED: needs design`, surface
the question to the control-plane chat. Never self-approve.
