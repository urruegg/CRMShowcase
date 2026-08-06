# ADR-0005 — Power Platform application users for CI service principals

| Field | Value |
| --- | --- |
| Status | Accepted |
| Date | 2026-08-06 |
| Deciders | Repo owner |
| Related | [ADR-0002](./ADR-0002-oidc-federation-for-github-actions-to-entra.md), [ADR-0003](./ADR-0003-terraform-as-iac-toolchain.md), [ADR-0004](./ADR-0004-ci-plane-app-registrations-and-github-environments.md), [../ENVIRONMENTS.md](../ENVIRONMENTS.md) |

## Context

[ADR-0004](./ADR-0004-ci-plane-app-registrations-and-github-environments.md)
provisioned two Entra service principals (`crm-showcase-ci-dev`,
`crm-showcase-ci-test`) that CI signs in as via OIDC federation. That gives them
an Entra identity in the demo tenant — but Dataverse recognises identities via
its own `systemusers` table (specifically for services, records with a populated
`applicationid` field, known as "application users"). Without a `systemuser`
record and a security role, an SP can authenticate but cannot read or write
anything in Dataverse.

This ADR records how the two CI service principals are added as **application
users** in their matching environment.

## What we tried and why it didn't work

- **`powerplatform_user` resource** in the `microsoft/power-platform` Terraform
  provider (v3.9.1). Applying it against the two SPs returns
  `HTTP 404 MissingUserDetails: "The user details for tenant id '...' and
  principal id '...' doesn't exist"`. The resource treats the SP as an
  already-existing user and fails to create one. There is currently no other
  provider resource in v3.9.1 that provisions a service-principal application
  user with a security role.

## Decision

Provision the application users via a small, committed, idempotent PowerShell
script that calls the Dataverse Web API directly:
[`../../infra/scripts/add-ci-app-users.ps1`](../../infra/scripts/add-ci-app-users.ps1).

For each `(env, SP, role name)` triple the script:

1. Looks up the SP's Entra app ID and object ID via `az ad sp list`.
2. Queries `GET /api/data/v9.2/systemusers?$filter=applicationid eq <appId>`.
   - If a `systemuser` record with that `applicationid` already exists, reuse it.
   - Otherwise `POST /api/data/v9.2/systemusers` with `applicationid`,
     `azureactivedirectoryobjectid`, and the root business-unit binding.
3. Queries `GET /api/data/v9.2/roles?$filter=name eq '<roleName>'` to resolve
   the role's per-env GUID.
4. Queries the user's current role associations. If the target role is not
   already assigned, `POST /systemusers(<userId>)/systemuserroles_association/$ref`.

### Assigned roles

| Slot | SP | Security role | Rationale |
| --- | --- | --- | --- |
| `dev`  | `crm-showcase-ci-dev`  | **System Customizer**   | Least-privilege for a build target — can create/modify solutions, tables, forms, workflows, but cannot manage users. |
| `test` | `crm-showcase-ci-test` | **System Administrator** | Managed-solution import into a downstream env typically requires SA. Kept scoped to the `crmshowtest` env only via the separate app registration. |

### Not covered by this ADR

- **Tenant-scope admin access.** The CI SPs are *not* registered as
  [`powerplatform_admin_management_application`](https://registry.terraform.io/providers/microsoft/power-platform/latest/docs/resources/admin_management_application).
  They can act inside their env only. Tenant-wide changes (e.g.
  `powerplatform_tenant_settings`) stay a human-admin operation for now.
- **DLP policy assignment.** Follow-up.

## Why the script and not Terraform

- **Correct semantics today.** The provider resource is not usable for this case.
- **Small and inspectable.** ~120 lines, calls documented Dataverse Web API.
- **Idempotent.** Safe to re-run.
- **Committed and reviewable.** Same PR gate as any other change.
- **Portable to any tenant.** The script takes no per-tenant constants; it
  resolves everything (SP IDs, role IDs, business unit IDs) at runtime.

**Follow-up:** revisit when the `microsoft/power-platform` provider adds a
first-class resource for service-principal application users. At that point,
migrate to the Terraform resource and delete the script.

## Consequences

**Positive**
- CI SPs can now read/write Dataverse in their matching env with a specific
  security role.
- `terraform apply` in CI (once remote state exists) can deploy solutions.
- The role assignment is auditable in Dataverse via the `systemuser` +
  `systemuserroles_association` tables.

**Negative / cost**
- Two provisioning tools now (`terraform apply` + `add-ci-app-users.ps1`) for
  the CI identity plane. Documented in
  [../../infra/terraform/README.md](../../infra/terraform/README.md).
- The script must be re-run when a new environment slot is added or a role changes.
- If someone deletes the systemuser record in Dataverse, Terraform won't know —
  we'd need a `terraform plan` to notice drift (it wouldn't; Terraform doesn't
  track this).

## Applied to the ABSx demo tenant on 2026-08-06

- `crmshowdev`  → app user `# crm-showcase-ci-dev`  (systemuserid `279b6318-8f91-...`)  role `System Customizer`.
- `crmshowtest` → app user `# crm-showcase-ci-test` (systemuserid `b80234c6-8f91-...`) role `System Administrator`.

Verified via `GET /api/data/v9.2/roles(<role-id>)/systemuserroles_association?$filter=systemuserid eq <user-id>` — both users appear in their respective role's user list.
