# Engineering Agent Workflow

This document explains how the engineering custom agents in [.github/agents/](./)
cooperate to move work from idea → merged code → running demo.

## Handoff pattern

```
Idea / request
   │
   ▼
Product Owner  ─────►  story + acceptance criteria in docs/PRD.md
   │
   ▼
Enterprise Architect  ─────►  design note or ADR in docs/adr/
   │
   ▼
Developer  ─────►  code + tests, PR opened
   │
   ▼
Responsible-AI Officer  ─────►  approves AI-touching PRs (models, prompts, evals)
   │
   ▼
SecDevOps  ─────►  approves changes to CI, IaC, identity, or secret handling
   │
   ▼
Merge  ─────►  Developer or CRM Domain Expert verifies demo behaviour
```

## When to pick which agent

| I need to... | Ask this agent |
| --- | --- |
| Refine a user story or split an epic | Product Owner |
| Decide between Dataverse vs. Cosmos, or synchronous vs. event-driven | Enterprise Architect |
| Implement a Copilot Studio topic, a plug-in, or a Dataverse table | Developer |
| Review whether an AI change is safe to ship | Responsible-AI Officer |
| Wire up CI, GitHub Actions, or Managed Identity | SecDevOps |
| Check that a phrasing / journey feels right for a sales rep or service agent | CRM Domain Expert |

## Rules that apply to every agent

- Follow [SUPERPOWERS_CONTRACT.md](../../SUPERPOWERS_CONTRACT.md).
- Escalate rather than work around a guardrail.
- Prefer small, reviewable slices.
- If you touch models, prompts, or tool schemas, add or update an ADR.
- Treat Dataverse metadata as a governed semantic contract. English (`1033`) is
  the base language; German (`1031`), French (`1036`), and Italian (`1040`) are
  supported translations using native Dataverse localized labels.
- Every table, column, relationship, choice and action must have a precise
  English description; user-visible names, labels, choice text, help text, form
  labels and relevant descriptions must be translated into DE, FR and IT.
- Reject placeholder, tautological or implementation-only descriptions.
  Metadata must explain business meaning, scope, source/mastership, units or
  canonical values, sensitivity, and lifecycle where relevant so humans,
  Copilot and other agents can discover the model semantically.
