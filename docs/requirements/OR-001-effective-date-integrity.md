# OR-001 — Effective-date integrity enforcement

| Field | Value |
| --- | --- |
| **Status** | Open — deferred from Sprint 3 |
| **Feature** | [GitHub issue #9](https://github.com/urruegg/CRMShowcase/issues/9) |
| **Related sprint** | [Sprint 3 — Insurance Foundation](../superpowers/specs/2026-08-08-insurance-foundation-design.md) |
| **Decision authority** | Enterprise Architect |
| **Licence** | 🧩 own build / configuration; final mechanism not selected |
| **Upgrade impact** | To be declared by the selecting ADR |

## Requirement

Provide supported, deterministic enforcement that `validTo` is blank or on or
after `validFrom` for:

- `crmshow_accountcontactrole`;
- `crmshow_policypartyrole`.

The later decision must also define whether overlapping effective-dated
intervals remain Data Steward warnings or become hard constraints after the
source-system synchronization contract is known.

## Reason for deferral

Dataverse documents the `workflow` table but does not publish a supported
compiler or schema for hand-authoring business-rule XAML through the Web API.
Sprint 3 will not fabricate unsupported workflow payloads or silently add a
plug-in boundary that has not received architecture approval.

## Sprint 3 interim control

Sprint 3:

- preserves the effective-date semantics in EN, DE, FR and IT metadata;
- validates fixture and import payloads before Dataverse mutation;
- reports invalid or overlapping intervals for Data Steward review;
- demonstrates end-dating or deactivation rather than hard deletion.

These controls detect bad data but do not claim universal server-side
enforcement for every Dataverse write path.

## Options for the later feature

1. Add a synchronous validation plug-in in `crmshow_Integration`.
2. Author supported table-scoped business rules in Maker Studio and capture
   them through the governed solution export/intake pipeline.
3. Enforce the rule at the source/integration contract boundary and retain
   Dataverse detection as defence in depth.

The selected option requires an ADR update because it changes behavior
ownership, solution dependencies, or the governed authoring path.

## Acceptance criteria

- A supported enforcement mechanism is selected and documented in an ADR.
- Create and update reject `validTo < validFrom`.
- Enforcement covers API, fixture, integration and model-driven app writes.
- User-visible errors support EN, DE, FR and IT.
- No lookup recreation, silent date correction or success-shaped fallback is
  introduced.
- The overlap policy is explicit for each effective-dated role table.
- Unit, integration, DEV and managed TEST evidence is linked to issue #9.
