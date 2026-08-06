# Glossary — CRM Frontier Firm Showcase

## Frontier Firm concepts

| Term | Meaning in this repo |
| --- | --- |
| **Frontier Firm** | An organisation in which humans and AI agents work as a team. Coined by the Microsoft Work Trend Index. |
| **Human-agent team** | A workflow that explicitly splits *human decides* from *agent proposes / acts*. |
| **Runtime agent (`AG-F-##`)** | An agent *in* the showcase (e.g., Lead Qualification Assistant). See [../AGENTS.md](../AGENTS.md). |
| **Engineering agent (`AG-E-##`)** | A GitHub Copilot custom agent that *builds* the showcase. See [../.github/agents/](../.github/agents/). |

## CRM domain (insurance vertical)

| Term | Meaning |
| --- | --- |
| **Account** | Party container. `accountType` = Household · Business · Broker ([ADR-0006](./adr/ADR-0006-account-centre-of-gravity.md)). |
| **Contact** | Individual person; expresses a relationship role via `ContactRole`, never owns portfolio ([ADR-0007](./adr/ADR-0007-portfolio-at-account.md)). |
| **ContactRole** | Primary contact · Co-decision-maker · Contextual · Broker manager. |
| **Household** | An `Account` with `accountType = Household`. Single-person households are still accounts. |
| **Portfolio** | The set of policies and claims attached to an Account. |
| **Lead** | An expression of interest on an existing person, never a new person stub ([ADR-0009](./adr/ADR-0009-lead-as-interest-on-existing-person.md)). |
| **LeadCluster** | Grouping of leads on one household — the anti-over-contact guardrail. |
| **Consent** | Per contact, per channel, with source and capture date ([ADR-0010](./adr/ADR-0010-consent-per-contact-per-channel.md)). |
| **Next-Best-Action (NBA)** | An explainable recommendation an advisor can accept, edit or dismiss. |
| **General Agent (GA)** | An independent regional agency that owns the local relationship. |
| **Assistance** | A 24/7 in-life customer service operation (illustrated as "Contoso Assistance"). |
| **Jurisdiction-driven eligibility** | Coverage existence depends on jurisdiction; some products cannot be written in some jurisdictions ([ADR-0012](./adr/ADR-0012-jurisdiction-driven-eligibility.md)). |

## Insurance product lines (illustrated)

| Term | Meaning |
| --- | --- |
| **Building cover** | Insurance on the building itself. In the illustrated example subject to a monopoly insurer in some jurisdictions. |
| **Contents cover** | Insurance on the household contents. |
| **Liability cover** | Personal liability insurance. |
| **Motor cover** | Vehicle insurance; rating factors include postal-code, driver profile, vehicle. |
| **Natural-hazard cover** | Flood, hail, storm cover; zoned by geography. |

## Governance & pattern terms

| Term | Meaning |
| --- | --- |
| **Deterministic action layer** | The schema-validated code between an LLM proposal and a CRM mutation. See [AI.md](./AI.md). |
| **Grounding** | The property that a generated message refers only to information the agent actually retrieved. |
| **Golden set** | The versioned set of synthetic CRM scenarios used to evaluate AI behaviour. See [AI.md](./AI.md). |
| **Golden thread** | The end-to-end journey the whole architecture conversation hangs on. See [ideas/UC-01-relocation-across-jurisdictions/](./ideas/UC-01-relocation-across-jurisdictions/). |
| **Story (`US-###`)** | A user-story entry in [BACKLOG.md](./BACKLOG.md), scoped to fit in one PR. |
| **ADR** | Architecture Decision Record. One per architectural decision, in [adr/](./adr/). |
| **Superpowers Contract** | The binding operating contract for every Copilot agent in this repo. See [../SUPERPOWERS_CONTRACT.md](../SUPERPOWERS_CONTRACT.md). |
| **Maturity** | Honest flag on whether a capability is productive at customers today or on the roadmap. |
| **Business case** | A named end-to-end workflow with tasks, SLA, escalation and cross-system trace. Not to be confused with the ROI sense. |

## Illustrated fictional entities

| Term | Meaning |
| --- | --- |
| **Contoso Insurance** | The fictional illustrated customer. Use throughout demo content instead of any real customer name. |
| **the Smith household** | The fictional illustrated household in the golden thread. |
| **Contoso Assistance** | The fictional 24/7 assistance operation. |
