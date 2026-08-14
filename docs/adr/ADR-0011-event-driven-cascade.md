# ADR-0011 — Event-driven cascade with mandatory effective dating

| Field | Value |
| --- | --- |
| **Status** | **Proposed — to be confirmed with the customer architecture team.** |
| **Date** | 2026-08-06 · **Topic area** A3 · A5 |
| **Licence** | 🧩 configuration / own build · **Upgrade impact** Medium |

## Context

The golden thread: one address change must fan out to motor, contents, natural
hazards and building cover, plus regional-office reassignment and portfolio-discount
recalculation. Topic area A3 asks for the integration architecture, event-based
communication and error handling; A5 asks how business cases are modelled, steered,
monitored and traced **across systems**.

## Options

- **A — Point-to-point synchronous calls.** *Why not:* N² coupling, no replay, one
  slow engine stalls the user, and change control becomes intractable.
- **B — Nightly batch reconciliation.** *Why not:* a customer who moves is
  mis-covered until the batch runs. Unacceptable for a coverage-existence change.
- **C — Typed domain events with effective dating ✅ proposed.** A change on a
  **governed** attribute emits a typed domain event carrying the effective date.
  Subscribers (rating, eligibility, territory, discount) act idempotently.
  Failures dead-letter and replay.

## Decision (proposed)

Location is a **shared, governed attribute**. Changing it emits `AddressChanged`
with an effective date; the CRM identifies the impact set but **does not re-rate**
— rating stays in the engines
([ADR-0008](./ADR-0008-thin-crm-over-systems-of-record.md)).

## Consequences

- **Correctness:** a cascade that cannot state *as of when* is not correct.
  Effective dating is mandatory on every event, not optional metadata.
- **Operability:** every fan-out is traceable end-to-end — this is the A5
  monitoring answer.
- **Contract control:** event schemas live in `api/`, versioned, with a
  compatibility policy. A breaking change is an ADR, not a deployment. This
  answers A3's hardest question.
- **Open with the customer:** the interaction with the analytics platform,
  partner master, and any employee portal remains `[TBD]`. Which bus/middleware
  carries the events is now evaluated — the customer uses Kafka on Confluent
  Cloud, and four candidate integration patterns (both inbound and outbound)
  are documented without a final decision in
  [ADR-0025](./ADR-0025-crm-core-systems-kafka-confluent-integration-pattern.md).
