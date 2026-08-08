# Backlog

| Status | Draft 0.2 · **Owner** `AG-E-01` Product Owner |

Trace: **Topic area → use case → story → ADR → PR → evidence.**

Story IDs are stable. Priorities move; IDs do not.

## Epic 1 — Golden thread runnable end to end

The one journey the whole architecture conversation hangs on: the Smith
household relocates across a jurisdiction boundary. See
[ideas/UC-01-relocation-across-jurisdictions/README.md](./ideas/UC-01-relocation-across-jurisdictions/README.md).

| ID | Story | ADR | Status |
| --- | --- | --- | --- |
| US-101 | Smith household fixture seeded in the sandbox (synthetic) | — | `[TBD]` |
| US-102 | Address change emits `AddressChanged` with effective date | [ADR-0011](./adr/ADR-0011-event-driven-cascade.md) | `[TBD]` |
| US-103 | Impact set is visible and traceable across affected policies | [ADR-0011](./adr/ADR-0011-event-driven-cascade.md) | `[TBD]` |
| US-104 | Building-cover eligibility re-evaluated on jurisdiction crossing | [ADR-0012](./adr/ADR-0012-jurisdiction-driven-eligibility.md) | `[TBD]` |
| US-105 | GA reassignment runs as a governed business case | [ADR-0013](./adr/ADR-0013-ga-ownership-and-territory.md) | `[TBD]` |
| US-106 | Portfolio discount recalculated on the remaining policies | [ADR-0011](./adr/ADR-0011-event-driven-cascade.md) | `[TBD]` |
| US-107 | Exactly one advisory contact proposed per household | [ADR-0009](./adr/ADR-0009-lead-as-interest-on-existing-person.md) | `[TBD]` |
| US-108 | Failed downstream call dead-letters and replays | [ADR-0011](./adr/ADR-0011-event-driven-cascade.md) | `[TBD]` |

## Epic 2 — The live build (A4)

| ID | Story | Status |
| --- | --- | --- |
| US-201 | Three candidate changes selected and validated | `[TBD]` |
| US-202 | Agent chain produces ADR → solution change → test | `[TBD]` |
| US-203 | Pipeline deploys to sandbox in under 4 minutes | `[TBD]` |
| US-204 | Rollback demonstrated | `[TBD]` |
| US-205 | Recorded fallback produced and cued | `[TBD]` |

## Epic 3 — Runtime agents (AG-F-##)

| ID | Story | Status |
| --- | --- | --- |
| US-301 | AG-F-01 Next-Best-Action: scores the book and emits explainable NBA cards into the advisor cockpit | `[TBD]` |
| US-302 | AG-F-02 Life-Event Detection: detects a governed-attribute change and emits a typed domain event | `[TBD]` |
| US-303 | AG-F-03 Case Management (prefill): predicts and populates case fields at conversation end | `[TBD]` |
| US-304 | AG-F-04 Conversation Intelligence: summarises interaction + writes back with provenance badge | `[TBD]` |
| US-305 | AG-F-05 Data-Quality: detects duplicates / ambiguous identity, raises closed-loop remediation | `[TBD]` |
| US-306 | AG-F-06 Campaign & Content Assist: NLQ segment building + content generation for marketing | `[TBD]` |

## Epic 4 — Governance evidence

| ID | Story | Status |
| --- | --- | --- |
| US-401 | Every licensing flag resolved ([LICENSING.md](./LICENSING.md)) | `[TBD]` |
| US-402 | Every AI maturity verified ([AI.md](./AI.md)) | `[TBD]` |
| US-403 | Regression suite green on the eight curveballs ([TEST.md](./TEST.md)) | `[TBD]` |
| US-404 | `.github/workflows/terraform.yml` extended with `plan` on real remote state | `[TBD]` |

## Epic 5 — Solution containers (Sprint 1)

Traces to spec [`docs/superpowers/specs/2026-08-06-solution-containers-design.md`](./superpowers/specs/2026-08-06-solution-containers-design.md).

