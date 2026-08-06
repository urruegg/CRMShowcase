# Agent Registry — Runtime & Engineering Agents

| Field | Value |
| --- | --- |
| Product | CRM Frontier Firm Showcase |
| Document | Agent Registry (runtime `AG-F-##` + engineering `AG-E-##`) |
| Version | 0.1 (Draft) |
| Status | Draft |
| Classification | Public — anonymized demo |

**Related documents:**
[docs/PERSONAS-JOURNEY.md](./docs/PERSONAS-JOURNEY.md) ·
[docs/AI.md](./docs/AI.md) ·
[docs/DATA.md](./docs/DATA.md) ·
[docs/SECURITY.md](./docs/SECURITY.md) ·
[docs/COMPLIANCE.md](./docs/COMPLIANCE.md) ·
[docs/DESIGN-PRINCIPLES.md](./docs/DESIGN-PRINCIPLES.md)

> **Two classes of agent.**
> This registry covers **(1) runtime / functional agents `AG-F-##`** — the CRM agents
> *inside* the showcase, that a sales rep or service agent actually collaborates with —
> and **(2) engineering / build-time agents `AG-E-##`** — the GitHub Copilot custom
> agents that *build* the showcase (files under [.github/agents/](./.github/agents/)).

---

## 1. Runtime agents — the CRM teammates (`AG-F-##`)

These agents run in the showcase. They are the *product* the visitor sees.
Each entry lists **Purpose · Inputs → Outputs · Realizing service · Guardrails
· Human-in-the-loop (HITL)**.

### AG-F-01 — Lead Qualification Assistant
- **Purpose.** Draft a qualification summary for a new lead so a sales rep can decide in
  under a minute whether to pursue.
- **Inputs → Outputs.** Lead record + last N interactions → grounded summary + suggested next step.
- **Realizing service.** Copilot Studio agent on top of Dataverse + Azure OpenAI reasoning model.
- **Guardrails.** Grounded in retrieved records only. Content Safety on output. No outbound send.
- **HITL.** Sales rep clicks Approve to act on the suggestion; nothing is sent automatically.

### AG-F-02 — Service Triage Agent
- **Purpose.** Classify an incoming case, pull relevant knowledge, and draft a first response.
- **Inputs → Outputs.** Case record + KB search → suggested category + draft reply.
- **Realizing service.** Copilot Studio agent + Azure AI Search (KB) + Dataverse.
- **Guardrails.** Draft reply is never sent to a customer without human approval.
  Category is proposed, not committed, until human confirms.
- **HITL.** Service agent approves category + reply before the case advances.

### AG-F-03 — Campaign Copy Generator
- **Purpose.** Draft segment-appropriate marketing copy against an approved brief.
- **Inputs → Outputs.** Brief + segment definition + brand voice → draft variants.
- **Realizing service.** Azure OpenAI + Content Safety + brand-voice grounding docs.
- **Guardrails.** Copy is drafted for review — never scheduled or sent by the agent.
  No claims (compliance, availability, pricing) unless they are in the brief.
- **HITL.** Marketing operator approves before the campaign is scheduled.

### AG-F-04 — RevOps Insights Agent
- **Purpose.** Summarise pipeline movement and flag anomalies for a RevOps lead.
- **Inputs → Outputs.** Aggregated CRM metrics → summary + top-N anomalies with links.
- **Realizing service.** Copilot Studio agent + Dataverse aggregates.
- **Guardrails.** Summary cites the underlying records. No autonomous quota / target changes.
- **HITL.** RevOps lead accepts or dismisses each flagged item.

> Additional runtime agents may be added as the showcase grows. Every new agent
> gets an entry here **and** a story in [docs/PRD.md](./docs/PRD.md).

---

## 2. Engineering agents — the builders (`AG-E-##`)

These are the GitHub Copilot custom agents that build the showcase. Each has a
dedicated file in [.github/agents/](./.github/agents/) and a matching chat mode
in [.github/chatmodes/](./.github/chatmodes/).

| Agent | File | Approves |
| --- | --- | --- |
| `AG-E-01` Product Owner | [product-owner.agent.md](./.github/agents/product-owner.agent.md) | Story shape and acceptance criteria |
| `AG-E-02` Developer | [developer.agent.md](./.github/agents/developer.agent.md) | Code slices matching a story |
| `AG-E-03` Enterprise Architect | [enterprise-architect.agent.md](./.github/agents/enterprise-architect.agent.md) | ADRs, contract shape, human/agent split |
| `AG-E-04` SecDevOps | [secdevops.agent.md](./.github/agents/secdevops.agent.md) | CI/CD, identity, IaC |
| `AG-E-05` CRM Domain Expert | [crm-domain-expert.agent.md](./.github/agents/crm-domain-expert.agent.md) | Personas, journeys, phrasing |
| `AG-E-06` Responsible-AI Officer | [responsible-ai-officer.agent.md](./.github/agents/responsible-ai-officer.agent.md) | Models, prompts, evals, Content Safety |

See [.github/agents/AGENT_WORKFLOW.md](./.github/agents/AGENT_WORKFLOW.md)
for the handoff pattern and
[.github/agents/NON_DELEGABLE_WORK.md](./.github/agents/NON_DELEGABLE_WORK.md)
for the decisions no agent may make alone.
