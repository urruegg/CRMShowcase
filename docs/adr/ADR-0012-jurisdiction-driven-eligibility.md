# ADR-0012 — Jurisdiction-driven product eligibility

| Field | Value |
| --- | --- |
| **Status** | **Proposed** |
| **Date** | 2026-08-06 · **Topic area** A3 · A5 |
| **Licence** | 🧩 configuration / own build · **Upgrade impact** Medium |

## Context

Some jurisdictions operate a mandatory monopoly building insurer (in the illustrated
Swiss example, 19 cantons run a cantonal `KGV`; seven — GE, UR, SZ, TI, AI, VS, OW
— are free market, known collectively as `GUSTAVO`). Moving across that boundary
changes whether Contoso Insurance can **write the cover at all**. This is a
coverage-*existence* question, not a pricing question — and it is the curveball
that separates a genuinely model-driven platform from a pretty UI.

The pattern is not unique to Switzerland; other markets have equivalent
jurisdiction-driven eligibility (US flood-zone rules, some national natural-hazard
schemes). The decision below applies wherever jurisdiction changes coverage
existence.

## Decision (proposed)

Product eligibility is evaluated against a **jurisdiction model** before any
rating call. On a jurisdiction change the system must **withdraw or originate**
the product and route to a human — never silently re-price a product it is not
permitted to write.

## Consequences

- Eligibility rules are externalised and governed, not embedded per product.
- Jurisdiction-changing outcomes always involve a human (see
  [ADR-0014](./ADR-0014-agents-advisory-by-design.md)).
- **Demo value:** this is the moment where the architecture either holds or does
  not. Let the domain expert (`AG-E-05`) trigger it live.
