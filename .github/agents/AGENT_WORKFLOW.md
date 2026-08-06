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
