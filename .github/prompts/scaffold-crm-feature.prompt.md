---
mode: agent
description: Scaffold a new CRM Frontier Firm showcase feature end-to-end (story → design → code stub → tests → docs).
---

# Prompt — Scaffold a CRM showcase feature

Use this prompt to add a new feature to the CRM Frontier Firm Showcase.

## Inputs I need from you

1. **User story** in the form: *As a &lt;persona&gt;, I want &lt;capability&gt;, so that &lt;outcome&gt;.*
2. **Use case link**: UC1, UC2, or UC3 from [docs/PRD.md](../../docs/PRD.md).
3. **Autonomy scope**: fully human-driven, human-in-the-loop, or agent-autonomous with human review.
4. **Data source**: Dataverse table(s) / external system(s) touched.

## What I will produce

- A story entry (`US-###`) draft appended to the backlog section of [docs/PRD.md](../../docs/PRD.md).
- If architecture-impacting: a new ADR under [docs/adr/](../../docs/adr/) following the ADR-0001 shape.
- A code stub with clear TODO markers where deterministic validation must live.
- A test skeleton covering: happy path, unsupported input, and — for AI paths — a grounding check.
- A checklist in the PR description mapping to the guardrails in
  [SUPERPOWERS_CONTRACT.md](../../SUPERPOWERS_CONTRACT.md) §1.

## What I will refuse to do

- Introduce real customer data.
- Introduce secrets.
- Give an agent authority to send external communication or change financial fields without human approval, unless the story's acceptance criteria explicitly scopes it.
- Bypass Content Safety on customer-visible generated output.
