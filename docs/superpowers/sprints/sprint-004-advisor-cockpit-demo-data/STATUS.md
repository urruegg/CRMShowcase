# Sprint-004 STATUS

**Charter:** [#125](https://github.com/urruegg/CRMShowcase/issues/125) · **Started:** 2026-08-17

## Streams

| Stream | Issue | Class | State |
| --- | --- | --- | --- |
| prereq-fixes | [#126](https://github.com/urruegg/CRMShowcase/issues/126) | EXECUTION-ONLY | 🟡 #120 fixed + merged ([PR #137](https://github.com/urruegg/CRMShowcase/pull/137), commit `1da315c`); #124 re-authoring blocked on GitHub outage (see below) |
| mcp-agent-decision | [#127](https://github.com/urruegg/CRMShowcase/issues/127) | DESIGN-SENSITIVE | 🟡 decision recorded; mechanical Maker-Portal step deferred to owner |
| mobiliar-intake-governance | [#128](https://github.com/urruegg/CRMShowcase/issues/128) | DESIGN-SENSITIVE | ✅ merged ([PR #133](https://github.com/urruegg/CRMShowcase/pull/133)) |
| tenant-user-inventory | [#129](https://github.com/urruegg/CRMShowcase/issues/129) | DESIGN-SENSITIVE | ✅ merged ([PR #135](https://github.com/urruegg/CRMShowcase/pull/135)) |
| fixture-enrichment | [#130](https://github.com/urruegg/CRMShowcase/issues/130) | DESIGN-SENSITIVE | ✅ merged ([PR #134](https://github.com/urruegg/CRMShowcase/pull/134)) |
| seed-owner-wiring | [#131](https://github.com/urruegg/CRMShowcase/issues/131) | EXECUTION-ONLY | 🟡 [PR #136](https://github.com/urruegg/CRMShowcase/pull/136) open, `gate1` green once but rerun hit the GitHub outage — needs one more clean check run |
| e2e-dev-test-verify | [#132](https://github.com/urruegg/CRMShowcase/issues/132) | EXECUTION-ONLY | ⬜ not started — blocked on the two items above + #124 re-authoring |

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

**PR #137 opened for prereq-fixes; live re-authoring blocked on merge to
`main` (2026-08-17).** Dispatched `cd-solution-dev.yml` against
`feat/sprint-004-prereq-fixes` (run
[32031985164](https://github.com/urruegg/CRMShowcase/actions/runs/32031985164))
to verify the #120 fix live before merging. Result: `validate` job (the
full offline Pester suite) **succeeded in 23m12s** — this independently
re-confirms the fix's 424/0/2 pass count. The `author` job (which would
actually re-author the missing tables live) was **rejected by the `dev`
GitHub Environment's deployment branch policy** (`custom_branch_policies:
true` — only specific branches, expected to be `main`, may deploy) — not a
code defect. **Consequence:** live re-authoring of the #124 tables cannot be
verified from a feature branch; it requires PR #137 to merge to `main`
first, then a fresh `cd-solution-dev.yml` dispatch against `main`. This is
a genuine human-merge decision point (Intake Contract: merge is always a
human act) — flagged to the repo owner rather than worked around.

**Temporary merge-authority exception, owner-directed (2026-08-17).** The
owner could not reach the GitHub web UI and explicitly authorized the
control-plane session to merge sprint-004 PRs directly via `gh pr merge`
for the remainder of this demo-data build — reverting to the standard
human-only merge pattern (Intake Contract) once the sprint's build phase is
done. Recorded here for traceability per this repo's own audit-trail
convention; every PR merged under this exception is called out explicitly
below with who authorized it and when.

**PR #137 merged, owner-approved via chat (2026-08-17, commit `1da315c`).**
Owner gave explicit "approve PR 137" instruction (GitHub web UI was
unavailable to them) and separately authorized the control plane to merge
subsequent sprint-004 PRs directly for the rest of this build. `gh pr merge
137 --squash` executed; closed #120 automatically. `main` now carries the
#120 fix — dispatched `cd-solution-dev.yml` against `main` (not a feature
branch, since the `dev` environment's branch policy only allows that) to
re-author the missing #124 tables live: run
[32037106837](https://github.com/urruegg/CRMShowcase/actions/runs/32037106837),
in progress.

## Live DEV + TEST evidence

_Not yet available — populated by the `e2e-dev-test-verify` stream (#132)
once `prereq-fixes` (#126), `mcp-agent-decision` (#127), and
`seed-owner-wiring` (#131) have merged._

## Session paused 2026-08-17 17:11 — GitHub outage, resume tomorrow

**Root cause of the last few failures: an active, GitHub-wide incident**,
not our code. Confirmed via `https://www.githubstatus.com/api/v2/status.json`
(`"indicator":"major","description":"Partial System Outage"`) and the
unresolved-incidents feed (started ~13:40 UTC, impact `critical`, components
`Actions` / `Pull Requests` / `Issues` / `Copilot` all `major_outage`,
`API Requests` `degraded_performance`). This explains: the repeated
`microsoft/powerplatform-actions` action-download timeouts/429s inside the
`author` job of the DEV workflow (two separate attempts, both failing at
job **setup**, before any of our code ran), the `gate1` rerun for PR #136
failing at the same action-download stage, and the transient `HTTP 503`
errors from `gh api`/`gh pr view` calls during this session.

### What is safely done (merged to `main`)

- **#120 closed** — `Invoke-NativeLookupExtensionReconciliation` fix merged
  via [PR #137](https://github.com/urruegg/CRMShowcase/pull/137) (commit
  `1da315c`). Verified twice: full offline suite 424/0/2 (local) and a
  live `validate` job re-run 424/0/2 green (in CI, twice — both DEV dispatch
  attempts today got past `validate` cleanly; only `author`'s job **setup**
  hit the outage).
- **mobiliar-intake-governance** merged via
  [PR #133](https://github.com/urruegg/CRMShowcase/pull/133).
- **tenant-user-inventory** (`Get-DemoPresenterUser.ps1`) merged via
  [PR #135](https://github.com/urruegg/CRMShowcase/pull/135).
- **fixture-enrichment** merged via
  [PR #134](https://github.com/urruegg/CRMShowcase/pull/134).
- All 4 corresponding worktrees retired (`Remove-SprintWorktree.ps1`); their
  branches remain on GitHub for history but are fully merged.

### What is still open — pick these up first tomorrow

1. **Check `https://www.githubstatus.com` first.** Do not retry Actions/PR
   operations until `Actions`/`Pull Requests` report operational again.
2. **PR #136** (`seed-owner-wiring`, worktree
   `wt/sprint-004-seed-owner-wiring`, branch
   `feat/sprint-004-seed-owner-wiring`, still open, not merged) — its
   `gate1` passed once already (commit `eae79b5`, run `32038801628`) but a
   required rerun on the next sync commit (`9f662d4`) hit the outage
   mid-download. Once GitHub is healthy: `gh pr checks 136`, and if `gate1`
   is stale/failed, `gh run rerun <id> --failed` (or just wait — no code
   changes needed, this is purely an infra retry). Then
   `gh pr merge 136 --squash --delete-branch=false` (owner has authorized
   direct control-plane merges for the remainder of this build — see the
   "Temporary merge-authority exception" note above; revert to human-only
   merge once the sprint's build phase is done). Then retire its worktree
   with `Remove-SprintWorktree.ps1`.
3. **#124 (re-authoring the missing DEV tables)** — dispatch
   `gh workflow run cd-solution-dev.yml --repo urruegg/CRMShowcase --ref main`
   once GitHub's Actions component is healthy. Expect it to succeed now that
   #120 is merged to `main` (the only two failures today were the outage
   hitting job setup, not the actual authoring logic — `validate` passed
   both times). Once tables are live (`crmshow_leadcluster`,
   `crmshow_claimprojection`, `crmshow_nextbestaction`,
   `crmshow_nbaprovenance`, `crmshow_measuresnapshot`), redo the
   intake-export (`Export-Solution.ps1` → `Unpack-Solution.ps1` against
   `solution/core/datamodel`) to actually close #124.
4. **#127 (`mcp-agent-decision`)** — mechanical Maker-Portal step still
   needs the owner: App Designer → Agents tab → Agent feed → "In your feed"
   → remove the agent → Save → Publish (see
   [the decision doc](../../specs/2026-08-17-advisor-cockpit-mcp-agent-dependency-decision.md)
   for exact steps). Re-export `crmshow_Sales` and re-run
   `cd-solution-test.yml` afterward to confirm #121 is actually closed.
5. **e2e-dev-test-verify (#132)** — only after 2-4 above are done: dispatch
   `cd-solution-dev.yml` (DEV evidence) and `cd-solution-test.yml` (TEST
   promotion evidence), then write the `## Live DEV + TEST evidence` section
   above per the Sprint Operating Model's closing requirement.

### Local git state (verified clean before pausing)

- Control-plane branch `docs/s3-test-evidence-e2e-verify`: merged with
  latest `main`, no uncommitted changes.
- `wt/sprint-004-seed-owner-wiring`: clean, fully pushed, PR #136 open.
- The 4 merged streams' worktrees removed; their remote branches
  (`feat/sprint-004-{prereq-fixes,mobiliar-intake-governance,
  tenant-user-inventory,fixture-enrichment}`) still exist on GitHub
  (already merged — safe to delete whenever convenient, not urgent).
