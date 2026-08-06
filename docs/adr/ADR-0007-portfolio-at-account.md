# ADR-0007 — Portfolio at the Account; Contact connects via ContactRole

| Field | Value |
| --- | --- |
| **Status** | Accepted · **Date** 2026-08-06 · **Topic area** A2 |
| **Licence** | 🧩 configuration / own build · **Upgrade impact** Low |

## Context

A household holds multiple policies and multiple stakeholders. Topic area A2 asks
how household structures, partner relationships and contracts integrate into the
360° view, and how that information is exposed to different roles.

## Options

- **A — Portfolio on Contact.** *Why not:* a household's building / contents /
  liability cover is inherently shared; attaching it to one person misrepresents
  reality and breaks as soon as the household changes.
- **B — Portfolio on both.** *Why not:* ambiguous ownership, duplicated rollups.
- **C — Portfolio on Account; Contact via `ContactRole` ✅ chosen.** `Policy` and
  `Claim` hang off `Account`. `Contact` connects through `ContactRole` — Primary
  Contact · Co-decision-maker · Contextual · Broker Manager — and never owns the
  portfolio.

## Decision

Contact expresses a **relationship role**, not portfolio ownership.

## Consequences

- Household changes (marriage, divorce, child moving out) reshape roles, not
  portfolios.
- Role-based exposure of the 360° view follows naturally from `ContactRole`.
- **Reversibility:** high.
