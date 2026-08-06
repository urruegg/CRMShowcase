# Custom Agents

Custom agents defined in this folder are scoped to a single domain (see
[the domain map](../../docs/domains/README.md)). Prefer the matching
domain agent over the default agent when working on a change that falls
clearly within one domain; use the default agent for cross-domain changes.

| Agent | Domain type | Domain |
| --- | --- | --- |
| [`crm-architecture.agent.md`](crm-architecture.agent.md) | Architecture | [CRM Core Platform](../../docs/domains/architecture/crm.md) |
| [`other-systems.agent.md`](other-systems.agent.md) | Architecture | [Other Systems](../../docs/domains/architecture/other-systems.md) |
| [`sales.agent.md`](sales.agent.md) | Functional | [Sales](../../docs/domains/functional/sales.md) |
| [`customer-service.agent.md`](customer-service.agent.md) | Functional | [Customer Service](../../docs/domains/functional/customer-service.md) |
| [`marketing.agent.md`](marketing.agent.md) | Functional | [Marketing](../../docs/domains/functional/marketing.md) |
| [`field-service.agent.md`](field-service.agent.md) | Functional | [Field Service](../../docs/domains/functional/field-service.md) |

When adding a new domain (see
[`docs/domains/README.md`](../../docs/domains/README.md) for the process),
add a matching agent here and a row to this table.
