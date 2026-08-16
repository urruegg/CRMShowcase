# ADR-0008 — Thin CRM over the systems of record

| Field | Value |
| --- | --- |
| **Status** | Accepted |
| **Date** | 2026-08-06 |
| **Topic area** | A1 — Architecture vision · A2 — Data model |
| **Use case** | All |
| **Licence** | 🧩 configuration / own build |
| **Upgrade impact** | None — this is a boundary decision, not an extension |

## Context

The customer's requirement is explicit that insurance-technical logic stays in the
existing engines. Topic area A1 asks which technical and functional
responsibilities the CRM takes over and **where existing systems remain leading**.
The failure mode across CRM programmes in insurance is the CRM quietly becoming a
second policy system — at which point the customer owns two sources of truth and
a permanent reconciliation problem.

## Options

### Option A — Full insurance data model in CRM
Model policy, coverage, claim, rating and product structures natively in the CRM
suite.
**Why not:** duplicates the systems of record, creates dual-master reconciliation,
and ties the customer's insurance logic to the CRM vendor's release cycle.

### Option B — CRM as a pure UI over services
No persisted CRM domain objects; everything read through live service calls.
**Why not:** no offline resilience, no CRM-side analytics, unacceptable latency on
the 360° view, and no place to hold the demand-side objects (lead, opportunity,
interaction) that are genuinely CRM's.

### Option C — Thin CRM over the engines ✅ chosen
CRM owns **demand and relationship**: Account, Contact, ContactRole, Lead,
LeadCluster, Opportunity, Activity, Consent, Case, NextBestAction. `Policy`,
`Claim` and `Quote` exist as CRM-side projections carrying **external reference
keys** to the policy administration, claims and quoting engines. Rating,
underwriting and policy administration stay in the engines.

## Decision

The CRM orchestrates demand and relationships over the insurance engines. Policy,
Claim and Quote are reference-keyed projections, never masters. Rating and
eligibility are *invoked*, never *reimplemented*.

## Consequences

- **At the next release:** no insurance logic is coupled to CRM platform upgrades.
- **Operationally:** one source of truth per domain; no dual-system reconciliation.
- **For the customer's teams (shared responsibility):** clean ownership line — the
  business owns demand-side configuration, the engine teams keep the
  insurance-technical layer.
- **Reversibility:** high. Projections can be extended without touching the engines.
- **Cost:** integration quality becomes load-bearing. See
  [ADR-0011](./ADR-0011-event-driven-cascade.md) and
  [../INTEGRATION.md](../INTEGRATION.md).
- **Party mastership lifecycle (2026-08-14):** the same thin-CRM principle
  extends to Account/Contact identity, not only Policy/Claim/Quote. A new
  relationship is born CRM-owned (prospect stage); once a contract exists,
  mastership of party data switches to the core system (PDV) and syncs back
  to CRM. Modeled as `crmshow_mastershipstatus` (CRMOwned/SourceMastered),
  `crmshow_mastersystem` (choice, e.g. PDV), and `crmshow_lastsyncedon` on
  both `account` and `contact` — see
  [2026-08-14-advisor-cockpit-datamodel-scope-reduction-design.md](../superpowers/specs/2026-08-14-advisor-cockpit-datamodel-scope-reduction-design.md).

## Competitive note

Both incumbent suites tempt the customer to absorb insurance logic into the CRM
(packaged Person / Policy / Claim / Producer schemas). This position matches what
the requirement actually asks for — thin orchestration over the engines — on an
open Dataverse schema that stays flexible.
