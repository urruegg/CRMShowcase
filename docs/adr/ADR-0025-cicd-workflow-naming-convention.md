# ADR-0025 — CI/CD workflow naming convention

| Field | Value |
| --- | --- |
| **Status** | Accepted |
| **Date** | 2026-08-11 |
| **Decision mode** | Reversible organizational change |
| **Confidence** | High |
| **Deciders** | SecDevOps, Enterprise Architect, repo owner |
| **Topic area** | A8 — lifecycle, deployment, rollback |
| **Licence** | Own build — GitHub Actions workflows |
| **Upgrade impact** | Low — file renames + `name:` fields; job names unchanged so branch-protection required checks are unaffected |
| **CAF methodology** | Govern, Manage |
| **WAF pillar(s)** | Operational Excellence |
| **Zero Trust** | No change to auth posture |
| **Responsible AI** | Not AI-relevant |

## Context

The workflow files under `.github/workflows/` had inconsistent, non-descriptive
names (`terraform.yml`, `solution-ci.yml`, `solution-author-dev.yml`,
`solution-promote-test.yml`) that mixed lifecycle stage (CI vs CD) and target
environment without a clear convention. The original delivery plans also
intended `solution-deploy-dev.yml` / `solution-deploy-test.yml`, which the built
files never matched — so there was drift between plan and reality.

## Decision

Adopt a **lifecycle-first `ci-*` / `cd-*` naming convention**:
`<stage>-<subject>[-<target>].yml`.

| Old file | New file | `name:` |
| --- | --- | --- |
| `terraform.yml` | `cd-infra.yml` | CD — Infra (Terraform) |
| `solution-ci.yml` | `ci-solution.yml` | CI — Solution |
| `solution-author-dev.yml` | `cd-solution-dev.yml` | CD — Solution to DEV |
| `solution-promote-test.yml` | `cd-solution-test.yml` | CD — Solution to TEST |

- `ci-*` = validation only (PR gates, no environment writes).
- `cd-*` = deployment (infra provisioning / solution deploy to an environment).
- **Job names are unchanged** (`gate1`, `validate`) so the branch-protection
  required status check `gate1` keeps matching.
- `cd-infra.yml` retains its dual role (PR validate + OIDC smoke on merge);
  splitting it into `ci-infra.yml` + `cd-infra.yml` is deferred (YAGNI).

## Consequences

- Path-trigger globs updated: `ci-solution.yml` now watches
  `.github/workflows/ci-solution.yml` and `.github/workflows/cd-solution-*.yml`;
  `cd-infra.yml` self-reference updated.
- Test references updated: `ReviewedRefControls.Tests.ps1` →
  `ci-solution.yml`; `Publish-InsuranceFoundation.Tests.ps1` →
  `cd-solution-dev.yml`.
- Current-state docs updated (README, ADR-0004, MICROSOFT-FRAMEWORKS, BACKLOG).
- **Dated records left as-is:** `docs/superpowers/plans/*`, `specs/*` and the
  sprint status boards keep their original workflow names as historical
  evidence. This ADR is the old→new mapping for anyone following a stale
  reference.
- The `skip-solution-ci` label is unchanged (no bypass label exists in
  `ci-solution.yml`; the label rename would be cosmetic churn).

## Related

- [ADR-0002 — OIDC federation](./ADR-0002-oidc-federation-for-github-actions-to-entra.md)
- [ADR-0004 — CI-plane app registrations and GitHub environments](./ADR-0004-ci-plane-app-registrations-and-github-environments.md)
- [ADR-0017 — ALM everything through the pipeline](./ADR-0017-alm-everything-through-the-pipeline.md)
