# Copilot Instructions — CRMShowcase-

CRMShowcase- is a showcase implementation of a Customer Relationship
Management (CRM) platform for a "Frontier Firm". This document is the
repository-wide entry point for GitHub Copilot (chat, code review, and the
coding agent). It describes how the repository is organized and points to
the more detailed, domain-specific guidance that lives under `docs/domains/`
and `.github/agents/`.

## How this repository is organized

Content is split into two complementary taxonomies so that both platform
engineers and business/functional stakeholders can find the guidance that
matters to them:

1. **Architecture domains** — how the system is built and integrated.
   See [`docs/domains/architecture/`](../docs/domains/architecture/).
   - [CRM Core Platform](../docs/domains/architecture/crm.md)
   - [Other Systems (integrations & supporting platforms)](../docs/domains/architecture/other-systems.md)
2. **Functional domains** — what the system does for the business.
   See [`docs/domains/functional/`](../docs/domains/functional/).
   - [Sales](../docs/domains/functional/sales.md)
   - [Customer Service](../docs/domains/functional/customer-service.md)
   - [Marketing](../docs/domains/functional/marketing.md)
   - [Field Service](../docs/domains/functional/field-service.md)

Each domain doc describes its scope, key components/processes, and any
domain-specific conventions. When working on a change, start by reading the
relevant architecture domain doc (to understand system boundaries) and the
relevant functional domain doc (to understand the business process being
supported).

## Custom agents

Domain-scoped custom agents are defined under [`.github/agents/`](agents/).
Prefer invoking the agent matching the domain you are working in — it
carries the narrower context and conventions for that domain — over the
general-purpose default agent. See [`.github/agents/README.md`](agents/README.md)
for the full list.

## General conventions

- Keep changes minimal and scoped to the domain(s) affected by the task.
- When a change spans multiple domains, call this out explicitly in the PR
  description and update the docs for every affected domain.
- Prefer updating an existing domain doc over creating a new, overlapping
  one. If a new domain is genuinely needed, add it to both the domain
  folder and the domain map above.
- Do not duplicate business logic documentation between architecture and
  functional docs — architecture docs describe *how* (systems, data,
  integration), functional docs describe *what/why* (business process,
  personas, outcomes).
