# Shared Responsibility

| Field | Value |
| --- | --- |
| **Topic area** | **A9** — Shared responsibility |
| Status | Draft 0.2 |

## What the customer asks

How responsibility for **processes, data quality, rule sets and configurations**
splits between the business functions (Marketing, Sales, Service) and between
business and IT: governance including control and audit mechanisms, approval
processes, ownership of business objects, and the scope for business functions
to make changes independently.

## Draft RACI

`[TBD — to be worked through **with** the customer in the review. A RACI we
bring finished is a RACI they will argue with; one we draft together is one
they own.]`

| Area | Business function | Customer IT | Implementation partner | Microsoft |
| --- | --- | --- | --- | --- |
| Fields, views, forms | R | A | C | — |
| Business rules, templates | R | A | C | — |
| Segments, campaigns, content | **R/A** | C | — | — |
| Data quality & stewardship | **R/A** | C | — | — |
| Consent records & policy | **R/A** | C | — | — |
| Data model core | C | **R/A** | R | C |
| Integrations & contracts | C | **A** | **R** | C |
| Pro-code extensions | — | **A** | **R** | C |
| Pipelines & environments | — | **R/A** | R | C |
| Agent configuration & prompts | C | **A** | R | C |
| Agent evaluation & RAI | C | **A** | R | **C** |
| KPI definitions | **R** | **A** | C | — |
| Platform availability & updates | — | C | — | **R/A** |

## The two questions that actually matter

1. **What can a business function change on Monday without a ticket?** Answer
   concretely, with the tier-1 list from [EXTENSIBILITY.md](./EXTENSIBILITY.md).
   A vague answer here reads as "everything needs IT", which is what they fear.
2. **Where does GA autonomy stop?** Central: model, templates, rules,
   approvals, KPI definitions. Local: content, selections, local campaigns and
   events. Never: per-GA forks
   ([ADR-0013](./adr/ADR-0013-ga-ownership-and-territory.md)).

## Control & audit

- Every change to a governed object is traceable to a PR and an ADR.
- Approval workflows for decentral campaigns and content.
- Consent changes are audited by construction — source and capture date are
  part of the record
  ([ADR-0010](./adr/ADR-0010-consent-per-contact-per-channel.md)).
- Agent behaviour changes are versioned and reviewed
  ([SUPERPOWERS_CONTRACT.md](../SUPERPOWERS_CONTRACT.md) §1 rule 8).
