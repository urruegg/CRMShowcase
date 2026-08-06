# Compliance — What the Demo May and May Not Claim

| Field | Value |
| --- | --- |
| Version | 0.1 (Draft) |
| Status | Draft |

> **Template.** This file exists so the CRM Domain Expert
> ([.github/agents/crm-domain-expert.agent.md](../.github/agents/crm-domain-expert.agent.md))
> and Responsible-AI Officer
> ([.github/agents/responsible-ai-officer.agent.md](../.github/agents/responsible-ai-officer.agent.md))
> have a shared reference.

## 1. Scope
The CRM Frontier Firm Showcase is a **demo**. It is not certified against any regulatory
regime and it must not imply that it is.

## 2. What the demo may claim
- "Demonstrates a pattern for grounded AI in CRM."
- "Illustrates human-agent teaming for sales, service, and marketing workflows."
- "Uses synthetic data only."
- "Aligns with Microsoft Responsible AI principles."

## 3. What the demo must not claim
- "GDPR-compliant" or any equivalent certification.
- "Ready for production use."
- "Processes real customer data safely" — because it does not process real customer data at all.
- "Replaces a human decision-maker for customer-visible actions."

## 4. Responsible-AI stance
- Every AI-drafted customer-facing message is disclosed as AI-assisted (DP-11).
- Content Safety is applied on customer-visible output (AI.md §5).
- A human is accountable for anything that reaches an actual customer (DP-03).

## 5. Data-handling stance
- Synthetic-only in the demo (DP-05, [DATA.md](./DATA.md)).
- Tenant isolation (DP-06, [SECURITY.md](./SECURITY.md)).
