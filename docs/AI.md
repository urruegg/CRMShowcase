# AI, Agents & Governance

| Field | Value |
| --- | --- |
| **Topic area** | **A6** — AI, agents and governance |
| Status | Draft 0.2 · **Owner** `AG-E-06` |

## What the customer asks

Beyond a demonstration of the AI agents and assistance functions: the
**underlying data sources**, the **configurability of prompts and rules**,
**model governance**, and the means of **monitoring and quality-assuring
productive AI applications**. Plus — stated plainly — **which of the shown
functions are already productive at customers and which are roadmap**. How
**own AI models** can be integrated. And the mechanisms against
**misbehaviour, hallucination and regulatory risk**.

> This is a compliance audit wearing a demo's clothes. Answer it as an audit
> and it goes well. Answer it as a demo and it goes badly.

## The governing position

[ADR-0014](./adr/ADR-0014-agents-advisory-by-design.md) — **agents recommend at
scale; humans decide.** Event- and schedule-triggered agents score the whole
book and emit explainable Next-Best-Actions; the advisor accepts, edits or
dismisses, and that decision is the learning signal.

Say clearly that this is a **design position for a regulated insurer, not a
platform limitation.** They will ask. Claiming it as a limitation is both
untrue and weak.

## Agent inventory

See [../AGENTS.md](../AGENTS.md) for `AG-F-01`…`AG-F-04` (with room to grow to
`AG-F-06+`) with purpose, inputs/outputs, guardrails, side effects,
human-in-the-loop, **maturity** and licence flag.

## Maturity — the honesty table

| Capability | Productive at customers | Roadmap | Notes |
| --- | --- | --- | --- |
| `[TBD — complete this table before the next review, per capability, verified.]` | | | |

**Do not blur this.** The customer asked for the distinction explicitly. Being
visibly candid on the roadmap items buys trust for everything else — and
getting caught overstating one capability retroactively devalues every other
claim we made.

## Grounding, prompts & rules

- Agents ground on **one Dataverse** plus M365 content natively — the agent
  works where the advisor already works.
- Prompts, rules and agent definitions are **versioned in Git**, PR-reviewed,
  changelogged. No silent model or prompt swap
  ([SUPERPOWERS_CONTRACT.md](../SUPERPOWERS_CONTRACT.md) §1 rule 8).
- `[TBD — the configurability surface for business functions vs. IT: what can
  be tuned without a deployment. This is a shared-responsibility question too.]`

## Guardrails against misbehaviour & hallucination

- **Explainability required.** A Next-Best-Action the advisor cannot explain to
  a customer is not shippable.
- **Consent as a hard gate** before any outbound-capable recommendation
  ([ADR-0010](./adr/ADR-0010-consent-per-contact-per-channel.md)).
- **Human-in-the-loop** on every customer-facing act.
- **Content safety** on generative output.
- **Evaluation gate:** agent evals run in CI; a regression blocks merge.
- **Provenance visible in the UI** — agent-written rows carry a marker so the
  contribution is never mistaken for human-entered data.
- Jurisdiction-changing outcomes always route to a human
  ([ADR-0012](./adr/ADR-0012-jurisdiction-driven-eligibility.md)).

## Own models

`[TBD — prepare a concrete answer: bring-your-own-model paths, where a customer
model plugs in, and what changes in the governance chain when it does.]`

## Monitoring productive AI

`[TBD — what is measured, where it surfaces, who owns the alert, and what the
remediation loop looks like. "Monitoring exists" is not an answer to an
operations audience.]`

## What is not native — say it first

- **Paid Meta/Google** is not a native send channel → audience activation via
  export connectors.
- **Look-alike modelling** is not native → Azure ML.
- **Budget / ROI / CPL** → custom table plus Power BI.
- **Live transcript & Copilot voice** → native voice channel only
  ([ADR-0015](./adr/ADR-0015-voice-channel-boundary.md)).
