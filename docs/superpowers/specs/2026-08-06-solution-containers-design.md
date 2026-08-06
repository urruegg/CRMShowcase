# Sprint 1 — Power Platform Solution Containers

| Field | Value |
| --- | --- |
| **Status** | Draft — pending user approval |
| **Date** | 2026-08-06 |
| **Deciders** | Repo owner |
| **Related** | [ADR-0002](../../adr/ADR-0002-oidc-federation-for-github-actions-to-entra.md) · [ADR-0003](../../adr/ADR-0003-terraform-as-iac-toolchain.md) · [ADR-0004](../../adr/ADR-0004-ci-plane-app-registrations-and-github-environments.md) · [ADR-0005](../../adr/ADR-0005-power-platform-application-users-for-ci.md) · [ADR-0006..0010](../../adr/) domain ADRs · [ADR-0017](../../adr/ADR-0017-alm-everything-through-the-pipeline.md) · [MICROSOFT-FRAMEWORKS.md](../../MICROSOFT-FRAMEWORKS.md) |

## Purpose

Lay the Power Platform **solutions layer** — six empty solution containers with
the correct dependency chain, deployed to DEV (unmanaged) and TEST (managed) —
before any real customisation goes in.

This is the first sprint that touches Dataverse. Every subsequent story that
adds a table, column, form or business rule lands into one of these
containers. Getting the containers right first prevents the classic Power
Platform ALM failure mode: the wrong publisher, the wrong dependency chain,
or a monolithic "custom solution" that cannot be reorganised without data
loss.

## What "done" looks like

- Six empty Power Platform solutions live in the ABSx demo tenant:
  `crmshow_Foundation`, `crmshow_DataModel`, `crmshow_Integration`,
  `crmshow_Sales`, `crmshow_Service`, `crmshow_Marketing`.
- All six are present as unmanaged solutions in `crmshowdev` and as managed
  solutions in `crmshowtest`, with matching versions.
- A demonstrable end-to-end run: touch one solution in DEV via
  `make.powerapps.com` → intake workflow opens PR → CI green → merge →
  auto-deploy DEV → workflow_dispatch → approve → deploy TEST → smoke green.
- [ADR-0019](../../adr/) — Solution versioning strategy — accepted.
- All 14 sprint issues closed with linked PRs.

## Non-goals

- No real customisation content in the six solutions this sprint. They ship
  empty. Adding the ADR-0006..0010 schema is the next sprint.
- No Copilot Studio topics. That comes with the first runtime-agent slice.
- No production environment. TEST is the highest environment this sprint
  targets.

---

## Design

### 1. Repository layout

