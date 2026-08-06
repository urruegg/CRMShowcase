# ADR-0015 — Voice channel boundary for live transcript and Copilot

| Field | Value |
| --- | --- |
| **Status** | Accepted · **Date** 2026-08-06 · **Topic area** A3 · A6 |
| **Licence** | `[TBD]` · **Upgrade impact** Low |

## Context

Contoso Assistance runs a 24/7 assistance operation. Live transcript, Copilot
voice summaries, Next-Best-Action and a live "Buddy" are high-value — and they
have a hard architectural precondition.

## Decision

Live transcript and Copilot voice capabilities are available on the **native voice
channel only**. They are **not** available while a third-party contact-centre
platform owns the call. Custom extraction is possible via the transcription-data
WebSocket on the native path.

## Consequences

- This is a **structural boundary, not a preference.** State it plainly; do not
  let the customer discover it after a telephony decision.
- It makes the telephony choice an architecture decision with AI consequences,
  not a procurement detail.

## Competitive note

Alternative stacks reach voice through a separate telephony vendor and contract.
A native voice path means fewer seams for a 24/7 assistance operation.
