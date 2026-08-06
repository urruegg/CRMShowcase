# Workflow, Business Cases & End-to-End Processes

| Field | Value |
| --- | --- |
| **Topic area** | **A5** — Workflow, business cases, end-to-end processes |
| Status | Draft 0.2 |

## What the customer asks

How business and technical end-to-end processes are supported: how business
cases are **modelled, steered, monitored and extended**, and how the CRM
interacts with processes **outside** the CRM. Of particular interest: task
steering, escalations, **SLA monitoring**, monitoring, process tracking and
traceability **across several systems**. The goal: to understand which
orchestration capabilities the platform genuinely brings and **where external
workflow or process solutions become necessary.**

> That last clause is an invitation to be honest about limits. Take it. A
> provider who names where their orchestration stops is more believable on
> everything before that point.

## The demo business case

**GA reassignment on the cross-jurisdiction move**
([ADR-0013](./adr/ADR-0013-ga-ownership-and-territory.md)) — a governed
handover, not a field update. It carries ownership transfer, commissioning,
local claims routing and continuity-of-service obligations, and it spans CRM
and the systems of record.

Shown end to end: trigger → tasks → SLA → escalation → cross-system trace →
completion.

## Capabilities

| Need | Platform answer |
| --- | --- |
| Process modelling | Business process flows, flows, declarative rules |
| Task steering | Work assignment, queues, routing |
| Escalation & SLA | `[TBD — confirm the SLA mechanism and its limits]` |
| Monitoring | `[TBD]` |
| Cross-system tracing | Correlation identifier carried on every domain event ([ADR-0011](./adr/ADR-0011-event-driven-cascade.md)) |

## Where external process tooling is genuinely needed

`[TBD — answer honestly. Candidates: long-running human-centric processes
spanning many non-CRM systems; existing customer BPM investments; regulated
processes with their own evidence requirements.]`
