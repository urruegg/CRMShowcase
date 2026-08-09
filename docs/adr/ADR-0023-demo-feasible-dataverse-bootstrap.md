# ADR-0023 - Demo-feasible Dataverse bootstrap and steady-state identities

| Field | Value |
| --- | --- |
| **Status** | Proposed hypothesis |
| **Date** | 2026-08-09 |
| **Decision mode** | Working hypothesis |
| **Confidence** | High for the demo boundary; medium for automated target bootstrap |
| **Deciders** | Enterprise Architect, SecDevOps, repo owner |
| **Topic area** | A8 - lifecycle, deployment, and rollback |
| **Use case** | Sprint 3 Insurance Foundation |
| **Licence** | Configuration / own build; environment entitlements require validation |
| **Upgrade impact** | Medium - separates bootstrap from normal deployment |
| **CAF methodology** | Ready, Adopt, Govern, Secure, Manage |
| **WAF pillar(s)** | Security and Operational Excellence; Reliability improved by preflight |
| **Zero Trust** | Verify explicitly, use least privilege, assume breach |
| **Responsible AI** | Not AI-relevant |

## Context

The DEV OIDC application user has System Customizer and can author the reviewed
schema, but Dataverse rejects security-role creation because it lacks
prvCreateRole.
[Run 31302762752](https://github.com/urruegg/CRMShowcase/actions/runs/31302762752/job/93218095999)
proved that choices, extensions, tables, relationships, keys, views, forms,
and multilingual metadata are feasible before that boundary.

## Options

### Option A - Permanently elevate normal CI

Rejected. A one-time bootstrap capability must not become a permanent
steady-state privilege.

### Option B - Remove custom roles

Rejected as the normal path. It produces an incomplete Foundation solution.

### Option C - Manual demo prerequisite plus separate target bootstrap

Preferred. An authorized administrator creates the reviewed roles once. Normal
CI verifies them and performs only demo-safe schema reconciliation and export.
A dedicated automated bootstrap identity remains a target-state hypothesis.

## Working hypothesis

Use the existing System Customizer application user for steady-state DEV
authoring. Exclude role mutation from normal CI. Treat role existence as a
read-only preflight prerequisite. Revisit automated bootstrap only when tenant
capabilities support a separately approved and auditable privileged identity.

## Evidence and assumptions

- **Known:** System Customizer lacks prvCreateRole in this tenant.
- **Known:** normal CI can reconcile the reviewed schema metadata.
- **Inferred:** imported source-controlled solutions can become the steady-state
  path after the first successful export.
- **Evidence still required:** administrator-created roles export correctly and
  a second CI run succeeds without role mutation.

## Validation and review triggers

Reopen when the Power Platform provider supports application-user role
assignment, a supported bootstrap API becomes available, or managed TEST
promotion requires a different permission model.

## Consequences

- **At the next release:** import reviewed solution packages; do not reconstruct
  released metadata with live authoring.
- **Operationally:** first environment setup has an administrator prerequisite.
- **For customer teams:** bootstrap and deployment identities have separate
  accountability.
- **Reversibility:** automated bootstrap can replace the runbook without
  changing the schema contract.
