# Solution Design & Architecture

| Field | Value |
| --- | --- |
| **Topic area** | **A1** — Architecture vision, target picture, role of the CRM platform |
| Status | Draft 0.2 · **Owner** `AG-E-03` Enterprise Architect |

## What the customer asks

A consolidated view of the target architecture and the CRM platform's role in
the future application landscape: **which functional and technical
responsibilities the CRM takes over, and where existing systems remain
leading.** Of particular interest: interaction with the analytics platform,
customer analytics, partner master, employee portal and communication
platforms; which architecture principles secure long-term stability,
extensibility and technological independence; and a transparent view of
dependencies on vendor components, platform services and third parties.

> Note the last clause. The customer is asking us to volunteer our own lock-in
> surface. Doing so credibly is worth more than any capability slide.

## Position

**We are not proposing another CRM. We are proposing a Customer Engagement
Platform** — and a deliberately *thin* one over the customer's insurance
engines ([ADR-0008](./adr/ADR-0008-thin-crm-over-systems-of-record.md)).

CRM owns **demand and relationship**. The engines keep **insurance-technical
logic**.

| CRM is leading | System of record stays leading |
| --- | --- |
| Account / Household / Contact / ContactRole | Partner master — identity `[TBD — confirm mastership split]` |
| Lead · LeadCluster · Opportunity · Activity | Policy administration engine |
| Consent (per contact, per channel) | Rating & underwriting engines |
| Case / service interaction | Claims processing |
| NextBestAction · campaign response | Quoting engine |
| Interaction history & 360° projection | Analytical platform |

`Policy`, `Claim` and `Quote` exist CRM-side as **reference-keyed
projections**, never masters.

## Architecture principles (testable, not decorative)

A principle that cannot fail a review is not a principle. See
[DESIGN-PRINCIPLES.md](./DESIGN-PRINCIPLES.md) for the full set with failure
tests. The core ones for A1:

1. **Thin CRM over the engines.** No insurance logic in Dataverse. Testable:
   no rating or eligibility computation exists in the solution.
2. **One party model.** One `Account` with `accountType`; no B2C/B2B fork
   ([ADR-0006](./adr/ADR-0006-account-centre-of-gravity.md)).
3. **Events carry effective dates.** A cascade that cannot state *as of when*
   is incorrect ([ADR-0011](./adr/ADR-0011-event-driven-cascade.md)).
4. **Contracts are versioned artefacts.** A breaking change is an ADR, not a
   deployment.
5. **Every extension declares its upgrade impact.** Enforced in the ADR
   template and in CI.
6. **Everything reaches an environment through the pipeline**
   ([ADR-0017](./adr/ADR-0017-alm-everything-through-the-pipeline.md)). Manual
   environment changes are invisible and therefore forbidden.
7. **Agents recommend; humans decide**
   ([ADR-0014](./adr/ADR-0014-agents-advisory-by-design.md)).
8. **Consent is evaluated at the API layer**, not the UI
   ([ADR-0010](./adr/ADR-0010-consent-per-contact-per-channel.md)).

## Landscape

`[TBD — target-state diagram. Draft with the customer's architecture team
rather than presenting a finished picture; a diagram co-drawn in the room is
worth more than one we bring.]`

Systems to place explicitly: **partner master**, **policy administration** (SAP
or equivalent), **claims engine**, **quoting engine**, **analytics platform**,
**customer analytics platform**, **employee portal**, **communication
platforms**, **telephony** (see [ADR-0015](./adr/ADR-0015-voice-channel-boundary.md)).

## Dependencies — stated openly

| Dependency | Nature | Mitigation |
| --- | --- | --- |
| Dataverse as the platform | Vendor platform | Open schema; solution source-controlled; data exportable |
| Model-driven UI framework | Vendor component | Standard-first; custom surfaces isolated ([EXTENSIBILITY.md](./EXTENSIBILITY.md)) |
| Native voice channel for live transcript / Copilot voice | Vendor capability boundary | Stated in [ADR-0015](./adr/ADR-0015-voice-channel-boundary.md) — it is an architecture decision, not a detail |
| Paid-media activation, look-alike modelling | Not native | Export connectors / Azure ML — stated as extensions, not native claims |
| `[TBD]` | | |

## Open points for the next review

- Mastership split between the partner master and CRM for identity and partner data
- The event backbone in the target landscape ([ADR-0011](./adr/ADR-0011-event-driven-cascade.md))
- Provisioning mechanism and latency toward the analytics platform ([ADR-0018](./adr/ADR-0018-analytics-split-crm-vs-databricks.md))
- Territory authority for GA assignment ([ADR-0013](./adr/ADR-0013-ga-ownership-and-territory.md))
