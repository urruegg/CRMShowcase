# Sprint-004 STATUS

**Charter:** [#125](https://github.com/urruegg/CRMShowcase/issues/125) · **Started:** 2026-08-17

## Streams

| Stream | Issue | Class | State |
| --- | --- | --- | --- |
| prereq-fixes | [#126](https://github.com/urruegg/CRMShowcase/issues/126) | EXECUTION-ONLY | 🟡 #120 fix implemented (424/0/2 Pester), live DEV re-run in progress; #124 needs re-authoring first (see below) |
| mcp-agent-decision | [#127](https://github.com/urruegg/CRMShowcase/issues/127) | DESIGN-SENSITIVE | 🟡 decision recorded; mechanical Maker-Portal step deferred |
| mobiliar-intake-governance | [#128](https://github.com/urruegg/CRMShowcase/issues/128) | DESIGN-SENSITIVE | ✅ [PR #133](https://github.com/urruegg/CRMShowcase/pull/133) |
| tenant-user-inventory | [#129](https://github.com/urruegg/CRMShowcase/issues/129) | DESIGN-SENSITIVE | ✅ [PR #135](https://github.com/urruegg/CRMShowcase/pull/135) |
| fixture-enrichment | [#130](https://github.com/urruegg/CRMShowcase/issues/130) | DESIGN-SENSITIVE | ✅ [PR #134](https://github.com/urruegg/CRMShowcase/pull/134) |
| seed-owner-wiring | [#131](https://github.com/urruegg/CRMShowcase/issues/131) | EXECUTION-ONLY | ✅ [PR #136](https://github.com/urruegg/CRMShowcase/pull/136) |
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

**#120 fixed, reviewed, and live-verifying (2026-08-17).** Implementer
subagent added `Invoke-NativeLookupExtensionReconciliation` (+
`New-NativeLookupRelationshipMetadata`/`Get-NativeLookupRelationshipRequest`/
`Get-NativeLookupRelationshipMetadata`) to `Publish-InsuranceFoundation.ps1`,
branching `Invoke-NativeExtensionReconciliation` on `type -eq 'Lookup'` to
check existence via `ManyToOneRelationships` and create via
`POST /RelationshipDefinitions`, mirroring the existing custom-table
ordinary-relationship pattern instead of the generic Attributes POST
Dataverse rejects for Lookup types. Full offline suite: **424 passed, 0
failed, 2 skipped**. Control-plane review (spec compliance + code quality):
approved — diff closely mirrors the existing `Get-OrdinaryRelationshipRequest`
pattern, correctly updates 3 pre-existing dependent test assertions (Attributes
POST count 21→20, new RelationshipDefinitions POST assertion, corrected
integration-test request-sequence array), no `Assert-MockCalled` regressions.
Pushed to `feat/sprint-004-prereq-fixes`; live DEV re-authoring dispatched
against that branch to verify before merge — run
[32031985164](https://github.com/urruegg/CRMShowcase/actions/runs/32031985164),
in progress.

**#124 finding: the expected DEV-authored tables no longer exist live
(2026-08-17).** The implementer's export/unpack attempt (Part B) came back
with only `account`, `contact`, `crmshow_accountcontactrole`,
`crmshow_policypartyrole`, `crmshow_policyprojection` as RootComponents —
missing `crmshow_leadcluster`, `crmshow_claimprojection`,
`crmshow_nextbestaction`, `crmshow_nbaprovenance`, `crmshow_measuresnapshot`
and the lead/incident native extensions that sprint-003's STATUS.md recorded
as DEV-authored via run 31805085480 (2026-08-14). Confirmed independently via
direct `az rest` query against `crmshowdev`'s `EntityDefinitions`: none of
those 5 tables exist live today. Root cause hypothesis: the 2026-08-14
authoring run (or a later one) partially failed/rolled back due to exactly
the #120 Lookup-creation bug (`crmshow_leadclusterid`'s relationship is one
of the native extensions in that same schema slice) — the schema is still
declared in `solution/schema/insurance-foundation.json`, so this is a
re-authoring gap, not a lost design decision. Owner confirmed: dispatch
`cd-solution-dev.yml` (now with the #120 fix) to re-author these tables live,
then redo the intake-export. Sequenced after the fix's live-verify run above.

## Live DEV + TEST evidence

_Not yet available — populated by the `e2e-dev-test-verify` stream (#132)
once `prereq-fixes` (#126), `mcp-agent-decision` (#127), and
`seed-owner-wiring` (#131) have merged._
