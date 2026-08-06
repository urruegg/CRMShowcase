# ADR-0017 — Everything reaches an environment through the pipeline

| Field | Value |
| --- | --- |
| **Status** | **Proposed** |
| **Date** | 2026-08-06 · **Topic area** A4 · A8 |
| **Licence** | 🧩 configuration / own build · **Upgrade impact** — this *is* the upgrade answer |

## Context

Topic area A4 asks what extensions cost at the next release. A8 asks for
lifecycle management of configurations, extensions and integrations — versioning,
deployment, test automation, rollback — and how complexity stays controllable
after several release cycles.

## Decision (proposed)

No change reaches any environment except through the pipeline. Solution
components are source-controlled under `solution/`; every change is traceable
to a PR, an ADR and a test run; rollback is a pipeline action, not a manual
repair.

## Consequences

- **Manual environment changes become invisible and therefore forbidden.** This
  is the single biggest driver of long-term controllability, and it is the honest
  answer to *"how does this stay manageable after several release cycles?"*
- **Rollback must be demonstrable, not described.** If we cannot roll a live
  change back in front of the customer, we should not make the claim.
- Requires discipline from the customer and the implementation partner, not just
  from us — which is precisely the shared-responsibility conversation.
