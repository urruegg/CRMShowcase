# CRM Showcase

CRM Frontier Firm Showcase — a reference implementation for a modern CRM built
with **human-agent teams** on top of Dynamics 365 / Dataverse / Power Platform
/ Copilot Studio / Azure AI Foundry. The illustrated vertical is **insurance**;
the architecture patterns generalise to any regulated B2C/B2B CRM.

## Executive summary

The question that shapes a CRM programme running past 2038 is not *"can this
platform satisfy today's requirements?"* but *"can it enable the requirements
that do not exist yet?"* This repository is the engineering surface behind that
answer: the design decisions, the data model, the integration contracts, the
agent definitions and the pipeline that produce the Dynamics 365 solution the
customer sees running in the sandbox.

**GitHub-native, agent-driven delivery** with end-to-end traceability from
requirement → ADR → solution change → test → evidence is the delivery model we
propose *and* the thing we demonstrate live.

## Three modes

| Mode | What it is | Where it lives |
| --- | --- | --- |
| **RUN** | The working solution, live | Sandbox environment |
| **DESIGN** | Decisions, models, contracts | [docs/](./docs/), [docs/adr/](./docs/adr/) |
| **BUILD** | Agents producing a real change | [.github/agents/](./.github/agents/), [solution/](./solution/) |

**RUN always comes first in any demonstration.** DESIGN and BUILD are the
answer to *"and how did it get there — and what happens at the next release?"*

## The golden thread

One customer, one change, cascading — see
[docs/ideas/UC-01-relocation-across-jurisdictions/](./docs/ideas/UC-01-relocation-across-jurisdictions/).

> The Smith household relocates across a jurisdiction boundary. One address
> change must re-rate motor, contents and natural-hazard cover; **withdraw and
> re-originate** building cover because the jurisdiction changed; reassign the
> household to a different General Agent; and unwind the multi-product
> discount on the remaining policies.

Every architectural conversation is validated against this one thread.

## Copilot governance

Every contribution — human or Copilot — follows the same rules:

- [SUPERPOWERS_CONTRACT.md](./SUPERPOWERS_CONTRACT.md) — binding operating contract.
- [AGENTS.md](./AGENTS.md) — 6 runtime agents (`AG-F-##`) + 10 engineering agents (`AG-E-##`).
- [CONTRIBUTING.md](./CONTRIBUTING.md) — ground rules and workflow.
- [.github/copilot-instructions.md](./.github/copilot-instructions.md) — repo-wide Copilot rules.
- [.github/instructions/superpowers.instructions.md](./.github/instructions/superpowers.instructions.md) — path-scoped rules loaded automatically.
- [.github/agents/](./.github/agents/) — one Copilot custom agent per engineering role.
- [.github/chatmodes/](./.github/chatmodes/) — the same roles as chat modes.

## Documentation

Start here:
- [docs/DESIGN-PRINCIPLES.md](./docs/DESIGN-PRINCIPLES.md) — read before any design decision. Each principle has a failure test.
- [docs/PRD.md](./docs/PRD.md) — product intent, use cases, non-goals.
- [docs/SD.md](./docs/SD.md) — solution design and target architecture.
- [docs/BACKLOG.md](./docs/BACKLOG.md) — working backlog by epic.
- [docs/COPILOT-BUILD-GUIDE.md](./docs/COPILOT-BUILD-GUIDE.md) — how PRs move through this repo.

Full index: [docs/README.md](./docs/README.md).

## Repository layout

```
README.md   AGENTS.md   SUPERPOWERS_CONTRACT.md   CONTRIBUTING.md
.github/
   copilot-instructions.md
   agents/*.agent.md           10 engineering agents (AG-E-01..10)
   chatmodes/*.chatmode.md     matching chatmodes
   instructions/               path-scoped rules
   prompts/                    reusable prompts
   workflows/                  ci-solution · cd-infra · cd-solution-dev/test
   ISSUE_TEMPLATE/             governance escalation etc.
   pull_request_template.md
docs/
   SD · DATA · INTEGRATION · EXTENSIBILITY · PROCESSES · AI · ANALYTICS
   OPERATIONS · SHARED-RESPONSIBILITY · LICENSING · COMPLIANCE · SECURITY
   DESIGN-PRINCIPLES · PERSONAS-JOURNEY · TEST · BACKLOG · COPILOT-BUILD-GUIDE
   PRD · GLOSSARY · ENVIRONMENTS
   adr/                        architecture decision records (0001..0018)
   ideas · specs · plans · sprints · reviews
api/                            integration contracts (OpenAPI, event schemas)
data/scenarios/                 the golden-thread fixture (synthetic only)
solution/                       unmanaged Dataverse solution, source-controlled
infra/terraform/                IaC for tenant, environments, Entra, GitHub
```

## Licensing flag

Every capability section carries one of:

- `✅` in the offer
- `➕` additional licence required
- `🧩` configuration / own build — no additional licence
- `🗺️` roadmap — not yet productive

The consolidated view is [docs/LICENSING.md](./docs/LICENSING.md).
**An unflagged capability is a finding.**

## Disclaimers

- **Public — anonymised demo.** No real customer identity, policy or claims data.
  The illustrated customer is fictional (Contoso Insurance); the illustrated
  household is fictional (the Smith household).
- **All commercial and licensing statements are indicative** in a demo context;
  in a real engagement they must be confirmed against the offer before being
  asserted.
- **Not legal advice** — data-protection and regulatory positions in
  [docs/COMPLIANCE.md](./docs/COMPLIANCE.md) are illustrative; the customer's
  legal function validates them in a real programme.
