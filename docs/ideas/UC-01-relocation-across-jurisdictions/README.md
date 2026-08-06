# UC-01 — Household relocation across a jurisdiction boundary (the golden thread)

| Field | Value |
| --- | --- |
| **Use case** | UC-01 (Sales: Lead → Advisory → Quote → Close) |
| **Curveballs applied** | 1 (cross-jurisdiction cascade) · 2 (building cover eligibility) · 3 (GA reassignment) · 7 (discount unwinding) |
| **Topic areas covered** | A1 · A2 · A3 · A4 · A5 · A6 · A7 · A8 · A9 |
| **Data** | **Synthetic only.** `[TBD — data/scenarios/smith-household.json]` |

## Scenario

> The **Smith household** is an existing Contoso Insurance customer in Bern
> (an illustrated jurisdiction where a cantonal monopoly building insurer
> applies) with motor, contents, liability, natural-hazard and building cover,
> and a multi-product discount. They buy a house in Schwyz (illustrated
> free-market jurisdiction). One address change is entered.

That single change must:

1. **Re-rate** motor (postal-code rating, parking), contents / burglary (zone),
   and natural hazards (flood / hail zone) — via the engines of record, with
   correct effective dating.
2. **Re-evaluate coverage existence** for building cover: the old jurisdiction
   is a monopoly canton, the new one is free market. The system must withdraw
   or originate the product — never silently re-price one it may not write —
   and route to a human.
3. **Reassign the household** to a different General Agent, with ownership
   transfer, commissioning, local claims routing and continuity of service.
4. **Unwind and recalculate** the multi-product discount across the remaining
   policies.
5. **Create qualified demand**: the move is a genuine advisory moment. A
   Next-Best-Action reaches the new GA's advisor with full context — and the
   Lead attaches to the person who already exists, grouped in a `LeadCluster`
   so the household is approached **once**.

## Why this thread

- It is **jurisdiction-specific**. Around 80 independent General Agents make
  step 3 a curveball incumbent packaged suites cannot improvise.
- It forces every architectural conversation we want to have: boundaries (A1),
  household model and mastership (A2), event fan-out and contracts (A3),
  extensibility (A4), governed business case (A5), agent + human-in-the-loop
  (A6), analytics (A7), and the pipeline that produced it (A8/A9).
- It is a **real customer moment**, not a feature tour. It matches the demo
  narrative: *"Every selection should answer one question — which customer
  needs our attention right now?"*

## Walkthrough by topic area

| # | What we show on this thread |
| --- | --- |
| **A1** | Which system owns what: CRM holds the relationship and the demand; the engines keep rating, underwriting and policy administration ([ADR-0008](../../adr/ADR-0008-thin-crm-over-systems-of-record.md)). Where the partner master, policy administration, analytics platform, customer analytics and employee portal sit. |
| **A2** | The 360° view before and after: household, ContactRole, policies, claims, life event. Live schema extension on stage. Mastership and dedup. |
| **A3** | `AddressChanged` fans out with effective dating; contracts in `api/`; the failure path — retry, dead-letter, replay, idempotency ([ADR-0011](../../adr/ADR-0011-event-driven-cascade.md)). |
| **A4** | The live build: customer picks a change (e.g. add a rating-relevant attribute), agents produce ADR → solution change → test → PR → sandbox. Then roll it back. |
| **A5** | GA reassignment as a governed business case: tasks, SLA, escalation, cross-system tracing ([ADR-0013](../../adr/ADR-0013-ga-ownership-and-territory.md)). |
| **A6** | The agent detects the life event and proposes the NBA; the human accepts. Grounding, explainability, human-in-the-loop, maturity ([ADR-0014](../../adr/ADR-0014-agents-advisory-by-design.md)). |
| **A7** | The same data in Power BI for GA steering; what stays in CRM vs. the analytics platform ([ADR-0018](../../adr/ADR-0018-analytics-split-crm-vs-databricks.md)). |
| **A8** | The morning's PR in the pipeline history; rollback ([ADR-0017](../../adr/ADR-0017-alm-everything-through-the-pipeline.md)). |
| **A9** | Who owns the eligibility rule, the territory model, the consent record, the KPI definition. |

## Acceptance criteria (demonstrable live)

- [ ] Entering the new address produces a **visible, traceable** impact set across all affected policies.
- [ ] Building cover is **withdrawn or re-originated**, never silently re-priced.
- [ ] The household is reassigned to the correct GA with a recorded handover.
- [ ] The remaining policies' discount is recalculated.
- [ ] Exactly **one** advisory contact is proposed for the household, not one per policy.
- [ ] Every step carries an effective date.
- [ ] The whole cascade is traceable end-to-end across systems.
- [ ] A deliberately failed integration call dead-letters and replays cleanly.

## Open points

`[TBD]` — items to close with the customer are tracked in
[../../reviews/](../../reviews/).
