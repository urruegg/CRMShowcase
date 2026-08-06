# ADR-0013 — General Agent ownership transfer and territory model

| Field | Value |
| --- | --- |
| **Status** | **Proposed** |
| **Date** | 2026-08-06 · **Topic area** A2 · A5 · A9 |
| **Licence** | 🧩 configuration / own build · **Upgrade impact** Medium |

## Context

Contoso Insurance's cooperative structure runs roughly 80 independent **General
Agents (GA)** — regional agencies with local autonomy — that own the local
relationship, advice and claims. A cross-region move reassigns the household to a
different agency. This touches shared-responsibility directly, because GA autonomy
versus central standardisation is exactly the responsibility-split question.

## Decision (proposed)

Ownership is a first-class, dated relationship on the Account, driven by a
territory model. Reassignment is a **governed business case** with handover, not
a field update: it carries commissioning implications, local claims routing and
continuity-of-service obligations.

## Consequences

- **A4 tension made explicit:** GAs need local flexibility; the platform needs
  standardisation. The answer is a governed extension surface — central templates
  and rules, local content and selections — not per-GA forks.
- **A9:** the RACI for GA-level configuration, data ownership and approval lands
  here.
- **Open with the customer:** the authoritative source of territory assignment,
  and whether reassignment is ever automatic. `[TBD]`
