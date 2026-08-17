# Sprint-004 addendum — #121 MCP Server / Agent-Builder dependency decision

| Field | Value |
| --- | --- |
| **Status** | Decided (2026-08-17) — mechanical removal step pending, requires an interactive Maker Portal action |
| **Related** | [design spec](./2026-08-17-advisor-cockpit-demo-data-design.md) · [plan Task 2](../plans/2026-08-17-advisor-cockpit-demo-data.md#task-2-mcp-agent-decision-stream--resolve-121-design-sensitive) · [issue #121](https://github.com/urruegg/CRMShowcase/issues/121) · [ADR-0014](../../adr/ADR-0014-agents-advisory-by-design.md) |

## Decision

**Option (a) chosen:** remove the Copilot/AI-assistant agent feed entry from the
live DEV `crmshow_AdvisorCockpit` app module, dropping its hard dependency on
`crmshow_AdvisorCockpit_MCPServer` and the `uxagentproject` "Advisor Cockpit
Page" (`{57de26e1-9bfa-452d-a8e8-fa45a00dd0e5}`), rather than promoting the
MCP Server + Agent-Builder project to TEST as well. Rationale: the agent is
advisory-only per ADR-0014 and was never part of this sprint's scope; keeping
it out of TEST avoids an additional licensing/governance surface for a
capability nobody has designed or reviewed yet.

## Findings (live DEV investigation, 2026-08-17)

Confirmed via `az rest` against `https://crmshowdev.crm.dynamics.com`:

- `crmshow_AdvisorCockpit_MCPServer` (`mcpserverid`
  `525a3be9-9798-f111-b8db-000d3a30c0f4`) and the `uxagentproject` "Advisor
  Cockpit Page" (`57de26e1-9bfa-452d-a8e8-fa45a00dd0e5`) both still exist live
  in DEV.
- Neither is linked via an `appmodulecomponent` record (`objectid eq
  <mcpserverid or uxagentprojectid>` returns zero rows) — the dependency is
  **not** expressed through the standard solution-component-add mechanism
  that `AddAppComponents`/`RemoveAppComponents` manage.
- The link is instead recorded in the `appmodule` record's own `descriptor`
  JSON field, under a dedicated `AppElements` array:
  ```json
  "AppElements":[{"ObjectId":"525a3be9-9798-f111-b8db-000d3a30c0f4","AppElementType":"MCPServer","CanvasAppType":0,"ObjectName":"Advisor Cockpit MCP Server"}]
  ```
  This is the App Designer's **Agents tab** / "Agent feed" feature (see
  Microsoft Learn: "Add agents to your model-driven app (preview)").
- Per that documentation, removal is a **Maker Portal-only, interactive
  action** — App Designer → **Agents** tab → **Agent feed** dropdown → **In
  your feed** → select the agent → **...** → **Remove from feed** → Save →
  Publish. There is no documented Web API action for this specific
  mechanism (unlike the generic `AddAppComponents`/`RemoveAppComponents`
  actions, which cover views/forms/dashboards/entities, not the Agent feed).
  Hand-editing the `descriptor` field directly via the Web API was
  considered and rejected: it is a platform-managed, computed field, and
  writing to it directly is unsupported and risks corrupting the app module.
  "Removing an agent from an app doesn't remove the agent from the
  environment" (per the same doc) — the MCP Server/Agent-Builder project
  records themselves can remain in DEV, unused; only the app module's
  dependency declaration needs to go.

## Remaining mechanical steps (interactive, human-performed)

1. Sign in to [make.powerapps.com](https://make.powerapps.com) against the
   `crmshowdev` environment.
2. Open the **Advisor Cockpit** app in the App Designer (Edit).
3. Go to the **Agents** tab → **Agent feed** dropdown → **In your feed**.
4. Select the agent (Advisor Cockpit Page / its MCP Server entry) → **...**
   → **Remove from feed**.
5. **Save**, then **Publish** the app.
6. Re-export the `crmshow_Sales` solution (unmanaged) and confirm the
   `descriptor`'s `AppElements` array no longer references the MCP Server
   (re-check via the same `az rest` query used above).
7. Dispatch `cd-solution-test.yml` and confirm the missing-dependency error
   for `crmshow_Sales` is gone.
8. Close issue #121.

This addendum records the decision and investigation; the control-plane
session cannot perform steps 1-5 itself (no interactive Maker Portal
credentials in its browser tool) — see the sprint-004 STATUS.md for who
completes them and when.
