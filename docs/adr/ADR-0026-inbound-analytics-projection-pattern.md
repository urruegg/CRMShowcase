# ADR-0026 — Inbound analytics projection pattern (data platform → CRM)

| Field | Value |
| --- | --- |
| **Status** | Accepted |
| **Date** | 2026-08-11 |
| **Decision mode** | Committed decision (for the cockpit); the catalogue is a reusable reference |
| **Confidence** | High — grounded in Microsoft-documented integration patterns and ADR-0008/0018 |
| **Deciders** | Enterprise Architect (AG-E-03) · Integration Engineer (AG-E-09) · Data Engineer & Scientist (AG-E-07) |
| **Topic area** | A3 — Integration · A7 — Analytics |
| **Use case** | UC-01 · Advisor Cockpit ([spec](../superpowers/specs/2026-08-11-advisor-cockpit-design.md)) |
| **Licence** | 🧩 configuration / own build |
| **Upgrade impact** | Low — the projection table + contract are additive; the producer can change without touching consumers |
| **CAF methodology** | Adopt · Govern |
| **WAF pillar(s)** | Primary: Operational Excellence · Reliability. Trade-off: Cost Optimization vs freshness (a copy must be refreshed). |
| **Zero Trust** | Least privilege — project only the measures a named persona needs; read-only in CRM. |
| **Responsible AI** | Transparency — surfaced numbers cite their source system and as-of date. |

## Context

[ADR-0018](./ADR-0018-analytics-split-crm-vs-databricks.md) sets the split
between operational analytics in CRM and enterprise analytics on the data
platform (Databricks), but left the **provisioning mechanism and latency toward
the analytics platform** as an open `[TBD]`. The Advisor Cockpit forces the
question: model-computed numbers (AI-Score, forecast, scorecard, product-line
and region analytics, aggregate KPIs) must appear **in-context** inside the
cockpit. This ADR records the reusable pattern catalogue for getting
data-platform data **into** the app and selects one for the cockpit.

The well-known Dataverse⇄lakehouse integrations (Azure Synapse Link for
Dataverse, Link to Microsoft Fabric) are **outbound** (CRM → lake). This ADR is
about the **inbound** direction.

## Options

### Option A — Materialized projection ("snapshot") ✅ preferred
A scheduled job computes aggregates on the platform and **upserts them into a
Dataverse table**, keyed by *subject · metric · as-of date*. Production producer:
Databricks job → Azure Data Factory / Synapse pipeline / Power Platform dataflow.
**Why:** the app reads a normal Dataverse table — fast, filterable, relatable to
CRM rows, governed by security roles, and it composes pixel-precisely inside a
PCF. Cost: it is a copy, so freshness is owned (daily/hourly is sufficient for
KPIs/scores/forecasts).

### Option B — Virtual table (live read-through)
A Dataverse virtual table over an OData/SQL endpoint on the lake; no copy,
always fresh. **Why not (here):** needs a stable low-latency endpoint, is
read-only with query/relationship limits, and every page render hits the
external system. Good when data is large, must be live, and read-only.

### Option C — Embedded Power BI / Fabric
Leave analytics in the lakehouse; surface an embedded visual on the page.
**Why not (here):** separate security/latency model, and hard to interleave
pixel-perfectly with a custom PCF layout. Good for rich historical charts and
cross-domain blending; real cockpits often blend A (numbers) with C (heavy
charts).

## Decision or working hypothesis

The Advisor Cockpit uses **Option A — a materialized projection**. Analytics land
in a Dataverse table (`crmshow_measuresnapshot`, in `crmshow_Integration`) via a
versioned, contract-first schema in `api/`. Because the demo tenant has no Azure
subscription, the producer is **mimicked**: synthetic "gold" fixtures are seeded
by the CD pipeline. Swapping the mock producer for a real Databricks→ADF feed
changes the **producer only** — the consumer contract is unchanged. All three
options remain valid reusable patterns for future scenarios.

## Evidence and assumptions

- **Known:** Dataverse tables are the most faithful in-context surface for a PCF;
  the demo tenant has no Azure subscription (data platform must be mocked);
  ADR-0008 keeps the platform authoritative and the CRM copy read-only.
- **Inferred:** daily/hourly freshness is adequate for the surfaced measures.
- **Evidence still required:** the real Contoso Insurance core-system/data-platform
  integration (API/event/latency) — will select the production producer for
  Option A (or move a measure to B/C).

## Validation and review triggers

Reopen when the real data-platform integration is designed, or when a measure
needs sub-minute latency (→ Option B) or rich historical drill-down (→ Option C).
Deciders: AG-E-03 + AG-E-09.

## Consequences

- **At the next release:** `crmshow_measuresnapshot` + its `api/` contract ship;
  the seed step populates DEV/TEST.
- **Operationally:** freshness/latency is a pipeline concern; the failure path is
  re-seed / re-run.
- **For the customer's teams:** the contract in `api/` is the hand-off point to
  the data-platform team; they own the producer, CRM owns the consumer.
- **Reversibility:** high — drop the table + contract; no system-of-record data
  is lost (the platform stays authoritative).

## Competitive note

Forces the equivalent engagement to state *how* analytics reach the operative
screen and *who owns freshness* — a contract-and-ownership answer, not a
dashboard screenshot.
