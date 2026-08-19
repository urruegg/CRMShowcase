# Sprint 005 - Power Apps Code Apps Advisor Cockpit Parity

| Field | Value |
| --- | --- |
| **Charter issue** | [#139](https://github.com/urruegg/CRMShowcase/issues/139) |
| **Story / use case** | US-301 / UC-01 Advisor Cockpit |
| **Design** | [Power Apps Code Apps Foundation and Advisor Cockpit B1/B2 Parity Proof](../../specs/2026-08-19-power-apps-code-app-advisor-cockpit-parity-design.md) |
| **Plan** | [Implementation plan](../../plans/2026-08-19-power-apps-code-app-advisor-cockpit-parity.md) |
| **Architecture record** | [ADR-0033](../../../adr/ADR-0033-crm-ux-placement-in-b2e-landscape.md) plus planned ADR-0041 |
| **Runtime target** | DEV and TEST; no PROD |

## Outcome

Establish Power Apps Code Apps as the primary repository path for bespoke
full-page CRM experiences. Prove the complete Advisor Cockpit as two separate
applications: standalone B1 and model-driven-hosted B2. Validate both with live
Dataverse data in DEV and TEST, then produce an evidence-backed recommendation
without automatically selecting a winner.

## Streams

| Stream | Issue | Autonomy | Goal | Dependency |
| --- | --- | --- | --- | --- |
| governance | [#140](https://github.com/urruegg/CRMShowcase/issues/140) | DESIGN-SENSITIVE | Record the build rule and attended ALM exception | approved design |
| shared-foundation | [#141](https://github.com/urruegg/CRMShowcase/issues/141) | DESIGN-SENSITIVE | Extract shared packages and capture parity baseline | governance |
| b1-standalone | [#142](https://github.com/urruegg/CRMShowcase/issues/142) | DESIGN-SENSITIVE | Build standalone Code App | shared-foundation |
| b2-embedded | [#143](https://github.com/urruegg/CRMShowcase/issues/143) | DESIGN-SENSITIVE | Build embedded Code App and MDA host | shared-foundation |
| quality-gates | [#144](https://github.com/urruegg/CRMShowcase/issues/144) | EXECUTION-ONLY | Add deterministic CI and release checks | B1 and B2 |
| dev-proof | [#145](https://github.com/urruegg/CRMShowcase/issues/145) | DESIGN-SENSITIVE | Publish and validate both hosts in DEV | implementation and gates |
| test-proof | [#146](https://github.com/urruegg/CRMShowcase/issues/146) | DESIGN-SENSITIVE | Promote, validate, and roll back in TEST | DEV proof |
| decision-evidence | [#147](https://github.com/urruegg/CRMShowcase/issues/147) | DESIGN-SENSITIVE | Score B1/B2 and recommend a host | DEV and TEST proof |

## Guardrails

- No B2E implementation or simulation.
- No Azure dependency or Dataverse schema extension.
- No raw Dataverse Web API, custom API, flow, secret-based CI, literal DEV URL,
  or deployed fixture fallback.
- The local fixture-backed PCF harness is the visual baseline; the deployed PCF
  is not a live comparator or fallback.
- Architecture, visual refinement, host-specific divergence, and live
  publication remain attended.
- Any new design decision stops with `BLOCKED: needs design`.

## Definition of Done

- [ ] All streams merged to `main` through reviewed PRs.
- [ ] Shared packages and separate B1/B2 identities build from source.
- [ ] B1/B2 visual and functional parity is documented before divergence.
- [ ] Provenance remains normal/grey/yellow with accessible non-color cues.
- [ ] Every visible action is covered by the write-capability matrix.
- [ ] B1/B2 run with live data under a least-privilege advisor in DEV and TEST.
- [ ] Managed DEV-to-TEST promotion and previous-version rollback are proven.
- [ ] The scorecard recommends without automatically selecting a winner.
- [ ] DEV and TEST evidence satisfies the Sprint Operating Model requirements.
