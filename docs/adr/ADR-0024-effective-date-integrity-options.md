# ADR-0024 — Effective-date integrity options (excluded from the Proof #2 slice)

| Field | Value |
| --- | --- |
| **Status** | Accepted |
| **Date** | 2026-08-11 |
| **Decision mode** | Reversible scope decision; enforcement mechanism deferred |
| **Confidence** | High for the Proof #2 exclusion; medium for the eventual enforcement mechanism |
| **Deciders** | Enterprise Architect, Responsible-AI & Compliance Officer, repo owner |
| **Topic area** | A8 — lifecycle, deployment, rollback |
| **Use case** | Sprint-002 Insurance Foundation promotion (Proof #2) |
| **Licence** | 🧩 own build / configuration; enforcement mechanism not yet selected |
| **Upgrade impact** | None in Proof #2 (nothing built); the later mechanism declares its own |
| **CAF methodology** | Govern, Manage |
| **WAF pillar(s)** | Reliability, Security, Operational Excellence |
| **Zero Trust** | Verify explicitly; least privilege; assume breach |
| **Responsible AI** | Accountability (human decides the mechanism), transparency (options recorded) |

## Context

Effective-date integrity requires that `crmshow_validto` is blank or on/after
`crmshow_validfrom` for `crmshow_accountcontactrole` and
`crmshow_policypartyrole`. The Insurance Foundation spec
([2026-08-08](../superpowers/specs/2026-08-08-insurance-foundation-design.md))
already declines to hand-author unsupported business-rule XAML through the Web
API and declines to add an unapproved plug-in boundary; it tracks the gap as
[OR-001](../requirements/OR-001-effective-date-integrity.md) / issue #9.

Proof #2
([2026-08-11 promotion design](../superpowers/specs/2026-08-11-insurance-foundation-promotion-design.md))
promotes a managed schema slice to TEST and must **not** ship a plug-in or a
business rule.

## Decision

**Proof #2 excludes all effective-date enforcement and reporting from the
promoted managed slice.** Specifically excluded from the managed package:

- every table `businessRule` (the `*validdateorder` date-order validations);
- the `OverlapReporting` and `InvalidDateReporting` views.

No plug-in and no Dataverse business rule is built. Detection remains a
payload-validation and steward concern **outside** the promoted package. The
enforcement mechanism is **not selected** in Proof #2 and is recorded below as
an option set. Selecting one later is a governance-changing event requiring an
ADR update.

## Options (for the later enforcement decision)

### Option 1 — Synchronous validation plug-in in `crmshow_Integration`

- **Pros:** universal server-side enforcement across every write path; strongest
  guarantee.
- **Cons:** introduces a pro-code plug-in boundary and assembly lifecycle;
  higher upgrade impact; needs architecture + Responsible-AI review; changes the
  solution dependency graph.

### Option 2 — Maker-Studio table-scoped business rules

- **Pros:** supported, low-code, table-scoped; captured through the governed
  export/intake pipeline; no assembly.
- **Cons:** business rules do not cover every write path (e.g. some API/bulk
  paths); must be authored in Maker Studio and intaken, not hand-authored as XAML.

### Option 3 — Source / integration-contract enforcement, Dataverse detection as defence in depth

- **Pros:** enforces where the data is mastered; keeps Dataverse thin; detection
  views remain a steward safety net.
- **Cons:** depends on the source synchronization contract that does not yet
  exist; Dataverse alone cannot then claim universal enforcement.

## Consequences

- [OR-001](../requirements/OR-001-effective-date-integrity.md) remains **Open**
  and now points to this ADR as its decision record.
- Proof #2 ships no enforcement and no reporting views; the TEST managed slice is
  pure schema/metadata/localization/ALM.
- The eventual selection changes behaviour ownership, solution dependencies, or
  the governed authoring path, and therefore requires an ADR update plus
  Responsible-AI review.

## Related

- [OR-001 — Effective-date integrity](../requirements/OR-001-effective-date-integrity.md) · issue #9
- [Insurance Foundation spec](../superpowers/specs/2026-08-08-insurance-foundation-design.md)
- [Proof #2 promotion design](../superpowers/specs/2026-08-11-insurance-foundation-promotion-design.md)
- [ADR-0008 — thin CRM over systems of record](./ADR-0008-thin-crm-over-systems-of-record.md)
- [ADR-0019 — provisional insurance data model shape](./ADR-0019-provisional-insurance-data-model-shape.md)
