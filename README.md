# CRM Showcase

CRM Frontier Firm Showcase Implementation — a reference for a CRM built with
**human-agent teams** on top of Dynamics 365 / Dataverse / Power Platform / Copilot
Studio / Azure AI Foundry.

## Copilot governance

This repo runs a governed agent-driven build model. Every contribution — human or
Copilot — follows the same rules:

- [SUPERPOWERS_CONTRACT.md](./SUPERPOWERS_CONTRACT.md) — binding operating contract.
- [AGENTS.md](./AGENTS.md) — runtime and engineering agent registry.
- [.github/copilot-instructions.md](./.github/copilot-instructions.md) — repo-wide Copilot rules.
- [.github/instructions/superpowers.instructions.md](./.github/instructions/superpowers.instructions.md) — path-scoped rules loaded automatically.
- [.github/agents/](./.github/agents/) — one Copilot custom agent per engineering role.
- [.github/chatmodes/](./.github/chatmodes/) — the same roles as chat modes.
- [docs/](./docs/) — product, design, AI, security, compliance, test artefacts.

## Read next

- [docs/DESIGN-PRINCIPLES.md](./docs/DESIGN-PRINCIPLES.md) — read before any design decision.
- [docs/PRD.md](./docs/PRD.md) — use cases and backlog.
- [docs/COPILOT-BUILD-GUIDE.md](./docs/COPILOT-BUILD-GUIDE.md) — how PRs move through this repo.
