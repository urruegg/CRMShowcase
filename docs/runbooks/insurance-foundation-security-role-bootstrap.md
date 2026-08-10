# Insurance Foundation security-role bootstrap

| Field | Value |
| --- | --- |
| **Status** | Approved administrator runbook |
| **Date** | 2026-08-09 |
| **Maturity** | Demo-only DEV bootstrap prerequisite; not automated; TEST delivery is not part of this runbook |
| **Licence** | 🧩 configuration / own build; authorized Power Platform administrator entitlements are required |
| **Related** | [ADR-0023](../adr/ADR-0023-demo-feasible-dataverse-bootstrap.md) · [Demo-Feasible Dataverse Authoring and Bootstrap](../superpowers/specs/2026-08-09-demo-feasible-dataverse-authoring-design.md) · [Sprint 3 Insurance Foundation](../superpowers/specs/2026-08-08-insurance-foundation-design.md) |

## Purpose

Create the two reviewed DEV roles once without granting GitHub CI permanent
security-role administration. Normal CI remains the reviewed `System
Customizer` application user.

## Preconditions

- Authorized Power Platform administrator.
- DEV only: `https://crmshowdev.crm.dynamics.com`.
- Reviewed contract: `solution/schema/insurance-foundation.json`.
- If you run the publisher from Windows PowerShell 5.1 instead of PowerShell 7,
  local `python` and the `jsonschema` package are already present, and both
  `python --version` and `python -c "import jsonschema"` succeed. PowerShell 7
  uses `Test-Json` and does not require this fallback.
- Approved delivery tracking: issue [#40](https://github.com/urruegg/CRMShowcase/issues/40).
- No credentials or access tokens are copied into GitHub, the repository, or
  workflow inputs.

## Permitted changes

This bootstrap may change only:

- `CRM Showcase Insurance Reader`;
- `CRM Showcase Insurance Data Steward`;
- localized English (`1033`), German (`1031`), French (`1036`), and Italian
  (`1040`) role labels and descriptions;
- only the privileges declared by the reviewed contract.

If the local confirmation text or resulting structural verifier output implies
any other change, stop and escalate under administrator review.

## Procedure

1. Sign in interactively as the authorized administrator in a local shell:

   ```powershell
   az login --tenant b829e4ef-1a9f-45ba-80e5-48408aa421a9 --allow-no-subscriptions
   ```

2. If you are running Windows PowerShell 5.1, verify the local JSON Schema
   fallback prerequisite first. If either command fails, stop and correct the
   local prerequisite before continuing. Do not install packages automatically
   as part of this run.

   ```powershell
   python --version
   python -c "import jsonschema"
   ```

   If you are running PowerShell 7, skip this step because `Test-Json` handles
   the schema validation path.

3. Run the reviewed publisher locally with the explicit privileged scope:

   ```powershell
   .\scripts\solution\Publish-InsuranceFoundation.ps1 `
     -EnvironmentUrl 'https://crmshowdev.crm.dynamics.com' `
     -ContractPath '.\solution\schema\insurance-foundation.json' `
     -Scope SecurityRoles `
     -Confirm
   ```

4. Review every `ShouldProcess` confirmation before accepting it. The run is
   bounded to the permitted changes listed above.

5. Run the GET-only, read-only verifier:

   ```powershell
   .\scripts\solution\Test-InsuranceSecurityRoles.ps1 `
     -EnvironmentUrl 'https://crmshowdev.crm.dynamics.com' `
     -ContractPath '.\solution\schema\insurance-foundation.json'
   ```

6. Confirm the verifier reports:
   - overall `State` = `Ready`;
   - one `Ready` result for each reviewed role;
   - `MutationOccurred` = `false`.
   Use the verifier only as evidence of:
   - exact case-sensitive root role identity/name;
   - solution membership;
   - exact declared privileges and Dataverse depth;
   - no mutation during verification.

7. For localized English (`1033`), German (`1031`), French (`1036`), and
   Italian (`1040`) role labels/descriptions, capture the reviewed
   `ShouldProcess`/publisher output from step 3 and inspect the role
   translations in Power Platform before attaching evidence. This is a manual
   evidence item because the current GET-only verifier does not retrieve
   localized role labels/descriptions.

8. Attach the verifier JSON output and the manual localization evidence to
   issue #40, then trigger **Author insurance foundation in DEV**.

## Failure and rollback

- Stop immediately if verification reports an exact-name mismatch, unexpected
  privileges, wrong solution ownership, duplicate root roles, unsupported
  depth, or any other `ContractConflict`.
- Stop immediately if the manual Power Platform review shows incorrect
  EN/DE/FR/IT role labels or descriptions.
- Do **not** delete either role.
- Do **not** elevate normal GitHub CI beyond the approved `System Customizer`
  role.
- Correct the role identity, solution membership, privilege assignment, or
  localized translation locally under administrator review, rerun the
  read-only verifier for structural evidence, repeat the manual localization
  review, and add the updated evidence to issue #40.

## Evidence and sign-out

- Keep the local terminal transcript, reviewed `ShouldProcess`/publisher
  output, Power Platform translation review screenshots/notes, and pasted
  verifier JSON as administrator evidence for issue #40.
- Localized label/description evidence remains manual because the current
  GET-only verifier does not retrieve localized role labels/descriptions.
- After the verified DEV bootstrap is complete, sign out locally:

  ```powershell
  az logout
  ```

This runbook does not automate the bootstrap and does not claim TEST delivery.
