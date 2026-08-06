# Infrastructure as Code

The showcase's tenant, environment, identity, and GitHub configuration is captured
as Terraform. Design: [../docs/adr/ADR-0003-terraform-as-iac-toolchain.md](../docs/adr/ADR-0003-terraform-as-iac-toolchain.md).
Environment slot definitions: [../docs/ENVIRONMENTS.md](../docs/ENVIRONMENTS.md).

## Layout (target)

```
infra/
└── terraform/
    ├── versions.tf              # required providers, pinned
    ├── providers.tf             # provider configuration (OIDC in CI)
    ├── variables.tf             # inputs (tenant, env slots, github repo)
    ├── outputs.tf               # useful outputs
    ├── main.tf                  # module wiring
    ├── terraform.tfvars.example # placeholder values (committed)
    ├── terraform.tfvars         # real values (GIT-IGNORED)
    └── modules/
        ├── powerplatform/       # environments, DLP, env settings
        ├── entra/               # app registrations + federated credentials
        ├── github/              # GitHub Environments + secrets/variables
        └── azure/               # Key Vault, App Insights (added as needed)
```

## Status

- **Layout:** planned, folder exists as a placeholder.
- **Terraform files:** to be scaffolded in the next milestone step, once the current
  tenant state has been read and the environments have been renamed to
  `crmshowdev` / `crmshowtest`.

## How to run (once files land)

```powershell
cd infra/terraform
Copy-Item terraform.tfvars.example terraform.tfvars   # fill in real values locally
terraform init
terraform plan
# Then, once reviewed:
terraform apply
```

## Guardrails

- `terraform.tfvars` is **git-ignored** (see the repo `.gitignore`). Real tenant IDs,
  environment IDs, and GitHub repo identifiers live only in that file locally.
- Terraform authenticates via **workload identity federation (OIDC)** in CI, per
  [ADR-0002](../docs/adr/ADR-0002-oidc-federation-for-github-actions-to-entra.md).
- Locally, Terraform uses your `az login` session. No credentials in `terraform.tfvars`.
- Any change to app registrations, Power Platform environment settings, or GitHub
  Environments goes through a PR with a `terraform plan` output attached.
