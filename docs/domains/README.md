# Domain Map

This repository's documentation and Copilot guidance are organized into two
complementary domain taxonomies. Every piece of guidance should live in
exactly one of these folders (or reference it) so that the "source of
truth" for a given concern is unambiguous.

## Architecture domains — `architecture/`

Describe **how** the system is built: platforms, integration points, data
flows, and technical ownership boundaries.

| Domain | Description |
| --- | --- |
| [CRM](architecture/crm.md) | The core CRM platform: entities, data model, customization layer. |
| [Other Systems](architecture/other-systems.md) | Everything the CRM integrates with: ERP, identity, messaging, data platform, and other supporting systems. |

## Functional domains — `functional/`

Describe **what** the system does for the business: processes, personas,
and outcomes, independent of the underlying technology.

| Domain | Description |
| --- | --- |
| [Sales](functional/sales.md) | Lead-to-cash: leads, opportunities, quotes, orders. |
| [Customer Service](functional/customer-service.md) | Case management, knowledge base, entitlements/SLAs. |
| [Marketing](functional/marketing.md) | Campaigns, segmentation, journeys, marketing lists. |
| [Field Service](functional/field-service.md) | Work orders, scheduling, technician dispatch. |

## Adding a new domain

1. Decide whether the new guidance is architectural or functional (see
   definitions above). Most new business capabilities are functional
   domains; new integration points or platform layers are architecture
   domains.
2. Add a new markdown file to the appropriate folder using the existing
   docs as a template (Scope, Key Components/Processes, Conventions,
   Related Domains).
3. Add a row to the table above and to the domain map in
   [`.github/copilot-instructions.md`](../../.github/copilot-instructions.md).
4. If the domain warrants dedicated Copilot guidance, add a matching
   custom agent under [`.github/agents/`](../../.github/agents/) and list it
   in [`.github/agents/README.md`](../../.github/agents/README.md).
