# ADR-0029 — Platform-managed baseline privileges are out of reviewed-role contract scope

| Field | Value |
| --- | --- |
| **Status** | Accepted |
| **Date** | 2026-08-12 |
| **Decision mode** | Committed decision |
| **Confidence** | High — verified against the live DEV org; repo owner approved |
| **Deciders** | Business owner / repo owner (human) · Enterprise Architect (AG-E-03) · SecDevOps (AG-E-04) · Responsible-AI Officer (AG-E-06) |
| **Topic area** | A5 — Security · RBAC / reviewed security roles |
| **Licence** | 🧩 configuration (Dataverse security roles + CI verifier) |
| **Upgrade impact** | None — verifier comparison logic only; no schema or app surface change |
| **CAF methodology** | Secure · Govern |
| **WAF pillar(s)** | Primary: Security (keeps reviewed roles least-privileged on everything we control). Trade-off: absolute-exactness vs. platform reality — bounded to an inert, platform-managed baseline. |
| **Zero Trust** | Least-privilege preserved: the contract still governs every CRM privilege + denied verb; only an inert, non-removable platform baseline is excluded from the exact-match check. |
| **Responsible AI** | Accountability — the reviewed-role contract remains the source of truth for all governed privileges; the exclusion is explicit, named, and pattern-scoped. |

## Context

The reviewed Insurance Foundation security roles (`CRM Showcase Insurance
Reader` / `Data Steward`) are authored from the contract and verified with an
**exact privilege-set** check ([`Test-InsuranceSecurityRoles.ps1`](../../scripts/solution/Test-InsuranceSecurityRoles.ps1)):
any privilege on the role that is not in the contract is a `ContractConflict`.

When the bootstrap finally ran end-to-end (after ADR‑#40 root-role detection and
the role-localization fix), the verifier reported `ContractConflict` on **four
privileges nobody put in the contract**:

- `prvReadSharePointDocument`, `prvReadSharePointData`, `prvWriteSharePointData`, `prvCreateSharePointData`

Verified against the live DEV org (read-only):

- **Server-Based SharePoint Integration is OFF** — `sharepointdeploymenttype = 0`
  (None), **0** SharePoint sites. There is nothing to disable.
- Dataverse **auto-grants these privileges to every newly created security role**
  as a protected baseline. They are present on both the pre-existing Reader
  (9 privileges = 5 contract + 4 baseline) and the freshly created Data Steward
  (21 = 17 contract + 4 baseline).
- They **survive `ReplacePrivilegesRole`** — the publisher already tries to set
  the exact set, and they come back. The publisher cannot remove them.
- They are **inert** here: no sites, integration off → nothing to read or write.

So the roles are correct for everything we govern; the exact-match rule fails
only on a platform baseline outside our control.

## Options

### Option A — Allowlist the platform baseline in the verifier ✅ preferred
Exclude platform-managed baseline privileges (matched by pattern, e.g.
`*SharePoint*`) from the verifier's "unexpected" comparison. The contract still
fully governs every CRM privilege, depth, and denied verb.

### Option B — Enumerate the baseline privileges in the contract per role
Rejected: brittle and org-specific — the baseline set varies by which platform
features are provisioned, so the contract would drift per environment.

### Option C — Disable Server-Based SharePoint Integration in DEV
Not actionable: it is already off (`sharepointdeploymenttype = 0`, 0 sites), yet
the privileges are still granted. Nothing to disable.

## Decision

Adopt **Option A**. The reviewed-role contract governs the CRM privilege set and
denied verbs; **platform-managed baseline privileges** (currently the SharePoint
document-management set, matched by the `SharePoint` name pattern) are treated as
out of contract scope and excluded from the exact-match "unexpected" check in
[`Test-InsuranceSecurityRoles.ps1`](../../scripts/solution/Test-InsuranceSecurityRoles.ps1)
(`Test-InsuranceRoleBaselinePrivilege`). `Missing`, `WrongDepth`, denied-verb,
and duplicate checks are unchanged — least-privilege on everything we control is
preserved.

## Consequences

- The bootstrap verifier converges to `Ready`, unblocking DEV/TEST evidence.
- If a future org grants a different platform baseline, extend the pattern in
  `Test-InsuranceRoleBaselinePrivilege` (single, named location) — do not add
  baselines to the contract.
- Should real SharePoint integration ever be in scope, revisit this ADR: the
  SharePoint privileges would then be governed intentionally, not inert.
