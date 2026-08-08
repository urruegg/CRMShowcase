# Architecture Decision Records

Every architectural decision lives here. No decision lives only in a deck or a chat.

ADRs are numbered sequentially and never renumbered. A superseded ADR stays in
the repo with `Status: Superseded by ADR-NNNN` — the history is the point.

Two loose series live side by side:

- **Governance / build ADRs (0001–0005)** record real decisions made while bringing
  the showcase up: Copilot governance, OIDC federation, Terraform, CI plane, CI app
  users.
- **Domain ADRs (0006–0019)** record the CRM Frontier Firm design position on the
  illustrated insurance vertical: party model, portfolio placement, thin CRM over
  the engines, consent, event cascade, jurisdiction eligibility, GA territory,
  agents-advisory, voice, outbound, ALM, analytics split.

## Shape

Copy [ADR-TEMPLATE.md](./ADR-TEMPLATE.md) and edit — do not invent a new shape.

## Naming

`ADR-####-kebab-case-title.md`, four-digit sequence, no gaps.

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

ADRs 0011, 0012, 0013, 0017, 0018, and 0019 remain proposed until confirmed
with customer architecture in the next review.

## When to open an ADR

- Change to an agent tool schema.
- Change to a model, prompt, or eval baseline.
- Change to the data model.
- Change to the human/agent split in a workflow.
- Change to identity, network posture, or ALM pipeline.

## When *not* to open one

- Local refactor, dependency bump, typo fix, docs polish. Use a normal PR.