Approach B (nested `core/` + `apps/`) with a top-level `manifest.json` and
CODEOWNERS wired to folders. This matches Microsoft's own team structure and
the "Multiple solutions with dedicated development environments" pattern
from
[Organize your solutions](https://learn.microsoft.com/power-platform/alm/organize-solutions).

```
solution/
├── manifest.json                             # single source of truth
├── manifest.schema.json                      # JSON Schema for validation
├── core/
│   ├── foundation/
│   │   ├── Other/
│   │   │   ├── Solution.xml
│   │   │   ├── Customizations.xml
│   │   │   └── Relationships.xml
│   │   └── ... unpacked components ...
│   ├── datamodel/                            # extends foundation
│   └── integration/                          # extends foundation
└── apps/
    ├── sales/                                # extends foundation + datamodel + integration
    ├── service/                              # extends foundation + datamodel + integration
    └── marketing/                            # extends foundation + datamodel + integration
```

### 2. Publisher (locked, one for the entire showcase)

| Field | Value |
| --- | --- |
| Display name | CRM Showcase |
| Unique name | `CRMShowcase` |
| Prefix | `crmshow` |
| Customization option value prefix | `10000` |

Microsoft's ALM guidance is emphatic: **one publisher for all solutions**.
Publisher cannot be changed for a component after it ships as managed.
Choosing `crmshow` up front matches the anonymised environment slot names
(`crmshowdev`, `crmshowtest`) and avoids re-branding pain later.

### 3. The six solutions

| Solution | Layer | Owner | Contents (this sprint = empty except version stamp) |
| --- | --- | --- | --- |
| `crmshow_Foundation` | Core | AG-E-08 Dataverse Modeler | Security roles baseline, shared choice sets |
| `crmshow_DataModel` | Core | AG-E-08 Dataverse Modeler | ADR-0006..0010 extensions (added in Sprint 2) |
| `crmshow_Integration` | Core | AG-E-09 Integration Engineer | Custom API defs, plug-in registrations, event-schema pointers |
| `crmshow_Sales` | App | AG-E-01 Product Owner + AG-E-08 | Sales-cockpit extensions on top of native Sales App |
| `crmshow_Service` | App | AG-E-01 + AG-E-08 | Case triage on top of native Customer Service |
| `crmshow_Marketing` | App | AG-E-01 + AG-E-08 | Segment / campaign extensions |

### 4. Dependency chain

```
Foundation
  ├─→ DataModel
  │     ├─→ Sales
  │     ├─→ Service
  │     └─→ Marketing
  └─→ Integration
        └─→ (referenced by any app that emits/consumes events)
```

### 5. The manifest.json (single source of truth)

`solution/manifest.json` is the machine-readable declaration the workflow
reads for names, versions, dependency order, and publisher. Its shape:

```json
{
  "$schema": "./manifest.schema.json",
  "publisher": {
    "displayName": "CRM Showcase",
    "uniqueName": "CRMShowcase",
    "prefix": "crmshow",
    "customizationOptionValuePrefix": 10000
  },
  "versioning": {
    "scheme": "semver-four-part",
    "format": "MAJOR.MINOR.PATCH.BUILD",
    "rules": {
      "MAJOR": "breaking schema change (rename, delete, type change on published column)",
      "MINOR": "additive feature (new table, new column, new form)",
      "PATCH": "fix (label typo, form layout, business rule tweak)",
      "BUILD": "GitHub Actions run number ($env:GITHUB_RUN_NUMBER); source of uniqueness"
    }
  },
  "solutions": [
    { "uniqueName": "crmshow_Foundation", "displayName": "CRM Showcase - Foundation",
      "path": "core/foundation", "version": "1.0.0.0", "dependsOn": [],
      "owner": "AG-E-08" },
    { "uniqueName": "crmshow_DataModel", "displayName": "CRM Showcase - Data Model",
      "path": "core/datamodel", "version": "1.0.0.0",
      "dependsOn": ["crmshow_Foundation"], "owner": "AG-E-08" },
    { "uniqueName": "crmshow_Integration", "displayName": "CRM Showcase - Integration",
      "path": "core/integration", "version": "1.0.0.0",
      "dependsOn": ["crmshow_Foundation"], "owner": "AG-E-09" },
    { "uniqueName": "crmshow_Sales", "displayName": "CRM Showcase - Sales",
      "path": "apps/sales", "version": "1.0.0.0",
      "dependsOn": ["crmshow_Foundation", "crmshow_DataModel", "crmshow_Integration"],
      "owner": "AG-E-01" },
    { "uniqueName": "crmshow_Service", "displayName": "CRM Showcase - Service",
      "path": "apps/service", "version": "1.0.0.0",
      "dependsOn": ["crmshow_Foundation", "crmshow_DataModel", "crmshow_Integration"],
      "owner": "AG-E-01" },
    { "uniqueName": "crmshow_Marketing", "displayName": "CRM Showcase - Marketing",
      "path": "apps/marketing", "version": "1.0.0.0",
      "dependsOn": ["crmshow_Foundation", "crmshow_DataModel", "crmshow_Integration"],
      "owner": "AG-E-01" }
  ]
}
```

**Guardrails**:

- `manifest.json` is the **only** place versions live. `Solution.xml` files
  inherit their version from the manifest at pack time.
- Adding a solution requires a manifest edit **and** a folder. Workflow
  refuses to build unlisted folders or list non-existent ones.
- Circular dependencies fail at `validate-manifest`.

### 6. Semantic versioning

Four-part `MAJOR.MINOR.PATCH.BUILD` (Dataverse-native).

| Bump | Trigger | Update strategy |
| --- | --- | --- |
| **MAJOR** | Breaking schema change | Fresh redeploy or `--stage-and-upgrade` with migration script |
| **MINOR** | Additive feature | `pac solution import --upgrade` |
| **PATCH** | Fix, no schema change | `pac solution import --upgrade` |
| **BUILD** | Every CI run | Automatic via `$env:GITHUB_RUN_NUMBER` |

**Bump decision**:

- PATCH and BUILD are automatic.
- MAJOR and MINOR require a PR label (`version-bump:major` /
  `version-bump:minor`). Workflow refuses to auto-bump for these.

**Detection heuristic** (advisory for MINOR/PATCH, **blocking** for MAJOR —
if the heuristic detects a MAJOR pattern, the workflow fails until the
`version-bump:major` label is present):

- Files touched under `Solution.xml` in `<AttributeDisplayCollectionOverride>`
  only → suggest `version-bump:patch` (advisory).
- New `<Entity>` or `<attribute>` nodes → suggest `version-bump:minor`
  (advisory).
- Existing `<Entity>` or `<attribute>` nodes removed, or `<Type>` /
  `<SchemaName>` values changed → require `version-bump:major` label to
  merge (blocking).

**Bump mechanic**: CI reads manifest → computes new versions for changed
solutions → writes back into manifest + each affected `Solution.xml` →
commits as `chore: bump versions [skip ci]`.

**Fresh-redeploy rule**: a managed solution's version can only ever increase
in a target environment. Fresh redeploys install whatever the manifest
declares as current; existing environments follow a monotonic upgrade
sequence.

### 7. Maker Studio intake

Two workflows, both landing changes as PRs. Third path documented as an
idea, deferred.

**Path A — On-demand (`solution-intake-on-demand.yml`)**

Trigger: `workflow_dispatch` with inputs `solution` and `reason`.

Steps: OIDC sign-in to DEV → `pac solution export --managed=false` → `pac
solution unpack` → XML normalisation → compare version → open PR on branch
`intake/<solution>/<run_number>` titled
`feat(solution): maker intake from DEV — <solution> — <reason>`.

Guardrail: one solution per PR.

**Path B — Scheduled drift (`solution-intake-drift.yml`)**

Trigger: `cron: 0 6 * * 1-5` (weekdays 06:00 UTC). Skippable with `[skip
drift]` in last commit message.

Steps: for each manifest entry → export → unpack to temp → `git diff` against
tracked folder. If any diff, open one PR titled `chore(solution): DEV drift
detected <YYYY-MM-DD>` with one commit per drifted solution. Assign to the
maker whose Entra ID last modified any drifted component (queried via
Dataverse audit history); fallback to repo owner.

Guardrail: drift PRs are advisory. Stale drift PRs (>7 days open) trigger a
warning issue.

**Path C — Deferred**: Power Platform → Git integration (Preview).
Documented in
[docs/ideas/UC-02-git-integration-preview/README.md](../../ideas/) with a
GitHub feature-request issue.

**Shared plumbing** in `scripts/solution/`:

- `export.ps1`, `unpack.ps1`, `pack.ps1`, `import.ps1`, `bump-version.ps1`.
  Each script has one job, takes a solution name, reads paths from the
  manifest.

**Auth**: never a stored connection string. Entra ID / OIDC via the CI
service principal in CI ([ADR-0002](../../adr/ADR-0002-oidc-federation-for-github-actions-to-entra.md),
[ADR-0004](../../adr/ADR-0004-ci-plane-app-registrations-and-github-environments.md)),
interactive `pac auth create --url $env:POWER_PLATFORM_ENV_URL` locally.

### 8. PR gates + DEV → TEST promotion

**Gate 1** — every PR touching `solution/**` runs `solution-ci.yml`:

| Check | Passes if | Fails if |
| --- | --- | --- |
| `validate-manifest` | JSON schema passes, every declared path exists, no cycles, no unlisted folders | Any mismatch |
| `pac solution pack` | Every solution packs into a valid unmanaged zip | Pack error |
| `pac solution check` | Solution Checker reports 0 High severity issues | Any High issue |
| `version-bump-detect` | No breaking-change signals, or correct `version-bump:*` label present | Breaking-change signal without `version-bump:major` label |
| Unit tests | Manifest parser, version-bumper, script smoke tests pass | Any script test fails |
| `terraform plan` | No infra drift on `infra/terraform/` | Plan shows changes not in this PR |

All six must be green. High severity Solution Checker issues block; Medium
and Low are surfaced as PR comments but not blocking. The comment-posting
step requires the workflow to have `pull-requests: write` permission —
declared at the workflow level, not per-job.

**Deploy DEV** (`solution-deploy-dev.yml`) — triggered on push to `main`
(paths: `solution/**`, `.github/workflows/solution-*.yml`).

Steps: OIDC sign-in to DEV → read manifest → topological sort → pack each
solution unmanaged → `pac solution import --publish-changes` in dependency
order → smoke test each solution (Web API query `GET
/api/data/v9.2/solutions?$filter=uniquename eq '...'`) → post version-list
commit status.

**Deploy TEST** (`solution-deploy-test.yml`) — triggered via
`workflow_dispatch` with input `commit_sha` (must match a commit on `main`).

Runs on GitHub Environment `test` — requires:

- 1 required reviewer (repo owner + CODEOWNERS of touched paths).
- Deployment branch rule: `main` only.
- Wait timer: 0.

Steps after approval: OIDC sign-in to TEST (via `crm-showcase-ci-test` per
[ADR-0005](../../adr/ADR-0005-power-platform-application-users-for-ci.md)) →
pack each solution managed → import in order → smoke test → create Git tag
`deploy/test/<UTC>-<short-sha>`.

**Rollback**:

- DEV: fix forward.
- TEST: re-run `solution-deploy-test.yml` with an earlier `commit_sha` and
  approve. Downgrading a managed layer will fail loudly (feature, not bug);
  the rollback then follows the documented delete-and-reimport path in
  [docs/runbooks/solution-rollback.md](../../runbooks/).

**CODEOWNERS** wired to folders:

```
solution/manifest.json           @urruegg
solution/core/foundation/        @urruegg
solution/core/datamodel/         @urruegg
solution/core/integration/       @urruegg
solution/apps/sales/             @urruegg
solution/apps/service/           @urruegg
solution/apps/marketing/         @urruegg
.github/workflows/solution-*.yml @urruegg
scripts/solution/                @urruegg
```

All lines currently route to `@urruegg` because the repo has one committer.
Each line becomes the right domain team as collaborators join.

### 9. Sprint tracking in GitHub

**Milestone**: `Sprint 1 — Solution containers`.

**Epic** (parent issue): `[Epic] Sprint 1 — Power Platform solution containers`
— links to this spec, the implementation plan, and every child issue.

**Child issues** (each becomes a PR):

| # | Issue | Owner | Depends on |
| --- | --- | --- | --- |
| S1-01 | Provision `pac` CLI on the runner + docs for local install | AG-E-04 | — |
| S1-02 | Add `pac auth create` to CI + verify OIDC works for Power Platform | AG-E-04 | S1-01 |
| S1-03 | `solution/manifest.json` + `manifest.schema.json` + parser | AG-E-08 | — |
| S1-04 | Scaffold six empty solutions in DEV, export, unpack, commit | AG-E-08 | S1-02, S1-03 |
| S1-05 | `scripts/solution/*.ps1` | AG-E-04 + AG-E-08 | S1-03 |
| S1-06 | `.github/workflows/solution-ci.yml` (Gate 1) | AG-E-04 | S1-05 |
| S1-07 | `.github/workflows/solution-deploy-dev.yml` | AG-E-04 | S1-05, S1-06 |
| S1-08 | Wire GitHub Environment `test` reviewers + `solution-deploy-test.yml` | AG-E-04 | S1-07 |
| S1-09 | `solution-intake-on-demand.yml` + `solution-intake-drift.yml` | AG-E-04 | S1-05 |
| S1-10 | ADR-0019 — Solution versioning strategy | AG-E-03 | S1-03 |
| S1-11 | Extend `.github/CODEOWNERS` with folder-scoped rules | AG-E-04 | — |
| S1-12 | `docs/ideas/UC-02-git-integration-preview/README.md` + feature-request issue | AG-E-01 | — |
| S1-13 | `docs/runbooks/solution-rollback.md` | AG-E-04 | S1-08 |
| S1-14 | End-to-end verification: fresh commit → DEV → TEST → smoke green | AG-E-04 | S1-08 |

### 10. Skills used

| Skill / tool | Purpose |
| --- | --- |
| `microsoft-learn` MCP | Grounding in Microsoft-authoritative docs (used throughout this brainstorm) |
| `pac` (Power Platform CLI) | Solution export / unpack / pack / import / check — install via `dotnet tool install --global Microsoft.PowerApps.CLI.Tool` |
| `microsoft/powerplatform-actions@v1` | Same functions in GitHub Actions — `actions-install`, `who-am-i`, `export-solution`, `unpack-solution`, `pack-solution`, `import-solution`, `check-solution` |
| `azure/login@v2` (OIDC) | Already in use for Terraform ([ADR-0002](../../adr/ADR-0002-oidc-federation-for-github-actions-to-entra.md)) |
| `hashicorp/setup-terraform@v3` | Already in use |
| Pester | PowerShell test framework for the manifest parser and version bumper |
| `writing-plans` skill | Turn this spec into a step-by-step implementation plan (next) |

**Deliberately not adopted**: Microsoft ALM Accelerator template — too heavy
and opinionated for our shape. We roll our own workflow using the official
Microsoft-published GitHub Actions.

---

## What lands in the repo when this sprint closes

```
solution/
  manifest.json
  manifest.schema.json
  core/foundation/            (six empty solutions, unpacked, versioned)
  core/datamodel/
  core/integration/
  apps/sales/
  apps/service/
  apps/marketing/

scripts/solution/
  export.ps1
  unpack.ps1
  pack.ps1
  import.ps1
  bump-version.ps1
  tests/*.Tests.ps1           (Pester)

.github/
  workflows/
    solution-ci.yml
    solution-deploy-dev.yml
    solution-deploy-test.yml
    solution-intake-on-demand.yml
    solution-intake-drift.yml
  CODEOWNERS                  (extended with folder-scoped rules)

docs/
  adr/ADR-0019-solution-versioning-strategy.md
  ideas/UC-02-git-integration-preview/README.md
  runbooks/solution-rollback.md
  BACKLOG.md                  (Sprint 1 stories added under a new "Epic 5 — Solution containers" section with US-501..US-514 tracking the 14 issues)
```

## Framework alignment

Recap for the record — this sprint advances:

- **CAF**: **Ready** (empty containers are the target-environment shape) and
  **Adopt** (source-controlled solutions with pipeline promotion). See
  [MICROSOFT-FRAMEWORKS.md §CAF](../../MICROSOFT-FRAMEWORKS.md#cloud-adoption-framework-caf).
- **WAF**: primary pillar **Operational Excellence** (nothing reaches an
  environment except through the pipeline — [ADR-0017](../../adr/ADR-0017-alm-everything-through-the-pipeline.md)),
  secondary **Reliability** (rollback is a pipeline action; version rules
  prevent import failures). See
  [MICROSOFT-FRAMEWORKS.md §WAF](../../MICROSOFT-FRAMEWORKS.md#azure-well-architected-framework-waf).
- **Zero Trust**: extends the OIDC-only pattern to Power Platform — no
  stored connection strings, one app registration per environment, Dataverse
  role scoped per env ([ADR-0004](../../adr/ADR-0004-ci-plane-app-registrations-and-github-environments.md),
  [ADR-0005](../../adr/ADR-0005-power-platform-application-users-for-ci.md)). See
  [MICROSOFT-FRAMEWORKS.md §Zero Trust](../../MICROSOFT-FRAMEWORKS.md#zero-trust).
- **Responsible AI**: unaffected — no AI content this sprint.

## Authoritative references

- [Organize your solutions](https://learn.microsoft.com/power-platform/alm/organize-solutions)
- [Solution concepts](https://learn.microsoft.com/power-platform/alm/solution-concepts-alm)
- [pac solution CLI reference](https://learn.microsoft.com/power-platform/developer/cli/reference/solution)
- [microsoft/powerplatform-actions on GitHub](https://github.com/microsoft/powerplatform-actions)
- Cloud Adoption Framework — [overview](https://learn.microsoft.com/azure/cloud-adoption-framework/overview)
- Well-Architected Framework — [pillars](https://learn.microsoft.com/azure/well-architected/pillars)
- Zero Trust — [overview](https://learn.microsoft.com/security/zero-trust/zero-trust-overview)
