# Environments — CRM Frontier Firm Showcase

| Field | Value |
| --- | --- |
| Version | 0.2 (Draft) |
| Status | Draft |
| Classification | Public — anonymised demo |

> **This file is public and anonymised.** Real tenant IDs, environment URLs, GUIDs,
> and account names are never committed. See
> [.env.example](../.env.example) for the shape and
> [adr/ADR-0002-oidc-federation-for-github-actions-to-entra.md](./adr/ADR-0002-oidc-federation-for-github-actions-to-entra.md)
> for the auth pattern.

## 1. Where real values live

| Kind of value | Where it lives | Why |
| --- | --- | --- |
| Tenant / environment identifiers | Developer's local `.env.local` and `infra/terraform/terraform.tfvars` (both git-ignored) | Not secrets, but identifying — kept off a public repo |
| Service-principal / workload-identity IDs | GitHub Actions **environment secrets & variables** | Rotatable, scoped, auditable |
| Any actual credential | **Azure Key Vault** in the demo tenant | Single source of truth, rotation, RBAC |
| Human sign-in for local dev | Interactive `az login` / Power Platform CLI | No stored password anywhere |

## 2. Environment slots

The showcase uses two Power Platform environments. Slot names below are the anonymised
identifiers used throughout the repo. Real branded names (if any) live only in
local `.env.local` and in the tenant admin console — never in Git.

### `crmshowdev` (slot `DEV`) — **live**
- **Purpose.** Developer environment. Dynamics 365 Foundation + custom solution
  (**unmanaged**). Used for build and unit-level demo.
- **Data classification.** Synthetic only.
- **URL.** `https://crmshowdev.crm.dynamics.com/` — verified `HTTP 200` on 2026-08-06.
- **Display name.** *CRM Showcase - DEV*.
- **Placeholders in `.env.example`.** `${DEV_ENV_URL}`, `${DEV_ENV_ID}`, `${DEV_ORG_ID}`.
- **Access model.** Least-privilege service principal for CI (see
  [adr/ADR-0002-oidc-federation-for-github-actions-to-entra.md](./adr/ADR-0002-oidc-federation-for-github-actions-to-entra.md)).
  Interactive human sign-in for local dev.
- **Languages.** English (`1033`) is the base language. German (`1031`), French
  (`1036`), and Italian (`1040`) must be enabled before Sprint 3 metadata is
  deployed ([ADR-0021](./adr/ADR-0021-multilingual-semantic-dataverse-metadata.md)).

### `crmshowtest` (slot `TEST`) — **live**
- **Purpose.** Integration testing and demo environment. All **managed** solutions,
  including the custom solution promoted from `crmshowdev`.
- **Data classification.** Synthetic only.
- **URL.** `https://crmshowtest.crm.dynamics.com/` — verified `HTTP 200` on 2026-08-06.
- **Display name.** *CRM Showcase - TEST*.
- **Placeholders in `.env.example`.** `${TEST_ENV_URL}`, `${TEST_ENV_ID}`, `${TEST_ORG_ID}`.
- **Access model.** As `crmshowdev`. A separate app registration
  (`crm-showcase-ci-test`) so a compromise of `crmshowdev` does not reach `crmshowtest`.
- **Languages.** The enabled-language set must match DEV: EN base plus DE, FR
  and IT. Promotion smoke tests verify the language set before managed imports.

## 3. Rules

1. **Never commit real values** for any of the placeholders above. Not in code, not in
   fixtures, not in workflow files, not in ADRs. Real values live in
   [.env.local](../.env.example) locally or in GitHub Actions environment secrets/variables.
2. **Never store an admin UPN or password in the repo.** GitHub Actions authenticate to
   Entra via **workload identity federation (OIDC)** —
   see [ADR-0002](./adr/ADR-0002-oidc-federation-for-github-actions-to-entra.md).
3. **Least privilege per environment.** One app registration per environment slot,
   with only the roles required for what CI actually does in that slot.
4. **No cross-tenant paths.** These environments live in the demo tenant only. No
   network path, no shared identity, no shared data plane with any other tenant.
5. **Synthetic data only.** Every row in `DEV` and `TEST` must be synthetic. Never
   copy real customer data into either environment
   (see [DATA.md](./DATA.md) §1, [SECURITY.md](./SECURITY.md) §1).

## 4. When a story needs new environment access

- Open an ADR (or update ADR-0002) if the change adds a new app registration,
  a new API permission, or a new environment slot.
- Add the placeholder(s) to [.env.example](../.env.example) — shape only.
- Add the real value(s) to your local `.env.local` and to the matching GitHub
  Actions environment.
- Never send the real values through a PR review comment, an issue, or a chat log.

## 5. Escalation

If you ever find a real tenant ID, environment URL, GUID, UPN, or credential in a
commit or PR:

1. **Rotate** the affected credential (or, for identifiers, decide whether the value
   is materially sensitive — Global Admin UPNs are).
2. **Rewrite history** with `git filter-repo` or GitHub's push-protection unblock flow.
3. **Open a `governance-escalation` issue** citing this file.
