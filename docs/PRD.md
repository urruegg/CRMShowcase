# PRD — CRM Frontier Firm Showcase

| Field | Value |
| --- | --- |
| Version | 0.1 (Draft) |
| Status | Draft |

> **Template.** Replace the placeholders as the showcase concretises. Do not delete the
> template structure — the Copilot agents rely on the section headings.

## 1. Purpose

A reference implementation that demonstrates a modern **CRM built with human-agent teams**:
sales, service, and marketing workflows executed collaboratively by humans and Copilot /
Copilot Studio agents on top of a CRM data plane.

The showcase is a **demo, not a production system**. Every design decision is a
demonstration of a pattern, not a delivery to a live customer.

## 2. Personas
See [PERSONAS-JOURNEY.md](./PERSONAS-JOURNEY.md).

## 3. Use cases

### UC1 — Assisted lead-to-cash
Sales rep + Lead Qualification Assistant (`AG-F-01`) collaborate from a new inbound lead
through to a first meeting scheduled.

### UC2 — Agentic service triage & resolution
Service agent + Service Triage Agent (`AG-F-02`) collaborate to categorise, respond to, and
resolve incoming cases with grounded knowledge.

### UC3 — Human-in-the-loop marketing campaign generation
Marketing operator + Campaign Copy Generator (`AG-F-03`) collaborate to produce
segment-appropriate copy variants for a scheduled campaign.

## 4. Backlog

> Add new stories here as `US-###` entries. Every story links to a use case and one or
> more principles from [DESIGN-PRINCIPLES.md](./DESIGN-PRINCIPLES.md).

### US-001 — Repo bootstrap (this PR)
As a repo maintainer, I want the Copilot governance stack in place, so that every
subsequent contribution is traceable and safe by default.

**Acceptance criteria**
- Repo has `.github/copilot-instructions.md`, `.github/agents/`, `.github/chatmodes/`,
  and `.github/instructions/superpowers.instructions.md`.
- Repo has `SUPERPOWERS_CONTRACT.md` and `AGENTS.md`.
- Repo has this `docs/` folder with template artefacts.
- Every internal link resolves.

**Traceability**
- Use case: (repo enablement, not a UC)
- Principles: DP-08 (small slices), DP-09 (evidence-in-PR)

### US-002 — Example story shape (placeholder)
As a Sales rep, I want a grounded qualification summary for a new lead, so that I can
decide in under 60 seconds whether to pursue.

**Acceptance criteria**
- The summary is grounded in the lead record and last 5 interactions.
- The summary never claims a source it did not retrieve.
- Nothing is sent until I click Approve.

**Traceability**
- Use case: UC1
- Principles: DP-03, DP-04, DP-11

## 5. Out of scope

- Real customer data of any kind (DP-05).
- Any integration into a customer's production tenant (DP-06).
- Live outbound communication without human approval (DP-03).
