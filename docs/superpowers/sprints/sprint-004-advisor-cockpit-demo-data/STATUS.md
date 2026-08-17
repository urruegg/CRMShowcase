# Sprint-004 STATUS

**Charter:** [#125](https://github.com/urruegg/CRMShowcase/issues/125) · **Started:** 2026-08-17

## Streams

| Stream | Issue | Class | State |
| --- | --- | --- | --- |
| prereq-fixes | [#126](https://github.com/urruegg/CRMShowcase/issues/126) | EXECUTION-ONLY | ⬜ not started |
| mcp-agent-decision | [#127](https://github.com/urruegg/CRMShowcase/issues/127) | DESIGN-SENSITIVE | ⬜ not started |
| mobiliar-intake-governance | [#128](https://github.com/urruegg/CRMShowcase/issues/128) | DESIGN-SENSITIVE | ⬜ not started |
| tenant-user-inventory | [#129](https://github.com/urruegg/CRMShowcase/issues/129) | DESIGN-SENSITIVE | ⬜ not started |
| fixture-enrichment | [#130](https://github.com/urruegg/CRMShowcase/issues/130) | DESIGN-SENSITIVE | ⬜ not started |
| seed-owner-wiring | [#131](https://github.com/urruegg/CRMShowcase/issues/131) | EXECUTION-ONLY | ⬜ not started |
| e2e-dev-test-verify | [#132](https://github.com/urruegg/CRMShowcase/issues/132) | EXECUTION-ONLY | ⬜ not started |

**2026-08-17.** Charter #125 + 7 stream issues (#126–#132) opened. Confirmed
live `pac auth` / `az rest` access to both `crmshowdev` and `crmshowtest` as
`admin@ABSx15847880.onmicrosoft.com` (the same account already used for
`crmshow-ci-*` bootstrap per ADR-0005) — this is the account
`tenant-user-inventory` (#129) is expected to resolve as the demo presenter.

**mcp-agent-decision (#127) — decision made, mechanical step pending
(2026-08-17).** Live DEV investigation confirmed both `crmshow_AdvisorCockpit_MCPServer`
and the `uxagentproject` "Advisor Cockpit Page" still exist and are linked
via the `appmodule.descriptor` JSON's `AppElements` array (the App Designer's
"Agents tab" / agent-feed feature) — not via a standard `appmodulecomponent`
row. Decision: remove the agent-feed entry (option a) rather than promote it
to TEST. Per Microsoft Learn, removal is a Maker-Portal-only interactive
action (App Designer → Agents tab → Remove from feed → Save/Publish); no
Web API action covers this specific mechanism, and hand-editing `descriptor`
directly was rejected as unsupported/risky. Recorded in
[2026-08-17-advisor-cockpit-mcp-agent-dependency-decision.md](../../specs/2026-08-17-advisor-cockpit-mcp-agent-dependency-decision.md).
Owner deferred the interactive step to be done at their convenience; the
control plane proceeds with other streams meanwhile.

**prereq-fixes (#126) — dispatched to a subagent, in progress (2026-08-17).**
Worktree `wt/sprint-004-prereq-fixes` created; implementer subagent working
through the #120 fix (TDD) and #124 intake-export.

## Live DEV + TEST evidence

_Not yet available — populated by the `e2e-dev-test-verify` stream (#132)
once `prereq-fixes` (#126), `mcp-agent-decision` (#127), and
`seed-owner-wiring` (#131) have merged._
