# Reporting, Analytics & Data Usage

| Field | Value |
| --- | --- |
| **Topic area** | **A7** — Reporting, analytics, data usage |
| Status | Draft 0.2 |

## What the customer asks

The CRM platform is to become the **central working platform** for sales,
marketing and service. Therefore: which analysis, reporting and dashboard
capabilities exist **directly inside** the solution; how data is provisioned
to onward analytics platforms; self-service for business functions; role-based
evaluations; **KPI governance**; integration of existing tools such as
**Power BI**; and which scenarios require external data / analytics platforms.

## The split ([ADR-0018](./adr/ADR-0018-analytics-split-crm-vs-databricks.md))

| In CRM | In the analytics platform |
| --- | --- |
| Operational, in-context, role-based analytics | Cross-domain modelling |
| Advisor cockpit, GA steering | Long-horizon history |
| Campaign performance, service KPIs | Data-science workloads, look-alike modelling |
| Self-service within governed KPI definitions | Blending CRM with non-CRM domains |

**Power BI spans both** on a governed semantic layer.

State this as a **principle the customer can apply themselves**, not a list.
Otherwise every new report becomes a debate — which is exactly the failure
mode they are trying to avoid by asking.

## KPI governance

A KPI defined twice is a KPI nobody trusts. Definitions are governed centrally
and versioned; business functions get self-service **within** them, not around
them. Ownership sits in [SHARED-RESPONSIBILITY.md](./SHARED-RESPONSIBILITY.md)
— this is a shared-responsibility topic wearing an analytics hat.

## Open

`[TBD — provisioning mechanism and latency expectation toward the analytics
platform.]`
