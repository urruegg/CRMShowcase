# Data — Model & Synthetic-Only Rules

| Field | Value |
| --- | --- |
| Version | 0.1 (Draft) |
| Status | Draft |

> **Template.** Fill in table/entity design as the showcase concretises.

## 1. Non-negotiables
- **No real customer data in the demo** (DP-05, [SUPERPOWERS_CONTRACT.md §1.3](../SUPERPOWERS_CONTRACT.md)).
- **Tenant isolation** (DP-06): demo runs in the demo tenant only.
- **Audit every mutation** initiated by an agent (who / what / when / why).

## 2. Data domains

| Domain | Description | Sensitivity in demo |
| --- | --- | --- |
| D1 | CRM records (accounts, leads, cases) | synthetic-only |
| D2 | Interaction history (emails, calls, chats) | synthetic-only |
| D3 | Knowledge base articles for service triage | public / synthetic |
| D4 | Marketing briefs & brand voice guides | synthetic |
| D5 | Aggregate pipeline metrics | derived from synthetic D1 |

## 3. Synthetic-data rules
- Names, emails, phone numbers must be from clearly-fictional generators.
- Company names must be from a curated list of obviously-fake names (e.g., "Contoso",
  "Fabrikam", "Adventure Works").
- No copy-pasted real emails, transcripts, or contracts. Ever.

## 4. Storage
> Fill in as decided (Dataverse tables, Azure AI Search indexes, blob containers, etc.).

## 5. Deterministic action layer
See [AI.md §4](./AI.md) — every agent-initiated mutation goes through a schema-validated
tool call. Direct writes from LLM output are prohibited.
