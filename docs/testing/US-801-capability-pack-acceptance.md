# US-801 — Capability pack acceptance scenarios

| Field | Value |
| --- | --- |
| **Story** | US-801 |
| **Decision** | [ADR-0022](../adr/ADR-0022-curated-external-copilot-capability-packs.md) |
| **Test type** | Prompt and instruction discovery acceptance |
| **Data** | Synthetic prompts only |

Run these scenarios after changing any capability imported by ADR-0022. They
are deterministic metadata-discovery tests, not claims about a model's
free-form response quality.

## Execution procedure

1. Check out the candidate commit and run from the repository root.
2. Give an isolated read-only Copilot reviewer one scenario at a time.
3. For prompt scenarios, match the prompt to the `description` or trigger
   metadata and inspect the selected capability's CRMShowcase overlay.
4. For file scenarios, evaluate the instruction front matter `applyTo`
   pattern against the supplied path.
5. Record the selected files and verify every expected assertion below.
6. Fail the scenario if discovery is ambiguous, an expected guardrail is
   absent, or the capability claims authority owned by an `AG-E-##` role.

## Scenarios

| ID | Prompt or file context | Expected discovery and application |
| --- | --- | --- |
| CAP-01 | "Build a custom connector that exposes a governed Dataverse action to Copilot Studio through MCP." | Select the conditional Power Platform MCP Integration Expert. Require AG-E-03, AG-E-04, AG-E-06 and AG-E-09 review. State that no MCP service is configured and do not invent credentials or connectivity. |
| CAP-02 | "Harden the GitHub Actions workflow that deploys a managed solution to TEST." | Select `github-actions-hardening`. Enforce pinned actions, least-privilege permissions, OIDC/managed identity, environment protection and secret-free configuration. |
| CAP-03 | Edit `solution/Controls/SampleControl/ControlManifest.Input.xml` or a sibling PCF source file, then compare with `solution/manifest.json`. | Apply both PCF instruction files only to the control path. Do not apply them to `solution/manifest.json` or other non-PCF solution metadata. Preserve DEV-unmanaged and TEST-managed ALM, localization and human-approval guardrails; prefer GA React/Fluent platform libraries for React controls. |
| CAP-04 | "Scaffold a Power Apps Code App with a Dataverse data source." | Select `power-apps-code-app-scaffold`. Start from the current Microsoft Vite template with `@microsoft/power-apps-vite`; generate the `pa app init`, `pa app add data-source`, `pa app run` and `pa app push` workflow; do not prescribe legacy `pac code` commands or concurrent local servers. |

## Recorded result

| Field | Value |
| --- | --- |
| **Date** | 2026-08-08 |
| **Repository commit** | `34834c2a9009f269e49012c751a5898ad0f49855` |
| **Upstream pin** | `ab7544d03d4c49fdd07f5958e1888ad39c4118e2` |
| **Runner** | GitHub Copilot CLI 1.0.79-9, isolated read-only `explore` agent |
| **Model** | Not surfaced by the isolated runner |
| **Method** | Repository metadata, trigger and `applyTo` inspection; no runtime Power Platform or MCP calls |

| ID | Result | Captured evidence |
| --- | --- | --- |
| CAP-01 | Pass | Selected `.github/agents/power-platform-mcp-integration-expert.agent.md`. Confirmed explicit MCP/custom-connector scope; AG-E-03/04/06/09 review; no implied MCP server, credentials or independent authority. |
| CAP-02 | Pass | Selected `.github/skills/github-actions-hardening/SKILL.md`. Confirmed workflow permission review, pinned actions, OIDC, least privilege and rejection of long-lived credentials. |
| CAP-03 | Pass | Selected both `.github/instructions/pcf-*.instructions.md` files for `solution/Controls/SampleControl/ControlManifest.Input.xml`, but not for `solution/manifest.json`. Confirmed multilingual, human-approval, DEV-unmanaged and TEST-managed rules plus GA React/Fluent platform-library guidance. |
| CAP-04 | Pass | Selected `.github/skills/power-apps-code-app-scaffold/SKILL.md`. Confirmed the Microsoft Vite template and `powerApps()` plugin, one local server, `pa app init`, `pa app add data-source`, `pa app run` and `pa app push`; `pac code` is explicitly legacy. |

**Limitation:** this run proves repository discovery metadata and overlays are
internally consistent. It does not prove live model behavior or external
service availability; those require a separate eval or integration test when
a delivery story enables the capability.