| ID | Story | Status |
| --- | --- | --- |
| US-501 | Provision pac CLI on runner + local install docs | `[TBD]` |
| US-502 | Add pac auth create to CI + verify Power Platform OIDC | `[TBD]` |
| US-503 | solution/manifest.json + schema + parser | `[TBD]` |
| US-504 | Scaffold six empty solutions in DEV, export, unpack, commit | `[TBD]` |
| US-505 | scripts/solution/*.ps1 (export, unpack, pack, import, bump-version) | `[TBD]` |
| US-506 | .github/workflows/solution-ci.yml (Gate 1) | `[TBD]` |
| US-507 | .github/workflows/solution-deploy-dev.yml | `[TBD]` |
| US-508 | GitHub Environment test reviewers + solution-deploy-test.yml | `[TBD]` |
| US-509 | solution-intake-on-demand.yml + solution-intake-drift.yml | `[TBD]` |
| US-510 | ADR-0019 solution versioning strategy | `[TBD]` |
| US-511 | Extend .github/CODEOWNERS with folder-scoped rules | `[TBD]` |
| US-512 | docs/ideas/UC-02-git-integration-preview + issue | `[TBD]` |
| US-513 | docs/runbooks/solution-rollback.md | `[TBD]` |
| US-514 | End-to-end verification: fresh commit -> DEV -> TEST -> smoke green | `[TBD]` |

## Epic 6 — Mobiliar prototype intake and data-model baseline (Sprint 2)

Traces to
[`docs/superpowers/specs/2026-08-08-mobiliar-prototype-intake-design.md`](./superpowers/specs/2026-08-08-mobiliar-prototype-intake-design.md).

| ID | Story | Status |
| --- | --- | --- |
| US-601 | Export and unpack the Mobiliar prototype into a quarantined intake area | Done — [#6](https://github.com/urruegg/CRMShowcase/issues/6) |
| US-602 | Scan and sanitize the snapshot for secrets, environment values, and customer content | Done — [#6](https://github.com/urruegg/CRMShowcase/issues/6) |
| US-603 | Generate a deterministic machine-readable artefact BOM | Done — [#6](https://github.com/urruegg/CRMShowcase/issues/6) |
| US-604 | Map BOM artefacts to domains, target solution containers, and review dispositions | Done — [#6](https://github.com/urruegg/CRMShowcase/issues/6) |
| US-605 | Design the CRM Showcase target data-model extensions | Done — [#6](https://github.com/urruegg/CRMShowcase/issues/6) |
| US-606 | Publish linked sprint evidence in a GitHub feature issue | Done — [#6](https://github.com/urruegg/CRMShowcase/issues/6) |

## Epic 7 — Insurance Foundation (Sprint 3)

Traces to [GitHub issue #8](https://github.com/urruegg/CRMShowcase/issues/8)
and the
[Sprint 3 design](./superpowers/specs/2026-08-08-insurance-foundation-design.md).

| ID | Story | Status |
| --- | --- | --- |
| US-701 | Reconcile EN/DE/FR/IT environment languages as IaC desired state | Planned — [#8](https://github.com/urruegg/CRMShowcase/issues/8) |
| US-702 | Deliver shared insurance choices and security roles | Planned — [#8](https://github.com/urruegg/CRMShowcase/issues/8) |
| US-703 | Extend Account and Contact | Planned — [#8](https://github.com/urruegg/CRMShowcase/issues/8) |
| US-704 | Deliver effective-dated AccountContactRole | Planned — [#8](https://github.com/urruegg/CRMShowcase/issues/8) |
| US-705 | Deliver Account-owned PolicyProjection | Planned — [#8](https://github.com/urruegg/CRMShowcase/issues/8) |
| US-706 | Deliver effective-dated PolicyPartyRole | Planned — [#8](https://github.com/urruegg/CRMShowcase/issues/8) |
| US-707 | Validate schema and multilingual semantic metadata | Planned — [#8](https://github.com/urruegg/CRMShowcase/issues/8) |
| US-708 | Deploy unmanaged to DEV and managed to TEST | Planned — [#8](https://github.com/urruegg/CRMShowcase/issues/8) |
| US-709 | Load synthetic fixtures and publish smoke evidence | Planned — [#8](https://github.com/urruegg/CRMShowcase/issues/8) |
| US-710 | Enforce effective-date integrity across every Dataverse write path | Deferred — [#9](https://github.com/urruegg/CRMShowcase/issues/9) · [OR-001](./requirements/OR-001-effective-date-integrity.md) |

## Bootstrap stories already delivered

| ID | Story | Commit |
| --- | --- | --- |
| US-001 | Repo bootstrap: governance stack in place | `a2accf9` |
| US-002 | Anonymised environments + OIDC pattern (ADR-0002) | `11ce688` |
| US-003 | Terraform IaC toolchain locked in (ADR-0003) | `0bc4d15` |
| US-004 | Tenant access proven; envs renamed; Terraform state imported | `ded5117` |
| US-005 | CI plane (Entra + GitHub Environments + workflow) live end-to-end | `391dd68`, `f6db7d5` |
| US-006 | Power Platform application users for CI SPs (ADR-0005) | `72d6ef8` |
