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
| `modules/powerplatform/` | Power Platform environments + tenant settings. |

## Bootstrap on the current tenant (ABSx demo)

The two showcase environments already exist and were renamed to the anonymised
`crmshowdev` / `crmshowtest` slot names. To bring them under Terraform management
without recreating them:

```powershell
# 1. Copy the example to the git-ignored real tfvars
Copy-Item terraform.tfvars.example terraform.tfvars
# 2. Fill in real tenant_id, github_owner, environment id GUIDs, security_group_id
# 3. Sign in to the demo tenant if not already
az login --tenant <TENANT_ID> --use-device-code --allow-no-subscriptions
# 4. Initialise Terraform
terraform init
# 5. Import existing envs (uses the id values from terraform.tfvars)
../../infra/scripts/bootstrap-import.ps1
# 6. Review the plan carefully
terraform plan
# 7. Only if the plan shows exactly the intended changes:
terraform apply
# 8. Add the two CI service principals as Dataverse application users
#    (Terraform provider does not yet support this — see ADR-0005)
../../infra/scripts/add-ci-app-users.ps1 -Slot all
```

## Bootstrap on a fresh tenant

For "deploy to any tenant" reproducibility:

```powershell
# 1. Sign in to the new tenant
az login --tenant <NEW_TENANT_ID> --use-device-code --allow-no-subscriptions
# 2. Copy the example, set id = "" for each environment (so they get created)
Copy-Item terraform.tfvars.example terraform.tfvars
# 3. Fill in tenant_id, github_owner, github_repository, security_group_id
# 4. Initialise + apply
terraform init
terraform plan
terraform apply
```

## Guardrails

- `terraform.tfvars` is `.gitignore`d — real values never enter Git.
- Providers use CLI-based auth by default (`az login` locally). In CI, the same
  providers use OIDC via workload identity federation per
  [ADR-0002](../../docs/adr/ADR-0002-oidc-federation-for-github-actions-to-entra.md).
- The Entra (`azuread`) and GitHub (`integrations/github`) provider blocks are wired
  in `providers.tf` but their resources are **not scaffolded yet** — coming in the
  next milestone (Entra app registrations + federated credentials).
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
