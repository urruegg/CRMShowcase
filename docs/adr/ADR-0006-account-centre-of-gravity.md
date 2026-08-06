# ADR-0006 — Account is the centre of gravity

| Field | Value |
| --- | --- |
| **Status** | Accepted |
| **Date** | 2026-08-06 |
| **Topic area** | A2 — Data model, data architecture, 360° customer view |
| **Licence** | 🧩 configuration / own build |
| **Upgrade impact** | Low — standard entity extension |

## Context

Contoso Insurance is overwhelmingly retail (roughly 2.3M private customers, 2M
interested parties, 300k prospects) but must serve B2C households, businesses and
brokers on one 360° view. Topic area A2 asks how the central customer and partner
view is technically realised and how household structures, life events, partner
relationships and contracts integrate into it.

## Options

### Option A — Person-Account split (B2C vs. B2B models)
**Why not:** a well-known one-way door. It splits the schema, duplicates automation,
and forces two versions of every process. Assistance and broker scenarios would need
their own model.

### Option B — Separate Household entity alongside Account
**Why not:** two party containers competing for the same role; every lookup has to
ask which one it means.

### Option C — One Account with an `accountType` discriminator ✅ chosen
`Account` is a **party container** with `accountType` = `Household` · `Business` ·
`Broker`. For B2C the container *is* the household: a private customer is a
`Contact` under a `Household` account. A single-person household is still an
account — one consistent shape.

## Decision

One `Account` entity, discriminated by `accountType`. Assistance and broker
scenarios reuse the same model, extended rather than forked.

## Consequences

- **At the next release:** one schema to upgrade, not two.
- **Operationally:** policies and claims that are inherently shared (building,
  contents, liability) sit naturally at household level.
- **Reversibility:** high compared to a Person-Account split, which is effectively
  permanent.

## Competitive note

Alternative packaged insurance suites often take the Person-Account decision early
and permanently. This shape stays one model across sales, service, after-sales and
broker.
