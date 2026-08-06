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
| US-301 | AG-F-01 Lead Qualification: drafts a grounded summary on a new lead | `[TBD]` |
| US-302 | AG-F-02 Service Triage: classifies + drafts first response with grounded knowledge | `[TBD]` |
| US-303 | AG-F-03 Campaign Copy: drafts segment-appropriate variants against an approved brief | `[TBD]` |
| US-304 | AG-F-04 RevOps Insights: summarises pipeline movement and flags anomalies | `[TBD]` |

## Epic 4 — Governance evidence

| ID | Story | Status |
| --- | --- | --- |
| US-401 | Every licensing flag resolved ([LICENSING.md](./LICENSING.md)) | `[TBD]` |
| US-402 | Every AI maturity verified ([AI.md](./AI.md)) | `[TBD]` |
| US-403 | Regression suite green on the eight curveballs ([TEST.md](./TEST.md)) | `[TBD]` |
| US-404 | `.github/workflows/terraform.yml` extended with `plan` on real remote state | `[TBD]` |

## Bootstrap stories already delivered

| ID | Story | Commit |
| --- | --- | --- |
| US-001 | Repo bootstrap: governance stack in place | `a2accf9` |
| US-002 | Anonymised environments + OIDC pattern (ADR-0002) | `11ce688` |
| US-003 | Terraform IaC toolchain locked in (ADR-0003) | `0bc4d15` |
| US-004 | Tenant access proven; envs renamed; Terraform state imported | `ded5117` |
| US-005 | CI plane (Entra + GitHub Environments + workflow) live end-to-end | `391dd68`, `f6db7d5` |
| US-006 | Power Platform application users for CI SPs (ADR-0005) | `72d6ef8` |
