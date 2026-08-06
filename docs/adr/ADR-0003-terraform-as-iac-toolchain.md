# ADR-0003 — Terraform as the IaC toolchain for the showcase

| Field | Value |
| --- | --- |
| Status | Accepted |
| Date | 2026-08-06 |
| Deciders | Repo owner |
| Related | [ADR-0001](./ADR-0001-adopt-agent-driven-copilot-governance.md), [ADR-0002](./ADR-0002-oidc-federation-for-github-actions-to-entra.md), [../ENVIRONMENTS.md](../ENVIRONMENTS.md) |

## Context

The showcase spans **four control planes**:

1. **Power Platform** — Dataverse environments, environment-level settings, DLP policies, solutions.
2. **Entra ID** — app registrations, federated credentials, role assignments.
3. **Azure** — Key Vault, Application Insights, optional AI Foundry / App Service resources.
4. **GitHub** — Environments, secrets, variables, branch protection.

The requirement from the repo owner: *"the tenant and environment configuration should
be part of the IaC to ensure we can deploy the showcase to any tenant we want."*
That means a single, parameterised IaC that reproduces the showcase in a fresh tenant.

Two candidate toolchains were considered:

**Bicep + PowerShell/pac scripts**
- **Pros.** Pure Microsoft toolchain. Bicep is well-supported in VS Code and Azure DevOps.
  Familiar to Azure-only teams.
- **Cons.** **Bicep has no native Power Platform resource types.** Power Platform env
  creation, DLP policies, and env-level settings would need PowerShell or `pac` scripts
  wrapped in a workflow, sitting outside Bicep state. That splits IaC across two
  paradigms and two state models. The Microsoft.Graph Bicep provider for Entra apps
  is still in preview.

**Terraform (with official providers)**
- **Pros.** One IaC, one state, one plan/apply cycle across all four planes:
  - `microsoft/power-platform` (official Microsoft-published provider) — environments,
    DLP policies, environment settings, solution deployments.
  - `hashicorp/azuread` — app registrations, federated credentials, groups.
  - `hashicorp/azurerm` — Azure resources.
  - `integrations/github` — GitHub Environments, secrets, variables, branch protection.
  All GA (except non-controversial preview attributes documented per-resource).
- **Cons.** Adds Terraform to the toolchain (extra install, extra learning curve for
  Bicep-only teams). State file management needs a remote backend (Azure Storage) once
  we go beyond the demo.

## Decision

Adopt **Terraform** as the IaC toolchain for the entire showcase.

### Structure

```
infra/
├── README.md
├── terraform/
│   ├── versions.tf              # required providers, pinned versions
│   ├── providers.tf             # provider configuration (uses OIDC in CI)
│   ├── variables.tf             # inputs (tenant, env slot names, GitHub repo)
│   ├── outputs.tf               # useful outputs (app IDs, env URLs)
│   ├── main.tf                  # module wiring
│   ├── terraform.tfvars.example # placeholder values (committed)
│   ├── terraform.tfvars         # real values (git-ignored)
│   └── modules/
│       ├── powerplatform/       # environments, DLP, env settings
│       ├── entra/               # app registrations + federated credentials
│       ├── github/              # GitHub Environments + secrets/variables
│       └── azure/               # Key Vault, App Insights (added as needed)
```

### Providers (pinned in `versions.tf`)

- `microsoft/power-platform` — Power Platform environments and settings.
- `hashicorp/azuread` — Entra ID app registrations, federated credentials.
- `hashicorp/azurerm` — Azure resources.
- `integrations/github` — GitHub Environments and secrets.

### State

- **Local state** during initial bootstrap on the maintainer's machine (state file is
  git-ignored, contains no secrets but does contain identifiers).
- **Remote state in Azure Storage** once the first apply has landed and a shared
  storage account exists — tracked as a follow-up.

### Authentication

- **From CI:** Terraform authenticates to Entra + Azure via **workload identity
  federation** ([ADR-0002](./ADR-0002-oidc-federation-for-github-actions-to-entra.md)).
- **From local dev:** Terraform uses the maintainer's `az login` session and the
  Power Platform provider uses the same or an OAuth device-code flow.
- **No client secrets or admin UPNs are ever passed to Terraform.**

### Reproducibility ("any tenant")

- All tenant / environment / GitHub identifiers are variables in
  `terraform.tfvars` (not committed).
- The plan `plan → apply` against a fresh tenant should recreate the showcase from
  scratch. The maintainer runs `terraform import` once to bring the existing ABSx
  environments under Terraform management on first bootstrap.

## Consequences

**Positive**
- One IaC, one state, one review path. Every tenant-touching change is captured as
  a Terraform diff visible in a PR.
- Renaming, retiring, or re-creating environments becomes a `terraform apply` with
  a review, not a click in Power Platform Admin Center.
- The showcase's own infrastructure becomes part of the demo — "this repo is the
  system it describes."

**Negative / cost**
- Repo maintainers must install Terraform locally. Documented in
  [../../infra/README.md](../../infra/README.md).
- The Power Platform provider is younger than azurerm/azuread; some resource-level
  attributes may be limited. Documented per-resource as we hit them.
- Remote state needs a bootstrap Azure Storage account, tracked as a follow-up.

**Follow-ups**
- Provision the initial Terraform layout in `infra/terraform/` (this session, next turn).
- `terraform import` the existing `crmshowdev` and `crmshowtest` environments.
- Add a remote state backend (Azure Storage) once the shared infra exists.
- Add a CI workflow `terraform plan` on PR and `terraform apply` on merge to `main`.
