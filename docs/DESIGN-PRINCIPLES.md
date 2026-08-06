# Design Principles — CRM Frontier Firm Showcase

| Field | Value |
| --- | --- |
| Version | 0.1 (Draft) |
| Status | Draft |

These principles set the default answer when a design question is ambiguous. Deviating
requires an ADR under [adr/](./adr/).

## DP-01 — Frontier Firm framing
The showcase demonstrates **human-agent teams**. Every workflow makes the split between
"human decides" and "agent proposes / acts" explicit.

## DP-02 — Deterministic boundary at the CRM edge
Free-text LLM output never mutates a record directly. A deterministic, schema-validated
action layer sits between the model and Dataverse (or any system of record).

## DP-03 — Human accountability for customer-visible output
Sending outbound communication, changing pricing/quotes, and closing service cases require
human approval unless a specific story explicitly scopes autonomy.

## DP-04 — Grounded generation
Every customer-visible AI-generated message is grounded in retrieved CRM context and
cites what it used. If context is insufficient, the agent asks a clarifying question
rather than inventing an answer.

## DP-05 — Synthetic-only demo data
The demo processes only synthetic or clearly-labelled sample data. Never real customer data.

## DP-06 — Tenant isolation
The demo runs in an isolated Microsoft 365 / Azure demo tenant. No code path may reach
into a customer's production tenant.

## DP-07 — Managed Identity over stored secrets
Prefer Entra ID + Managed Identity + OIDC. Any stored secret lives in Key Vault and is
justified in a PR.

## DP-08 — Small, reviewable slices
Prefer one working slice today over a grand plan tomorrow. Split epics before coding.

## DP-09 — Evidence-in-PR
Every PR carries its own proof: green CI, a test for the changed behaviour, and — where
AI behaviour changed — a link to the eval run.

## DP-10 — Boring, default Microsoft-platform choices
Prefer Dataverse, Power Platform, Copilot Studio, and Azure AI Foundry unless an ADR
explicitly justifies deviating.

## DP-11 — Disclosure
Every AI-drafted customer-facing message is disclosed as AI-assisted.

## DP-12 — Fairness and quality by cohort
When evaluating AI behaviour, check quality across at least two representative user
cohorts, not just the aggregate.
