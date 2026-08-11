# Proof #2 — Insurance Foundation promotion to TEST via the delegation pattern

| Field | Value |
| --- | --- |
| **Status** | Approved design — ready for implementation planning |
| **Date** | 2026-08-11 |
| **Decision mode** | Reversible delivery hypothesis, proven by execution |
| **Working hypothesis** | Running a real, deterministic ALM slice (the Insurance Foundation, minus plug-ins and business rules) through the Proof #1 delegation pattern is the safest second proof — it exercises parallel worktree streams and both autonomy classes end to end to a managed TEST (prod-equivalent) deployment. |
| **Confidence** | High for the promoted slice and the pattern mechanics; medium for live TEST deploy until environment approval is exercised |
| **Maturity** | Design; promotion automation not yet built |
| **Licence** | 🧩 configuration / own build; Dynamics 365 and Power Platform entitlements validated per environment |
| **Upgrade impact** | Additive MINOR; managed `crmshow_Foundation` and `crmshow_DataModel` promoted to TEST; no destructive upgrade |
| **Depends on** | Proof #1 delegation toolchain (`scripts/orchestration/*`, PR #45). This branch is stacked on `docs/delegated-sprint-operating-model`; rebase onto `main` after #45 merges. |
| **Related** | [Insurance Foundation spec](./2026-08-08-insurance-foundation-design.md) · new **ADR-0024** (effective-date integrity options) · [OR-001](../../requirements/OR-001-effective-date-integrity.md) · [ADR-0004](../../adr/ADR-0004-ci-plane-app-registrations-and-github-environments.md) · [ADR-0017](../../adr/ADR-0017-alm-everything-through-the-pipeline.md) · [ADR-0019](../../adr/ADR-0019-provisional-insurance-data-model-shape.md) · [ADR-0023](../../adr/ADR-0023-delegated-sprint-operating-model.md) · [SPRINT-OPERATING-MODEL](../SPRINT-OPERATING-MODEL.md) |
| **Frameworks** | CAF Adopt, Govern, Manage · WAF Operational Excellence, Reliability, Security · Zero Trust · Responsible AI (accountability, transparency) |

---

## 1. Outcome

Proof #2 runs a **real feature** — the Insurance Foundation — through the
delegation pattern established in Proof #1, ending in a **managed deployment to
TEST as the production-equivalent environment**, with linked evidence. It
proves the pattern on real ALM work; it does not re-solve insurance modeling.

It reuses the scope of
[2026-08-08-insurance-foundation-design.md](./2026-08-08-insurance-foundation-design.md),
minus the carve-outs in §2, and adds the managed DEV→TEST promotion path that
does not exist yet.

## 2. Refined scope (plug-ins and business rules excluded)

### In the promoted managed slice

`crmshow_Foundation` + `crmshow_DataModel`, containing only:

- tables (`crmshow_accountcontactrole`, `crmshow_policyprojection`,
  `crmshow_policypartyrole`) and the native Account/Contact extensions;
- columns, global choices, alternate keys, relationships;
- EN (`1033`), DE (`1031`), FR (`1036`), IT (`1040`) localization;
- minimal admin forms and list views (non-effective-date);
- the two security roles.

### Excluded from the slice

- **All effective-date logic artifacts** — the `businessRules`-derived
  reporting/validation views **and** any enforcement.
- **Any plug-in** (`crmshow_Integration` stays empty).

**Mechanism.** The managed component set simply **omits** the effective-date
views. DEV keeps them (harmless, unmanaged); TEST never receives them. There is
**no destructive DEV cleanup** and no view deletion.

### Captured as ADR-0024

The whole effective-date integrity decision — detection **and** enforcement —
is recorded in **ADR-0024** with the three options (synchronous validation
plug-in · Maker-Studio table-scoped business rules · source/integration-contract
enforcement), superseding the framing in
[OR-001](../../requirements/OR-001-effective-date-integrity.md). No plug-in and
no business rule is built in Proof #2. OR-001 / issue #9 remains open and now
points to ADR-0024 for the decision record.

## 3. Delegated streams (Option 2 — both autonomy classes)

| Stream | Class | Worktree | Deliverable |
| --- | --- | --- | --- |
| **A** | **DESIGN-SENSITIVE (attended)** | `wt/sprint-002-adr` | `ADR-0024` effective-date integrity options + a scope-refinement note on the Insurance Foundation spec. Human-reviewed by design — proves the autopilot guardrail. |
| **B** | **EXECUTION-ONLY (headless)** | `wt/sprint-002-promote` | `.github/workflows/solution-promote-test.yml` + a managed-import wrapper exposing `InstallOrUpdate` / `StageForUpgrade` / `ApplyUpgrade`, packaging only the in-scope component set (no effective-date views). Unit-tested (Pester). |
| **C** | **EXECUTION-ONLY (headless)** | `wt/sprint-002-smoke` | TEST smoke-test suite (Pester): all four LCIDs active; both managed solutions present at expected version and managed state; tables/columns/alternate keys/relationships present; Reader can read but not mutate; Data Steward can create/update but not administer security; localized labels retrievable for all four LCIDs. |

Streams are created with `New-SprintWorktree.ps1` and dispatched with
`Invoke-StreamDelegation.ps1`: Stream A attended (the wrapper refuses a headless
launch for a DESIGN-SENSITIVE packet); Streams B and C headless with the
`git push` / `rm` / `git reset` deny-list. Each intakes to the trunk via PR.

