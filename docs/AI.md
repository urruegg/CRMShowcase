# AI — Model, Prompt, Eval, and Content-Safety Rules

| Field | Value |
| --- | --- |
| Version | 0.1 (Draft) |
| Status | Draft |

> **Template.** Fill in the concrete model choices as they land. This file is the
> single source of truth the Responsible-AI Officer agent
> ([.github/agents/responsible-ai-officer.agent.md](../.github/agents/responsible-ai-officer.agent.md))
> reasons over.

## 1. Scope
This file governs every place the showcase invokes a generative model. It covers:
model selection, prompts, tool schemas, retrieval, evals, and Content Safety.

## 2. Non-negotiables
- **The LLM proposes; a deterministic layer disposes.** Free-text output never mutates
  a CRM record directly (DP-02).
- **Every customer-visible AI-generated message is grounded** in retrieved CRM context
  and cites what it used (DP-04).
- **Every AI-drafted customer-facing message is disclosed** as AI-assisted (DP-11).
- **No customer PII** is sent to a model unless the story explicitly requires it and
  the tenant is approved for that use.
- **Human approval** is required before an AI draft is sent externally or writes a
  system-of-record field (DP-03), unless a story explicitly scopes autonomy.

## 3. Model choices
> Fill in as decided. Record each choice in an ADR.

| Runtime agent | Purpose | Model (TBD) | Region (TBD) |
| --- | --- | --- | --- |
| `AG-F-01` Lead Qualification | reasoning + drafting | TBD | TBD |
| `AG-F-02` Service Triage | reasoning + retrieval + drafting | TBD | TBD |
| `AG-F-03` Campaign Copy | drafting | TBD | TBD |
| `AG-F-04` RevOps Insights | summarisation + anomaly flagging | TBD | TBD |

## 4. Deterministic action layer
Any tool call that mutates CRM state must:
- Have a JSON-schema definition.
- Validate inputs server-side (types, ranges, allow-lists) before execution.
- Reject-on-ambiguity rather than guess.
- Log the exact input + result for audit.

## 5. Content Safety
Every customer-visible generated message passes through Azure AI Content Safety (or
equivalent) with categories: **hate, sexual, violence, self-harm** at least. Any
detection blocks the send and surfaces to the human reviewer.

## 6. Prompts
Prompts live in Git under a `prompts/` folder inside each agent's source module (to be
created when the first runtime agent is implemented). No inline prompt strings in code.

## 7. Evaluations
The **golden set** is a versioned collection of synthetic CRM scenarios plus expected
behavioural properties (grounding, refusal-when-uncertain, tone, fairness by cohort).

- **7.1 — Grounding.** Draft cites retrieved context that actually exists.
- **7.2 — Refusal.** When context is insufficient, agent asks a clarifying question.
- **7.3 — Fairness.** Quality parity across at least two representative cohorts (DP-12).
- **7.4 — Regression gate.** Evals run in CI; a regression blocks merge.

## 8. Change log
> Record every model, prompt, or eval-baseline change here (or link to the PR / ADR).

- `2026-08-06` — Repo bootstrap. No runtime AI configured yet.
