# Sprint-004 — Advisor Cockpit demo data realism — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deliver a demo-realistic, presenter-personalized Advisor Cockpit data set — evaluated from the Mobiliar reference intake, seeded with `ownerid` resolved to the DEV/TEST System Administrator, wired into both `cd-solution-dev.yml` and `cd-solution-test.yml`, and closed out with full live DEV+TEST evidence — after first clearing the three inherited sprint-003 blockers (#120, #121, #124) that currently prevent a clean TEST promotion.

**Architecture:** Follows this repo's [Sprint Operating Model](../SPRINT-OPERATING-MODEL.md) exactly: one GitHub Sprint-004 charter issue, one stream issue + handover packet per stream below, each stream built in its own isolated `wt/sprint-004-<stream>` worktree, dispatched headless (`EXECUTION-ONLY`) or attended (`DESIGN-SENSITIVE`) per the [Handover Contract](../contracts/HANDOVER-CONTRACT.md), returned to trunk via `Complete-StreamIntake.ps1` (push + PR, never merge — merge stays a human act).

**Tech Stack:** PowerShell 5.1 (`scripts/solution/*.ps1`, `scripts/orchestration/*.ps1`), Pester, Dataverse Web API v9.2 via `az rest` (OIDC), GitHub Actions (`cd-solution-dev.yml` / `cd-solution-test.yml`), `gh` CLI.

**Design spec:** [2026-08-17-advisor-cockpit-demo-data-design.md](./2026-08-17-advisor-cockpit-demo-data-design.md)

---

## Task 0: Control plane — Sprint-004 charter + stream issues

**Files:**
- Create: `docs/superpowers/sprints/sprint-004-advisor-cockpit-demo-data/sprint.md`
- Create: `docs/superpowers/sprints/sprint-004-advisor-cockpit-demo-data/STATUS.md`
- Modify: `docs/superpowers/sprints/README.md` (add the sprint-004 row)

This task runs directly on the trunk (`docs/s3-test-evidence-e2e-verify` or `main`, whichever the control-plane session is on) — it is **not** a delegated stream.

- [ ] **Step 1: Create the Sprint-004 charter issue**

```powershell
gh issue create --repo urruegg/CRMShowcase `
  --title "sprint-004: Advisor Cockpit demo data realism (charter)" `
  --label "sprint:004" `
  --body @'
Charter for sprint-004: make the Advisor Cockpit demo data set realistic and
presenter-personalized, closing the three sprint-003 carry-over blockers first.

Design spec: docs/superpowers/specs/2026-08-17-advisor-cockpit-demo-data-design.md
Plan: docs/superpowers/plans/2026-08-17-advisor-cockpit-demo-data.md
Operating model: docs/superpowers/SPRINT-OPERATING-MODEL.md

