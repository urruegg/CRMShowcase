# ADR-0014 — Agents recommend at scale; humans decide

| Field | Value |
| --- | --- |
| **Status** | Accepted |
| **Date** | 2026-08-06 |
| **Topic area** | A6 — AI, agents and governance |
| **Licence** | `[TBD — per component, see docs/LICENSING.md]` |
| **Upgrade impact** | Low |

## Context

Topic area A6 asks about model governance, monitoring and QA of productive AI,
mechanisms against misbehaviour, hallucination and regulatory risk — and which
capabilities are genuinely productive at customers today. For a regulated
insurer, the governing question is not *how capable* the agents are but *who is
accountable* for what they do.

## Options

### Option A — Autonomous customer-facing agents
Agents act directly on customers (send, adjust, commit).
**Why not:** no named human accountable for a customer-facing act; unacceptable
regulatory exposure; and it makes every hallucination a customer incident rather
than a dismissed card.

### Option B — Copilot-only, in-session assistance
Assistance only when a human is already in the record.
**Why not:** cannot cover a book of millions of customers. The value of scoring
the whole book is lost.

### Option C — Event/scheduled agents at scale, advisory by design ✅ chosen
Agents run on events (case/claim created, renewal, lifecycle change) or on
schedule (nightly batch), score the whole book and emit **explainable
Next-Best-Actions**. The recommendation lands in the advisor's cockpit as an
action card the human accepts, edits or dismisses — and that decision feeds the
learning loop.

## Decision

Agents are advisory by design. Autonomy on a customer-facing act requires a new
ADR plus Responsible-AI review — never a configuration change.

## Consequences

- **Regulatory:** a named human is accountable for every customer-facing decision.
- **Quality:** every accept/dismiss is a labelled training signal.
- **Scale:** book-wide coverage without book-wide risk.
- **Constraint to state openly:** this is a *design* position, not a platform
  limit. Say so — the customer will ask, and claiming it as a limitation is both
  wrong and weak.

## Competitive note

Agents ground on one Dataverse and on M365 content natively — the agent works
where the advisor already works. Reaching M365 through connectors, or from a
non-M365-native fabric, does not make that structural.
