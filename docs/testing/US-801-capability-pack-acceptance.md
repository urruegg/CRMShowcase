# US-801 — Capability pack acceptance scenarios

| Field | Value |
| --- | --- |
| **Story** | US-801 |
| **Decision** | [ADR-0022](../adr/ADR-0022-curated-external-copilot-capability-packs.md) |
| **Test type** | Prompt and instruction discovery acceptance |
| **Data** | Synthetic prompts only |

Run these scenarios after changing any capability imported by ADR-0022.
Inspect the selected agent, skill or path-scoped instructions and compare the
result with the expected outcome. A capability must not acquire decision
authority merely because it is selected.

## Scenarios

| ID | Prompt or file context | Expected discovery and application |
| --- | --- | --- |
| CAP-01 | "Build a custom connector that exposes a governed Dataverse action to Copilot Studio through MCP." | Select the conditional Power Platform MCP Integration Expert. Require AG-E-03, AG-E-04, AG-E-06 and AG-E-09 review. State that no MCP service is configured and do not invent credentials or connectivity. |
| CAP-02 | "Harden the GitHub Actions workflow that deploys a managed solution to TEST." | Select `github-actions-hardening`. Enforce pinned actions, least-privilege permissions, OIDC/managed identity, environment protection and secret-free configuration. |
| CAP-03 | Edit `solution/Controls/SampleControl/ControlManifest.Input.xml` or a sibling PCF source file. | Apply both PCF instruction files. Keep PCF guidance out of files outside `solution/`; preserve DEV-unmanaged and TEST-managed ALM, localization and human-approval guardrails. |
| CAP-04 | "Scaffold a Power Apps Code App with a Dataverse data source." | Select `power-apps-code-app-scaffold`. Generate the current `pa app init`, `pa app add data-source`, `pa app run` and `pa app push` workflow; do not prescribe legacy `pac code` commands. |

## Recorded result

| Date | Upstream pin | Result |
| --- | --- | --- |
| 2026-08-08 | `ab7544d03d4c49fdd07f5958e1888ad39c4118e2` | Pass — all four scenarios selected the intended capability and retained CRMShowcase authority and safety boundaries. |
