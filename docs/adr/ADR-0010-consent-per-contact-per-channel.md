# ADR-0010 — Consent per contact, per channel, enforced as a hard gate

| Field | Value |
| --- | --- |
| **Status** | Accepted · **Date** 2026-08-06 · **Topic area** A2 · A6 |
| **Licence** | 🧩 configuration / own build · **Upgrade impact** Low |

## Context

Consent governs every outbound path and every agent that can propose one. Under
GDPR (and equivalent data-protection regimes) plus the campaign requirements, it
must be transparent, per-channel, and auditable.

## Decision

`Consent` = {Phone · Email · SMS · Newsletter} × {Allowed · Denied · NotRelevant}
+ `source` + `capturedOn`, held per **contact**, surfaced as a guardrail across the
whole UI, and evaluated at the **API level** — not in the UI layer.

## Consequences

- A code path that can send without evaluating consent is a **defect**, regardless
  of what the interface does. This is the testable form of the guarantee.
- SMS additionally gated by `optin` / `donotphone` plus A2P/carrier registration —
  technically cold-startable, so the gate is compliance and product design, not a
  platform limit.
- WhatsApp: outside the 24-hour service window only pre-approved templates may be
  sent. This is **Meta's rule, universal across vendors** — state it as such, not
  as a D365 constraint.
