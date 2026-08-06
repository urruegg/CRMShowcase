# Glossary — CRM Frontier Firm Showcase

| Term | Meaning in this repo |
| --- | --- |
| **Frontier Firm** | An organisation in which humans and AI agents work as a team. Coined by the Microsoft Work Trend Index. |
| **Human-agent team** | A workflow that explicitly splits *human decides* from *agent proposes / acts*. |
| **Runtime agent (`AG-F-##`)** | An agent *in* the showcase (e.g., Lead Qualification Assistant). See [AGENTS.md](../AGENTS.md). |
| **Engineering agent (`AG-E-##`)** | A GitHub Copilot custom agent that *builds* the showcase. See [.github/agents/](../.github/agents/). |
| **Deterministic action layer** | The schema-validated code that sits between an LLM proposal and a CRM mutation. See [AI.md §4](./AI.md). |
| **Grounding** | The property that a generated message refers only to information the agent actually retrieved. |
| **Golden set** | The versioned set of synthetic CRM scenarios used to evaluate AI behaviour. See [AI.md §7](./AI.md). |
| **Story (`US-###`)** | A user-story entry in [PRD.md](./PRD.md), scoped to fit in one PR. |
| **ADR** | Architecture Decision Record. One per architectural decision, in [adr/](./adr/). |
| **Superpowers Contract** | The binding operating contract for every Copilot agent in this repo. See [SUPERPOWERS_CONTRACT.md](../SUPERPOWERS_CONTRACT.md). |
