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
| **1 · Configuration** | Fields, model-driven forms, views, timelines, commands, business rules, security roles, templates | **None** — carried by the platform | Business function, within governance |
| **2 · Low-code** | Declarative canvas apps, flows, Copilot Studio agents and declarative logic | **Low** — versioned, testable, reversible | IT / Power Platform team |
| **3 · Pro-code** | Power Apps Code Apps, plugins, custom APIs, PCF controls and external services | **Declared per change** — requires ADR | IT / partner, with EA approval |

**The rule that makes this real:** an extension with no declared upgrade impact
does not merge. It is enforced in the ADR template and in CI — not in a
governance handbook nobody reads.

## CRM UX build order

[ADR-0041](./adr/ADR-0041-code-apps-primary-for-bespoke-full-page-crm-ux.md)
commits this placement rule:

1. Use **model-driven configuration** for native forms, views, timelines and
   commands.
2. Use **Power Apps Code Apps** for bespoke full-page CRM experiences after the
   native path is shown to be insufficient.
3. Use **PCF** for embedded controls that require form, dataset or field
   context.

Code Apps use Power Apps managed hosting, but their TypeScript/React source is
an own-build pro-code extension for governance and upgrade purposes. A
declarative canvas app remains a low-code option when its interaction model is
sufficient; it is not interchangeable with a Code App in the extension tier.
Every Code App requires a declared upgrade impact and Power Apps Premium plus
applicable Dynamics 365 / Copilot Studio persona-level licensing validation.

The Advisor Cockpit B1/B2 parity proof validates host placement. It does not
change this build order or select B1/B2 before live DEV and TEST evidence.

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
- **Where Code Apps fit:** bespoke full-page CRM work that needs a controlled
  responsive React experience, app-local generated Dataverse services and
  managed Power Apps hosting. Native forms and timelines remain model-driven
  deep work rather than being rebuilt inside the Code App.
- **Where PCF fits:** embedded controls whose behavior depends on model-driven
  form, dataset or field context.
- **Where the boundaries are:** generated-service limitations stay visible;
  authenticated and deployed apps have no fixture fallback; app sharing,
  Dataverse roles and model-driven access are validated separately; DEV
  publication is attended; TEST is managed-pipeline only; environment URLs are
  configuration rather than source constants.

For full-page work, follow the
[Code App Local-First Polish Loop](./superpowers/patterns/code-app-local-first-polish-loop.md).
For embedded PCF work, follow the retained
[PCF Local-First Polish Loop](./superpowers/patterns/pcf-local-first-polish-loop.md).

## The live demonstration

See [COPILOT-BUILD-GUIDE.md](./COPILOT-BUILD-GUIDE.md). Question → ADR →
solution change + test → PR → pipeline → sandbox → **rollback**.

The closing line: *"That was not an unmanaged customization. It was reviewed
source, tested evidence and a reversible managed release."*