## Streams
1. prereq-fixes (#120, #124) — EXECUTION-ONLY
2. mcp-agent-decision (#121) — DESIGN-SENSITIVE
3. mobiliar-intake-governance — DESIGN-SENSITIVE
4. tenant-user-inventory — DESIGN-SENSITIVE
5. fixture-enrichment — DESIGN-SENSITIVE
6. seed-owner-wiring — EXECUTION-ONLY
7. e2e-dev-test-verify — EXECUTION-ONLY

## Definition of Done
- [ ] All 7 streams merged to main via PR (never self-merged).
- [ ] `## Live DEV + TEST evidence` section in this sprint'"'"'s STATUS.md per the
      Sprint Operating Model'"'"'s closing requirement.
- [ ] #120, #121, #124 closed.
'@
```

Record the returned issue number as `#S` (the charter issue number) — it is
substituted for `<charter-issue>` in every step below.

- [ ] **Step 2: Create the 7 stream issues**

Run once per stream (adjust `--title`/`--body`, keep `--label`):

```powershell
gh issue create --repo urruegg/CRMShowcase --label "sprint:004" `
  --title "sprint-004/prereq-fixes: fix #120 lookup creation + #124 intake-export" `
  --body "Stream of sprint-004 charter #<charter-issue>. Autonomy class: EXECUTION-ONLY. Closes #120, #124. See docs/superpowers/plans/2026-08-17-advisor-cockpit-demo-data.md Task 1."

gh issue create --repo urruegg/CRMShowcase --label "sprint:004" `
  --title "sprint-004/mcp-agent-decision: resolve #121 TEST promotion blocker" `
  --body "Stream of sprint-004 charter #<charter-issue>. Autonomy class: DESIGN-SENSITIVE. Closes #121. See docs/superpowers/plans/2026-08-17-advisor-cockpit-demo-data.md Task 2."

gh issue create --repo urruegg/CRMShowcase --label "sprint:004" `
  --title "sprint-004/mobiliar-intake-governance: finish intake/mobiliar governance" `
  --body "Stream of sprint-004 charter #<charter-issue>. Autonomy class: DESIGN-SENSITIVE. See docs/superpowers/plans/2026-08-17-advisor-cockpit-demo-data.md Task 3."

gh issue create --repo urruegg/CRMShowcase --label "sprint:004" `
  --title "sprint-004/tenant-user-inventory: resolve DEV/TEST presenter identity" `
  --body "Stream of sprint-004 charter #<charter-issue>. Autonomy class: DESIGN-SENSITIVE. See docs/superpowers/plans/2026-08-17-advisor-cockpit-demo-data.md Task 4."

gh issue create --repo urruegg/CRMShowcase --label "sprint:004" `
  --title "sprint-004/fixture-enrichment: enrich Advisor Cockpit fixtures" `
  --body "Stream of sprint-004 charter #<charter-issue>. Autonomy class: DESIGN-SENSITIVE. See docs/superpowers/plans/2026-08-17-advisor-cockpit-demo-data.md Task 5."

gh issue create --repo urruegg/CRMShowcase --label "sprint:004" `
  --title "sprint-004/seed-owner-wiring: wire presenter ownerid + TEST seed step" `
  --body "Stream of sprint-004 charter #<charter-issue>. Autonomy class: EXECUTION-ONLY. See docs/superpowers/plans/2026-08-17-advisor-cockpit-demo-data.md Task 6."

gh issue create --repo urruegg/CRMShowcase --label "sprint:004" `
  --title "sprint-004/e2e-dev-test-verify: live DEV+TEST evidence" `
  --body "Stream of sprint-004 charter #<charter-issue>. Autonomy class: EXECUTION-ONLY. See docs/superpowers/plans/2026-08-17-advisor-cockpit-demo-data.md Task 7."
```

Record each returned number as `#N1`..`#N7` (stream issue numbers, in the
same order as the task numbers below).

- [ ] **Step 3: Scaffold sprint.md and STATUS.md**

Create `docs/superpowers/sprints/sprint-004-advisor-cockpit-demo-data/sprint.md`
following the exact structure of
`docs/superpowers/sprints/sprint-003-advisor-cockpit/sprint.md` (Outcome /
Streams table with columns Stream · Phase · Issue · Class · State, all rows
`⬜ not started`) and `STATUS.md` with a `## Streams` heading and empty
`## Live DEV + TEST evidence` placeholder heading (to be filled by Task 7).
Add the sprint-004 row to `docs/superpowers/sprints/README.md`'s index table,
matching the existing sprint-001/002/003 row format.

- [ ] **Step 4: Commit**

```bash
git add docs/superpowers/sprints/sprint-004-advisor-cockpit-demo-data docs/superpowers/sprints/README.md
git commit -m "docs(sprint-004): open charter + stream issues, scaffold sprint folder"
```

---

## Task 1: `prereq-fixes` stream — fix #120 + #124 (EXECUTION-ONLY)

**Worktree setup (run on trunk before dispatching):**

```powershell
. scripts/orchestration/New-SprintWorktree.ps1
New-SprintWorktree -SprintId 'sprint-004' -StreamId 'prereq-fixes' `
  -IssueNumber <N1> -AutonomyClass 'EXECUTION-ONLY' -DesignRef 'docs/superpowers/specs/2026-08-17-advisor-cockpit-demo-data-design.md'
```

**Files (inside `wt/sprint-004-prereq-fixes`):**
- Modify: `scripts/solution/Publish-InsuranceFoundation.ps1` (functions `Invoke-NativeExtensionReconciliation` at line ~1870, `Get-PicklistAttributeMetadata` at line ~1182, reusing the relationship-creation pattern from `New-OrdinaryRelationshipMetadata`/`Get-OrdinaryRelationshipRequest` at lines ~365-415 and `Invoke-ExistingOrdinaryRelationshipReconciliation` at line ~2180)
- Test: `scripts/solution/tests/Publish-InsuranceFoundation.Tests.ps1`
- Export/reconcile (no code, a data pull): `solution/core/datamodel/**` via `pac solution export` + `scripts/solution/Unpack-Solution.ps1`

### Root cause (already diagnosed — give this to the implementer verbatim)

`crmshow_leadclusterid` is declared in `insurance-foundation.json`'s
`nativeExtensions` array (line ~517) as:
```json
{"table":"lead","logicalName":"crmshow_leadclusterid","schemaName":"crmshow_LeadClusterId","type":"Lookup","lookup":{"targets":["crmshow_leadcluster"],"authoring":"InitialTableCreate"},"required":false,"auditing":true,"solution":"crmshow_DataModel", ...}
```
`Invoke-NativeExtensionReconciliation` (line ~1870) unconditionally calls
`Get-PicklistAttributeMetadata $Extension.table $Extension.logicalName` to
check whether the extension already exists — but that function queries
`Microsoft.Dynamics.CRM.PicklistAttributeMetadata`, which can never match a
`Lookup`-typed attribute. So `$existing` is always `$null` for a Lookup
native extension, and the code always falls into
`New-NativeAttributeRequest` (line ~565), which does a plain
`POST /EntityDefinitions(LogicalName='lead')/Attributes` — the exact call
Dataverse rejects with `0x80040203` for `LookupAttributeMetadata`. Custom
tables already avoid this: `Invoke-ExistingOrdinaryRelationshipReconciliation`
(line ~2180) checks existence via `$Snapshot.ManyToOneRelationships` and
creates via `POST /RelationshipDefinitions` with
`OneToManyRelationshipMetadata` (see `New-OrdinaryRelationshipMetadata`,
line ~365, and `Get-OrdinaryRelationshipRequest`, line ~402). Native
extensions have no equivalent branch for `type -eq 'Lookup'`.

- [ ] **Step 1: Write the failing Pester test**

Add to `scripts/solution/tests/Publish-InsuranceFoundation.Tests.ps1` (find
the `Describe` block covering `Invoke-NativeExtensionReconciliation` and add
a sibling `It`; if none exists yet, add a new `Describe 'Invoke-NativeExtensionReconciliation'`
block near the existing native-extension test coverage):

```powershell
It 'creates a Lookup-type native extension via RelationshipDefinitions, not a plain Attributes POST' {
    $extension = [pscustomobject]@{
        table = 'lead'; logicalName = 'crmshow_leadclusterid'
        schemaName = 'crmshow_LeadClusterId'; type = 'Lookup'
        lookup = [pscustomobject]@{ targets = @('crmshow_leadcluster'); authoring = 'InitialTableCreate' }
        required = $false; auditing = $true; solution = 'crmshow_DataModel'
        metadata = [pscustomobject]@{
            label = @{ '1033' = 'Lead Cluster' }
            description = @{ '1033' = 'Lead cluster the lead belongs to.' }
        }
    }
    Mock Get-ManyToOneRelationshipSnapshot { return @() }
    Mock Invoke-PlannedRequest { return [pscustomobject]@{} }
    Invoke-NativeExtensionReconciliation $extension
    Should -Invoke -CommandName Invoke-PlannedRequest -Times 1 -Exactly -ParameterFilter {
        $Request.Path -eq '/RelationshipDefinitions' -and
        $Request.Body.'@odata.type' -eq 'Microsoft.Dynamics.CRM.OneToManyRelationshipMetadata' -and
        $Request.Body.Lookup.LogicalName -eq 'crmshow_leadclusterid'
    }
}
```

> **Repo convention note:** use `Should -Invoke -CommandName <Name> -Times N
> -Exactly [-ParameterFilter {...}]` for mock assertions, not
> `Assert-MockCalled` (Pester v3/v4-era syntax that intermittently fails to
> load under this repo's pinned Pester 6.0.1). Run `Import-Module Pester
> -RequiredVersion 6.0.1 -Force` before `Invoke-Pester` locally, matching
> `cd-solution-dev.yml`/`cd-solution-test.yml` exactly.

- [ ] **Step 2: Run test to verify it fails**

Run: `Invoke-Pester -Path scripts/solution/tests/Publish-InsuranceFoundation.Tests.ps1 -Output Detailed`
Expected: FAIL — `Get-ManyToOneRelationshipSnapshot` does not exist yet, and
the real code still posts to `/Attributes`.

- [ ] **Step 3: Implement the fix**

Add a small existence-check helper (mirrors the custom-table pattern) and
branch `Invoke-NativeExtensionReconciliation` on `$Extension.type`:

```powershell
function Get-ManyToOneRelationshipSnapshot {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string]$TableLogicalName,
        [Parameter(Mandatory)] [string]$LookupColumnLogicalName
    )
    $escapedTable = ConvertTo-ODataKeyString $TableLogicalName
    $response = Invoke-DataverseRequest -Method GET -Path (
        "/EntityDefinitions(LogicalName='$escapedTable')/ManyToOneRelationships?" +
        "`$select=SchemaName,ReferencedEntity,ReferencingEntity,ReferencingAttribute,MetadataId"
    )
    return @($response.value | Where-Object {
        $_.ReferencingAttribute -eq $LookupColumnLogicalName
    })
}

function New-NativeLookupRelationshipRequest {
    [CmdletBinding()]
    param([Parameter(Mandatory)] $Extension)
    $target = [string]$Extension.lookup.targets[0]
    return [pscustomobject]@{
        Method = 'POST'
        Path = '/RelationshipDefinitions'
        Solution = $Extension.solution
        Body = [ordered]@{
            '@odata.type' = 'Microsoft.Dynamics.CRM.OneToManyRelationshipMetadata'
            SchemaName = $Extension.schemaName
            ReferencedAttribute = "${target}id"
            ReferencedEntity = $target
            ReferencingEntity = $Extension.table
            AssociatedMenuConfiguration = @{
                Behavior = 'UseLabel'; Group = 'Details'
                Label = ConvertTo-LocalizedLabel $Extension.metadata.label
                Order = 10000
            }
            CascadeConfiguration = Get-ExpectedOrdinaryRelationshipCascade -ReferencedEntity $target
            Lookup = [ordered]@{
                '@odata.type' = 'Microsoft.Dynamics.CRM.LookupAttributeMetadata'
                LogicalName = $Extension.logicalName
                SchemaName = $Extension.schemaName
                AttributeType = 'Lookup'
                AttributeTypeName = @{ Value = 'LookupType' }
                DisplayName = ConvertTo-LocalizedLabel $Extension.metadata.label
                Description = ConvertTo-LocalizedLabel $Extension.metadata.description
                RequiredLevel = ConvertTo-RequiredLevel ([bool]$Extension.required)
                IsAuditEnabled = @{ Value = [bool]$Extension.auditing }
            }
        }
    }
}
```

Then, in `Invoke-NativeExtensionReconciliation`, replace the unconditional
`Get-PicklistAttributeMetadata` existence check + `New-NativeAttributeRequest`
creation with a branch: when `$Extension.type -eq 'Lookup'`, check existence
via `Get-ManyToOneRelationshipSnapshot` and create (if absent) via
`Invoke-PlannedRequest (New-NativeLookupRelationshipRequest $Extension)`;
otherwise keep the existing Picklist/plain-attribute path unchanged.

- [ ] **Step 4: Run test to verify it passes**

Run: `Invoke-Pester -Path scripts/solution/tests/Publish-InsuranceFoundation.Tests.ps1 -Output Detailed`
Expected: PASS, and the full existing suite still green (no regressions to
the Picklist/Text/DateTime native-extension paths).

- [ ] **Step 5: Full offline suite + commit**

```powershell
Invoke-Pester -Path scripts/solution/tests -Output Detailed
git add scripts/solution/Publish-InsuranceFoundation.ps1 scripts/solution/tests/Publish-InsuranceFoundation.Tests.ps1
git commit -m "fix(insurance-foundation): create Lookup-type native extensions via RelationshipDefinitions

Fixes #120 — crmshow_leadclusterid (lead -> crmshow_leadcluster) was
routed through the generic Attributes POST, which Dataverse rejects for
LookupAttributeMetadata. Invoke-NativeExtensionReconciliation now checks
existence via ManyToOneRelationships and creates via
POST /RelationshipDefinitions for Lookup-typed native extensions, mirroring
the existing custom-table ordinary-relationship pattern."
```

- [ ] **Step 6: Close #124 — intake-export the DEV-authored schema**

Requires a live `az`/`pac` session against `crmshowdev` (ask the control-plane
session for the environment URL/credentials if not already configured in the
worktree's shell). Run:

```powershell
pwsh scripts/solution/Export-Solution.ps1 -SolutionName crmshow_DataModel -EnvironmentUrl <crmshowdev-url> -OutputPath intake/.tmp/crmshow_DataModel.zip
pwsh scripts/solution/Unpack-Solution.ps1 -SolutionZipPath intake/.tmp/crmshow_DataModel.zip -TargetPath solution/core/datamodel
git status solution/core/datamodel
```

Review the diff: it must show exactly `crmshow_leadcluster`,
`crmshow_claimprojection`, `crmshow_nextbestaction`, `crmshow_nbaprovenance`,
`crmshow_measuresnapshot`, and the native extensions from the 2026-08-14
scope-reduction addendum (per sprint-003 STATUS.md) — nothing unexpected. If
the diff includes anything unrelated (e.g. environment-specific IDs that
should be filtered), stop and flag `BLOCKED: needs design` rather than
committing it.

- [ ] **Step 7: Commit the intake-export**

```bash
git add solution/core/datamodel
git commit -m "chore(datamodel): intake-export DEV-authored foundational/cockpit tables

Closes #124 — crmshow_leadcluster, crmshow_claimprojection,
crmshow_nextbestaction, crmshow_nbaprovenance, crmshow_measuresnapshot and
their native extensions, authored live in DEV run 31805085480 (2026-08-14),
are now reflected in solution/core/datamodel source."
```

- [ ] **Step 8: Self-review, then stop (control plane takes over for intake)**

The implementer subagent's job ends here: commits exist in the worktree
branch, verification (Step 5's Pester run) is green. Do **not** push or open
a PR from inside the worktree — report `DONE` back to the control plane,
which runs `Complete-StreamIntake.ps1` (Task "Stream intake", below) after
the two-stage review passes.

---

## Task 2: `mcp-agent-decision` stream — resolve #121 (DESIGN-SENSITIVE)

**Worktree setup:**

```powershell
New-SprintWorktree -SprintId 'sprint-004' -StreamId 'mcp-agent-decision' `
  -IssueNumber <N2> -AutonomyClass 'DESIGN-SENSITIVE' -DesignRef 'docs/superpowers/specs/2026-08-17-advisor-cockpit-demo-data-design.md'
```

This stream is **attended** — per the Handover Contract it may never be
launched headless. Run it as an interactive `copilot` session (or continue in
this control-plane session, working inside the worktree path) with the human
present, since it requires a live look at the DEV `crmshow_AdvisorCockpit` app
module and a governance call.

**Goal / Definition of Done:** Issue #121 is closed. Either (a) the
Copilot/AI-assistant feature is removed from the `crmshow_AdvisorCockpit` app
module in DEV, the app is re-exported, and `crmshow_Sales` promotes cleanly to
TEST with no missing-dependency error; or (b)
`crmshow_AdvisorCockpit_MCPServer` and the `uxagentproject`
(`{57de26e1-9bfa-452d-a8e8-fa45a00dd0e5}`) are deliberately included in the
TEST promotion set, with the licensing/governance implications recorded. The
decision and its rationale are written into a short addendum under
`docs/superpowers/specs/` (new file, e.g.
`2026-08-1x-advisor-cockpit-mcp-agent-dependency-decision.md`) or as a note
appended to the existing 2026-08-15 MDA app design spec — whichever the
attended session judges more appropriate once it has seen the live DEV app
module.

**Allowed scope (paths):** `solution/apps/sales/**` (app module manifest
only, not the PCF controls), `docs/superpowers/specs/**`,
`docs/superpowers/sprints/sprint-004-advisor-cockpit-demo-data/**`.

**Verification commands:**
```
gh workflow run cd-solution-test.yml --repo urruegg/CRMShowcase
```
(dispatched only after the decision is implemented in DEV and re-exported —
this is the actual test of whether the blocker is resolved: the TEST
promotion run must no longer report the missing-dependency error for
`crmshow_Sales`.)

**Guardrails:** Inherit `SUPERPOWERS_CONTRACT.md` §1. This is a licensing- and
governance-relevant decision (Copilot/AI-assistant feature toggle vs.
promoting an agent-builder project) — per `AGENTS.md` §Authority this may need
Enterprise Architect (AG-E-03) and Responsible-AI Officer (AG-E-06) review in
the PR, since it touches an agent capability surface even though advisory-only
(ADR-0014). Flag the PR accordingly.

**Escalation rule:** If neither option (a) nor (b) is acceptable once the live
app module is inspected, STOP, write `BLOCKED: needs design`, and surface the
question back to the control-plane chat rather than guessing.

- [ ] Investigate the live DEV `crmshow_AdvisorCockpit` app module (Maker Portal or `pac`/Web API read of the app module's components) and confirm exactly how the Copilot/AI-assistant toggle introduced the MCP Server + Agent-Builder project dependency.
- [ ] Decide (a) vs (b) with the user attended; record the decision + rationale in a design-doc addendum.
- [ ] Implement the decision in DEV (remove the toggle, or promote the two extra components) and re-export the `crmshow_Sales` package.
- [ ] Dispatch `cd-solution-test.yml` and confirm the missing-dependency error is gone.
- [ ] Commit the design-doc addendum + any manifest changes.
- [ ] Report `DONE` (or `BLOCKED: needs design` with the specific question) back to the control plane. Do not push or open the PR yourself.

---

## Task 3: `mobiliar-intake-governance` stream (DESIGN-SENSITIVE)

**Worktree setup:**

```powershell
New-SprintWorktree -SprintId 'sprint-004' -StreamId 'mobiliar-intake-governance' `
  -IssueNumber <N3> -AutonomyClass 'DESIGN-SENSITIVE' -DesignRef 'docs/superpowers/specs/2026-08-17-advisor-cockpit-demo-data-design.md'
```

**Goal / Definition of Done:** `intake/mobiliar/` has the same governance
shape as `intake/contoso-insurance/`: a `README.md` stating the same
evidence-only boundary (no Dataverse records, no branded/PII content
committed, raw ZIP/scan stay in ignored `.raw/`/`.scan/`), a `bom/` folder
with a component inventory (mirroring
`intake/contoso-insurance/bom/artefacts.csv`'s columns —
disposition/targetSolution/licenceReview — regenerated via
`scripts/solution/New-SolutionBom.ps1` against the existing
`intake/mobiliar/.scan/source-scan.json` and `.raw` snapshot, re-validating
with `scripts/solution/Test-IntakeSnapshot.ps1` first if the snapshot's
staleness is in doubt), and a `mappings/` folder documenting which Mobiliar
source concepts (e.g. `cr7e8_sharedpage01advisorcockpit`,
`cr7e8_ucmb1page18brunnercustomer360`, the ERD visualizer HTML) map to which
Advisor Cockpit fixture or concept. It concludes with a short evaluation
report (`intake/mobiliar/evaluation.md` or a section in the `README.md`)
naming **concrete** fixture-field enrichments for Task 5 to implement (e.g.
specific product lines, claim statuses, additional lead-cluster examples,
richer activity types) — grounded in what the Mobiliar reference artefacts
actually show, not invented.

**Allowed scope (paths):** `intake/mobiliar/**` (excluding the already
git-ignored `.raw/`/`.scan/` raw contents — only governance artefacts are
committed).

**Verification commands:**
```
pwsh scripts/solution/Test-IntakeSnapshot.ps1 -IntakeRoot intake/mobiliar
```

**Guardrails:** Inherit `SUPERPOWERS_CONTRACT.md` §1 rules 1 and 3 exactly as
`intake/contoso-insurance/README.md` already states them for that source —
this stream must state and follow the identical boundary for Mobiliar. Never
commit raw exported web resources, customer-branded content, or
source-environment identifiers — only sanitized structural metadata, counts,
classifications, and design decisions, exactly as the existing
`intake/mobiliar/.scan/source-scan.json` PII scan already demonstrates
(13 matches: `EmailAddress`, `SourceEnvironment` — these categories must not
leak into any committed governance artefact).

**Escalation rule:** If the existing `.raw`/`.scan` snapshot looks stale or
incomplete for the governance write-up, regenerate it per
`intake/contoso-insurance/README.md`'s own "Regeneration" steps
(`Export-Solution.ps1` → `Unpack-Solution.ps1` → `Test-IntakeSnapshot.ps1` →
`New-SolutionBom.ps1`) rather than writing governance docs against
known-stale data.

- [ ] Confirm/regenerate the `.raw`/`.scan` snapshot if stale.
- [ ] Write `intake/mobiliar/README.md` mirroring the contoso-insurance boundary language.
- [ ] Write `intake/mobiliar/bom/` (component inventory) via `New-SolutionBom.ps1`.
- [ ] Write `intake/mobiliar/mappings/` documenting source-concept → Advisor Cockpit fixture/concept mapping.
- [ ] Write the evaluation report naming concrete fixture enrichments for Task 5.
- [ ] Run `Test-IntakeSnapshot.ps1` against `intake/mobiliar` and confirm it passes (no PII categories in committed files).
- [ ] Commit and report `DONE` back to the control plane.

---

## Task 4: `tenant-user-inventory` stream (DESIGN-SENSITIVE)

**Worktree setup:**

```powershell
New-SprintWorktree -SprintId 'sprint-004' -StreamId 'tenant-user-inventory' `
  -IssueNumber <N4> -AutonomyClass 'DESIGN-SENSITIVE' -DesignRef 'docs/superpowers/specs/2026-08-17-advisor-cockpit-demo-data-design.md'
```

Classed DESIGN-SENSITIVE (not EXECUTION-ONLY) because "how to safely resolve
a presenter identity with no personal data committed" is a genuine design
question the design spec resolved at a principle level but not at the exact
OData-query level — the attended session should confirm the query shape
against a live environment before it is treated as settled.

**Files:**
- Create: `scripts/solution/Get-DemoPresenterUser.ps1`
- Test: `scripts/solution/tests/Get-DemoPresenterUser.Tests.ps1`

**Goal / Definition of Done:** A new `Get-DemoPresenterUser.ps1` script,
following the exact dot-source-safe pattern of `seed-advisor-cockpit.ps1`
(non-mandatory params, auto-invoke only when run directly), exposes:

```powershell
function Get-DemoPresenterUser {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string]$EnvironmentUrl,
        [string]$PresenterUserId
    )
    if ($PresenterUserId) { return $PresenterUserId }

    $baseUrl = $EnvironmentUrl.TrimEnd('/')
    $url = "$baseUrl/api/data/v9.2/systemusers?" +
        "`$select=systemuserid,fullname,accessmode&`$filter=isdisabled eq false&" +
        "`$expand=systemuserroles_association(`$select=name)"
    $response = az rest --method GET --url $url --resource "$baseUrl/" --only-show-errors | ConvertFrom-Json

    $admins = @($response.value | Where-Object {
        $_.accessmode -eq 0 -and
        @($_.systemuserroles_association | ForEach-Object { $_.name }) -contains 'System Administrator'
    })

    if ($admins.Count -eq 0) {
        throw "No enabled, interactive System Administrator found in '$EnvironmentUrl'. Refusing to seed ownerless demo data — pass -PresenterUserId explicitly if this is intentional."
    }
    if ($admins.Count -gt 1) {
        Write-Warning "Get-DemoPresenterUser: $($admins.Count) System Administrators found; using the first alphabetically by fullname."
    }
    $chosen = @($admins | Sort-Object fullname)[0]
    return [string]$chosen.systemuserid
}

if ($MyInvocation.InvocationName -ne '.') {
    param([string]$EnvironmentUrl, [string]$PresenterUserId)
    Get-DemoPresenterUser -EnvironmentUrl $EnvironmentUrl -PresenterUserId $PresenterUserId
}
```

`accessmode -eq 0` is Dataverse's "Read-Write" (interactive) value — this is
what excludes the CI application users provisioned by
`infra/scripts/add-ci-app-users.ps1` per ADR-0005 (application users are
typically `accessmode = 4`, Non-interactive). Confirm this against the live
DEV/TEST environment during the attended session (query both a known CI app
user and a known interactive admin and diff their `accessmode` values) before
treating the filter as final — if the live values differ from this
assumption, adjust the filter and note the correction in the packet.

- [ ] **Step 1: Write the failing test**

```powershell
BeforeAll {
    . "$PSScriptRoot/../Get-DemoPresenterUser.ps1"
}

Describe 'Get-DemoPresenterUser' {
    It 'returns the explicit override without calling az rest' {
        Mock az {}
        $result = Get-DemoPresenterUser -EnvironmentUrl 'https://crmshowdev.crm.dynamics.com' -PresenterUserId '11111111-1111-1111-1111-111111111111'
        $result | Should -Be '11111111-1111-1111-1111-111111111111'
        Should -Invoke -CommandName az -Times 0 -Exactly
    }

    It 'resolves the single enabled interactive System Administrator' {
        Mock az {
            '{"value":[{"systemuserid":"aaa","fullname":"Rahel Moser","accessmode":0,"systemuserroles_association":[{"name":"System Administrator"}]},{"systemuserid":"bbb","fullname":"CI App User","accessmode":4,"systemuserroles_association":[{"name":"System Administrator"}]}]}'
        }
        $result = Get-DemoPresenterUser -EnvironmentUrl 'https://crmshowdev.crm.dynamics.com'
        $result | Should -Be 'aaa'
    }

    It 'picks the alphabetically-first fullname and warns when multiple admins are found' {
        Mock az {
            '{"value":[{"systemuserid":"zzz","fullname":"Zoe Admin","accessmode":0,"systemuserroles_association":[{"name":"System Administrator"}]},{"systemuserid":"aaa","fullname":"Anna Admin","accessmode":0,"systemuserroles_association":[{"name":"System Administrator"}]}]}'
        }
        $result = Get-DemoPresenterUser -EnvironmentUrl 'https://crmshowdev.crm.dynamics.com' -WarningVariable warnings -WarningAction SilentlyContinue
        $result | Should -Be 'aaa'
        $warnings | Should -Not -BeNullOrEmpty
    }

    It 'throws when no enabled interactive System Administrator is found' {
        Mock az { '{"value":[]}' }
        { Get-DemoPresenterUser -EnvironmentUrl 'https://crmshowdev.crm.dynamics.com' } | Should -Throw
    }

    It 'excludes a disabled or non-interactive System Administrator' {
        Mock az {
            '{"value":[{"systemuserid":"ci","fullname":"CI App User","accessmode":4,"systemuserroles_association":[{"name":"System Administrator"}]}]}'
        }
        { Get-DemoPresenterUser -EnvironmentUrl 'https://crmshowdev.crm.dynamics.com' } | Should -Throw
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `Invoke-Pester -Path scripts/solution/tests/Get-DemoPresenterUser.Tests.ps1 -Output Detailed`
Expected: FAIL — `Get-DemoPresenterUser.ps1` does not exist yet.

- [ ] **Step 3: Write `scripts/solution/Get-DemoPresenterUser.ps1`** with the implementation shown above.

- [ ] **Step 4: Run test to verify it passes**

Run: `Invoke-Pester -Path scripts/solution/tests/Get-DemoPresenterUser.Tests.ps1 -Output Detailed`
Expected: PASS, 5/5.

- [ ] **Step 5: Attended live confirmation**

Against the real `crmshowdev` environment (ask the control plane for the URL
if not already available in the worktree shell), run:

```powershell
. scripts/solution/Get-DemoPresenterUser.ps1
Get-DemoPresenterUser -EnvironmentUrl 'https://<crmshowdev-url>'
```

Confirm it resolves exactly one `systemuserid` and that this corresponds to
a real, loggable-in System Administrator account (not the CI app user). If
the live `accessmode` values differ from the assumption above, fix the
filter and re-run Steps 1-4.

- [ ] **Step 6: Commit**

```bash
git add scripts/solution/Get-DemoPresenterUser.ps1 scripts/solution/tests/Get-DemoPresenterUser.Tests.ps1
git commit -m "feat(seed): add Get-DemoPresenterUser to resolve the DEV/TEST System Administrator

Resolves the presenter identity for personalized demo ownership at
runtime, by role + enabled + interactive state (accessmode=0) — never
a committed UPN/e-mail. Supports an explicit -PresenterUserId override."
```

Report `DONE` back to the control plane (do not push/open PR).

---

## Task 5: `fixture-enrichment` stream (DESIGN-SENSITIVE)

**Worktree setup:**

```powershell
New-SprintWorktree -SprintId 'sprint-004' -StreamId 'fixture-enrichment' `
  -IssueNumber <N5> -AutonomyClass 'DESIGN-SENSITIVE' -DesignRef 'docs/superpowers/specs/2026-08-17-advisor-cockpit-demo-data-design.md'
```

**Depends on:** Task 3's evaluation report (`intake/mobiliar/README.md` or
`evaluation.md`) — read it first; it names the concrete enrichments this
stream implements. Do not start this stream until Task 3 has merged (or at
minimum, until its evaluation report is committed on its own branch and can
be read).

**Goal / Definition of Done:** `data/scenarios/advisor-cockpit/*.json`
(`accounts-contacts.json`, `leads.json`, `policies.json`, `claims.json`,
`activities.json` — `measures.json` and `nba.json` are out of scope unless
Task 3's report specifically calls for a change there) are enriched per
Task 3's concrete findings, while staying within the 7 existing fixture
files and their existing shapes (no new entity types, no schema change).
Every new record stays synthetic and Contoso-Insurance-branded: e-mail
addresses on the reserved `.example` domain, phone numbers with the `555`
fictional marker, GA **Bern-Mittelland**, advisor **Rahel Moser** — per
`data/scenarios/advisor-cockpit/README.md`'s existing convention. Update that
README's fixture table/description if new record categories are added.

**Allowed scope (paths):** `data/scenarios/advisor-cockpit/**` only. Do not
touch `seed-advisor-cockpit.ps1` (Task 6's scope) or any schema file.

**Verification commands:**
```
pwsh scripts/solution/tests/SeedAdvisorCockpit.Tests.ps1
```
(the existing `Get-SeedPlan` tests already assert every fixture file parses
and has a non-empty alternate key per record group — enriched fixtures must
keep passing this unchanged.) Additionally validate `measures.json` (if
touched) against `api/advisor-cockpit/measure-snapshot.schema.json` using
whatever schema-validation approach the repo already uses for that contract
(check `api/advisor-cockpit/` for an existing validation script/test first).

**Guardrails:** SUPERPOWERS_CONTRACT.md §1 rule 3 (no real customer data) is
the binding constraint here — Task 3's Mobiliar findings inform *what kind*
of data is realistic (e.g. typical Swiss motor/household/legal-protection
product mix, claim status vocabulary), never real names/values copied from
the Mobiliar source.

**Escalation rule:** If Task 3's evaluation report is ambiguous about what to
change, or a proposed enrichment would require a new fixture field with no
existing schema column, STOP, write `BLOCKED: needs design`, and surface the
question rather than inventing a schema change unilaterally (schema changes
are Enterprise Architect / Dataverse Modeler territory per `AGENTS.md`).

- [ ] Read Task 3's evaluation report.
- [ ] Enrich the named fixture files, keeping every synthetic-data convention from `data/scenarios/advisor-cockpit/README.md`.
- [ ] Update `data/scenarios/advisor-cockpit/README.md` if the fixture shape/description changed.
- [ ] Run `SeedAdvisorCockpit.Tests.ps1` and confirm it still passes.
- [ ] Commit and report `DONE` back to the control plane.

---

## Task 6: `seed-owner-wiring` stream (EXECUTION-ONLY)

**Depends on:** Task 4 (`Get-DemoPresenterUser.ps1` merged or at least
readable on its branch) and Task 5 (enriched fixtures).

**Worktree setup:**

```powershell
New-SprintWorktree -SprintId 'sprint-004' -StreamId 'seed-owner-wiring' `
  -IssueNumber <N6> -AutonomyClass 'EXECUTION-ONLY' -DesignRef 'docs/superpowers/specs/2026-08-17-advisor-cockpit-demo-data-design.md'
```

**Files:**
- Modify: `scripts/solution/seed-advisor-cockpit.ps1`
- Modify: `scripts/solution/tests/SeedAdvisorCockpit.Tests.ps1`
- Modify: `.github/workflows/cd-solution-test.yml`

- [ ] **Step 1: Write the failing test for owner-assignment on the account upsert body**

Add to `scripts/solution/tests/SeedAdvisorCockpit.Tests.ps1`:

```powershell
It 'sets ownerid@odata.bind on the account upsert body when a presenter is supplied' {
    $row = [pscustomobject]@{ key = 'ACC-BRUNNER'; name = 'Brunner Household'; accountType = 'Household' }
    $body = ConvertTo-AccountUpsertBody -Row $row -PresenterUserId 'aaa-bbb-ccc'
    $body.'ownerid@odata.bind' | Should -Be '/systemusers(aaa-bbb-ccc)'
}

It 'omits ownerid@odata.bind on the account upsert body when no presenter is supplied' {
    $row = [pscustomobject]@{ key = 'ACC-BRUNNER'; name = 'Brunner Household'; accountType = 'Household' }
    $body = ConvertTo-AccountUpsertBody -Row $row
    $body.Contains('ownerid@odata.bind') | Should -BeFalse
}

It 'passes -PresenterUserId through Invoke-AdvisorCockpitSeed into Get-AccountUpsertRequests' {
    Mock Get-DemoPresenterUser { 'resolved-presenter-id' }
    Mock Get-AccountKeyMap { [ordered]@{} }
    Mock Get-MeasureUpsertRequests { @() }
    Mock Get-AccountUpsertRequests { @() }
    Mock Get-ClaimUpsertRequests { @() }
    Mock Invoke-DataverseRequest { }
    Invoke-AdvisorCockpitSeed -EnvironmentUrl 'https://crmshowdev.crm.dynamics.com' -Confirm:$false
    Should -Invoke -CommandName Get-AccountUpsertRequests -Times 1 -Exactly -ParameterFilter {
        $PresenterUserId -eq 'resolved-presenter-id'
    }
}
```

> **Repo convention note (confirmed 2026-08-17 while implementing Task 4):**
> this codebase's actual, dominant mocking-assertion convention is
> `Should -Invoke -CommandName <Name> -Times N -Exactly [-ParameterFilter {...}]`
> (see `SeedAdvisorCockpit.Tests.ps1`, `Set-SolutionVersions.Tests.ps1`,
> `Test-InsuranceFoundationConvergence.Tests.ps1`, etc.) — **not**
> `Assert-MockCalled`, which is Pester v3/v4-era syntax that intermittently
> fails to load under this repo's pinned Pester 6.0.1 (`Import-Module Pester
> -RequiredVersion 6.0.1`, per `cd-solution-dev.yml`/`cd-solution-test.yml`).
> Always run `Import-Module Pester -RequiredVersion 6.0.1 -Force` before
> `Invoke-Pester` locally to match CI exactly. Use `Should -Invoke` in every
> task above, including Task 1's test.

- [ ] **Step 2: Run test to verify it fails**

Run: `Invoke-Pester -Path scripts/solution/tests/SeedAdvisorCockpit.Tests.ps1 -Output Detailed`
Expected: FAIL — `ConvertTo-AccountUpsertBody` has no `-PresenterUserId`
parameter yet, and `Invoke-AdvisorCockpitSeed` does not call
`Get-DemoPresenterUser`.

- [ ] **Step 3: Wire owner assignment**

In `seed-advisor-cockpit.ps1`:
1. Add `. "$PSScriptRoot/Get-DemoPresenterUser.ps1"` near the top (after the
   existing `$ErrorActionPreference = 'Stop'`).
2. Add an optional `-PresenterUserId` parameter to
   `ConvertTo-AccountUpsertBody`, `Get-AccountUpsertRequests`, and
   `Invoke-AdvisorCockpitSeed`, threading it through:

```powershell
function ConvertTo-AccountUpsertBody {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] $Row,
        [string]$PresenterUserId
    )
    $body = [ordered]@{
        name                = [string]$Row.name
        crmshow_accounttype = ConvertTo-GlobalChoiceValue -Code ([string]$Row.accountType) -KnownCodes @('Household', 'Business', 'Broker')
        crmshow_seedkey     = [string]$Row.key
    }
    if ($PresenterUserId) { $body.'ownerid@odata.bind' = "/systemusers($PresenterUserId)" }
    return $body
}
```
Update `Get-AccountUpsertRequests` to accept and forward `-PresenterUserId`
to `ConvertTo-AccountUpsertBody`. Update `Invoke-AdvisorCockpitSeed` to
resolve the presenter once via `Get-DemoPresenterUser -EnvironmentUrl
$EnvironmentUrl` when no `-PresenterUserId` was passed by the caller, and
forward it into `Get-AccountUpsertRequests`. Follow the exact same
"resolve-if-not-supplied" pattern already used for `$AccountKeyMap` via
`Get-AccountKeyMap` a few lines above it in the same function.

- [ ] **Step 4: Run test to verify it passes**

Run: `Invoke-Pester -Path scripts/solution/tests/SeedAdvisorCockpit.Tests.ps1 -Output Detailed`
Expected: PASS, full file green (22 previous + 3 new = 25/25).

- [ ] **Step 5: Add the TEST seed step to `cd-solution-test.yml`**

Read `.github/workflows/cd-solution-dev.yml` around its existing "Seed
Advisor Cockpit demo data" step (line ~154) and its smoke-check step, and add
the equivalent two steps (seed + smoke-check) to `cd-solution-test.yml` at
the corresponding point in its `import`/`promote` job (immediately after the
solution import step, mirroring the DEV job's placement relative to its own
export step). Reuse the same `seed-advisor-cockpit.ps1
-EnvironmentUrl $env:POWER_PLATFORM_ENV_URL -Confirm:$false` invocation
style and the same measures-based smoke-check query
(`crmshow_measuresnapshots`, unconditionally seeded) already used in
`cd-solution-dev.yml`.

- [ ] **Step 6: Validate workflow YAML syntax**

```powershell
python -c "import yaml; yaml.safe_load(open('.github/workflows/cd-solution-test.yml'))"
```
Expected: no output, no error (mirrors how the sprint-003 STATUS.md recorded
the same YAML-syntax check for the DEV pipeline step).

- [ ] **Step 7: Commit**

```bash
git add scripts/solution/seed-advisor-cockpit.ps1 scripts/solution/tests/SeedAdvisorCockpit.Tests.ps1 .github/workflows/cd-solution-test.yml
git commit -m "feat(seed): wire presenter ownerid into account upserts; add TEST seed step

Accounts/leads/activities/NBA seeded by seed-advisor-cockpit.ps1 are now
owned by the resolved DEV/TEST System Administrator (Get-DemoPresenterUser),
supporting a personalized live demo. cd-solution-test.yml gains the same
seed + smoke-check step cd-solution-dev.yml already has, so TEST is no
longer left without demo data."
```

Report `DONE` back to the control plane (do not push/open PR).

---

## Task 7: `e2e-dev-test-verify` stream (EXECUTION-ONLY)

**Depends on:** Tasks 1, 2 (both prerequisite blockers resolved) and Task 6
(owner-wiring + TEST seed step merged).

**Worktree setup:**

```powershell
New-SprintWorktree -SprintId 'sprint-004' -StreamId 'e2e-dev-test-verify' `
  -IssueNumber <N7> -AutonomyClass 'EXECUTION-ONLY' -DesignRef 'docs/superpowers/specs/2026-08-17-advisor-cockpit-demo-data-design.md'
```

**Files:**
- Modify: `docs/superpowers/sprints/sprint-004-advisor-cockpit-demo-data/STATUS.md`

- [ ] **Step 1: Dispatch `cd-solution-dev.yml`**

```powershell
gh workflow run cd-solution-dev.yml --repo urruegg/CRMShowcase
gh run list --repo urruegg/CRMShowcase --workflow cd-solution-dev.yml --limit 1
```
Wait for completion; record the run URL and, from its logs, the offline
Pester pass/fail counts (e.g. "N passed, 0 failed, M skipped").

- [ ] **Step 2: Confirm the DEV smoke-check**

From the same run's logs, confirm the "Seed Advisor Cockpit demo data" and
its smoke-check step both succeeded, and that a manual spot-check query
against `crmshowdev` shows at least one seeded `account` with `ownerid`
resolved to the presenter identity from Task 4/6 (not blank, not the CI app
user):
```powershell
az rest --method GET --url "https://<crmshowdev-url>/api/data/v9.2/accounts?`$select=name,_ownerid_value&`$filter=crmshow_seedkey ne null&`$top=1" --resource "https://<crmshowdev-url>/"
```

- [ ] **Step 3: Dispatch TEST promotion**

```powershell
gh workflow run cd-solution-test.yml --repo urruegg/CRMShowcase
gh run list --repo urruegg/CRMShowcase --workflow cd-solution-test.yml --limit 1
```
Wait for completion; record the run URL and build a step-by-step result
table (one row per pipeline step, ✅/❌/⚠️, any defects found+fixed called
out), mirroring
`docs/superpowers/sprints/sprint-002-insurance-foundation-promotion/STATUS.md`'s
"Live promotion evidence" section format. Confirm the `crmshow_Sales`
missing-dependency error from #121 no longer occurs (Task 2's fix must have
already landed).

- [ ] **Step 4: Confirm the TEST smoke-check + seeded ownership**

Same spot-check as Step 2, against `crmshowtest`.

- [ ] **Step 5: Write the `## Live DEV + TEST evidence` section**

In `docs/superpowers/sprints/sprint-004-advisor-cockpit-demo-data/STATUS.md`,
add:
```markdown
## Live DEV + TEST evidence

**DEV** — run <url>, offline Pester: <N> passed, 0 failed, <M> skipped.
Seed + smoke-check green; sample seeded account ownerid confirmed resolved
to <presenter systemuserid>, not the CI application user.

**TEST** — promotion run <url>. Step-by-step result:

| Step | Result | Notes |
| --- | --- | --- |
| ... | ✅/❌/⚠️ | ... |

TEST-side seed + smoke-check: <result>. #120, #121, #124 confirmed resolved
(no missing-dependency error, no Lookup-creation error, schema matches
source control).
```

- [ ] **Step 6: Commit**

```bash
git add docs/superpowers/sprints/sprint-004-advisor-cockpit-demo-data/STATUS.md
git commit -m "docs(sprint-004): record live DEV+TEST evidence, close #120/#121/#124"
```

Report `DONE` back to the control plane (do not push/open PR).

---

## Stream intake (control plane — after each task's two-stage review passes)

For each completed task above, the control plane (not the implementer
subagent) runs:

```powershell
. scripts/orchestration/Complete-StreamIntake.ps1
Complete-StreamIntake -WorktreePath 'C:\Users\urruegg\source\urruegg\wt\sprint-004-<stream>' `
  -Branch 'feat/sprint-004-<stream>' -IssueNumber <N> `
  -Title '<matching the stream issue title>'
```

This pushes the branch and opens a PR against `main` — it never merges.
Merge is a human act (branch protection + CODEOWNERS + CI). After merge, the
control plane retires the worktree:

```powershell
. scripts/orchestration/Remove-SprintWorktree.ps1
Remove-SprintWorktree -SprintId 'sprint-004' -StreamId '<stream>'
```

Update the stream's row in `sprint.md`'s Streams table and update
`STATUS.md` after each PR opens and after each merge, following the exact
narrative style of `sprint-003-advisor-cockpit/STATUS.md`.

---

## Final step: finishing the sprint

Once all 7 streams are merged and Task 7's evidence section is committed,
use **superpowers:finishing-a-development-branch** for the charter-tracking
branch (if the control plane itself accumulated any commits beyond Task 0 on
a dedicated branch), and close the Sprint-004 charter issue referencing the
`## Live DEV + TEST evidence` section, mirroring how sprint-003's STATUS.md
closed out.
