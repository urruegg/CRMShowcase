# Compliance

| Field | Value |
| --- | --- |
| Status | **Draft skeleton 0.2** · **Owner** `AG-E-06` |

> **This document is a skeleton.** It must be completed with the delivery and
> legal teams before any position is asserted to a customer. **Not legal advice**
> — the customer's legal function and DPO validate all positions.

## Scope

The CRM Frontier Firm Showcase is a **demo**. It is not certified against any
regulatory regime and it must not imply that it is.

| Area | Status |
| --- | --- |
| GDPR (and equivalent local data-protection laws, e.g. Swiss revDSG) | `[TBD]` |
| Financial-regulator outsourcing expectations | `[TBD]` |
| Data residency commitment | `[TBD — must trace to the offer]` |
| DPIA | `[TBD]` |
| Retention & deletion | `[TBD]` |
| Consent ([ADR-0010](./adr/ADR-0010-consent-per-contact-per-channel.md)) | Modelled per contact per channel with source and capture date |
| AI-specific regulatory risk (A6) | See [AI.md](./AI.md) |

## What the demo may claim

- "Demonstrates a pattern for grounded AI in CRM."
- "Illustrates human-agent teaming for sales, service, and marketing workflows."
- "Uses synthetic data only."
- "Aligns with the six principles of the
  [Microsoft Responsible AI Standard](https://learn.microsoft.com/azure/machine-learning/concept-responsible-ai)
  — fairness, reliability and safety, privacy and security, inclusiveness,
  transparency, accountability — as mapped in
  [MICROSOFT-FRAMEWORKS.md](./MICROSOFT-FRAMEWORKS.md#responsible-ai-rai)."
- "Aligns with
  [Microsoft Zero Trust principles](https://learn.microsoft.com/security/zero-trust/zero-trust-overview)
  — verify explicitly, use least privilege, assume breach — as mapped in
  [MICROSOFT-FRAMEWORKS.md](./MICROSOFT-FRAMEWORKS.md#zero-trust)."
- "Follows the
  [Cloud Adoption Framework](https://learn.microsoft.com/azure/cloud-adoption-framework/overview)
  and the
  [Well-Architected Framework](https://learn.microsoft.com/azure/well-architected/pillars)
  as design references."

## What the demo must not claim

- "GDPR-compliant" or any equivalent certification.
- "Ready for production use."
- "Processes real customer data safely" — because it does not process real
  customer data at all.
- "Replaces a human decision-maker for customer-visible actions."

## Standing rules already in force

- **No real customer data outside production**
  ([SUPERPOWERS_CONTRACT.md](../SUPERPOWERS_CONTRACT.md) §1.3).
- **Consent evaluated at the API layer**, not the UI
  ([ADR-0010](./adr/ADR-0010-consent-per-contact-per-channel.md)).
- **Human accountable for every customer-facing act**
  ([ADR-0014](./adr/ADR-0014-agents-advisory-by-design.md)).
