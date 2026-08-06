# Security — Identity, Secrets, Network Posture

| Field | Value |
| --- | --- |
| Version | 0.1 (Draft) |
| Status | Draft |

> **Template.** Fill in concrete configuration as it lands. This file is what the
> SecDevOps agent ([.github/agents/secdevops.agent.md](../.github/agents/secdevops.agent.md))
> reasons over.

## 1. Non-negotiables
- **No secrets in code.** Use Entra ID + Managed Identity. Any stored secret lives in
  Azure Key Vault and is justified in a PR.
- **OIDC-federated deploys** — no long-lived cloud credentials in GitHub.
- **Tenant isolation** — demo tenant only. No path into a customer's production tenant.
- **Secret scanning + push protection** must stay enabled.
- **CodeQL** on every PR.

## 2. Identity
- All service-to-service auth uses Managed Identity.
- All user-facing endpoints are behind Entra ID.
- No shared service accounts.

## 3. Secrets
- Storage: Azure Key Vault.
- Rotation: automatic where the resource supports it.
- Access: least-privilege via role assignments, audited.

## 4. Network
- Public endpoints only where required for the demo experience.
- No inbound path from the internet to CRM data plane except via authenticated,
  rate-limited APIs.
- No path from the demo tenant to any customer production tenant.

## 5. Threat model (starter)
- **Prompt injection** — mitigated by grounding + deterministic action layer + refusal patterns.
- **Data exfiltration via agent tools** — mitigated by tool allow-list + audit log.
- **Secret leakage** — mitigated by secret scanning, push protection, Key Vault, and code review.
- **Impersonation** — mitigated by Entra ID + Managed Identity, no shared accounts.

## 6. Incident response
For a public showcase, incident response is limited to: revoke tokens, rotate secrets,
document root cause, add a regression test. Escalation for a real production system is
out of scope.
