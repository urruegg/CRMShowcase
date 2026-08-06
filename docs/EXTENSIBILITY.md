# Configuration, Extensibility & Upgrade Safety

| Field | Value |
| --- | --- |
| **Topic area** | **A4** — Configuration, extensibility, upgrade safety |
| Status | Draft 0.2 · **Owner** `AG-E-03` Enterprise Architect + `AG-E-02` Developer |

## What the customer asks

How flexibly the solution can be adapted, **and what such adaptations cost long
term**: which changes are pure configuration, which are low-code, and where
classic custom development becomes necessary — plus transparency on how those
extensions affect **upgradeability, maintainability and release changes**.
Specifically: how far individual General Agent requirements can be supported
*without* endangering standardisation and long-term controllability. And:
transparency on the possibilities and restrictions of UI adaptation — which is
often flagged as high value.

> This is the topic where most CRM answers are aspirational. It is also the
> topic where a repository beats a slide most decisively.

## The decision tree

Always in this order. State which tier you chose and why.

| Tier | Use when | Upgrade impact | Who can do it (A9) |
| --- | --- | --- | --- |
| **1 · Configuration** | Fields, forms, views, business rules, security roles, templates | **None** — carried by the platform | Business function, within governance |
| **2 · Low-code** | Flows, Power Apps surfaces, Copilot Studio agents, declarative logic | **Low** — versioned, testable, reversible | IT / Power Platform team |
| **3 · Pro-code** | Plugins, custom APIs, PCF controls, external services | **Declared per change** — requires ADR | IT / partner, with EA approval |

**The rule that makes this real:** an extension with no declared upgrade impact
does not merge. It is enforced in the ADR template and in CI — not in a
governance handbook nobody reads.

## GA individuality vs. standardisation

The real tension in extensibility, and the one the customer cares most about:

- **Central:** data model, templates, CI/CD rules, approval processes, eligibility
  and pricing rules, KPI definitions.
- **Local (GA):** content, selections, local campaigns and events, working
  preferences — inside a **governed extension surface**.
- **Never:** per-GA forks of the model or the solution. That is how a platform
  becomes unmaintainable, and it is the outcome to name explicitly as the thing
  we are preventing.

See [ADR-0013](./adr/ADR-0013-ga-ownership-and-territory.md) for ownership and
territory.

## UI adaptation — possibilities and restrictions

Often flagged as high value, which usually means the customer has been burned
before. Answer with both halves:

- **What is straightforward:** forms, views, dashboards, command bar,
  role-based surfaces, branded model-driven experiences.
- **Where the boundaries are:** `[TBD — enumerate honestly. An unqualified
  "fully customisable" will not survive contact with the customer's architects.]`

## The live demonstration

See [COPILOT-BUILD-GUIDE.md](./COPILOT-BUILD-GUIDE.md). Question → ADR →
solution change + test → PR → pipeline → sandbox → **rollback**.

The closing line: *"That was not custom development. That was a pull request —
documented, tested, reversible."*
