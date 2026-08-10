# Terraform layout

This directory holds the Terraform IaC for the CRM Frontier Firm Showcase.
Design: [../../docs/adr/ADR-0003-terraform-as-iac-toolchain.md](../../docs/adr/ADR-0003-terraform-as-iac-toolchain.md).

## Files

| File | Purpose |
| --- | --- |
| `versions.tf` | Pinned provider constraints. |
| `providers.tf` | Provider configuration (uses `az login` locally, OIDC in CI). |
| `variables.tf` | Root inputs. |
| `main.tf` | Wires the modules. |
| `outputs.tf` | Useful outputs (env URLs, IDs). |
| `terraform.tfvars.example` | **Committed placeholder** values. |
| `terraform.tfvars` | **GIT-IGNORED** real values (create locally). |
| `modules/entra/` | Entra app registrations + federated credentials for CI. |
| `modules/github/` | GitHub Environments, deployment policies, variables, and branch protection. |
| `modules/powerplatform/` | Power Platform environments + tenant settings. |

## Bootstrap on the current tenant (ABSx demo)

The two showcase environments already exist and were renamed to the anonymised
`crmshowdev` / `crmshowtest` slot names. The GitHub repository also already has
live Environment objects. Start from a clean local state, import the existing
live objects, then inspect the first plan before any apply. `../../infra/scripts/bootstrap-import.ps1`
only imports the Power Platform environments; the GitHub reviewed-ref controls
stay explicit in the runbook below.

### Auth prerequisites

```powershell
# Azure / Power Platform provider auth
az login --tenant <TENANT_ID> --use-device-code --allow-no-subscriptions

# GitHub CLI session for operator checks
gh auth status

# GitHub provider auth for Terraform (do not paste tokens into files)
$env:GH_TOKEN = (gh auth token)
$env:GITHUB_TOKEN = $env:GH_TOKEN
```

Use a GitHub session or token that can administer this repository's
environments, deployment policies, and branch protection. Do not store it in
`terraform.tfvars`, shell profile files, or any committed artifact.

### Existing-tenant bootstrap sequence

```powershell
# 1. Copy the example to the git-ignored real tfvars
Copy-Item terraform.tfvars.example terraform.tfvars
# 2. Fill in real tenant_id, github_owner, environment id GUIDs, security_group_id
# 3. Initialise Terraform
terraform init
# 4. Import existing Power Platform envs (uses the id values from terraform.tfvars)
../../infra/scripts/bootstrap-import.ps1
# 5. Import existing GitHub Environments (import ID format: <repo>:<environment>)
terraform import 'module.github.github_repository_environment.envs["dev"]' 'CRMShowcase:dev'
terraform import 'module.github.github_repository_environment.envs["test"]' 'CRMShowcase:test'
# 6. Import the existing live DEV + TEST main deployment policies
#    (IDs captured from live evidence on 2026-08-10; re-check if either GitHub Environment is recreated)
terraform import 'module.github.github_repository_environment_deployment_policy.allowed_branches["dev:main"]' 'CRMShowcase:dev:56913774'
terraform import 'module.github.github_repository_environment_deployment_policy.allowed_branches["test:main"]' 'CRMShowcase:test:56680080'
# 7. Import the existing live main branch protection
terraform import 'module.github.github_branch_protection.main' 'CRMShowcase:main'
# 8. Review the plan carefully
terraform plan
# 9. Only if the plan shows exactly the intended changes:
terraform apply
# 10. Add the two CI service principals as Dataverse application users
#    (Terraform provider does not yet support this — see ADR-0005)
../../infra/scripts/add-ci-app-users.ps1 -Slot all
# 11. Reconcile required languages before importing multilingual solutions
../../infra/scripts/Set-DataverseLanguages.ps1 `
  -EnvironmentUrl https://crmshowdev.crm.dynamics.com `
  -LocaleId 1033,1031,1036,1040
