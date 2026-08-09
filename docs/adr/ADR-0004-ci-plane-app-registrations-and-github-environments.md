# ADR-0004 — CI plane: app registrations, federated credentials, GitHub Environments

| Field | Value |
| --- | --- |
| Status | Accepted |
| Date | 2026-08-06 |
| Deciders | Repo owner |
| Related | [ADR-0002](./ADR-0002-oidc-federation-for-github-actions-to-entra.md), [ADR-0003](./ADR-0003-terraform-as-iac-toolchain.md), [../ENVIRONMENTS.md](../ENVIRONMENTS.md), [../SECURITY.md](../SECURITY.md) |

## Context

[ADR-0002](./ADR-0002-oidc-federation-for-github-actions-to-entra.md) established
that GitHub Actions authenticate to the demo tenant via workload identity federation,
never via stored secrets. [ADR-0003](./ADR-0003-terraform-as-iac-toolchain.md)
established that Terraform is the toolchain for provisioning this. This ADR
records **exactly what got provisioned** and how the pieces fit together, so a
reader looking at the running showcase can trace each CI action back to a specific
identity with a specific scope.

## Decision

Provision two Entra app registrations — one per environment slot — with **OIDC
federated credentials only** (no client secrets), matching two GitHub Environments
that surface the identifiers to CI as **non-secret variables**.

### Entra app registrations (created in the ABSx demo tenant)

| App | Purpose | Federated subject template |
| --- | --- | --- |
| `crm-showcase-ci-dev`  | CI targeting the `dev` (`crmshowdev`) environment  | `repo:{owner}@{owner_id}/{repo}@{repo_id}:environment:dev` and `repo:{owner}@{owner_id}/{repo}@{repo_id}:pull_request` |
| `crm-showcase-ci-test` | CI targeting the `test` (`crmshowtest`) environment | `repo:{owner}@{owner_id}/{repo}@{repo_id}:environment:test` and `repo:{owner}@{owner_id}/{repo}@{repo_id}:pull_request` |

- The subject template embeds the **numeric owner and repository IDs** — that
  matches GitHub's current default OIDC subject prefix on this repo
  (`sub_claim_prefix: repo:urruegg@46865858/CRMShowcase@1324936766`) and binds
  the credential to *this specific* owner/repo even across renames. The IDs are
  looked up at plan time via `data "github_user"` and `data "github_repository"`
  so the module is portable to any owner/repo. See
  [../../infra/terraform/modules/entra/main.tf](../../infra/terraform/modules/entra/main.tf).
- **No client secret.** Federation replaces it. Adding a client secret would be a
  policy violation ([SUPERPOWERS_CONTRACT.md §1.2](../../SUPERPOWERS_CONTRACT.md)).
- **`sign_in_audience = "AzureADMyOrg"`** — single-tenant apps, only usable in the
  demo tenant.
- **Two federated credentials per app:** one for `environment:<slot>` runs
  (post-merge / manual dispatch), one for `pull_request` events (validate-only CI).

### GitHub Environments

| Environment | Purpose | Variables set | Current live reviewer posture |
| --- | --- | --- | --- |
| `dev`  | CI targeting `crmshowdev`  | `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `POWER_PLATFORM_ENV_ID`, `POWER_PLATFORM_ENV_URL` | No required reviewers yet. |
| `test` | CI targeting `crmshowtest` | `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `POWER_PLATFORM_ENV_ID`, `POWER_PLATFORM_ENV_URL` | Required reviewer is the repo owner `urruegg` (GitHub user ID `46865858`). |

- `can_admins_bypass = false` — even repo admins go through the environment gate.
- `prevent_self_review = false` on `test` is a deliberate **demo constraint**.
  This personal repo currently has one dependable maintainer, so disallowing
  self-review would deadlock the TEST gate. Customer target state is stricter:
  use independent required reviewers and remove the owner-as-reviewer exception.

### Reviewed-ref controls: live evidence captured 2026-08-10

Evidence captured on 2026-08-10 from the live demo repo shows the reviewed-ref
controls are now active:

- `dev` deploys only from `main` via live deployment policy ID `56913774`.
- `test` deploys only from `main` via live deployment policy ID `56680080`.
- `test` keeps required reviewer `urruegg` (GitHub user ID `46865858`);
  `prevent_self_review = false` remains the deliberate single-maintainer demo
  exception.
- `main` branch protection is live and enforces pull-request flow, the `gate1`
  status check, conversation resolution, `required_linear_history = true`,
  `dismiss_stale_reviews = true`, `allows_force_pushes = false`,
  `allows_deletions = false`, and `required_approving_review_count = 0`.
- Deployment policy IDs are environment-scoped live identifiers. If either
  GitHub Environment is recreated, re-check the current policy ID before
  re-importing Terraform state.

Customer target state remains stricter: use independent required reviewers on
`test` and raise `required_approving_review_count` on `main` to at least one
independent approver once the repo is no longer single-maintainer.

### CI workflow

[`.github/workflows/terraform.yml`](../../.github/workflows/terraform.yml).

- **PR trigger.** `terraform fmt -check`, `terraform init -backend=false`,
  `terraform validate`. Never touches the tenant.
- **Push-to-main / manual dispatch.** Signs in via OIDC to the `dev` (or chosen)
  Entra app registration and prints the resolved identity + Power Platform
  target. Proves the whole federation loop works.

## What is deliberately NOT in this ADR

- **Real `terraform plan` / `apply` in CI.** Requires remote state (Azure Storage
  backend). The demo tenant currently has no Azure subscription, so remote state
  is a follow-up: either add an Azure subscription and use Azure Storage, or use
  Terraform Cloud's free tier. Until then, applies happen from the maintainer's
  laptop with `az login` + local state (see [../../infra/terraform/README.md](../../infra/terraform/README.md)).
- **Power Platform env access for the CI SPs.** The service principals authenticate
  to Entra, but they are not yet registered as application users in Dataverse
  environments. That's what a follow-up ADR (0005) will scope — with a specific
  security role per slot (System Customizer in `dev`, System Administrator in
  `test`) — once we have a concrete solution deployment to run.
- **Copilot Studio / Dataverse solution deployment.** Sequenced after the CI
  identity plane is proven working end-to-end.

## Consequences

**Positive**
- Every CI run is auditable to a specific identity + a specific GitHub
  Environment + a specific subject claim.
- No stored secrets for CI to leak. Rotating auth = revoking the federated
  credential, not rotating a password.
- The whole CI identity plane is `terraform apply`-reproducible on any tenant.

**Negative / cost**
- No apply from CI until remote state exists. Applies stay on the maintainer
  laptop for now. Documented and time-bounded.
- The Power Platform env-user assignment step is manual until ADR-0005 lands.

**Follow-ups**
- **ADR-0005** — Power Platform env-user assignment for the CI SPs.
- **ADR-0006** — Remote state backend choice.
- Replace the demo owner-reviewer exception on `test` with independent required
  reviewers once a second maintainer or customer approver exists.
- Raise `required_approving_review_count` above zero for customer repos while
  preserving imported live evidence for the demo repo.
