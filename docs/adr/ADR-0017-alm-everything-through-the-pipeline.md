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

### Bounded attended DEV Code App exception

[ADR-0041](./ADR-0041-code-apps-primary-for-bespoke-full-page-crm-ux.md)
establishes one narrow authoring exception while the current noninteractive
Code Apps CLI publication path requires secret-based service-principal
authentication:

- A maker/admin may run attended `pa app push` in **DEV only** for a reviewed
  Code App commit.
- Git remains the source of truth. The evidence records the commit, successful
  build and tests, CLI version, app identity, solution identity, operator,
  timestamp and result.
- No client secret is introduced or stored in source, automation, fixtures,
  configuration or logs.
- There is no direct TEST authoring. The existing OIDC pipeline exports the
  complete DEV solution and imports that exact managed artifact into TEST.
- Existing solution validation, approval, export/import, convergence and
  rollback controls remain unchanged.

This exception permits an attended DEV publication mechanism; it does not
permit an unreviewed environment-only change.

## Consequences

- **Manual environment changes remain forbidden outside the bounded attended
  DEV Code App publication above.** The reviewed source and publication
  evidence make that exception visible and reconcilable.
- **Rollback must be demonstrable, not described.** If we cannot roll a live
  change back in front of the customer, we should not make the claim.
- **TEST remains pipeline-only.** Direct authoring, unmanaged substitution and
  a stored service-principal secret are not accepted shortcuts.
- Requires discipline from the customer and the implementation partner, not just
  from us — which is precisely the shared-responsibility conversation.
