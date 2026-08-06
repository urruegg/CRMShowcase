# Integration contracts

Every interface between the CRM and the wider landscape lives here as a
**versioned artefact**: OpenAPI for request/response, JSON Schema for domain
events.

## Rules

1. **Contract first.** No implementation before the schema.
2. **Versioned**, with a documented compatibility policy.
3. A **breaking change is an ADR**, not a deployment
   ([ADR-0011](../docs/adr/ADR-0011-event-driven-cascade.md)).
4. Every domain event carries an **effective date** and a **correlation
   identifier**.

Owner: [AG-E-09 Integration Engineer](../.github/agents/integration-engineer.agent.md).

This directory is the concrete answer to the A3 question about controlling
and versioning interface, data-structure and message-format changes across the
whole lifecycle.

## Planned contracts (as the golden thread lands)

| Contract | Purpose | Status |
| --- | --- | --- |
| `events/address-changed.schema.json` | Fan-out signal on the governed location attribute | `[TBD]` |
| `events/ga-reassigned.schema.json` | Business-case handover on a cross-jurisdiction move | `[TBD]` |
| `events/policy-eligibility-changed.schema.json` | Coverage-existence change on jurisdiction crossing | `[TBD]` |
| `events/portfolio-discount-recalculated.schema.json` | Portfolio-aware discount update | `[TBD]` |
