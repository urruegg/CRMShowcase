# CRM Showcase — GitHub Copilot Custom Instructions

| Field | Value |
| --- | --- |
| Product | CRM Frontier Firm Showcase |
| Document | Repo-wide Copilot Custom Instructions |
| Version | 0.1 (Draft) |
| Status | Draft |
| Classification | Public — anonymized demo |

<!--
Repository-wide instructions for GitHub Copilot (chat, coding agent, code completion).
Keep them concise and imperative. They are ALWAYS in context — do not bloat.
Deeper detail lives in ../docs/ and ../SUPERPOWERS_CONTRACT.md.
Related: ../AGENTS.md · ../SUPERPOWERS_CONTRACT.md · ./agents/*.agent.md · ./instructions/superpowers.instructions.md
-->

You are helping build the **CRM Frontier Firm Showcase**: a reference implementation that
demonstrates a modern **human-agent CRM** — sales, service, and marketing workflows
executed collaboratively by humans and Copilot / Copilot Studio agents on top of a
CRM data plane (Dynamics 365 / Dataverse / Power Platform / Azure AI Foundry).

Follow these instructions for every suggestion, chat answer, and coding-agent task in this repo.

## 1. Project context (read first)

- **Product**: CRM Frontier Firm Showcase — a demo, not a production system.
- **Frontier Firm framing**: humans and agents work as a team; agents are teammates that
  reason, act, and hand off, while humans stay accountable for customer-facing decisions.
- **Primary personas** (see [docs/PERSONAS-JOURNEY.md](../docs/PERSONAS-JOURNEY.md)):
  Sales rep, Service agent, Marketing operator, RevOps lead, Customer.
- **Primary use cases** (see [docs/PRD.md](../docs/PRD.md)):
  UC1 — Assisted lead-to-cash; UC2 — Agentic service triage & resolution;
  UC3 — Human-in-the-loop marketing campaign generation.
- Start every design decision from [docs/DESIGN-PRINCIPLES.md](../docs/DESIGN-PRINCIPLES.md)
  and the guardrails below.

## 2. Mandatory guardrails (never violate)

1. **No real customer data in the demo.** Use only synthetic or clearly-labelled
   sample data. Never introduce real names, emails, phone numbers, contract values,
   or CRM exports into fixtures, tests, seed scripts, or config.
2. **No secrets in code.** Credentials, keys, connection strings, and tokens never
   enter source, config, fixtures, or logs. Prefer **Microsoft Entra ID + Managed Identity**;
   store any secrets in **Azure Key Vault**. Secret scanning and push protection must stay green.
3. **Tenant isolation.** Demo workloads run in an isolated Microsoft 365 / Azure demo tenant.
   Do not add code paths, connections, or configuration that reach into a customer's
   production tenant.
4. **Responsible AI is enforced.** The LLM proposes; a deterministic, schema-validated layer
   disposes. See [docs/AI.md](../docs/AI.md). Every customer-visible generated output
   passes content-safety checks and is grounded in retrieved CRM context, not free-text
   invention.
5. **Human accountability for customer-impacting actions.** Agents may draft emails,
   summarise cases, and propose next steps, but sending outbound communication,
   changing pricing/quotes, or closing cases requires human approval unless explicitly
   scoped otherwise in the acceptance criteria of the story.
6. **Traceability in PRs.** Every PR links to a user story (`US-###` in
   [docs/PRD.md](../docs/PRD.md) or the backlog) and cites the design principle
   or ADR it advances.
7. **Evidence-in-PR.** Every PR includes green CI, tests for the changed behaviour,
   and — where AI behaviour changed — a link to the eval run in
   [docs/AI.md §7](../docs/AI.md).
8. **No silent changes to models, prompts, or agent tool schemas.** Version them in Git,
   review them in a PR, and record the decision in [docs/adr/](../docs/adr/) when it is
   architectural.
9. **Documentation first for cross-cutting decisions.** When a change affects the API
   contract, data model, residency, RAI stance, or the split of work between humans
   and agents, update or add an ADR before merging code.

## 3. How to write code in this repo

- Prefer **small, reviewable slices** over broad "final solution" PRs.
- Prefer **ecosystem tools** (package managers, scaffolders, refactoring tools, linters)
  over hand edits.
- Do not add new linting, build, or test tooling unless the task requires it.
- Do not fix unrelated issues in the same PR — call them out separately.
- Only comment code that genuinely needs clarification.

## 4. Where to look for deeper detail

- [SUPERPOWERS_CONTRACT.md](../SUPERPOWERS_CONTRACT.md) — the binding operating contract
  for every agent working in this repo.
- [AGENTS.md](../AGENTS.md) — the registry of engineering and runtime agents.
- [.github/agents/](./agents/) — one Markdown file per custom agent Copilot can adopt.
- [.github/chatmodes/](./chatmodes/) — the same personas exposed as chat modes.
- [.github/instructions/superpowers.instructions.md](./instructions/superpowers.instructions.md) — path-scoped rules loaded automatically.
- [docs/](../docs/) — product, design, AI, security, compliance, test, and ADR templates.
