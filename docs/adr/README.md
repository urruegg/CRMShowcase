# Architecture Decision Records

Every architectural decision lives here. No decision lives only in a deck or a chat.

ADRs are numbered sequentially and never renumbered. A superseded ADR stays in
the repo with `Status: Superseded by ADR-NNNN` — the history is the point.

Two loose series live side by side:

- **Governance / build ADRs (0001–0005)** record real decisions made while bringing
  the showcase up: Copilot governance, OIDC federation, Terraform, CI plane, CI app
  users.
- **Domain and delivery ADRs (0006–0039)** record the CRM Frontier Firm design position on the
  illustrated insurance vertical: party model, portfolio placement, thin CRM over
  the engines, consent, event cascade, jurisdiction eligibility, GA territory,
  agents-advisory, voice, outbound, ALM, analytics split, demo-feasible
  Dataverse bootstrap boundaries, effective-date integrity, the CI/CD workflow
  naming convention, the inbound analytics projection pattern, page-level PCF +
  the local-first polish loop, the Dataverse-to-Databricks integration
  pattern, the CRM-to-core-systems Kafka/Confluent Cloud integration
  pattern, Entra ID→Power Platform/Dynamics 365 identity and access
  management, CRM UX placement within the customer's B2E landscape, the
  ARO case/task management integration and Opportunity migration pattern,
  the PDV partner master-data integration pattern, the CRM lead/
  campaign external landscape (Comparis intake, Salesforce → Dynamics 365
  Marketing migration), the Power Platform environment strategy for
  the Household/Business/Broker business models, Microsoft Purview
  compliance/regulatory governance for Power Platform and Dynamics 365,
  and the DevSecOps CI/CD operating model choice between GitHub
  Enterprise and GitLab.

## Shape

Copy [ADR-TEMPLATE.md](./ADR-TEMPLATE.md) and edit — do not invent a new shape.

## Naming

`ADR-####-kebab-case-title.md`, four-digit sequence, no gaps.

`0039` is the latest allocated sequence; use `0040` for the next ADR.

## Index

