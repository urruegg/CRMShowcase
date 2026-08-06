# PRD — CRM Frontier Firm Showcase

| Field | Value |
| --- | --- |
| Version | 0.2 (Draft) |
| Status | Draft |

## 1. Purpose

A reference implementation that demonstrates a modern **CRM built with
human-agent teams** — sales, service, marketing and after-sales workflows
executed collaboratively by humans and Copilot / Copilot Studio agents on top
of a CRM data plane (Dynamics 365 / Dataverse / Power Platform / Azure AI
Foundry).

The showcase is a **demo, not a production system**. Every design decision is
a demonstration of a pattern, not a delivery to a live customer.

## 2. Illustrated vertical

The primary illustrated use case is **insurance** — an insurer running a
household portfolio through a network of General Agents. The architecture
patterns generalise to any regulated B2C/B2B CRM Frontier Firm; insurance is
the vehicle because it exposes every hard question (jurisdictional
eligibility, multi-master data, human-in-the-loop under regulation, portfolio
mechanics, agent territory) more sharply than most.

Illustrated customer: **Contoso Insurance** (fictional). Illustrated household:
**the Smith family**. Illustrated golden thread: the household relocates
across a jurisdiction boundary — see
[ideas/UC-01-relocation-across-jurisdictions/](./ideas/UC-01-relocation-across-jurisdictions/).

## 3. Personas
See [PERSONAS-JOURNEY.md](./PERSONAS-JOURNEY.md).

## 4. Use cases

### UC-01 — Household relocation across a jurisdiction boundary (golden thread)
One address change → cascade to all affected policies → coverage-existence
re-evaluation → GA reassignment → portfolio-discount recalculation → advisory
opportunity generated. See
[ideas/UC-01-relocation-across-jurisdictions/](./ideas/UC-01-relocation-across-jurisdictions/).

### UC-02 — Assisted lead-to-close
Advisor + Next-Best-Action Agent (`AG-F-01`) collaborate from a governed
signal (life event, service touchpoint, campaign response) through to a
scheduled first meeting.

### UC-03 — Agentic service triage & resolution
Assistance agent + Case Management Agent (`AG-F-03`) + Conversation
Intelligence Agent (`AG-F-04`) collaborate to categorise, respond to, and
resolve incoming cases with grounded knowledge.

### UC-04 — Human-in-the-loop marketing campaign generation
Marketer + Campaign & Content Assist Agent (`AG-F-06`) collaborate to produce
segment-appropriate copy variants for a scheduled campaign.

### UC-05 — Closed-loop data quality
Data steward + Data-Quality & Identity-Resolution Agent (`AG-F-05`) collaborate
to close a duplicate / ambiguous-identity remediation task with a recorded
decision.

## 5. Backlog

The full working backlog by epic lives in [BACKLOG.md](./BACKLOG.md). Story IDs
are stable; priorities move but IDs do not.

## 6. Out of scope

- Real customer data of any kind (DP-14).
- Any integration into a customer's production tenant.
- Live outbound communication without human approval
  ([ADR-0014](./adr/ADR-0014-agents-advisory-by-design.md)).
- Insurance-technical logic in the CRM
  ([ADR-0008](./adr/ADR-0008-thin-crm-over-systems-of-record.md)).
