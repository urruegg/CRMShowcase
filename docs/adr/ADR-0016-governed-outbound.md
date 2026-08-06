# ADR-0016 — Governed, consent-checked outbound messaging

| Field | Value |
| --- | --- |
| **Status** | Accepted · **Date** 2026-08-06 · **Topic area** A5 · A6 |
| **Licence** | `[TBD]` · **Upgrade impact** Low |

## Context

Marketing and service both need outbound SMS/WhatsApp. The platform has no native
"compose new message" cold-start for digital channels.

## Decision

All outbound digital messaging routes through **message template → Outbound
Configuration → flow**. Triggers are Automated · Instant · Scheduled. A custom
"Send SMS" button is feasible and honest — it is only an invocation surface;
template, configuration and opt-in still apply. Outbound **voice** is the
exception: ad-hoc from the dialpad / click-to-call.

## Consequences

- Present this as **deliberate governed architecture**, because it is: auditable,
  consent-checked, template-bound outbound is what a regulated insurer should
  want.
- Customer replies enter as a normal inbound omnichannel conversation, routed
  and assigned — the loop closes without a bespoke inbound path.
- Do not oversell a custom button as a native capability.