## 4. Promotion architecture

```
DEV (unmanaged, authored + reconciled)
  --export managed--> reviewed managed packages (in-scope component set only)
  --> solution-promote-test.yml  (GitHub Actions; TEST protected environment)
      preflight: LCIDs active, monotonic version, no unmanaged active layer
      import:    managed InstallOrUpdate (additive; no destructive upgrade)
  --> smoke suite (Stream C) --> deployment evidence
```

- The delegated streams **build** the automation, ADR and tests. The **live
  TEST deploy runs in GitHub Actions** against the real TEST environment
  (`crmshowtest`, app registration `crm-showcase-ci-test`), gated by the
  **protected-environment approval**
  ([ADR-0004](../../adr/ADR-0004-ci-plane-app-registrations-and-github-environments.md))
  — that approval is the human gate for "to prod-equivalent."
- Deployments occur only through GitHub Actions
  ([ADR-0017](../../adr/ADR-0017-alm-everything-through-the-pipeline.md)). The
  import wrapper exposes `InstallOrUpdate` / `StageForUpgrade` / `ApplyUpgrade`
  modes but Proof #2 uses additive `InstallOrUpdate` only.

## 5. TEST-as-prod-equivalent

TEST is the highest managed environment in the demo; there is no separate PROD
slot ([ENVIRONMENTS.md](../../ENVIRONMENTS.md)). Provisioning a real PROD slot
is explicitly out of scope and can be a later sprint. "Deployed & validated"
for Proof #2 means: managed `crmshow_Foundation` + `crmshow_DataModel` present
in TEST at the expected version, all four LCIDs active, the smoke suite green in
CI, and evidence linked in the PR and the sprint charter issue.

## 6. Traceability

```
Insurance Foundation spec -> ADR-0024 -> sprint-002 charter issue #S
  -> stream issues #A/#B/#C + handover packets
  -> wt/sprint-002-* branches -> PRs -> CI -> human merge to main
  -> solution-promote-test.yml -> TEST managed deploy (approved) -> evidence
```

New folder `docs/superpowers/sprints/sprint-002-insurance-foundation-promotion/`
(charter `sprint.md` + `STATUS.md`), reusing the Proof #1 issue templates,
handover/intake contracts and operating model.

## 7. Autopilot guardrail

- **Stream A** (`ADR-0024`) is DESIGN-SENSITIVE and **cannot** be launched
  headless — it runs attended and is human-reviewed, proving "design is never
  autopilot-approved; the human reviews the option."
- **Streams B and C** are EXECUTION-ONLY: headless autopilot restricted by the
  deny-list; they cannot self-integrate.
- A stream that discovers a new design decision stops and raises a clarification
  in the chat.

## 8. Frameworks mapping

- **CAF** — *Adopt* (managed promotion), *Govern* (traceability + required
  reviewers), *Manage* (environment lifecycle, evidence).
- **WAF** — *Operational Excellence* (repeatable promotion + smoke), *Reliability*
  (preflight gates, additive-only import), *Security* (least-privilege per-env
  identity, protected-environment approval).
- **Zero Trust** — verify explicitly (preflight + smoke), least privilege
  (per-environment app registration), assume breach (no cross-environment
  identity).
- **Responsible AI** — accountability (a human approves the TEST deploy),
  transparency (autonomy class + ADR recorded).

## 9. Acceptance criteria

- [ ] `ADR-0024` recorded — effective-date integrity options; **no** plug-in or
      business rule built; OR-001 re-pointed to ADR-0024.
- [ ] `solution-promote-test.yml` + managed-import wrapper (three modes)
      committed and unit-tested.
- [ ] TEST smoke suite committed and green.
- [ ] A packaging test verifies the managed slice **excludes** effective-date
      views and contains **no** plug-in.
- [ ] sprint-002 charter + three stream issues created; STATUS board carries
      evidence.
- [ ] Managed deploy to TEST green in GitHub Actions with version + smoke
      evidence linked (the gated live step, under protected-environment
      approval).

## 10. Risks and mitigations

| Risk | Mitigation |
| --- | --- |
| DEV authoring not green before managed export | Plan includes a DEV-reconcile/preflight check before export |
| TEST env credentials / GitHub environment approval not configured | Build + tests still merge; the live deploy waits on the protected-environment gate — no partial/destructive state |
| Managed package accidentally includes effective-date views | Packaging test asserts the excluded component set |
| Scope creep into Sprint-4 tables or enforcement | Explicit exclusions; enforcement lives only in ADR-0024 as options |

## 11. Out of scope (YAGNI)

- A real PROD environment slot (kept for a later sprint).
- Any plug-in or business rule (effective-date enforcement stays an ADR option).
- Destructive managed upgrade / component removal in TEST.
- Sprint-4 tables (coverage, jurisdiction, location, claim, quote, change-event,
  impact-assessment, eligibility-decision) and integration contracts.
- App forms/workspaces/command bars beyond the minimal admin surface.

## 12. Open follow-ups (for the plan)

- Confirm the existing `Export-Solution.ps1` / `Import-Solution.ps1` and
  `solution-ci.yml` conventions and reuse them for the TEST promotion workflow.
- Decide how the in-scope managed component set is expressed (solution
  component list vs. a packaging filter) and add the assertion test.
