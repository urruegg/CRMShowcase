# Functional Domain: Customer Service

## Scope

Case management and post-sales support: intake, triage, resolution, and
knowledge sharing, governed by service-level agreements (SLAs) and
entitlements.

## Key Processes

- **Case management** — intake (omnichannel), triage, assignment, and
  resolution tracking.
- **Knowledge base** — authoring, review, and publishing of knowledge
  articles used to resolve cases and support self-service.
- **Entitlements & SLAs** — customer support contracts, entitlement
  consumption, and SLA timers/escalations.
- **Queues & routing** — rule-based case routing to the right team or
  agent.

## Personas

- Customer service representative / agent
- Customer service manager
- Knowledge author

## Conventions

- SLA and entitlement rules should be modeled as configuration on top of
  the shared security/data model in the
  [CRM Core Platform](../architecture/crm.md), not hard-coded.
- Case notifications (email/SMS) go through the messaging providers
  defined in [Other Systems](../architecture/other-systems.md).

## Related Domains

- [CRM Core Platform](../architecture/crm.md) — shared Account/Contact data
  used by every case.
- [Other Systems](../architecture/other-systems.md) — notification/
  messaging integration.
- [Field Service](field-service.md) — cases can generate work orders for
  on-site resolution.
