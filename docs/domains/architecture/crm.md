# Architecture Domain: CRM Core Platform

## Scope

The core CRM platform that backs all functional domains (Sales, Customer
Service, Marketing, Field Service). This includes the data model, the
customization/extensibility layer, security model, and the APIs exposed to
functional modules and to other systems.

## Key Components

- **Data model** — core entities shared across functional domains (Account,
  Contact, Lead, Opportunity, Case, Campaign, Work Order) and the
  relationships between them.
- **Customization layer** — forms, views, business rules, workflows/flows,
  and plugins/extensions used to tailor the platform per functional domain
  without forking core logic.
- **Security model** — role-based access control, business unit hierarchy,
  and field-level security shared by every functional domain.
- **APIs** — the interfaces (REST/Web API, SDK, webhooks/events) that
  functional modules and [other systems](other-systems.md) use to read and
  write CRM data.

## Conventions

- Keep entity and field naming consistent across functional domains; do not
  introduce domain-specific duplicates of shared entities (e.g. a single
  `Account` entity is reused by Sales, Customer Service, and Field Service).
- Cross-cutting platform changes (security, data model, APIs) belong here,
  even if the motivating use case comes from a single functional domain.
- Prefer configuration/customization over code-level extensions when a
  requirement can be met either way.

## Related Domains

- [Other Systems](other-systems.md) — integration boundary for anything
  outside the CRM platform itself.
- All functional domains under
  [`docs/domains/functional/`](../functional/) build on top of this
  platform.
