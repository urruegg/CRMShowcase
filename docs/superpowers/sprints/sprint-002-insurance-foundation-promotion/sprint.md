# Sprint-002 — Insurance Foundation promotion (Proof #2)

Charter for the second proof of the delegated sprint operating model: run the
Insurance Foundation through the pattern to a managed **TEST (prod-equivalent)**
deployment, with plug-ins and business rules excluded.

**Design spec:** [../../specs/2026-08-11-insurance-foundation-promotion-design.md](../../specs/2026-08-11-insurance-foundation-promotion-design.md)
**Plan:** [../../plans/2026-08-11-insurance-foundation-promotion.md](../../plans/2026-08-11-insurance-foundation-promotion.md)
**ADR:** [ADR-0024](../../../adr/ADR-0024-effective-date-integrity-options.md)
**Operating model:** [../../SPRINT-OPERATING-MODEL.md](../../SPRINT-OPERATING-MODEL.md)

## Outcome

Promote the managed `crmshow_Foundation` + `crmshow_DataModel` schema slice
(tables, columns, choices, alternate keys, relationships, EN/DE/FR/IT
localization, Administration views/forms, security roles) from DEV to TEST. The
promoted package **excludes** all effective-date `businessRules` and the
`OverlapReporting` / `InvalidDateReporting` views, and **any plug-in**. The
effective-date enforcement decision is recorded in ADR-0024.

## Streams

| Stream | Autonomy class | Goal |
| --- | --- | --- |
| adr | DESIGN-SENSITIVE | ADR-0024 effective-date integrity options + OR-001 repoint + scope note (attended, human-reviewed) |
| promote | EXECUTION-ONLY | `Get-PromotionComponents` exclusion contract + `solution-promote-test.yml` two-job DEV→TEST workflow with exclusion gate |
| smoke | EXECUTION-ONLY | `Get-PromotionSmokeResult` offline-testable TEST smoke evaluator |

## Definition of done

- [ ] ADR-0024 recorded; no plug-in or business rule built; OR-001 re-pointed.
- [ ] Promotion contract + workflow committed and unit-tested.
- [ ] TEST smoke evaluator committed and green.
- [ ] Packaging exclusion verified (no effective-date views / no plug-in).
- [ ] sprint-002 charter + stream issues; STATUS evidence.
- [ ] Managed deploy to TEST green in GitHub Actions with version + smoke
      evidence (gated live step under protected-environment approval).
