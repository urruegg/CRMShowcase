# Advisor Cockpit MDA App + Sitemap Authoring Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build an idempotent, testable PowerShell reconciliation script that authors the "Advisor Cockpit" Model-Driven App (sitemap, app module, component attachments, security-role association) into a Dataverse environment via the Web API, following this repo's established `Publish-InsuranceFoundation.ps1` pattern — with the two already-Maker-Portal-created custom pages attached by referencing their own `uniquename` (resolved to a GUID via a query, the same idiom already used for `crmshow_seedkey` in the seed-pipeline work).

**Architecture:** One new script (`scripts/solution/publish-advisor-cockpit-app.ps1`) with pure, offline-testable "convert row → Web API body" functions plus a live-query resolver and a top-level orchestrator, driven by one new plain JSON contract file (no JSON-Schema-Draft infrastructure — deliberately leaner than `insurance-foundation.json`'s, since this contract describes one app/sitemap/component-list, not a whole data model; see "Scope note" below). Wired into `cd-solution-dev.yml` as a new step after table/choice authoring.

**Tech Stack:** PowerShell 5.1/7, Pester 6.0.1, `az rest` against Dataverse Web API v9.2, GitHub Actions (`cd-solution-dev.yml`).

**Scope note (YAGNI):** `insurance-foundation.json`'s JSON-Schema-Draft-2020-12 validation exists because that contract describes an entire, growing data model (choices, tables, columns, relationships, roles) that benefits from strict schema enforcement. This new contract describes exactly one app, one sitemap, and a short, fixed list of components — a hand-rolled required-keys/types check (Task 2) is proportionate and avoids replicating that heavier infrastructure for a much smaller problem.

**Design doc:** [2026-08-15-advisor-cockpit-mda-app-design.md](../specs/2026-08-15-advisor-cockpit-mda-app-design.md) (approved, merged as PR #108).

---

## Before starting: known blocker

**Task 1 (below) requires a live Dataverse read query.** At plan-writing time,
the `az rest` Dataverse-scoped token had expired (`az account get-access-token`
returned a stale cached expiry; `pac org who` succeeded, confirming the
underlying credential is fine — only `az`'s own token cache for this specific
resource needs a refresh). **Before starting Task 1, run `az login` (or
whatever refresh step is current practice) and confirm with:**

```powershell
az account get-access-token --resource "https://crmshowdev.crm.dynamics.com/" --query "expiresOn" -o tsv
```

If this returns a **future** timestamp, proceed. If `az rest` still returns
`Unauthorized` afterward, use `pac` CLI's own environment tooling or ask the
environment owner to refresh the session — do not guess past this blocker.

---

### Task 1: Confirm live facts (research spike, no code)

**Files:** None (research only — findings get written into Task 4's contract
JSON and Task 6's lookup table).

- [ ] **Step 1: Query an existing app module for reference `clienttype`/`formfactor`/`navigationtype` values**

Run (after confirming auth per "Before starting" above):

```powershell
$baseUrl = "https://crmshowdev.crm.dynamics.com"
$url = "$baseUrl/api/data/v9.2/appmodules?`$select=name,uniquename,clienttype,formfactor,navigationtype&`$top=10"
az rest --method GET --url $url --resource "$baseUrl/" --only-show-errors | ConvertFrom-Json | Select-Object -ExpandProperty value | Format-Table name, uniquename, clienttype, formfactor, navigationtype
```

Expected: a table of existing app modules (e.g. any out-of-box Sales/Service
app already provisioned in this environment) showing their `clienttype`/
`formfactor`/`navigationtype` values. Record these — they become the values
used in Task 4's contract JSON for the new "Advisor Cockpit" app.

- [ ] **Step 2: Query `solutioncomponents` for the general `componenttype` enum, filtered near the custom-page range**

```powershell
$baseUrl = "https://crmshowdev.crm.dynamics.com"
$url = "$baseUrl/api/data/v9.2/solutioncomponents?`$select=componenttype&`$top=1"
az rest --method GET --url $url --resource "$baseUrl/" --only-show-errors
```

This alone won't reveal the custom-page value (the entity only returns rows
that already exist as solution components in this org, and there may be no
custom page in this org yet). If it returns no matching rows, move to Step 3.

- [ ] **Step 3: Create ONE custom page in the Maker Portal (manual, one-time), then read back its own `appmodulecomponent`/`solutioncomponent` row to empirically discover its `componenttype`**

This is the one manual step the design doc already identified as
unavoidable. In the Maker Portal (make.powerapps.com), for the `crmshowdev`
environment: create a new custom page named `crmshow_advisorcockpitpage`
(the first of the two Advisor Cockpit pages), add the `AdvisorCockpit` PCF
control to it, save — do **not** add it to any app module yet. Then run:

```powershell
$baseUrl = "https://crmshowdev.crm.dynamics.com"
$url = "$baseUrl/api/data/v9.2/solutioncomponents?`$select=componenttype,objectid&`$filter=_solutionid_value eq <active-solution-guid>&`$top=50"
az rest --method GET --url $url --resource "$baseUrl/" --only-show-errors | ConvertFrom-Json | Select-Object -ExpandProperty value
```

(Substitute the GUID of whatever unmanaged solution the custom page landed
in — typically the environment's default solution unless you set the active
solution context in the Maker Portal first.) Find the row whose `objectid`
matches the new page's own GUID (visible in the Maker Portal's page details,
or via `GET /canvasapps?$filter=name eq 'crmshow_advisorcockpitpage'`) and
record its `componenttype` value.

- [ ] **Step 4: Record all three findings directly in this plan file**

Before starting Task 4, replace the three `<CONFIRM-IN-TASK-1>` placeholders
in Task 4's contract JSON with the values found above. This is the only
place in this plan where a value is deliberately left open pending research
— every other task's code is complete as written.

---

### Task 2: Contract loader + minimal validation

**Files:**
- Create: `solution/schema/advisor-cockpit-app.json`
- Create: `scripts/solution/publish-advisor-cockpit-app.ps1`
- Test: `scripts/solution/tests/PublishAdvisorCockpitApp.Tests.ps1`

- [ ] **Step 1: Write the failing test**

Create `scripts/solution/tests/PublishAdvisorCockpitApp.Tests.ps1`:

```powershell
# Pester tests for the Advisor Cockpit MDA app publisher (Sprint 3, #64).
# The script is dot-sourced (non-mandatory params, auto-invoke guard), so no
# Dataverse environment is touched by these tests.

BeforeAll {
    . "$PSScriptRoot/../publish-advisor-cockpit-app.ps1"
}

Describe 'publish-advisor-cockpit-app' {
    It 'loads the contract and validates required top-level keys are present' {
        $contract = Get-AdvisorCockpitAppContract -Path (Join-Path $PSScriptRoot '../../../solution/schema/advisor-cockpit-app.json')
        $contract.sitemap | Should -Not -BeNullOrEmpty
        $contract.appModule | Should -Not -BeNullOrEmpty
        $contract.components | Should -Not -BeNullOrEmpty
        $contract.securityRoles | Should -Not -BeNullOrEmpty
    }

    It 'throws a clear error when a required top-level key is missing' {
        $tmp = Join-Path $TestDrive 'bad-contract.json'
        '{"sitemap": {}}' | Set-Content -LiteralPath $tmp -Encoding UTF8
        { Get-AdvisorCockpitAppContract -Path $tmp } | Should -Throw '*appModule*'
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `Invoke-Pester -Path ./scripts/solution/tests/PublishAdvisorCockpitApp.Tests.ps1 -Output Detailed`
Expected: FAIL — `publish-advisor-cockpit-app.ps1` does not exist yet.

- [ ] **Step 3: Write the contract JSON**

Create `solution/schema/advisor-cockpit-app.json`:

```json
{
  "contractId": "crmshow.advisor-cockpit-app",
  "version": "1.0.0",
  "publisherUniqueName": "urruegg",
  "sitemap": {
    "uniqueName": "crmshow_advisorcockpitsitemap",
    "name": "Advisor Cockpit Sitemap",
    "isAppAware": true,
    "showHome": false,
    "showPinned": false,
    "showRecents": false,
    "enableCollapsibleGroups": false,
    "areas": [
      {
        "id": "area_advisorcockpit",
        "title": "Advisor Cockpit",
        "groups": [
          {
            "id": "group_cockpit",
            "title": "Cockpit",
            "subAreas": [
              { "id": "sub_advisorcockpit", "title": "Beratercockpit", "pageUniqueName": "crmshow_advisorcockpitpage" },
              { "id": "sub_salesleaderdashboard", "title": "F\u00fchrungsdashboard", "pageUniqueName": "crmshow_salesleaderdashboardpage" }
            ]
          }
        ]
      }
    ]
  },
  "appModule": {
    "uniqueName": "crmshow_advisorcockpitapp",
    "name": "Advisor Cockpit",
    "description": "Sales advisory cockpit and leader dashboard for the CRM Showcase.",
    "clientType": "<CONFIRM-IN-TASK-1>",
    "formFactor": "<CONFIRM-IN-TASK-1>",
    "navigationType": 0
  },
  "components": [
    { "type": "Sitemap", "referenceKind": "sitemapUniqueName", "reference": "crmshow_advisorcockpitsitemap" },
    { "type": "CustomPage", "referenceKind": "pageUniqueName", "reference": "crmshow_advisorcockpitpage" },
    { "type": "CustomPage", "referenceKind": "pageUniqueName", "reference": "crmshow_salesleaderdashboardpage" }
  ],
  "securityRoles": [
    "CRM Showcase Insurance Reader"
  ]
}
```

- [ ] **Step 4: Write the minimal implementation**

Create `scripts/solution/publish-advisor-cockpit-app.ps1`:

```powershell
<#
.SYNOPSIS
    Authors the Advisor Cockpit Model-Driven App into a Dataverse environment.
.DESCRIPTION
    Reads solution/schema/advisor-cockpit-app.json and idempotently reconciles
    the sitemap, app module, component attachments and security-role
    association via the Dataverse Web API (az rest). Authentication is
    acquired at runtime by `az rest` -- no connection strings.

    The two custom pages this app hosts (crmshow_advisorcockpitpage,
    crmshow_salesleaderdashboardpage) must already exist -- their canvas
    content has no Web API/CLI authoring path (Maker Portal only, confirmed
    Sprint 3). This script resolves them by uniquename via a live query
    (Get-CustomPageIdMap), the same idiom already used for account
    resolution in seed-advisor-cockpit.ps1.

    Safe to dot-source for testing: the top-level parameters are
    non-mandatory and the publish action runs only when the script is
    invoked directly with an -EnvironmentUrl.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$EnvironmentUrl,
    [string]$ContractPath
)

$ErrorActionPreference = 'Stop'

if (-not $ContractPath) {
    $ContractPath = (Resolve-Path (Join-Path $PSScriptRoot '../../solution/schema/advisor-cockpit-app.json')).Path
}
$script:ContractPath = $ContractPath

# Loads the contract and throws a clear error naming the missing key, rather
# than a generic PowerShell null-reference failure deeper in the script.
function Get-AdvisorCockpitAppContract {
    [CmdletBinding()]
    param([Parameter(Mandatory)] [string]$Path)

    $contract = (Get-Content -LiteralPath $Path -Raw -Encoding UTF8) | ConvertFrom-Json
    foreach ($required in @('sitemap', 'appModule', 'components', 'securityRoles')) {
        if (-not $contract.PSObject.Properties.Name.Contains($required)) {
            throw "Advisor Cockpit app contract is missing required key '$required'."
        }
    }
    return $contract
}

if ($MyInvocation.InvocationName -ne '.') {
    if ($EnvironmentUrl) {
        Write-Output 'Dry run scaffold -- publish orchestration lands in a later task.'
    }
    else {
        $contract = Get-AdvisorCockpitAppContract -Path $script:ContractPath
        Write-Output ("Contract loaded: app '{0}', {1} components, {2} security role(s)." -f $contract.appModule.name, @($contract.components).Count, @($contract.securityRoles).Count)
    }
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `Invoke-Pester -Path ./scripts/solution/tests/PublishAdvisorCockpitApp.Tests.ps1 -Output Detailed`
Expected: PASS (2/2).

- [ ] **Step 6: Commit**

```powershell
git add solution/schema/advisor-cockpit-app.json scripts/solution/publish-advisor-cockpit-app.ps1 scripts/solution/tests/PublishAdvisorCockpitApp.Tests.ps1
git commit -m "feat(sprint-003): add Advisor Cockpit app contract + loader (#64)"
```

---

### Task 3: `ConvertTo-GlobalChoiceValue`-style helper is not needed here — app module/sitemap fields are plain strings/ints, not GlobalChoice options. Skip to Task 4.

---

### Task 4: `ConvertTo-SitemapUpsertBody`

**Files:**
- Modify: `scripts/solution/publish-advisor-cockpit-app.ps1`
- Test: `scripts/solution/tests/PublishAdvisorCockpitApp.Tests.ps1`

- [ ] **Step 1: Write the failing test**

Add to `PublishAdvisorCockpitApp.Tests.ps1` (inside the `Describe` block):

```powershell
    It 'converts the contract sitemap section to a sitemapxml payload referencing both custom pages' {
        $contract = Get-AdvisorCockpitAppContract -Path (Join-Path $PSScriptRoot '../../../solution/schema/advisor-cockpit-app.json')
        $body = ConvertTo-SitemapUpsertBody -Sitemap $contract.sitemap
        $body.sitemapname | Should -Be 'Advisor Cockpit Sitemap'
        $body.sitemapnameunique | Should -Be 'crmshow_advisorcockpitsitemap'
        $body.isappaware | Should -BeTrue
        $body.sitemapxml | Should -Match 'crmshow_advisorcockpitpage'
        $body.sitemapxml | Should -Match 'crmshow_salesleaderdashboardpage'
        $body.sitemapxml | Should -Match '<SiteMap>'
    }
```

- [ ] **Step 2: Run test to verify it fails**

Run: `Invoke-Pester -Path ./scripts/solution/tests/PublishAdvisorCockpitApp.Tests.ps1 -Output Detailed`
Expected: FAIL — `ConvertTo-SitemapUpsertBody` is not recognized.

- [ ] **Step 3: Write the implementation**

Add to `publish-advisor-cockpit-app.ps1` (after `Get-AdvisorCockpitAppContract`):

```powershell
# Maps the contract's sitemap section to a sitemap upsert body, generating
# the raw Site Map XML from the structured areas/groups/subAreas -- so the
# XML itself is never hand-maintained as a giant string in the contract.
function ConvertTo-SitemapUpsertBody {
    [CmdletBinding()]
    param([Parameter(Mandatory)] $Sitemap)

    $areasXml = foreach ($area in @($Sitemap.areas)) {
        $groupsXml = foreach ($group in @($area.groups)) {
            $subAreasXml = foreach ($sub in @($group.subAreas)) {
                "<SubArea Id=`"$($sub.id)`" Title=`"$($sub.title)`" Url=`"/main.aspx?pagetype=custom&name=$($sub.pageUniqueName)`" />"
            }
            "<Group Id=`"$($group.id)`" Title=`"$($group.title)`">$($subAreasXml -join '')</Group>"
        }
        "<Area Id=`"$($area.id)`" Title=`"$($area.title)`">$($groupsXml -join '')</Area>"
    }
    $sitemapXml = "<SiteMap>$($areasXml -join '')</SiteMap>"

    [ordered]@{
        sitemapname             = [string]$Sitemap.name
        sitemapnameunique       = [string]$Sitemap.uniqueName
        sitemapxml              = $sitemapXml
        isappaware              = [bool]$Sitemap.isAppAware
        showhome                = [bool]$Sitemap.showHome
        showpinned              = [bool]$Sitemap.showPinned
        showrecents             = [bool]$Sitemap.showRecents
        enablecollapsiblegroups = [bool]$Sitemap.enableCollapsibleGroups
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `Invoke-Pester -Path ./scripts/solution/tests/PublishAdvisorCockpitApp.Tests.ps1 -Output Detailed`
Expected: PASS (3/3).

- [ ] **Step 5: Commit**

```powershell
git add scripts/solution/publish-advisor-cockpit-app.ps1 scripts/solution/tests/PublishAdvisorCockpitApp.Tests.ps1
git commit -m "feat(sprint-003): generate sitemap XML from the app contract (#64)"
```

**Note on the generated URL format:** `pagetype=custom&name=<uniquename>` is
the standard Dataverse custom-page navigation URL pattern. Verify this
against a real custom page's own sitemap entry (e.g. inspect an existing
app with a custom page, if one exists after Task 1 Step 3) before relying
on it in a live run — flagged here rather than asserted as 100% confirmed,
consistent with this plan's other Task-1-dependent facts.

---

### Task 5: `ConvertTo-AppModuleUpsertBody`

**Files:**
- Modify: `scripts/solution/publish-advisor-cockpit-app.ps1`
- Test: `scripts/solution/tests/PublishAdvisorCockpitApp.Tests.ps1`

- [ ] **Step 1: Write the failing test**

```powershell
    It 'converts the contract appModule section to an appmodule upsert body' {
        $contract = Get-AdvisorCockpitAppContract -Path (Join-Path $PSScriptRoot '../../../solution/schema/advisor-cockpit-app.json')
        $body = ConvertTo-AppModuleUpsertBody -AppModule $contract.appModule -PublisherId '11111111-1111-1111-1111-111111111111'
        $body.name | Should -Be 'Advisor Cockpit'
        $body.uniquename | Should -Be 'crmshow_advisorcockpitapp'
        $body.description | Should -Be 'Sales advisory cockpit and leader dashboard for the CRM Showcase.'
        $body.navigationtype | Should -Be 0
        $body.'publisherid@odata.bind' | Should -Be '/publishers(11111111-1111-1111-1111-111111111111)'
    }
```

- [ ] **Step 2: Run test to verify it fails**

Run: `Invoke-Pester -Path ./scripts/solution/tests/PublishAdvisorCockpitApp.Tests.ps1 -Output Detailed`
Expected: FAIL — `ConvertTo-AppModuleUpsertBody` is not recognized.

- [ ] **Step 3: Write the implementation**

Add to `publish-advisor-cockpit-app.ps1`:

```powershell
# Maps the contract's appModule section to an appmodule upsert body.
# PublisherId is resolved by the caller (a live lookup, not part of the
# contract) since the publisher already exists for every other solution
# component in this repo -- see Get-PublisherId.
function ConvertTo-AppModuleUpsertBody {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] $AppModule,
        [Parameter(Mandatory)] [string]$PublisherId
    )

    [ordered]@{
        name                        = [string]$AppModule.name
        uniquename                  = [string]$AppModule.uniqueName
        description                 = [string]$AppModule.description
        clienttype                  = [int]$AppModule.clientType
        formfactor                  = [int]$AppModule.formFactor
        navigationtype              = [int]$AppModule.navigationType
        'publisherid@odata.bind'    = "/publishers($PublisherId)"
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `Invoke-Pester -Path ./scripts/solution/tests/PublishAdvisorCockpitApp.Tests.ps1 -Output Detailed`
Expected: PASS (4/4).

- [ ] **Step 5: Commit**

```powershell
git add scripts/solution/publish-advisor-cockpit-app.ps1 scripts/solution/tests/PublishAdvisorCockpitApp.Tests.ps1
git commit -m "feat(sprint-003): map app module contract section to upsert body (#64)"
```

---

### Task 6: Component-type lookup + `Get-CustomPageIdMap` (live resolver)

**Files:**
- Modify: `scripts/solution/publish-advisor-cockpit-app.ps1`
- Test: `scripts/solution/tests/PublishAdvisorCockpitApp.Tests.ps1`

- [ ] **Step 1: Write the failing tests**

```powershell
    It 'resolves a known component type label to its Dataverse numeric value' {
        ConvertTo-ComponentTypeValue -Type 'Sitemap' | Should -Be 62
    }

    It 'throws on an unknown component type rather than guessing a value' {
        { ConvertTo-ComponentTypeValue -Type 'Dashboard' } | Should -Throw '*Dashboard*'
    }

    It 'builds a custom-page uniquename to GUID map from a live canvasapps query' {
        Mock -CommandName az -MockWith {
            '{"value":[{"canvasappid":"22222222-2222-2222-2222-222222222222","name":"crmshow_advisorcockpitpage"},{"canvasappid":"33333333-3333-3333-3333-333333333333","name":"crmshow_salesleaderdashboardpage"}]}'
        }
        $map = Get-CustomPageIdMap -EnvironmentUrl 'https://example.crm.dynamics.com' -PageUniqueNames @('crmshow_advisorcockpitpage', 'crmshow_salesleaderdashboardpage')
        $map['crmshow_advisorcockpitpage'] | Should -Be '22222222-2222-2222-2222-222222222222'
        $map['crmshow_salesleaderdashboardpage'] | Should -Be '33333333-3333-3333-3333-333333333333'
    }

    It 'throws when a referenced custom page does not exist yet in the environment' {
        Mock -CommandName az -MockWith { '{"value":[]}' }
        { Get-CustomPageIdMap -EnvironmentUrl 'https://example.crm.dynamics.com' -PageUniqueNames @('crmshow_missingpage') } |
            Should -Throw '*crmshow_missingpage*'
    }
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `Invoke-Pester -Path ./scripts/solution/tests/PublishAdvisorCockpitApp.Tests.ps1 -Output Detailed`
Expected: FAIL — `ConvertTo-ComponentTypeValue` and `Get-CustomPageIdMap` not recognized.

- [ ] **Step 3: Write the implementation**

Add to `publish-advisor-cockpit-app.ps1`:

```powershell
# Confirmed appmodulecomponent.componenttype values (Microsoft Learn,
# fetched 2026-08-15). CustomPage's value is filled in from Task 1's
# empirical finding -- update the number below once confirmed; every other
# value here is already documentation-confirmed.
$script:ComponentTypeValues = @{
    Entities = 1
    Views    = 26
    Forms    = 60
    Sitemap  = 62
    CustomPage = -1  # <CONFIRM-IN-TASK-1> -- replace -1 with the real value.
}

function ConvertTo-ComponentTypeValue {
    [CmdletBinding()]
    param([Parameter(Mandatory)] [string]$Type)

    if (-not $script:ComponentTypeValues.ContainsKey($Type)) {
        throw "Unknown component type '$Type'. Known types: $($script:ComponentTypeValues.Keys -join ',')."
    }
    return $script:ComponentTypeValues[$Type]
}

# Resolves each of the given custom-page uniquenames to its live canvasapp
# GUID. Throws immediately naming the missing page rather than silently
# building an incomplete map -- a missing custom page means the Maker
# Portal step (Task 1 Step 3 / design doc) has not happened yet for that
# page, which the caller needs to know about explicitly.
function Get-CustomPageIdMap {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string]$EnvironmentUrl,
        [Parameter(Mandatory)] [string[]]$PageUniqueNames
    )

    $baseUrl = $EnvironmentUrl.TrimEnd('/')
    $filter = ($PageUniqueNames | ForEach-Object { "name eq '$_'" }) -join ' or '
    $url = "$baseUrl/api/data/v9.2/canvasapps?`$select=canvasappid,name&`$filter=$filter"
    $response = az rest --method GET --url $url --resource "$baseUrl/" --only-show-errors | ConvertFrom-Json

    $map = [ordered]@{}
    foreach ($page in @($response.value)) {
        $map[[string]$page.name] = [string]$page.canvasappid
    }
    foreach ($expected in $PageUniqueNames) {
        if (-not $map.Contains($expected)) {
            throw "Custom page '$expected' does not exist yet in $EnvironmentUrl -- create it in the Maker Portal first (see the design doc's Approach A)."
        }
    }
    return $map
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `Invoke-Pester -Path ./scripts/solution/tests/PublishAdvisorCockpitApp.Tests.ps1 -Output Detailed`
Expected: PASS (8/8). Note: the `'resolves a known component type label'`
test passes for `Sitemap` (confirmed value 62); a parallel test for
`CustomPage` is deliberately **not** written yet — add it in a follow-up
once Task 1's value is confirmed, so the test suite doesn't encode an
unconfirmed `-1` as if it were correct.

- [ ] **Step 5: Commit**

```powershell
git add scripts/solution/publish-advisor-cockpit-app.ps1 scripts/solution/tests/PublishAdvisorCockpitApp.Tests.ps1
git commit -m "feat(sprint-003): component-type lookup + custom-page GUID resolver (#64)"
```

---

### Task 7: `Get-AppComponentAddRequests` (idempotent `AddAppComponents` body)

**Files:**
- Modify: `scripts/solution/publish-advisor-cockpit-app.ps1`
- Test: `scripts/solution/tests/PublishAdvisorCockpitApp.Tests.ps1`

- [ ] **Step 1: Write the failing tests**

```powershell
    It 'builds an AddAppComponents request for every contract component not already attached' {
        $contract = Get-AdvisorCockpitAppContract -Path (Join-Path $PSScriptRoot '../../../solution/schema/advisor-cockpit-app.json')
        $resolvedIds = @{
            'crmshow_advisorcockpitsitemap'      = '44444444-4444-4444-4444-444444444444'
            'crmshow_advisorcockpitpage'         = '22222222-2222-2222-2222-222222222222'
            'crmshow_salesleaderdashboardpage'   = '33333333-3333-3333-3333-333333333333'
        }
        $req = Get-AppComponentAddRequests -Components $contract.components -ResolvedIds $resolvedIds -ExistingObjectIds @() -AppId '55555555-5555-5555-5555-555555555555'
        $req.AppId | Should -Be '55555555-5555-5555-5555-555555555555'
        @($req.Components).Count | Should -Be 3
        ($req.Components | Where-Object { $_.sitemapid -eq '44444444-4444-4444-4444-444444444444' }).'@odata.type' | Should -Be 'Microsoft.Dynamics.CRM.sitemap'
    }

    It 'excludes components already attached to the app' {
        $contract = Get-AdvisorCockpitAppContract -Path (Join-Path $PSScriptRoot '../../../solution/schema/advisor-cockpit-app.json')
        $resolvedIds = @{
            'crmshow_advisorcockpitsitemap'      = '44444444-4444-4444-4444-444444444444'
            'crmshow_advisorcockpitpage'         = '22222222-2222-2222-2222-222222222222'
            'crmshow_salesleaderdashboardpage'   = '33333333-3333-3333-3333-333333333333'
        }
        $req = Get-AppComponentAddRequests -Components $contract.components -ResolvedIds $resolvedIds -ExistingObjectIds @('44444444-4444-4444-4444-444444444444') -AppId '55555555-5555-5555-5555-555555555555'
        @($req.Components).Count | Should -Be 2
    }

    It 'returns a null AddAppComponents request when every component is already attached' {
        $contract = Get-AdvisorCockpitAppContract -Path (Join-Path $PSScriptRoot '../../../solution/schema/advisor-cockpit-app.json')
        $resolvedIds = @{
            'crmshow_advisorcockpitsitemap'      = '44444444-4444-4444-4444-444444444444'
            'crmshow_advisorcockpitpage'         = '22222222-2222-2222-2222-222222222222'
            'crmshow_salesleaderdashboardpage'   = '33333333-3333-3333-3333-333333333333'
        }
        $req = Get-AppComponentAddRequests -Components $contract.components -ResolvedIds $resolvedIds -ExistingObjectIds @('44444444-4444-4444-4444-444444444444', '22222222-2222-2222-2222-222222222222', '33333333-3333-3333-3333-333333333333') -AppId '55555555-5555-5555-5555-555555555555'
        $req | Should -BeNullOrEmpty
    }
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `Invoke-Pester -Path ./scripts/solution/tests/PublishAdvisorCockpitApp.Tests.ps1 -Output Detailed`
Expected: FAIL — `Get-AppComponentAddRequests` not recognized.

- [ ] **Step 3: Write the implementation**

Add to `publish-advisor-cockpit-app.ps1`:

```powershell
# Maps a contract component to its @odata.type + id property name, since
# the AddAppComponents payload shape differs per entity type.
function Get-ComponentODataEntity {
    [CmdletBinding()]
    param([Parameter(Mandatory)] [string]$Type)

    switch ($Type) {
        'Sitemap'    { return @{ ODataType = 'Microsoft.Dynamics.CRM.sitemap'; IdProperty = 'sitemapid' } }
        'CustomPage' { return @{ ODataType = 'Microsoft.Dynamics.CRM.canvasapp'; IdProperty = 'canvasappid' } }
        default      { throw "No AddAppComponents entity mapping for component type '$Type'." }
    }
}

# Builds the AddAppComponents request body for every contract component not
# already present in $ExistingObjectIds (idempotent -- re-running this after
# a partial success only adds what's missing). Returns $null when there is
# nothing left to add, so the caller can skip the Web API call entirely.
function Get-AppComponentAddRequests {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] $Components,
        [Parameter(Mandatory)] [System.Collections.IDictionary]$ResolvedIds,
        [string[]]$ExistingObjectIds = @(),
        [Parameter(Mandatory)] [string]$AppId
    )

    $entries = foreach ($component in @($Components)) {
        $resolvedId = $ResolvedIds[[string]$component.reference]
        if (-not $resolvedId) {
            throw "No resolved id for component reference '$($component.reference)' (referenceKind '$($component.referenceKind)')."
        }
        if ($ExistingObjectIds -contains $resolvedId) {
            continue
        }
        $entity = Get-ComponentODataEntity -Type $component.type
        [ordered]@{
            '@odata.type'    = $entity.ODataType
            $entity.IdProperty = $resolvedId
        }
    }

    if (@($entries).Count -eq 0) {
        return $null
    }

    [pscustomobject]@{
        AppId      = $AppId
        Components = @($entries)
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `Invoke-Pester -Path ./scripts/solution/tests/PublishAdvisorCockpitApp.Tests.ps1 -Output Detailed`
Expected: PASS (11/11).

- [ ] **Step 5: Commit**

```powershell
git add scripts/solution/publish-advisor-cockpit-app.ps1 scripts/solution/tests/PublishAdvisorCockpitApp.Tests.ps1
git commit -m "feat(sprint-003): idempotent AddAppComponents request builder (#64)"
```

---

### Task 8: `Get-AppRoleAssociationRequests`

**Files:**
- Modify: `scripts/solution/publish-advisor-cockpit-app.ps1`
- Test: `scripts/solution/tests/PublishAdvisorCockpitApp.Tests.ps1`

- [ ] **Step 1: Write the failing tests**

```powershell
    It 'builds an associate request for each contract security role not already associated' {
        $roleIds = @{ 'CRM Showcase Insurance Reader' = '66666666-6666-6666-6666-666666666666' }
        $reqs = @(Get-AppRoleAssociationRequests -SecurityRoles @('CRM Showcase Insurance Reader') -RoleIds $roleIds -ExistingRoleIds @() -AppId '55555555-5555-5555-5555-555555555555')
        $reqs.Count | Should -Be 1
        $reqs[0].Path | Should -Be "/appmodules(55555555-5555-5555-5555-555555555555)/appmoduleroles_association/`$ref"
        $reqs[0].Body.'@odata.id' | Should -Match 'roles\(66666666-6666-6666-6666-666666666666\)'
    }

    It 'skips a role that is already associated' {
        $roleIds = @{ 'CRM Showcase Insurance Reader' = '66666666-6666-6666-6666-666666666666' }
        $reqs = @(Get-AppRoleAssociationRequests -SecurityRoles @('CRM Showcase Insurance Reader') -RoleIds $roleIds -ExistingRoleIds @('66666666-6666-6666-6666-666666666666') -AppId '55555555-5555-5555-5555-555555555555')
        $reqs.Count | Should -Be 0
    }

    It 'throws when a contract security role does not resolve to a live role id' {
        { Get-AppRoleAssociationRequests -SecurityRoles @('Unknown Role') -RoleIds @{} -ExistingRoleIds @() -AppId '55555555-5555-5555-5555-555555555555' } |
            Should -Throw '*Unknown Role*'
    }
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `Invoke-Pester -Path ./scripts/solution/tests/PublishAdvisorCockpitApp.Tests.ps1 -Output Detailed`
Expected: FAIL — `Get-AppRoleAssociationRequests` not recognized.

- [ ] **Step 3: Write the implementation**

Add to `publish-advisor-cockpit-app.ps1`:

```powershell
# Builds one $ref associate request per contract security role not already
# associated with the app. Uses the appmoduleroles_association navigation
# property directly (POST .../$ref), the standard Web API pattern for
# adding one member to an existing many-to-many relationship.
function Get-AppRoleAssociationRequests {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string[]]$SecurityRoles,
        [Parameter(Mandatory)] [System.Collections.IDictionary]$RoleIds,
        [string[]]$ExistingRoleIds = @(),
        [Parameter(Mandatory)] [string]$AppId
    )

    foreach ($roleName in $SecurityRoles) {
        if (-not $RoleIds.Contains($roleName)) {
            throw "No resolved role id for security role '$roleName'."
        }
        $roleId = $RoleIds[$roleName]
        if ($ExistingRoleIds -contains $roleId) {
            continue
        }
        [pscustomobject]@{
            Method = 'POST'
            Path   = "/appmodules($AppId)/appmoduleroles_association/`$ref"
            Body   = @{ '@odata.id' = "roles($roleId)" }
        }
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `Invoke-Pester -Path ./scripts/solution/tests/PublishAdvisorCockpitApp.Tests.ps1 -Output Detailed`
Expected: PASS (14/14).

- [ ] **Step 5: Commit**

```powershell
git add scripts/solution/publish-advisor-cockpit-app.ps1 scripts/solution/tests/PublishAdvisorCockpitApp.Tests.ps1
git commit -m "feat(sprint-003): idempotent security-role association request builder (#64)"
```

---

### Task 9: `Invoke-AdvisorCockpitAppPublish` (orchestrator)

**Files:**
- Modify: `scripts/solution/publish-advisor-cockpit-app.ps1`
- Test: `scripts/solution/tests/PublishAdvisorCockpitApp.Tests.ps1`

**Design note (applies the established repo pattern):**
`Publish-InsuranceFoundation.Tests.ps1` mocks exactly **one** central function
(`Invoke-DataverseRequest`) rather than the raw `az` CLI, because a real
orchestrator makes many differently-shaped calls (GET lookups, PATCH
upserts, POST actions) and mocking `az` itself for every shape is brittle.
This task follows the same pattern: `Invoke-AdvisorCockpitAppRequest` (below)
is the **only** function that calls `az`, handles both GET (returns parsed
JSON) and mutating methods, and is the single mock point for every test in
this task.

- [ ] **Step 1: Write `Invoke-AdvisorCockpitAppRequest` first (the shared, only-caller-of-`az` wrapper) and its own failing test**

Add to `PublishAdvisorCockpitApp.Tests.ps1`:

```powershell
    It 'issues a GET and returns the parsed JSON response' {
        Mock -CommandName az -MockWith { '{"appmoduleid":"55555555-5555-5555-5555-555555555555"}' }
        $result = Invoke-AdvisorCockpitAppRequest -BaseUrl 'https://example.crm.dynamics.com' -Method 'GET' -Path "/appmodules(uniquename='crmshow_advisorcockpitapp')?`$select=appmoduleid"
        $result.appmoduleid | Should -Be '55555555-5555-5555-5555-555555555555'
    }

    It 'issues a PATCH with a body and returns null' {
        Mock -CommandName az -MockWith { $global:LASTEXITCODE = 0 }
        $result = Invoke-AdvisorCockpitAppRequest -BaseUrl 'https://example.crm.dynamics.com' -Method 'PATCH' -Path "/sitemaps(sitemapnameunique='x')" -Body @{ sitemapname = 'x' }
        $result | Should -BeNullOrEmpty
        Should -Invoke -CommandName az -Times 1 -Exactly
    }
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `Invoke-Pester -Path ./scripts/solution/tests/PublishAdvisorCockpitApp.Tests.ps1 -Output Detailed`
Expected: FAIL -- `Invoke-AdvisorCockpitAppRequest` not recognized.

- [ ] **Step 3: Write `Invoke-AdvisorCockpitAppRequest`**

Add to `publish-advisor-cockpit-app.ps1`:

```powershell
# The only function that calls az directly. GET requests return the parsed
# JSON response; mutating requests (PATCH/POST) write the body to a temp
# file (avoids command-line length limits / quoting issues) and return
# null. This single choke point is what every test in this file mocks,
# instead of mocking az itself for each differently-shaped call.
function Invoke-AdvisorCockpitAppRequest {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)] [string]$BaseUrl,
        [Parameter(Mandatory)] [string]$Method,
        [Parameter(Mandatory)] [string]$Path,
        $Body
    )

    $url = "$BaseUrl/api/data/v9.2$Path"
    if ($Method -eq 'GET') {
        $response = az rest --method GET --url $url --resource "$BaseUrl/" --only-show-errors
        if ([string]::IsNullOrWhiteSpace($response)) { return $null }
        return ($response | ConvertFrom-Json)
    }

    if (-not $PSCmdlet.ShouldProcess($url, $Method)) { return $null }
    $tmp = [System.IO.Path]::GetTempFileName()
    try {
        ($Body | ConvertTo-Json -Depth 6) | Set-Content -LiteralPath $tmp -Encoding UTF8
        $headers = @('Content-Type=application/json')
        if ($Method -eq 'PATCH') { $headers += 'If-Match=*' }
        az rest --method $Method --url $url --resource "$BaseUrl/" `
            --headers @headers --body "@$tmp" --only-show-errors | Out-Null
    }
    finally {
        Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
    }
    return $null
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `Invoke-Pester -Path ./scripts/solution/tests/PublishAdvisorCockpitApp.Tests.ps1 -Output Detailed`
Expected: PASS (16/16).

- [ ] **Step 5: Commit**

```powershell
git add scripts/solution/publish-advisor-cockpit-app.ps1 scripts/solution/tests/PublishAdvisorCockpitApp.Tests.ps1
git commit -m "feat(sprint-003): shared Dataverse request wrapper for the app publisher (#64)"
```

- [ ] **Step 6: Write the orchestrator's own failing test**

Add to `PublishAdvisorCockpitApp.Tests.ps1`. This mocks **only**
`Invoke-AdvisorCockpitAppRequest` and `Get-CustomPageIdMap` (both already
tested standalone above) -- not `az` -- exactly matching how
`Publish-InsuranceFoundation.Tests.ps1` mocks `Invoke-DataverseRequest`:

```powershell
    It 'publishes the sitemap, app module, components and role association end to end' {
        Mock -CommandName Get-CustomPageIdMap -MockWith {
            @{
                'crmshow_advisorcockpitpage'       = '22222222-2222-2222-2222-222222222222'
                'crmshow_salesleaderdashboardpage' = '33333333-3333-3333-3333-333333333333'
            }
        }
        Mock -CommandName Invoke-AdvisorCockpitAppRequest -MockWith {
            switch -Regex ($Path) {
                "appmodules\(uniquename=" { return [pscustomobject]@{ appmoduleid = '55555555-5555-5555-5555-555555555555' } }
                "sitemaps\(sitemapnameunique=" { return [pscustomobject]@{ sitemapid = '44444444-4444-4444-4444-444444444444' } }
                '/appmodulecomponents'         { return [pscustomobject]@{ value = @() } }
                'appmoduleroles_association'   { return [pscustomobject]@{ value = @() } }
                default                        { return $null }
            }
        }

        Invoke-AdvisorCockpitAppPublish -EnvironmentUrl 'https://example.crm.dynamics.com' -PublisherId '11111111-1111-1111-1111-111111111111' -RoleIds @{ 'CRM Showcase Insurance Reader' = '66666666-6666-6666-6666-666666666666' } -Confirm:$false

        Should -Invoke -CommandName Invoke-AdvisorCockpitAppRequest -ParameterFilter { $Method -eq 'PATCH' -and $Path -match 'sitemaps' } -Times 1 -Exactly
        Should -Invoke -CommandName Invoke-AdvisorCockpitAppRequest -ParameterFilter { $Method -eq 'PATCH' -and $Path -match 'appmodules' } -Times 1 -Exactly
        Should -Invoke -CommandName Invoke-AdvisorCockpitAppRequest -ParameterFilter { $Method -eq 'POST' -and $Path -eq '/AddAppComponents' } -Times 1 -Exactly
        Should -Invoke -CommandName Invoke-AdvisorCockpitAppRequest -ParameterFilter { $Method -eq 'POST' -and $Path -match 'appmoduleroles_association' } -Times 1 -Exactly
        Should -Invoke -CommandName Invoke-AdvisorCockpitAppRequest -ParameterFilter { $Path -match 'ValidateApp' } -Times 1 -Exactly
        Should -Invoke -CommandName Invoke-AdvisorCockpitAppRequest -ParameterFilter { $Path -eq '/PublishAllXml' } -Times 1 -Exactly
    }

    It 'skips AddAppComponents entirely when every component is already attached' {
        Mock -CommandName Get-CustomPageIdMap -MockWith {
            @{
                'crmshow_advisorcockpitpage'       = '22222222-2222-2222-2222-222222222222'
                'crmshow_salesleaderdashboardpage' = '33333333-3333-3333-3333-333333333333'
            }
        }
        Mock -CommandName Invoke-AdvisorCockpitAppRequest -MockWith {
            switch -Regex ($Path) {
                "appmodules\(uniquename=" { return [pscustomobject]@{ appmoduleid = '55555555-5555-5555-5555-555555555555' } }
                "sitemaps\(sitemapnameunique=" { return [pscustomobject]@{ sitemapid = '44444444-4444-4444-4444-444444444444' } }
                '/appmodulecomponents'         { return [pscustomobject]@{ value = @(@{ objectid = '44444444-4444-4444-4444-444444444444' }, @{ objectid = '22222222-2222-2222-2222-222222222222' }, @{ objectid = '33333333-3333-3333-3333-333333333333' }) } }
                'appmoduleroles_association'   { return [pscustomobject]@{ value = @(@{ roleid = '66666666-6666-6666-6666-666666666666' }) } }
                default                        { return $null }
            }
        }

        Invoke-AdvisorCockpitAppPublish -EnvironmentUrl 'https://example.crm.dynamics.com' -PublisherId '11111111-1111-1111-1111-111111111111' -RoleIds @{ 'CRM Showcase Insurance Reader' = '66666666-6666-6666-6666-666666666666' } -Confirm:$false

        Should -Invoke -CommandName Invoke-AdvisorCockpitAppRequest -ParameterFilter { $Path -eq '/AddAppComponents' } -Times 0 -Exactly
        Should -Invoke -CommandName Invoke-AdvisorCockpitAppRequest -ParameterFilter { $Method -eq 'POST' -and $Path -match 'appmoduleroles_association' } -Times 0 -Exactly
    }
```

- [ ] **Step 7: Run tests to verify they fail**

Run: `Invoke-Pester -Path ./scripts/solution/tests/PublishAdvisorCockpitApp.Tests.ps1 -Output Detailed`
Expected: FAIL -- `Invoke-AdvisorCockpitAppPublish` not recognized.

- [ ] **Step 8: Write the orchestrator implementation**

Add to `publish-advisor-cockpit-app.ps1`, replacing the earlier scaffold
`if ($EnvironmentUrl) { Write-Output 'Dry run scaffold...' }` block from
Task 2 Step 4. Every Dataverse call goes through `Invoke-AdvisorCockpitAppRequest`
(Step 3 above) -- there is no direct `az` call left in this function:

```powershell
function Invoke-AdvisorCockpitAppPublish {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)] [string]$EnvironmentUrl,
        [Parameter(Mandatory)] [string]$PublisherId,
        [Parameter(Mandatory)] [System.Collections.IDictionary]$RoleIds
    )

    $baseUrl = $EnvironmentUrl.TrimEnd('/')
    $contract = Get-AdvisorCockpitAppContract -Path $script:ContractPath

    $pageNames = @($contract.components | Where-Object { $_.referenceKind -eq 'pageUniqueName' } | ForEach-Object { $_.reference })
    $pageIds = Get-CustomPageIdMap -EnvironmentUrl $baseUrl -PageUniqueNames $pageNames

    $sitemapBody = ConvertTo-SitemapUpsertBody -Sitemap $contract.sitemap
    Invoke-AdvisorCockpitAppRequest -BaseUrl $baseUrl -Method 'PATCH' -Path "/sitemaps(sitemapnameunique='$($contract.sitemap.uniqueName)')" -Body $sitemapBody | Out-Null

    $appModuleBody = ConvertTo-AppModuleUpsertBody -AppModule $contract.appModule -PublisherId $PublisherId
    Invoke-AdvisorCockpitAppRequest -BaseUrl $baseUrl -Method 'PATCH' -Path "/appmodules(uniquename='$($contract.appModule.uniqueName)')" -Body $appModuleBody | Out-Null

    $appId = (Invoke-AdvisorCockpitAppRequest -BaseUrl $baseUrl -Method 'GET' -Path "/appmodules(uniquename='$($contract.appModule.uniqueName)')?`$select=appmoduleid").appmoduleid
    $sitemapId = (Invoke-AdvisorCockpitAppRequest -BaseUrl $baseUrl -Method 'GET' -Path "/sitemaps(sitemapnameunique='$($contract.sitemap.uniqueName)')?`$select=sitemapid").sitemapid

    $resolvedIds = [ordered]@{ $contract.sitemap.uniqueName = $sitemapId }
    foreach ($key in $pageIds.Keys) { $resolvedIds[$key] = $pageIds[$key] }

    $existingComponents = (Invoke-AdvisorCockpitAppRequest -BaseUrl $baseUrl -Method 'GET' -Path "/appmodulecomponents?`$select=objectid&`$filter=_appmoduleidunique_value eq $appId").value
    $existingObjectIds = @($existingComponents | ForEach-Object { [string]$_.objectid })

    $addRequest = Get-AppComponentAddRequests -Components $contract.components -ResolvedIds $resolvedIds -ExistingObjectIds $existingObjectIds -AppId $appId
    if ($addRequest) {
        Invoke-AdvisorCockpitAppRequest -BaseUrl $baseUrl -Method 'POST' -Path '/AddAppComponents' -Body $addRequest | Out-Null
    }

    $existingRoles = (Invoke-AdvisorCockpitAppRequest -BaseUrl $baseUrl -Method 'GET' -Path "/appmodules($appId)/appmoduleroles_association?`$select=roleid").value
    $existingRoleIds = @($existingRoles | ForEach-Object { [string]$_.roleid })

    foreach ($roleReq in @(Get-AppRoleAssociationRequests -SecurityRoles $contract.securityRoles -RoleIds $RoleIds -ExistingRoleIds $existingRoleIds -AppId $appId)) {
        Invoke-AdvisorCockpitAppRequest -BaseUrl $baseUrl -Method $roleReq.Method -Path $roleReq.Path -Body $roleReq.Body | Out-Null
    }

    Invoke-AdvisorCockpitAppRequest -BaseUrl $baseUrl -Method 'POST' -Path "/appmodules($appId)/Microsoft.Dynamics.CRM.ValidateApp" -Body @{} | Out-Null
    Invoke-AdvisorCockpitAppRequest -BaseUrl $baseUrl -Method 'POST' -Path '/PublishAllXml' -Body @{} | Out-Null

    Write-Output "Advisor Cockpit app published: appmoduleid=$appId"
}
```

Also update the bottom dispatch block (from Task 2 Step 4) to:

```powershell
if ($MyInvocation.InvocationName -ne '.') {
    if ($EnvironmentUrl) {
        Write-Output 'Invoke-AdvisorCockpitAppPublish requires -PublisherId and -RoleIds; call it directly once those are resolved for your environment.'
    }
    else {
        $contract = Get-AdvisorCockpitAppContract -Path $script:ContractPath
        Write-Output ("Contract loaded: app '{0}', {1} components, {2} security role(s)." -f $contract.appModule.name, @($contract.components).Count, @($contract.securityRoles).Count)
    }
}
```

- [ ] **Step 9: Run tests to verify they pass**

Run: `Invoke-Pester -Path ./scripts/solution/tests/PublishAdvisorCockpitApp.Tests.ps1 -Output Detailed`
Expected: PASS (18/18).

- [ ] **Step 10: Commit**

```powershell
git add scripts/solution/publish-advisor-cockpit-app.ps1 scripts/solution/tests/PublishAdvisorCockpitApp.Tests.ps1
git commit -m "feat(sprint-003): Invoke-AdvisorCockpitAppPublish orchestrator (#64)"
```

**Open follow-up (not blocking this task):** `Invoke-AdvisorCockpitAppPublish`
requires the caller to already know `-PublisherId` and `-RoleIds` (GUIDs).
A later task (or a manual step in the CD-DEV wiring) needs a small
`Get-PublisherId`/`Get-SecurityRoleIds` resolver mirroring `Get-AccountKeyMap`'s
query pattern -- deliberately deferred here since this plan is already at
the point of diminishing bite-size; add it as Task 9a before wiring into
`cd-solution-dev.yml` if those resolvers don't already exist elsewhere in
the repo (check `Publish-InsuranceFoundation.ps1` for an existing publisher
lookup first -- it already resolves a publisher for every other component).

---

### Task 10: Wire into `cd-solution-dev.yml`

**Files:**
- Modify: `.github/workflows/cd-solution-dev.yml`

- [ ] **Step 1: Add the new step**

Add after the existing "Smoke-check seeded demo data" step and before
"Export managed and unmanaged solutions":

```yaml
      - name: Publish Advisor Cockpit app
        shell: pwsh
        run: |
          $root = $env:GITHUB_WORKSPACE
          . (Join-Path $root 'scripts/solution/publish-advisor-cockpit-app.ps1')
          $publisherId = (az rest --method GET --url "$env:POWER_PLATFORM_ENV_URL/api/data/v9.2/publishers?`$select=publisherid&`$filter=uniquename eq 'urruegg'" --resource "$env:POWER_PLATFORM_ENV_URL/" --only-show-errors | ConvertFrom-Json).value[0].publisherid
          $roleId = (az rest --method GET --url "$env:POWER_PLATFORM_ENV_URL/api/data/v9.2/roles?`$select=roleid&`$filter=name eq 'CRM Showcase Insurance Reader'" --resource "$env:POWER_PLATFORM_ENV_URL/" --only-show-errors | ConvertFrom-Json).value[0].roleid
          Invoke-AdvisorCockpitAppPublish -EnvironmentUrl $env:POWER_PLATFORM_ENV_URL -PublisherId $publisherId -RoleIds @{ 'CRM Showcase Insurance Reader' = $roleId } -Confirm:$false
          if ($LASTEXITCODE -ne 0) { throw 'Advisor Cockpit app publish failed.' }
```

- [ ] **Step 2: Validate YAML syntax**

Run: `python -c "import yaml; yaml.safe_load(open('.github/workflows/cd-solution-dev.yml')); print('YAML valid')"`
Expected: `YAML valid`

- [ ] **Step 3: Commit**

```powershell
git add .github/workflows/cd-solution-dev.yml
git commit -m "feat(sprint-003): wire Advisor Cockpit app publish into cd-solution-dev.yml (#64)"
```

**Not yet done, deliberately:** an actual live dispatch of the updated
pipeline. Per this session's established practice, running the pipeline
against live DEV is a separate, explicit action taken only after this plan's
code is reviewed and merged — not automatically as part of implementing it.

---

## Plan self-review notes

- **Spec coverage:** every confirmed fact from the design doc (appmodule/
  sitemap/appmodulecomponent/AddAppComponents shapes) is used in Tasks 4-9.
  Design doc's Approach A (one manual custom-page-creation step, everything
  else scripted) is what this plan implements.
- **Placeholder scan:** two deliberate, explicitly-flagged exceptions exist
  (Task 4's contract JSON `clientType`/`formFactor`, Task 6's `CustomPage`
  value) — both are Task 1 research outputs, not code-writing laziness, and
  each is called out with a `<CONFIRM-IN-TASK-1>` marker plus an explicit
  instruction on when/how to resolve it. No other step contains a
  placeholder.
- **Type consistency:** `ConvertTo-SitemapUpsertBody`, `ConvertTo-AppModuleUpsertBody`,
  `Get-AppComponentAddRequests`, `Get-AppRoleAssociationRequests` all take
  the same contract-shaped objects consistently across tasks; verified each
  later task's test fixtures match the JSON contract's actual field names
  from Task 2.
- **Real bug found and fixed during this self-review:** the first draft of
  Task 9 mocked the raw `az` CLI directly for the orchestrator test, with a
  single `if ($args -contains '/canvasapps') { ... } else { $LASTEXITCODE = 0 }`
  branch — but the orchestrator makes 8+ differently-shaped `az` calls (GET
  lookups expecting parsed JSON, PATCH upserts, POST actions), and the
  "else" branch would have returned nothing for calls that then pipe into
  `ConvertFrom-Json`, throwing on empty input. Checked how
  `Publish-InsuranceFoundation.Tests.ps1` handles this same problem: it
  mocks exactly **one** central function (`Invoke-DataverseRequest`), never
  the raw `az` CLI. Refactored Task 9 to introduce
  `Invoke-AdvisorCockpitAppRequest` as that same single choke point (GET
  returns parsed JSON, mutations return null), used for **every** Dataverse
  call in the orchestrator, and rewrote both the wrapper's own tests and the
  orchestrator's tests to mock only that one function with a `switch -Regex
  ($Path)` branch — matching the established, working pattern instead of a
  fragile one this plan would otherwise have shipped.
- **Test counts verified consistent end to end:** 2 (Task 2) -> 3 (Task 4)
  -> 4 (Task 5) -> 8 (Task 6) -> 11 (Task 7) -> 14 (Task 8) -> 16 (Task 9
  wrapper) -> 18 (Task 9 orchestrator) -- each task's stated "Expected: PASS
  (N/N)" matches the cumulative count of `It` blocks added so far.
- **Deferred, not forgotten:** the `Get-PublisherId`/`Get-SecurityRoleIds`
  resolver gap (noted after Task 9) and the sitemap URL-format assumption
  (noted after Task 4) are both real, honestly-flagged loose ends — check
  both before considering Task 10 fully done.

