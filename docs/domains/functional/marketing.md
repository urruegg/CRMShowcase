# Functional Domain: Marketing

## Scope

Campaign planning and execution, audience segmentation, and customer
journeys used to generate and nurture leads for Sales.

## Key Processes

- **Segmentation** — building marketing lists/segments from CRM data.
- **Campaigns & journeys** — multi-step, multi-channel campaigns
  (email, SMS, events) and automated customer journeys.
- **Lead generation & nurture** — capturing and scoring leads before
  handoff to [Sales](sales.md).
- **Campaign performance reporting** — engagement, conversion, and ROI
  reporting per campaign/journey.

## Personas

- Marketing manager
- Campaign/journey designer
- Marketing operations / administrator

## Conventions

- Journeys and campaigns send through the messaging providers defined in
  [Other Systems](../architecture/other-systems.md); do not integrate
  directly with a new provider without updating that integration contract.
- Segmentation queries should reuse the shared data model owned by the
  [CRM Core Platform](../architecture/crm.md).

## Related Domains

- [CRM Core Platform](../architecture/crm.md) — shared Contact/Lead data.
- [Other Systems](../architecture/other-systems.md) — messaging/notification
  providers.
- [Sales](sales.md) — receives qualified leads from Marketing.
