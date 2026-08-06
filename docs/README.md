# Documentation Index — CRM Frontier Firm Showcase

This folder holds product, design, AI, security, compliance, operations and
test artefacts that the Copilot agents in [.github/agents/](../.github/agents/)
reason over.

The illustrated primary vertical is **insurance** — see
[PERSONAS-JOURNEY.md](./PERSONAS-JOURNEY.md) and
[ideas/UC-01-relocation-across-jurisdictions/](./ideas/UC-01-relocation-across-jurisdictions/)
— but the architecture patterns generalise to any regulated B2C/B2B CRM
Frontier Firm.

## Start here

- [DESIGN-PRINCIPLES.md](./DESIGN-PRINCIPLES.md) — read before any design decision. Each principle has a failure test.
- [PRD.md](./PRD.md) — product intent, use cases, non-goals.
- [BACKLOG.md](./BACKLOG.md) — working backlog by epic.
- [PERSONAS-JOURNEY.md](./PERSONAS-JOURNEY.md) — who uses the showcase and how.
- [SD.md](./SD.md) — solution design, target architecture, dependencies stated openly.
- [COPILOT-BUILD-GUIDE.md](./COPILOT-BUILD-GUIDE.md) — how PRs move through this repo.

## Topic areas (following a common architecture-review framework)

| Topic | File | Owner |
| --- | --- | --- |
| **A1** — Architecture vision | [SD.md](./SD.md) | `AG-E-03` |
| **A2** — Data model, 360° view | [DATA.md](./DATA.md) | `AG-E-03` |
| **A3** — Integration | [INTEGRATION.md](./INTEGRATION.md) | `AG-E-04` |
| **A4** — Extensibility, upgrade safety | [EXTENSIBILITY.md](./EXTENSIBILITY.md) · [COPILOT-BUILD-GUIDE.md](./COPILOT-BUILD-GUIDE.md) | `AG-E-03` + `AG-E-02` |
| **A5** — Workflow, business cases | [PROCESSES.md](./PROCESSES.md) | `AG-E-02` |
| **A6** — AI, agents, governance | [AI.md](./AI.md) | `AG-E-06` |
| **A7** — Analytics | [ANALYTICS.md](./ANALYTICS.md) | `AG-E-03` |
| **A8** — Operations, ALM | [OPERATIONS.md](./OPERATIONS.md) | `AG-E-04` |
| **A9** — Shared responsibility | [SHARED-RESPONSIBILITY.md](./SHARED-RESPONSIBILITY.md) | `AG-E-01` |

## Cross-cutting

- [ENVIRONMENTS.md](./ENVIRONMENTS.md) — Power Platform environments (anonymised).
- [SECURITY.md](./SECURITY.md) — identity, secrets, network posture.
- [COMPLIANCE.md](./COMPLIANCE.md) — what claims the demo may and may not make.
- [LICENSING.md](./LICENSING.md) — capability register with maturity flags.
- [TEST.md](./TEST.md) — testing strategy + golden-thread regression cases.
- [GLOSSARY.md](./GLOSSARY.md) — shared vocabulary.

## Decision records

- [adr/](./adr/) — one Architecture Decision Record per architectural choice.
  Governance / build ADRs 0001–0005, domain ADRs 0006–0018.

## Workflow folders

- [ideas/](./ideas/) — intake: use cases, scenarios, customer questions.
- [specs/](./specs/) — worked designs, ready for an ADR.
- [plans/](./plans/) — delivery plans.
- [sprints/](./sprints/) — sprint delegation and status.
- [reviews/](./reviews/) — session and stakeholder review evidence.
