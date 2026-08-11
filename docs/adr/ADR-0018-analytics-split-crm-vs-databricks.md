# ADR-0018 — Analytics split: what stays in CRM, what goes to the analytics platform

| Field | Value |
| --- | --- |
| **Status** | **Proposed** |
| **Date** | 2026-08-06 · **Topic area** A7 |
| **Licence** | `[TBD]` · **Upgrade impact** Low |

## Context

Topic area A7 asks which analysis, reporting and dashboard capabilities exist
**inside** the solution, how data is provisioned to downstream analytics
platforms, and which scenarios genuinely require an external data/analytics
platform. The customer already runs a lakehouse-style analytics platform (in the
illustrated example, Databricks).

## Decision (proposed)

- **In CRM:** operational, role-based, in-context analytics — the advisor's
  cockpit, GA steering, campaign performance, service KPIs. Self-service for
  business functions within governed KPI definitions.
- **In the analytics platform:** cross-domain modelling, long-horizon history,
  data-science workloads, look-alike modelling, and anything blending CRM with
  non-CRM domains.
- **Power BI** spans both on a governed semantic layer.

## Consequences

- The split must be stated as a **principle the customer can apply themselves**,
  not a list — otherwise every new report becomes a debate.
- KPI governance is a shared-responsibility topic (A9), not a tooling topic.
- **Provisioning mechanism and latency** toward the analytics platform:
  **resolved by [ADR-0026](./ADR-0026-inbound-analytics-projection-pattern.md)** —
  inbound analytics use a *materialized projection* (with virtual-table and
  embedded Power BI / Fabric as catalogued alternatives).
