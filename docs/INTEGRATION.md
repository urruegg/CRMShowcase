# Integration, Interfaces & System Orchestration

| Field | Value |
| --- | --- |
| **Topic area** | **A3** — Integration, interfaces, system orchestration |
| Status | Draft 0.2 · **Owner** `AG-E-04` SecDevOps |

## What the customer asks

A best-practice integration architecture including **API strategy, event-based
communication, data provisioning and error handling**; demonstration on
concrete examples of how existing systems are connected and which integration
patterns are used; **standard adapters vs. necessary custom development**;
**responsibilities when integration problems occur**; long-term operability of
the integration landscape; and how changes to interfaces, data structures and
message formats are **controlled and versioned across the entire lifecycle**.

> The last clause is the one most providers answer weakly. Lead with it.

## Patterns

| Pattern | Use for | Example on the golden thread |
| --- | --- | --- |
| **Typed domain event** | State change that fans out | `AddressChanged` → rating, eligibility, territory, discount |
| **Request/response** | Synchronous lookup a user is waiting for | quote retrieval |
| **Bulk / scheduled** | Analytical provisioning | CRM → analytics platform |
| **Reference lookup** | Projection refresh | policy/claim detail from the engine |

## Non-negotiables

1. **Contract first.** Every interface has a versioned schema in `api/` with a
   documented compatibility policy. A breaking change is an **ADR**, not a
   deployment ([ADR-0011](./adr/ADR-0011-event-driven-cascade.md)).
2. **Effective dating travels with every domain event.** A cascade that cannot
   state *as of when* is not correct.
3. **Design the failure path before the happy path.** Retry, dead-letter,
   replay, idempotency — and a named owner who gets paged.
4. **No business logic in the integration layer.** Rating and eligibility are
   invoked, never reimplemented
   ([ADR-0008](./adr/ADR-0008-thin-crm-over-systems-of-record.md)).

## Standard vs. custom — state it plainly

| Connection | Nature |
| --- | --- |
| M365 / Teams / Outlook | Native |
| Power Platform connectors | Standard |
| Policy administration engine (Versicherungsprozesse) | Event-based via Kafka on Confluent Cloud — four candidate patterns evaluated, no decision yet — [ADR-0025](./adr/ADR-0025-crm-core-systems-kafka-confluent-integration-pattern.md) |
| Claims engine (Schadenprozesse) | Same Kafka/Confluent Cloud backbone as the policy administration engine — see [ADR-0025](./adr/ADR-0025-crm-core-systems-kafka-confluent-integration-pattern.md) |
| Partner master | `[TBD]` |
| Analytics platform | Three candidate patterns evaluated, no decision yet — [ADR-0024](./adr/ADR-0024-dataverse-to-databricks-integration-pattern.md) |
| Telephony | see [ADR-0015](./adr/ADR-0015-voice-channel-boundary.md) |

Never let a custom build be **discovered** later. A stated custom development
is a scoping fact; a discovered one is a credibility loss.

## Responsibility when an integration breaks

`[TBD — the operational RACI. This is a genuine question that will come up, and
"it depends on the interface" is the wrong answer. Work it through with the
delivery team.]`

## Lifecycle & versioning — the demo

Show a contract in `api/`, change it, and show the compatibility gate refusing
a breaking change in CI. Thirty seconds of pipeline output answers the question
more convincingly than ten minutes of explanation.