# 12. Import solutions only after language reconciliation reports every LCID Active
../../scripts/solution/Import-Solution.ps1 -ZipFile <SOLUTION_ZIP>
```

Before `terraform apply`, confirm all of the following in the plan:

- `module.github.github_repository_environment.envs["test"]` retains reviewer
  user ID `46865858`; there must be **no reviewer removal**.
- `module.github.github_repository_environment.envs["test"]` keeps
  `prevent_self_review = false`.
- `module.github.github_repository_environment_deployment_policy.allowed_branches["dev:main"]`
  and `["test:main"]` both remain imported from live state. At time of
  evidence, the live policy IDs are `56913774` for `dev:main` and `56680080`
  for `test:main`; if either GitHub Environment is recreated, re-check the
  current live policy ID before re-importing Terraform state.
- `module.github.github_branch_protection.main` remains imported from live
  state and shows `required_linear_history = true`,
  `dismiss_stale_reviews = true`, `required_approving_review_count = 0`, and
  `contexts = ["gate1"]` with no unexpected replacement.

## Bootstrap on a fresh tenant

For "deploy to any tenant" reproducibility:

```powershell
# 1. Sign in to the new tenant
az login --tenant <NEW_TENANT_ID> --use-device-code --allow-no-subscriptions
# 2. Provide GitHub provider auth in the current shell
gh auth status
$env:GH_TOKEN = (gh auth token)
$env:GITHUB_TOKEN = $env:GH_TOKEN
# 3. Copy the example, set id = "" for each environment (so they get created)
Copy-Item terraform.tfvars.example terraform.tfvars
# 4. Fill in tenant_id, github_owner, github_repository, security_group_id
# 5. Initialise + apply
terraform init
terraform plan
terraform apply
```

On a fresh tenant, Terraform creates the Power Platform environments. The GitHub
module also creates the repository environments, `dev:main` and `test:main`
deployment policies, and the desired `main` branch protection rule unless those
objects already exist in the live repo. If the repo is not fresh, import the
existing GitHub objects first instead of applying over unmanaged state.

For both existing and fresh environments, deployment ordering is strict:
Dataverse application users first, language reconciliation second, and solution
import third. `Set-DataverseLanguages.ps1` uses `az rest` to acquire its access
token at runtime; no token or credential is stored in Terraform state or logs.
Removing an LCID from `required_languages` does not deactivate that language.
The reconciler only activates desired languages and never disables languages.

## Guardrails

- `terraform.tfvars` is `.gitignore`d — real values never enter Git.
- Providers use CLI-based auth by default (`az login` locally). In CI, the same
  providers use OIDC via workload identity federation per
  [ADR-0002](../../docs/adr/ADR-0002-oidc-federation-for-github-actions-to-entra.md).
- The GitHub provider also needs authenticated repo-admin access in the current
  shell (`GITHUB_TOKEN`; `GH_TOKEN` if you are using `gh` CLI helpers). Never
  write that token to disk.
- The Entra (`azuread`) and GitHub (`integrations/github`) resources in this
  directory are active, not scaffold-only. On any repo or tenant with existing
  live objects, import first and only then review the plan.
- `powerplatform_tenant_settings` is a singleton per tenant; managing it here means
  changes to tenant-wide settings become PR-reviewable and reversible.

## Known drift on the ABSx tenant

- The current environments are SKU `SubscriptionBasedTrial` (MCAPS auto-provisioned
  trial). Terraform's `powerplatform_environment` supports `Trial`, `Sandbox`,
  `Production`, `Developer`. The `env_type` in `terraform.tfvars.example` is
  `Sandbox` — a first `terraform plan` after import will show drift on
  `environment_type`. That drift is ignored by `lifecycle.ignore_changes` in
  `modules/powerplatform/main.tf`.
- Old URL aliases from before the rename will keep redirecting for a period after
  the domain change; that's Microsoft-managed DNS TTL and not something Terraform
  controls.