| ADR | Decision | Topic area | Status |
| --- | --- | --- | --- |
| [0001](./ADR-0001-adopt-agent-driven-copilot-governance.md) | Adopt agent-driven Copilot governance | — | Accepted |
| [0002](./ADR-0002-oidc-federation-for-github-actions-to-entra.md) | OIDC federation for GitHub Actions → Entra | — | Accepted |
| [0003](./ADR-0003-terraform-as-iac-toolchain.md) | Terraform as the IaC toolchain | — | Accepted |
| [0004](./ADR-0004-ci-plane-app-registrations-and-github-environments.md) | CI plane — app registrations + GitHub Environments | — | Accepted |
| [0005](./ADR-0005-power-platform-application-users-for-ci.md) | Power Platform application users for CI SPs | — | Accepted |
| [0006](./ADR-0006-account-centre-of-gravity.md) | Account is the centre of gravity | A2 | Accepted |
| [0007](./ADR-0007-portfolio-at-account.md) | Portfolio at the Account; Contact via ContactRole | A2 | Accepted |
| [0008](./ADR-0008-thin-crm-over-systems-of-record.md) | Thin CRM over the systems of record | A1 · A2 | Accepted |
| [0009](./ADR-0009-lead-as-interest-on-existing-person.md) | Lead = expression of interest on an existing person | A2 · A5 | Accepted |
| [0010](./ADR-0010-consent-per-contact-per-channel.md) | Consent per contact, per channel, as a hard gate | A2 · A6 | Accepted |
| [0011](./ADR-0011-event-driven-cascade.md) | Event-driven cascade with effective dating | A3 · A5 | Proposed |
| [0012](./ADR-0012-jurisdiction-driven-eligibility.md) | Jurisdiction-driven product eligibility | A3 · A5 | Proposed |
| [0013](./ADR-0013-ga-ownership-and-territory.md) | GA ownership transfer & territory model | A2 · A5 | Proposed |
| [0014](./ADR-0014-agents-advisory-by-design.md) | Agents recommend at scale; humans decide | A6 | Accepted |
| [0015](./ADR-0015-voice-channel-boundary.md) | Voice channel boundary for live transcript & Copilot | A3 · A6 | Accepted |
| [0016](./ADR-0016-governed-outbound.md) | Governed, consent-checked outbound messaging | A5 · A6 | Accepted |
| [0017](./ADR-0017-alm-everything-through-the-pipeline.md) | Everything reaches an environment through the pipeline | A4 · A8 | Proposed |
| [0018](./ADR-0018-analytics-split-crm-vs-databricks.md) | Analytics split — CRM vs. analytics platform | A7 | Proposed |
| [0019](./ADR-0019-provisional-insurance-data-model-shape.md) | Provisional insurance data-model shape | A1 · A2 · A3 · A7 | Proposed |
| [0020](./ADR-0020-domain-ownership-within-six-solution-architecture.md) | Domain ownership within the six-solution architecture | A1 · A2 · A4 · A8 | Proposed hypothesis |
| [0021](./ADR-0021-multilingual-semantic-dataverse-metadata.md) | Multilingual semantic Dataverse metadata | A2 · A4 · A6 · A8 | Accepted |
| [0022](./ADR-0022-curated-external-copilot-capability-packs.md) | Curated external Copilot capability packs | A4 · A6 · A8 | Accepted |
| [0023](./ADR-0023-demo-feasible-dataverse-bootstrap.md) | Demo-feasible Dataverse bootstrap and steady-state identities | A8 | Proposed hypothesis |
| [0024](./ADR-0024-effective-date-integrity-options.md) | Effective-date integrity options | A8 | Accepted |
| [0025](./ADR-0025-cicd-workflow-naming-convention.md) | CI/CD workflow naming convention | A8 | Accepted |
| [0026](./ADR-0026-inbound-analytics-projection-pattern.md) | Inbound analytics projection pattern (data platform → CRM) | A3 · A7 | Accepted |
| [0027](./ADR-0027-page-level-pcf-and-local-first-polish-loop.md) | Page-level PCF + the PCF Local-First Polish Loop | A4 | Accepted |
| [0028](./ADR-0028-scoped-auto-merge-execution-only.md) | Scoped auto-merge for execution-only sprint streams | A8 | Accepted |
| [0029](./ADR-0029-platform-baseline-privileges-out-of-role-contract.md) | Platform-managed baseline privileges out of reviewed-role contract scope | A8 | Accepted |
| [0030](./ADR-0030-dataverse-to-databricks-integration-pattern.md) | Dataverse-to-Databricks integration pattern via Fabric/OneLake | A3 · A7 · A8 · A9 | Proposed hypothesis |
| [0031](./ADR-0031-crm-core-systems-kafka-confluent-integration-pattern.md) | CRM-to-core-systems event integration via Kafka on Confluent Cloud | A3 · A5 · A9 | Proposed hypothesis |
| [0032](./ADR-0032-entra-power-platform-dynamics365-identity-access-management.md) | Identity and access management — Entra ID to Power Platform & Dynamics 365 Security Roles | A2 · A8 · A9 | Proposed hypothesis |
| [0033](./ADR-0033-crm-ux-placement-in-b2e-landscape.md) | CRM UX placement in the B2E landscape — headless, UX layer, or hybrid | A1 · A5 · A6 | Proposed hypothesis |
| [0034](./ADR-0034-aro-case-task-management-integration-pattern.md) | ARO case/task management integration and Opportunity migration | A2 · A3 · A5 | Proposed hypothesis |
| [0035](./ADR-0035-pdv-partner-master-data-integration-pattern.md) | PDV partner master-data integration pattern — initial load, sync, and party origination policy | A2 · A3 | Proposed hypothesis |
| [0036](./ADR-0036-crm-lead-campaign-external-landscape.md) | CRM lead & campaign external landscape — Comparis intake and Salesforce → D365 Marketing migration | A2 · A3 · A5 | Proposed hypothesis |
| [0037](./ADR-0037-power-platform-environment-strategy-b2b-b2c.md) | Power Platform environment strategy for Household/Business/Broker business models | A2 · A4 · A8 | Proposed hypothesis |
| [0038](./ADR-0038-purview-power-platform-dynamics365-compliance.md) | Microsoft Purview compliance and regulatory governance for Power Platform & Dynamics 365 | A2 · A6 · A9 | Proposed hypothesis |
| [0039](./ADR-0039-devsecops-cicd-github-enterprise-vs-gitlab.md) | DevSecOps CI/CD operating model — GitHub Enterprise vs. GitLab vs. hybrid | A4 · A8 · A9 | Proposed hypothesis |

ADRs 0011, 0012, 0013, 0017, 0018, 0019, 0020, 0023, 0030, 0031, 0032, 0033,
0034, 0035, 0036, 0037, 0038, and 0039 remain proposed until confirmed with
customer architecture in the next review.

## Hypothesis-driven decisions

When material evidence is incomplete, do not hide uncertainty and do not wait
for perfect information. Use a **proposed hypothesis ADR**:

1. compare credible alternatives;
2. separate known facts, inferences, and missing evidence;
3. select a reversible working hypothesis with a confidence level;
4. define validation evidence, review triggers, and decision owners;
5. implement only a reviewable slice that can produce evidence;
6. update or supersede the ADR when evidence changes the decision.

[ADR-0020](./ADR-0020-domain-ownership-within-six-solution-architecture.md)
establishes this as the default decision pattern for CRM Showcase
implementation sprints. A hypothesis may guide delivery, but it must not become
an unreviewed permanent architecture through inertia.

## When to open an ADR

- Change to an agent tool schema.
- Change to a model, prompt, or eval baseline.
- Change to the data model.
- Change to the human/agent split in a workflow.
- Change to identity, network posture, or ALM pipeline.

## When *not* to open one

- Local refactor, dependency bump, typo fix, docs polish. Use a normal PR.
