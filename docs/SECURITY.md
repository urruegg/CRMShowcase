# Security

| Field | Value |
| --- | --- |
| Status | **Draft 0.3** · **Owner** `AG-E-04` SecDevOps |

## Framing — Zero Trust

Every rule below sits inside Microsoft's **Zero Trust** stance:
*never trust, always verify*. The three principles from the
[Zero Trust overview](https://learn.microsoft.com/security/zero-trust/zero-trust-overview)
— **verify explicitly · use least privilege · assume breach** — map to
concrete artefacts. See
[MICROSOFT-FRAMEWORKS.md §Zero Trust](./MICROSOFT-FRAMEWORKS.md#zero-trust)
for the full mapping.

The Security posture also satisfies the **Security pillar** of the
[Well-Architected Framework](https://learn.microsoft.com/azure/well-architected/pillars)
and the **Secure** methodology of the
[Cloud Adoption Framework](https://learn.microsoft.com/azure/cloud-adoption-framework/overview).

## Standing rules already in force

- **No secrets in code.** Entra ID + Managed Identity; any stored secret in Key
  Vault. Secret scanning and push protection stay green.
- **OIDC-federated deployment** ([ADR-0002](./adr/ADR-0002-oidc-federation-for-github-actions-to-entra.md)) — no long-lived cloud credentials.
- **No Global Admin service accounts.** Global Admin is human-only and MFA-enforced.
- **No tenant identifiers in Git.** Real tenant IDs, environment URLs, GUIDs, and
  UPNs live only in developer-local `.env.local` files and in GitHub Actions
  environment secrets/variables ([ENVIRONMENTS.md](./ENVIRONMENTS.md)).
- **Tenant isolation** — demo tenant only. No path into a customer production
  tenant.
- **CodeQL and Dependabot** on the supply chain.
- **A gate an agent can disable is not a gate.**

## Identity

- All service-to-service auth uses **Entra ID workload identity federation** (OIDC)
  or Managed Identity, per [ADR-0002](./adr/ADR-0002-oidc-federation-for-github-actions-to-entra.md).
- All user-facing endpoints are behind Entra ID.
- **One app registration per environment slot** (`dev`, `test`), least-privilege
  roles only, per [ADR-0004](./adr/ADR-0004-ci-plane-app-registrations-and-github-environments.md).
- CI service principals are added as Dataverse application users per
  [ADR-0005](./adr/ADR-0005-power-platform-application-users-for-ci.md).
- No shared service accounts across environments.

## Secrets

- Storage: Azure Key Vault.
- Rotation: automatic where the resource supports it.
- Access: least-privilege via role assignments, audited.

## Network

- Public endpoints only where required for the demo experience.
- No inbound path from the internet to CRM data plane except via authenticated,
  rate-limited APIs.
- No path from the demo tenant to any customer production tenant.

## Threat model (starter)

- **Prompt injection** — mitigated by grounding + deterministic action layer +
  refusal patterns.
- **Data exfiltration via agent tools** — mitigated by tool allow-list + audit log.
- **Secret leakage** — mitigated by secret scanning, push protection, Key Vault,
  and code review.
- **Impersonation** — mitigated by Entra ID + Managed Identity, no shared accounts.

## To complete

| Area | Status |
| --- | --- |
| Identity & access model (incl. GA scoping) | `[TBD]` |
| Data classification | `[TBD]` |
| Threat model — full pass | `[TBD]` |
| Logging, monitoring, incident response | `[TBD]` |
| Role-based exposure of the 360° view (A2) | `[TBD]` |
