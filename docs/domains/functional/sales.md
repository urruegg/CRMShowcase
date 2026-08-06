# Functional Domain: Sales

## Scope

The lead-to-cash process: capturing leads, qualifying them into
opportunities, producing quotes, and converting won opportunities into
orders.

## Key Processes

- **Lead management** — capture, qualification, and conversion of leads
  into accounts/contacts/opportunities.
- **Opportunity management** — sales stages, pipeline forecasting, and
  competitor tracking.
- **Quoting & ordering** — product/price list configuration, quote
  generation, and order fulfillment handoff.
- **Forecasting & reporting** — sales pipeline and performance dashboards
  for sales managers and reps.

## Personas

- Sales representative
- Sales manager
- Sales operations / administrator

## Conventions

- Sales-specific customizations (forms, views, business rules) should stay
  scoped to Sales entities; shared entities (Account, Contact) are owned by
  the [CRM Core Platform](../architecture/crm.md) architecture domain.
- Pricing and product data sourced from an ERP should go through the
  integration contract defined in
  [Other Systems](../architecture/other-systems.md), not be duplicated
  locally.

## Related Domains

- [CRM Core Platform](../architecture/crm.md) — shared data model and
  security.
- [Other Systems](../architecture/other-systems.md) — ERP integration for
  pricing/orders.
- [Marketing](marketing.md) — hands off qualified leads to Sales.
