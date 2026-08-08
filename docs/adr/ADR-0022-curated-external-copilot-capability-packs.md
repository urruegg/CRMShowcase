# ADR-0022 — Curated external Copilot capability packs

| Field | Value |
| --- | --- |
| **Status** | Accepted |
| **Date** | 2026-08-08 |
| **Decision mode** | Committed decision |
| **Confidence** | High — imported artefacts are pinned, scoped and acceptance-tested |
| **Deciders** | Enterprise Architect, SecDevOps, Developer, Integration Engineer, Responsible-AI Officer |
| **Topic area** | A4 — Extensibility · A6 — AI · A8 — ALM |
| **Use case** | US-801 |
| **Licence** | 🧩 own build using MIT-licensed upstream guidance |
| **Upgrade impact** | Low — prompt/instruction updates require an explicit upstream review and PR |
| **CAF methodology** | Ready · Adopt · Govern · Secure · Manage |
| **WAF pillar(s)** | Security · Operational Excellence · Reliability |
| **Zero Trust** | External instructions cannot weaken OIDC, least privilege, tenant isolation or secret handling. |
| **Responsible AI** | Transparency and accountability — provenance, scope and decision authority remain explicit. |

## Context

The showcase needs practical guidance for Power Platform custom connectors,
MCP integration, PCF ALM, Code Apps, workflow documentation and security
review. The public `github/awesome-copilot` catalogue contains useful agents
and skills, but adopting the catalogue wholesale would introduce duplicated
roles, unavailable paid MCP dependencies, stale product assumptions and
guidance that is not aware of CRMShowcase governance.

## Options

### Option A — Install every Power Platform artefact

**Rejected.** This would add overlapping architecture agents, FlowStudio
skills that require an unconfigured paid MCP service, Python Dataverse
guidance outside the selected stack, and connector-generation skills without
an active story.

### Option B — Do not import external capabilities

**Rejected.** Existing agents intentionally stay concise and do not contain
specialist GitHub Actions threat modelling, PCF lifecycle guidance, or the
complete Power Platform MCP connector surface.

### Option C — Curate, pin and constrain selected capabilities ✅ chosen

Import only capabilities that fill a verified gap. Pin every file to an
immutable upstream commit, retain the upstream MIT notice in
[`THIRD-PARTY-NOTICES.md`](../../THIRD-PARTY-NOTICES.md), add CRMShowcase
guardrails, test the representative discovery scenarios in
[`US-801-capability-pack-acceptance.md`](../testing/US-801-capability-pack-acceptance.md),
and keep decision authority with the existing `AG-E-##` owners.

## Decision

Adopt these pinned capability packs from
`github/awesome-copilot@ab7544d03d4c49fdd07f5958e1888ad39c4118e2`:

- conditional `Power Platform MCP Integration Expert`;
- `github-actions-hardening`;
- `security-review`;
- `create-github-action-workflow-specification`;
- `power-apps-code-app-scaffold`, corrected to current Code Apps guidance;
- PCF ALM and PCF best-practice path-scoped instructions.

The imported MCP specialist has no independent architecture or RAI authority.
It is invoked only for a story that changes a custom connector, MCP server or
Copilot Studio MCP integration, with AG-E-03, AG-E-04, AG-E-06 and AG-E-09
review.

Do not install FlowStudio skills until its paid MCP service is approved and
configured. Do not install generic Power Platform architecture or Python
Dataverse skills because existing agents and the selected stack supersede
them. Connector-suite and Copilot Studio MCP generator skills remain
on-demand until a concrete story needs them.

## Consequences

**Positive**

- Power Platform and pipeline implementation guidance is locally discoverable.
- Security reviews gain Actions-specific and cross-file threat models.
- External prompt provenance and upgrade review are explicit.

**Trade-offs**

- Imported guidance must be reviewed when Microsoft product status changes.
- The repository carries additional prompt/reference files.
- A capability being installed does not prove that its external service or
  licensed product feature is available.

## Validation and review triggers

- Re-run the documented
  [US-801 scenario-based acceptance tests](../testing/US-801-capability-pack-acceptance.md)
  after changing imported instructions.
- Review upstream changes before updating the pinned commit.
- Revisit this ADR when a paid MCP service, custom MCP connector, or Python
  Dataverse implementation becomes an approved story.
