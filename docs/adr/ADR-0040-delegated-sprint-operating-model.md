# ADR-0040 - Delegated sprint operating model (Copilot CLI control plane)

| Field | Value |
| --- | --- |
| **Status** | Accepted |
| **Date** | 2026-08-11 |
| **Decision mode** | Reversible process decision, proven by execution |
| **Confidence** | High for process and CLI mechanics; medium for headless ergonomics |
| **Deciders** | Enterprise Architect, SecDevOps, repo owner |
| **Topic area** | A8 - lifecycle, deployment, rollback; A9 - responsibility split |
| **Use case** | Sprint-001 delegated pattern |
| **Licence** | Own build - scripts and Markdown; Copilot CLI entitlement per operator |
| **Upgrade impact** | Low platform; Medium way-of-working; additive and reversible |
| **CAF methodology** | Govern, Secure, Manage |
| **WAF pillar(s)** | Operational Excellence, Security, Reliability |
| **Zero Trust** | Verify explicitly, least privilege, assume breach |
| **Responsible AI** | Accountability (human merges), transparency (autonomy class recorded) |

## Context

The showcase must demonstrate parallel, agent-driven delivery without weakening
governance. Work is designed and planned on the trunk, then delegated to local
GitHub Copilot CLI sessions running in git worktrees.

## Decision

Adopt a two-plane model: a control plane (trunk: brainstorm -> design -> plan ->
GitHub issue) and a delegated plane (worktrees under
`C:\Users\urruegg\source\urruegg\wt`, one per stream, each driven by Copilot
CLI). Streams carry a handover packet with an autonomy class. `EXECUTION-ONLY`
streams may run headless autopilot with a `git push`/`rm`/`git reset` deny-list;
`DESIGN-SENSITIVE` streams run attended. Intake is a PR to protected `main`; no
script merges.

## Guardrails

- Design is never autopilot-approved. A packet requires an approved-design ref;
  a `DESIGN-SENSITIVE` packet cannot be launched headless; a stream that meets a
  new design decision stops and asks in the chat.
- The deny-list prevents any stream from self-integrating or rewriting history.

## Consequences

- Adds `scripts/orchestration/*` and `docs/superpowers/{SPRINT-OPERATING-MODEL,
  contracts,sprints}`.
- Reuses existing branch protection, CODEOWNERS, CI and eval gates unchanged
  (ADR-0004, ADR-0017).

## Related

ADR-0001, ADR-0004, ADR-0014, ADR-0017;
`docs/superpowers/specs/2026-08-11-delegated-sprint-operating-model-design.md`.
