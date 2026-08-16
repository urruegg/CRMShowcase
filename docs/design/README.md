# Design pattern documents

This folder holds customer-facing "design pattern" walkthroughs — one per major architecture decision in this repo — meant for live discussion with EA/IT stakeholders during a demo. Each document condenses the options considered in its related ADR into plain language, without restating or overriding the ADR's own recorded decision.

| # | Pattern | Related ADR |
|---|---|---|
| 00 | [Frontier Firm operating model for insurance](./00-frontier-firm-operating-model-for-insurance.md) | `docs/FRONTIER-OPERATING-MODEL.md` |
| ADR-0019 | [Insurance data model shape](./ADR-0019-insurance-data-model-options.md) | [ADR-0019](../adr/ADR-0019-provisional-insurance-data-model-shape.md) |
| — | [Insurance data model extension (implementation detail)](./contoso-insurance-data-model-extension.md) | [ADR-0019](../adr/ADR-0019-provisional-insurance-data-model-shape.md) |
| ADR-0030 | [Dataverse to Databricks integration](./ADR-0030-dataverse-databricks-integration-options.md) | [ADR-0030](../adr/ADR-0030-dataverse-to-databricks-integration-pattern.md) |
| ADR-0031 | [CRM to core-systems Kafka/Confluent integration](./ADR-0031-kafka-confluent-integration-options.md) | [ADR-0031](../adr/ADR-0031-crm-core-systems-kafka-confluent-integration-pattern.md) |
| ADR-0032 | [Identity and access management (Entra to Power Platform)](./ADR-0032-iam-entra-power-platform-options.md) | [ADR-0032](../adr/ADR-0032-entra-power-platform-dynamics365-identity-access-management.md) |
| ADR-0033 | [CRM UX placement in the B2E landscape](./ADR-0033-crm-ux-placement-options.md) | [ADR-0033](../adr/ADR-0033-crm-ux-placement-in-b2e-landscape.md) |
| ADR-0034 | [ARO case/task management integration](./ADR-0034-aro-case-task-integration-options.md) | [ADR-0034](../adr/ADR-0034-aro-case-task-management-integration-pattern.md) |
| ADR-0035 | [PDV partner master data integration](./ADR-0035-pdv-partner-master-data-options.md) | [ADR-0035](../adr/ADR-0035-pdv-partner-master-data-integration-pattern.md) |
| ADR-0036 | [Lead and campaign external landscape](./ADR-0036-crm-lead-campaign-landscape-options.md) | [ADR-0036](../adr/ADR-0036-crm-lead-campaign-external-landscape.md) |
| ADR-0037 | [Power Platform environment strategy (B2B/B2C)](./ADR-0037-environment-strategy-options.md) | [ADR-0037](../adr/ADR-0037-power-platform-environment-strategy-b2b-b2c.md) |
| ADR-0038 | [Purview compliance for Power Platform/Dynamics 365](./ADR-0038-purview-compliance-options.md) | [ADR-0038](../adr/ADR-0038-purview-power-platform-dynamics365-compliance.md) |
| ADR-0039 | [DevSecOps CI/CD operating model](./ADR-0039-devsecops-cicd-options.md) | [ADR-0039](../adr/ADR-0039-devsecops-cicd-github-enterprise-vs-gitlab.md) |

## How to use these during a demo

1. Start with pattern 00 to set the Frontier Firm mental model.
2. Walk through whichever numbered pattern(s) are relevant to the stakeholder audience in the room.
3. Use the "Validate this live" section in each pattern doc to jump into the real ADR and any runnable evidence in the repo.
4. Remember: these documents never carry a final decision override — the ADR is always the system of record.
