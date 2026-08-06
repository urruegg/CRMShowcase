# Architecture Domain: Other Systems

## Scope

Everything the CRM platform integrates with, but does not own: identity,
ERP/finance, messaging/notifications, analytics/data platform, and any
other supporting system. This domain owns the integration contracts
(schemas, events, auth) between the CRM and the outside world.

## Key Components

- **Identity & access** — the identity provider used for authentication and
  single sign-on into the CRM platform, and how CRM security roles map to
  external group/role claims.
- **ERP / finance integration** — synchronization of accounts, products,
  pricing, and orders/invoices between the CRM and back-office/ERP systems.
- **Messaging & notifications** — email, SMS, and push notification
  providers used by functional domains (e.g. Marketing journeys, Customer
  Service case notifications).
- **Data platform / analytics** — data export, warehousing, and reporting
  pipelines that consume CRM data for BI and cross-system analytics.

## Conventions

- Integrations are defined by an explicit contract (schema + auth +
  ownership) documented here before implementation begins.
- Prefer event-driven/async integration for non-blocking flows (e.g.
  notifications, analytics export) and synchronous APIs only when the
  functional domain requires an immediate response.
- Changes to an external system's contract must be reflected in this
  document and communicated to every functional domain that depends on it.

## Related Domains

- [CRM Core Platform](crm.md) — the platform side of every integration
  listed above.
- Functional domains that consume these integrations: see
  [`docs/domains/functional/`](../functional/) (e.g. Marketing depends on
  messaging providers, Sales depends on the ERP integration for pricing).
