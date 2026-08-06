# ADR-0009 — A Lead is an expression of interest on a person who already exists

| Field | Value |
| --- | --- |
| **Status** | Accepted · **Date** 2026-08-06 · **Topic area** A2 · A5 |
| **Licence** | 🧩 configuration / own build · **Upgrade impact** Low |

## Context

The customer's semantics: a person can hold **many** leads, and leads can be
**grouped**. That inverts the native "lead-as-person-stub" model. The person almost
always already exists — in CRM or in the partner master.

## Options

- **A — Native lead as the person stub.** Use `subject`/`contactname`/`companyname`
  and let qualify create the contact. *Why not:* a person cannot hold multiple leads
  without duplicating the person stub; no clean grouping; qualification would create
  duplicate contacts for people who already exist.
- **B — Fully custom Lead entity.** *Why not:* loses native predictive scoring
  (`msdyn_leadscore` / `grade` / `trend`), BPF, routing/assignment, the lead stream
  views and NBA — all of which we would have to rebuild and then maintain.
- **C — Native `lead`, inverted, plus `LeadCluster` ✅ chosen.** Keep the native
  table for scoring, BPF, routing and cockpit; **always** set `parentcontactid`
  (and `parentaccountid`); add `LeadCluster` for grouping. `Prospect` / `Interested
  Party` / `Customer` is a lifecycle stage on Contact, so promotion is a status
  change, not a record migration.

## Decision

Native lead table, inverted. Qualification converts to **Opportunity only** — it
reuses the existing Contact/Account and never spawns a new person.

## Consequences

- Free native AI scoring and tooling *plus* the person-owns-many-leads semantics.
- `LeadCluster` is the **anti-over-contact guardrail**: the advisor runs one
  conversation, not five. In a book where a household holds many policies, this
  is a real customer-experience control, not a nicety.
- Typed `leadSource` (Claim-to-Lead · Service-to-Lead · Campaign · Inbound) keeps
  the closed loop legible and feeds attribution back to the originating
  Case/Claim/Campaign.
