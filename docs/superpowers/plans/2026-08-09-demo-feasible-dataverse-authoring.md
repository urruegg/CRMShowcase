# Demo-Feasible Dataverse Authoring Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deliver one deterministic DEV authoring workflow that stays within the existing `System Customizer` permissions, stops before mutation when the manual security-role prerequisite is missing, converges Dataverse metadata without operator reruns, and exports exactly four reviewed solution packages. `0023` is the latest allocated sequence; use `0024` for the next ADR.

**Architecture:** Split the current monolithic authoring path into read-only preflight, demo-safe schema reconciliation, read-only role/convergence verification, and exact package export. Keep security-role mutation available only as an explicit administrator-run bootstrap scope; document automated privileged bootstrap as an ADR hypothesis rather than implementing unavailable tenant capability.

**Tech Stack:** PowerShell 5.1-compatible scripts, Pester 6.0.1, Dataverse Web API v9.2, PAC CLI, GitHub Actions OIDC, Power Platform solutions, Markdown ADRs/runbooks.

---

## Delivery boundary

This plan implements the **demo scope** from
`docs/superpowers/specs/2026-08-09-demo-feasible-dataverse-authoring-design.md`.
It does not implement managed TEST promotion, TEST deployment evidence,
automated privileged bootstrap, fixtures, or persona security smoke tests.

The administrator role prerequisite is intentionally a gate:

- if the two custom roles do not exist, preflight returns
  `ManualPrerequisite` and no Dataverse mutation occurs;
- after an authorized administrator creates the roles, the normal DEV workflow
  verifies them but never creates or changes them;
- the current `System Customizer` assignment remains the steady-state CI role.

## File map

| Path | Responsibility |
| --- | --- |
| `docs/adr/ADR-0023-demo-feasible-dataverse-bootstrap.md` | Records demo boundary and target bootstrap hypothesis |
| `docs/adr/README.md` | Registers ADR-0023 in the numbering guidance, proposed list, and index |
| `docs/BACKLOG.md` | Updates US-702/US-708 scope, defers US-709 follow-up evidence, and preserves issue links |
| `scripts/solution/Test-InsuranceAuthoringPreflight.ps1` | Read-only environment, role, solution, and phase feasibility checks |
| `scripts/solution/tests/Test-InsuranceAuthoringPreflight.Tests.ps1` | Preflight result and no-mutation tests |
| `scripts/solution/Publish-InsuranceFoundation.ps1` | Adds explicit `Demo` and `SecurityRoles` scopes and bounded metadata waits |
| `scripts/solution/tests/Publish-InsuranceFoundation.Tests.ps1` | Scope isolation, polling, timeout, and workflow-order tests |
| `scripts/solution/Test-InsuranceSecurityRoles.ps1` | Read-only role ownership and privilege comparison |
| `scripts/solution/tests/Test-InsuranceSecurityRoles.Tests.ps1` | Role verifier tests |
| `scripts/solution/Test-InsuranceFoundationConvergence.ps1` | Read-only full demo contract check before export |
| `scripts/solution/tests/Test-InsuranceFoundationConvergence.Tests.ps1` | Convergence summary and conflict tests |
| `scripts/solution/Export-InsuranceFoundationPackages.ps1` | PAC export plus exact package-set verification |
| `scripts/solution/tests/Export-InsuranceFoundationPackages.Tests.ps1` | Export command and package-set tests |
| `.github/workflows/solution-author-dev.yml` | Preflight-first, demo-safe authoring, validation, and export |
| `docs/runbooks/insurance-foundation-security-role-bootstrap.md` | Administrator prerequisite and verification procedure |
| `docs/superpowers/specs/2026-08-08-insurance-foundation-design.md` | Marks managed TEST promotion, TEST deployment evidence, fixtures, persona security smoke tests, and automated role bootstrap as deferred |

### Task 1: Record the demo boundary and bootstrap hypothesis

**Files:**
- Create: `docs/adr/ADR-0023-demo-feasible-dataverse-bootstrap.md`
- Modify: `docs/adr/README.md` (register ADR-0023 in the ADR range/index)
- Modify: `docs/BACKLOG.md` (US-702/US-708 wording and US-709 deferral)
- Modify: `docs/superpowers/specs/2026-08-08-insurance-foundation-design.md`

- [ ] **Step 1: Write the ADR**

Create `docs/adr/ADR-0023-demo-feasible-dataverse-bootstrap.md`:

```markdown
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
prvCreateRole. Run 31302762752 proved that choices, extensions, tables,
relationships, keys, views, forms, and multilingual metadata are feasible
before that boundary.

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
```

- [ ] **Step 2: Register ADR-0023 in the ADR README**

In `docs/adr/README.md`, update the domain-and-delivery numbering range and
ADR index so ADR-0023 is discoverable and the next allocation remains clear:
`0023` is the latest allocated sequence; use `0024` for the next ADR.

```markdown
- **Domain and delivery ADRs (0006–0023)** record the CRM Frontier Firm design position on the
  illustrated insurance vertical: party model, portfolio placement, thin CRM over
  the engines, consent, event cascade, jurisdiction eligibility, GA territory,
  agents-advisory, voice, outbound, ALM, analytics split, and demo-feasible
  Dataverse bootstrap boundaries.

`0024` is allocated; use the next available sequence number for any new ADR.

| [0023](./ADR-0023-demo-feasible-dataverse-bootstrap.md) | Demo-feasible Dataverse bootstrap and steady-state identities | A8 | Proposed hypothesis |

ADRs 0011, 0012, 0013, 0017, 0018, 0019, 0020, and 0023 remain proposed until
confirmed with customer architecture in the next review.
```

- [ ] **Step 3: Update Sprint 3 backlog wording**

In `docs/BACKLOG.md`, change the affected Epic 7 rows to:

```markdown
| US-702 | Deliver shared insurance choices; create security roles through the approved DEV administrator prerequisite and verify them in CI | In progress - [#8](https://github.com/urruegg/CRMShowcase/issues/8), [#40](https://github.com/urruegg/CRMShowcase/issues/40) |
| US-708 | Author and export unmanaged/managed packages from DEV; managed TEST promotion is a separate solution-versioning sprint | In progress - [#8](https://github.com/urruegg/CRMShowcase/issues/8) |
| US-709 | Load synthetic fixtures and publish persona security smoke evidence after managed TEST promotion | Deferred - included in the separate solution-versioning and managed TEST-promotion sprint - [#8](https://github.com/urruegg/CRMShowcase/issues/8) |
```

- [ ] **Step 4: Align the original Sprint 3 specification**

Add this note after the Outcome section in
`docs/superpowers/specs/2026-08-08-insurance-foundation-design.md`:

```markdown
> **Demo feasibility amendment (2026-08-09).** The current tenant permits the
> environment-scoped CI application user to author schema metadata but not
> security roles. The approved Sprint 3 boundary is DEV authoring, validation,
> and exact package export. The administrator prerequisite and follow-up target
> sequence are defined in
> [Demo-Feasible Dataverse Authoring and Bootstrap](./2026-08-09-demo-feasible-dataverse-authoring-design.md)
> and [ADR-0023](../../adr/ADR-0023-demo-feasible-dataverse-bootstrap.md).
> Managed TEST promotion, TEST deployment evidence, fixtures, and persona
> security smoke tests remain separate follow-up work.
```

- [ ] **Step 5: Validate documentation**

Run:

```powershell
git diff --check
rg "TBD|TODO|placeholder" docs/adr/ADR-0023-demo-feasible-dataverse-bootstrap.md docs/adr/README.md
```

Expected: `git diff --check` exits 0 and `rg` returns no matches.

- [ ] **Step 6: Commit**

```powershell
git add docs/adr/ADR-0023-demo-feasible-dataverse-bootstrap.md docs/adr/README.md docs/BACKLOG.md docs/superpowers/specs/2026-08-08-insurance-foundation-design.md
git commit -m "docs(sprint-3): scope demo-feasible Dataverse bootstrap (US-702)"
```

### Task 2: Add a read-only authoring preflight

**Files:**
- Create: `scripts/solution/Test-InsuranceAuthoringPreflight.ps1`
- Create: `scripts/solution/tests/Test-InsuranceAuthoringPreflight.Tests.ps1`

- [ ] **Step 1: Write failing result-classification tests**

Create `scripts/solution/tests/Test-InsuranceAuthoringPreflight.Tests.ps1`:

```powershell
BeforeAll {
    $script:preflightPath = Join-Path $PSScriptRoot '../Test-InsuranceAuthoringPreflight.ps1'
    . $script:preflightPath
}

Describe 'Get-InsuranceAuthoringPhaseState' {
    It 'requires manual bootstrap when either reviewed role is absent' {
        Get-InsuranceAuthoringPhaseState `
            -SolutionsReady $true -SchemaFeasible $true `
            -RolesReady $false |
            Should -Be 'ManualPrerequisite'
    }

    It 'is ready when structural prerequisites are satisfied' {
        Get-InsuranceAuthoringPhaseState `
            -SolutionsReady $true -SchemaFeasible $true `
            -RolesReady $true |
            Should -Be 'Ready'
    }

    It 'reports unsupported tenant capability before role state' {
        Get-InsuranceAuthoringPhaseState `
            -SolutionsReady $true -SchemaFeasible $false `
            -RolesReady $false |
            Should -Be 'UnsupportedInTenant'
    }

    It 'plans language reconciliation without blocking schema authoring' {
        Get-LanguagePreflightAction `
            -Required @('1033','1031','1036','1040') `
            -Provisioned @('1033') |
            Should -Be 'Reconcile'
    }

    It 'accepts the proven System Customizer demo capability' {
        Test-DemoSchemaAuthoringCapability `
            -AssignedRoleNames @('System Customizer') |
            Should -BeTrue
    }

    It 'rejects an unproven steady-state role' {
        Test-DemoSchemaAuthoringCapability `
            -AssignedRoleNames @('Basic User') |
            Should -BeFalse
    }
}

Describe 'Invoke-InsuranceAuthoringPreflight' {
    BeforeEach {
        Mock Invoke-PreflightDataverseRequest {
            throw 'Unexpected endpoint'
        }
    }

    It 'performs GET requests only' {
        Mock Invoke-PreflightDataverseRequest {
            param($Method, $Path)
            if ($Path -like '/RetrieveProvisionedLanguages*') {
                return [pscustomobject]@{
                    RetrieveProvisionedLanguages = @(1033, 1031, 1036, 1040)
                }
            }
            if ($Path -like '/solutions?*') {
                return [pscustomobject]@{ value = @(
                    [pscustomobject]@{ uniquename='crmshow_Foundation' },
                    [pscustomobject]@{ uniquename='crmshow_DataModel' }
                ) }
            }
            if ($Path -like '/roles?*') {
                return [pscustomobject]@{ value = @(
                    [pscustomobject]@{ roleid='reader'; name='CRM Showcase Insurance Reader' },
                    [pscustomobject]@{ roleid='steward'; name='CRM Showcase Insurance Data Steward' }
                ) }
            }
            if ($Path -like '/WhoAmI*') {
                return [pscustomobject]@{ UserId='ci-user' }
            }
            if ($Path -like '/systemusers(*') {
                return [pscustomobject]@{ value = @(
                    [pscustomobject]@{ name='System Customizer' }
                ) }
            }
            throw "Unexpected endpoint: $Path"
        }

        $result = Invoke-InsuranceAuthoringPreflight `
            -EnvironmentUrl 'https://unit.crm.dynamics.com' `
            -Contract ([pscustomobject]@{
                solutions=@('crmshow_Foundation','crmshow_DataModel')
                languages=@('1033','1031','1036','1040')
                roles=@(
                    [pscustomobject]@{ name='CRM Showcase Insurance Reader' },
                    [pscustomobject]@{ name='CRM Showcase Insurance Data Steward' }
                )
            })

        $result.State | Should -Be 'Ready'
        Assert-MockCalled Invoke-PreflightDataverseRequest -ParameterFilter {
            $Method -ne 'GET'
        } -Times 0
    }
}
```

- [ ] **Step 2: Run tests and verify RED**

Run:

```powershell
Import-Module Pester -RequiredVersion 6.0.1
Invoke-Pester .\scripts\solution\tests\Test-InsuranceAuthoringPreflight.Tests.ps1 -Output Detailed
```

Expected: FAIL because the script and functions do not exist.

- [ ] **Step 3: Implement preflight classification and read-only transport**

Create `scripts/solution/Test-InsuranceAuthoringPreflight.ps1` with:

```powershell
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$EnvironmentUrl,
    [Parameter(Mandatory)] [string]$ContractPath
)

$ErrorActionPreference = 'Stop'
$script:PreflightBaseUrl = $EnvironmentUrl.TrimEnd('/') + '/api/data/v9.2'

function Invoke-PreflightDataverseRequest {
    param(
        [ValidateSet('GET')] [string]$Method = 'GET',
        [Parameter(Mandatory)] [string]$Path
    )
    $url = $script:PreflightBaseUrl + $Path
    $output = & az rest --method get --url $url `
        --resource ($EnvironmentUrl.TrimEnd('/') + '/') `
        --only-show-errors 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Preflight transport failure (GET $Path): $($output -join [Environment]::NewLine)"
    }
    if ([string]::IsNullOrWhiteSpace(($output -join ''))) {
        return [pscustomobject]@{}
    }
    return ($output -join [Environment]::NewLine) | ConvertFrom-Json
}

function Get-InsuranceAuthoringPhaseState {
    param(
        [bool]$SolutionsReady,
        [bool]$SchemaFeasible,
        [bool]$RolesReady
    )
    if (-not $SchemaFeasible) { return 'UnsupportedInTenant' }
    if (-not $SolutionsReady) { return 'Precondition' }
    if (-not $RolesReady) { return 'ManualPrerequisite' }
    return 'Ready'
}

function Get-LanguagePreflightAction {
    param(
        [string[]]$Required,
        [string[]]$Provisioned
    )
    if (@($Required | Where-Object { $_ -notin $Provisioned }).Count -gt 0) {
        return 'Reconcile'
    }
    return 'None'
}

function Test-DemoSchemaAuthoringCapability {
    param([string[]]$AssignedRoleNames)
    return @($AssignedRoleNames | Where-Object {
        $_ -in @('System Customizer', 'System Administrator')
    }).Count -gt 0
}

function Invoke-InsuranceAuthoringPreflight {
    param(
        [Parameter(Mandatory)] [string]$EnvironmentUrl,
        [Parameter(Mandatory)] $Contract
    )
    $identity = Invoke-PreflightDataverseRequest -Path '/WhoAmI'
    $assignedRoles = Invoke-PreflightDataverseRequest -Path (
        "/systemusers($($identity.UserId))/systemuserroles_association?" +
        "`$select=name"
    )
    $languages = Invoke-PreflightDataverseRequest `
        -Path '/RetrieveProvisionedLanguages()'
    $solutions = Invoke-PreflightDataverseRequest -Path (
        "/solutions?`$select=uniquename&`$filter=" +
        "uniquename eq 'crmshow_Foundation' or uniquename eq 'crmshow_DataModel'"
    )
    $roles = Invoke-PreflightDataverseRequest -Path (
        "/roles?`$select=roleid,name&`$filter=" +
        "_parentrootroleid_value eq null and (" +
        "name eq 'CRM Showcase Insurance Reader' or " +
        "name eq 'CRM Showcase Insurance Data Steward')"
    )

    $provisioned = @($languages.RetrieveProvisionedLanguages |
        ForEach-Object { [string]$_ })
    $solutionNames = @($solutions.value.uniquename)
    $roleNames = @($roles.value.name)
    $solutionsReady = @($Contract.solutions | Where-Object {
        $_ -notin $solutionNames
    }).Count -eq 0
    $languagesReady = @($Contract.languages | Where-Object {
        $_ -notin $provisioned
    }).Count -eq 0
    $rolesReady = @($Contract.roles.name | Where-Object {
        $_ -notin $roleNames
    }).Count -eq 0
    $schemaFeasible = Test-DemoSchemaAuthoringCapability `
        -AssignedRoleNames @($assignedRoles.value.name)

    [pscustomobject]@{
        State = Get-InsuranceAuthoringPhaseState `
            -SolutionsReady $solutionsReady `
            -SchemaFeasible $schemaFeasible `
            -RolesReady $rolesReady
        UserId = $identity.UserId
        SolutionsReady = $solutionsReady
        LanguagesReady = $languagesReady
        LanguageAction = Get-LanguagePreflightAction `
            -Required @($Contract.languages) `
            -Provisioned $provisioned
        RolesReady = $rolesReady
        AssignedRoleNames = @($assignedRoles.value.name)
        MissingRoles = @($Contract.roles.name | Where-Object {
            $_ -notin $roleNames
        })
        MutationOccurred = $false
    }
}

if ($MyInvocation.InvocationName -ne '.') {
    $contract = Get-Content -LiteralPath $ContractPath -Raw |
        ConvertFrom-Json
    $result = Invoke-InsuranceAuthoringPreflight `
        -EnvironmentUrl $EnvironmentUrl -Contract $contract
    $result | ConvertTo-Json -Depth 10
    if ($result.State -ne 'Ready') { exit 2 }
}
```

- [ ] **Step 4: Run tests and verify GREEN**

Run:

```powershell
Invoke-Pester .\scripts\solution\tests\Test-InsuranceAuthoringPreflight.Tests.ps1 -Output Detailed
```

Expected: all preflight tests pass.

- [ ] **Step 5: Commit**

```powershell
git add scripts/solution/Test-InsuranceAuthoringPreflight.ps1 scripts/solution/tests/Test-InsuranceAuthoringPreflight.Tests.ps1
git commit -m "feat(dataverse): add read-only authoring preflight (US-708)"
```

### Task 3: Isolate demo-safe and privileged authoring scopes

**Files:**
- Modify: `scripts/solution/Publish-InsuranceFoundation.ps1`
- Modify: `scripts/solution/tests/Publish-InsuranceFoundation.Tests.ps1`

- [ ] **Step 1: Write failing scope-isolation tests**

Add to `scripts/solution/tests/Publish-InsuranceFoundation.Tests.ps1`:

```powershell
It 'does not schedule role mutation in Demo scope' {
    Invoke-InsuranceFoundationReconciliation `
        -Contract $script:contract -Scope Demo -Confirm:$false | Out-Null

    @($script:calls | Where-Object {
        $_.Method -ne 'GET' -and
        ($_.Path -eq '/roles' -or $_.Path -match 'PrivilegesRole$')
    }) | Should -BeNullOrEmpty
}

It 'schedules only role mutation in SecurityRoles scope' {
    Invoke-InsuranceFoundationReconciliation `
        -Contract $script:contract -Scope SecurityRoles -Confirm:$false | Out-Null

    @($script:calls | Where-Object {
        $_.Method -ne 'GET' -and $_.Path -eq '/EntityDefinitions'
    }) | Should -BeNullOrEmpty
    @($script:calls | Where-Object {
        $_.Method -ne 'GET' -and $_.Path -eq '/GlobalOptionSetDefinitions'
    }) | Should -BeNullOrEmpty
    @($script:calls | Where-Object {
        $_.Method -ne 'GET' -and
        ($_.Path -eq '/roles' -or $_.Path -match 'PrivilegesRole$')
    }).Count | Should -BeGreaterThan 0
}

It 'keeps All as the explicit privileged legacy scope' {
    $text = Get-Content -LiteralPath $script:publisherPath -Raw
    $text | Should -Match "ValidateSet\\('Foundation', 'DataModel', 'Demo', 'SecurityRoles', 'All'\\)"
}
```

- [ ] **Step 2: Run targeted test and verify RED**

Run:

```powershell
Invoke-Pester .\scripts\solution\tests\Publish-InsuranceFoundation.Tests.ps1 -Output Detailed
```

Expected: FAIL because `Demo` and `SecurityRoles` are not accepted.

- [ ] **Step 3: Implement explicit scopes**

Change both `Scope` validation declarations to:

```powershell
[ValidateSet('Foundation', 'DataModel', 'Demo', 'SecurityRoles', 'All')]
[string]$Scope = 'Demo'
```

Replace the phase selection in `Invoke-InsuranceFoundationReconciliation` with:

```powershell
$includeChoices = $Scope -in @('Foundation', 'Demo', 'All')
$includeDataModel = $Scope -in @('DataModel', 'Demo', 'All')
$includeRoles = $Scope -in @('SecurityRoles', 'All')

if ($includeChoices) {
    foreach ($choice in $Contract.choices) {
        if ($PSCmdlet.ShouldProcess(
                $choice.logicalName,
                'Reconcile global choice'
            )) {
            Invoke-ChoiceReconciliation $choice
        }
    }
}
if ($includeDataModel) {
    foreach ($extension in $Contract.nativeExtensions) {
        if ($PSCmdlet.ShouldProcess(
                "$($extension.table)/$($extension.logicalName)",
                'Reconcile native extension'
            )) {
            Invoke-NativeExtensionReconciliation $extension
        }
    }
    foreach ($table in $Contract.tables) {
        if ($PSCmdlet.ShouldProcess(
                $table.logicalName,
                'Reconcile custom table'
            )) {
            Invoke-TableReconciliation $table
        }
    }
}
if ($includeRoles) {
    foreach ($role in $Contract.roles) {
        if ($PSCmdlet.ShouldProcess(
                $role.name,
                'Reconcile security role'
            )) {
            Invoke-RoleReconciliation $role $Contract
        }
    }
}
```

Choose the publish header with:

```powershell
$publishSolution = if ($Scope -eq 'SecurityRoles' -or
    ($includeChoices -and -not $includeDataModel)) {
    'crmshow_Foundation'
} else {
    'crmshow_DataModel'
}
```

- [ ] **Step 4: Run targeted and full solution tests**

Run:

```powershell
$targeted = Invoke-Pester .\scripts\solution\tests\Publish-InsuranceFoundation.Tests.ps1 -PassThru -Output Detailed
if ($targeted.Result -ne 'Passed') { throw 'Publisher tests failed.' }
$full = Invoke-Pester .\scripts\solution\tests -PassThru -Output Normal
if ($full.Result -ne 'Passed') { throw 'Solution tests failed.' }
```

Expected: all tests pass and no Demo-scope role mutation is recorded.

- [ ] **Step 5: Commit**

```powershell
git add scripts/solution/Publish-InsuranceFoundation.ps1 scripts/solution/tests/Publish-InsuranceFoundation.Tests.ps1
git commit -m "refactor(dataverse): isolate privileged role authoring (US-702)"
```

### Task 4: Replace workflow reruns with bounded metadata convergence

**Files:**
- Modify: `scripts/solution/Publish-InsuranceFoundation.ps1`
- Modify: `scripts/solution/tests/Publish-InsuranceFoundation.Tests.ps1`

- [ ] **Step 1: Write failing wait tests**

Add:

```powershell
Describe 'Wait-DataverseCondition' {
    It 'returns the first non-null condition result' {
        $script:attempt = 0
        Mock Start-Sleep {}
        $result = Wait-DataverseCondition `
            -Component 'table/lookup' -TimeoutSeconds 10 `
            -PollIntervalSeconds 1 -Condition {
                $script:attempt++
                if ($script:attempt -eq 3) {
                    return [pscustomobject]@{ LogicalName='crmshow_accountid' }
                }
                return $null
            }

        $result.LogicalName | Should -Be 'crmshow_accountid'
        $script:attempt | Should -Be 3
    }

    It 'throws a classified timeout with the component name' {
        Mock Start-Sleep {}
        Mock Get-Date {
            if (-not $script:clock) {
                $script:clock = [datetime]'2026-08-09T00:00:00Z'
            } else {
                $script:clock = $script:clock.AddSeconds(6)
            }
            return $script:clock
        }

        {
            Wait-DataverseCondition `
                -Component 'crmshow_policyprojection/crmshow_accountid' `
                -TimeoutSeconds 5 -PollIntervalSeconds 1 `
                -Condition { $null }
        } | Should -Throw '*EventualConsistencyTimeout*crmshow_policyprojection/crmshow_accountid*'
    }
}
```

- [ ] **Step 2: Run tests and verify RED**

Run:

```powershell
Invoke-Pester .\scripts\solution\tests\Publish-InsuranceFoundation.Tests.ps1 -Output Detailed
```

Expected: FAIL because `Wait-DataverseCondition` is absent.

- [ ] **Step 3: Implement the bounded condition wait**

Add before `Invoke-TableReconciliation`:

```powershell
function Wait-DataverseCondition {
    param(
        [Parameter(Mandatory)] [string]$Component,
        [Parameter(Mandatory)] [scriptblock]$Condition,
        [int]$TimeoutSeconds = 180,
        [int]$PollIntervalSeconds = 5
    )
    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    do {
        $result = & $Condition
        if ($null -ne $result) { return $result }
        if ((Get-Date) -ge $deadline) {
            throw "EventualConsistencyTimeout for '$Component' after $TimeoutSeconds seconds."
        }
        Start-Sleep -Seconds $PollIntervalSeconds
    } while ($true)
}

function Get-TableMetadataSnapshot {
    param([Parameter(Mandatory)] [string]$LogicalName)
    return Get-One (
        "/EntityDefinitions?`$select=MetadataId,LogicalName,SchemaName," +
        "OwnershipType,PrimaryNameAttribute,IsAuditEnabled,DisplayName,Description&" +
        "`$expand=Attributes(`$select=MetadataId,LogicalName,SchemaName," +
        "AttributeType,DisplayName,Description)," +
        "ManyToOneRelationships(`$select=SchemaName,ReferencedEntity," +
        "ReferencingEntity,ReferencingAttribute,CascadeConfiguration)&" +
        "`$filter=LogicalName eq '$LogicalName'"
    )
}
```

After a new table is published, wait for it:

```powershell
$existing = Wait-DataverseCondition `
    -Component $Table.logicalName `
    -Condition { Get-TableMetadataSnapshot $Table.logicalName }
```

Refactor `Invoke-TableReconciliation` so table creation and table validation
join one common path:

```powershell
$existing = Get-TableMetadataSnapshot $Table.logicalName
if ($null -eq $existing) {
    $choiceMetadataIds = Get-GlobalChoiceMetadataIds @($Table.columns)
    Invoke-PlannedRequest (
        Get-TableCreateRequest $Table $choiceMetadataIds
    ) | Out-Null
    Publish-TableMetadata $Table
    $existing = Wait-DataverseCondition `
        -Component $Table.logicalName `
        -Condition { Get-TableMetadataSnapshot $Table.logicalName }
}

# From this point onward, use the same relationship, column, localization,
# publish, and child reconciliation for both new and pre-existing tables.
Assert-SolutionOwnership $existing $Table.solution $Table.logicalName
```

Do not leave relationship recovery and column reconciliation inside an `else`
branch. The common path is what prevents the first workflow run from reaching
views before deep-inserted lookups are visible.

After each relationship create, wait until both lookup and relationship are
visible before continuing:

```powershell
$existing = Wait-DataverseCondition `
    -Component "$($Table.logicalName)/$($relationship.lookupColumn)" `
    -Condition {
        $snapshot = Get-TableMetadataSnapshot $Table.logicalName
        $lookup = @($snapshot.Attributes | Where-Object {
            $_.LogicalName -eq $relationship.lookupColumn
        })
        $relation = @($snapshot.ManyToOneRelationships | Where-Object {
            $_.SchemaName -eq $relationship.schemaName
        })
        if ($lookup.Count -eq 1 -and $relation.Count -eq 1) {
            return $snapshot
        }
        return $null
    }
```

Reuse the refreshed `$existing` snapshot for column and child reconciliation.
Do not submit views, forms, or keys against the pre-create snapshot.

- [ ] **Step 4: Add a regression proving dependent children wait**

Add a test that mocks the first table snapshot without the lookup and the
second with it, invokes `Invoke-TableReconciliation`, and asserts the
`/savedqueries` POST occurs after the second metadata GET:

```powershell
$lookupVisibleRead = @($script:calls | Where-Object {
    $_.Method -eq 'GET' -and $_.Path -like '/EntityDefinitions?*'
}).Count
$firstViewCreate = @($script:calls | Where-Object {
    $_.Method -eq 'POST' -and $_.Path -eq '/savedqueries'
})[0]
$firstViewCreate | Should -Not -BeNullOrEmpty
$lookupVisibleRead | Should -BeGreaterThan 1
```

- [ ] **Step 5: Run regression suites**

Run:

```powershell
$result = Invoke-Pester -Path @(
  '.\scripts\solution\tests\InsuranceFoundationContract.Tests.ps1',
  '.\scripts\solution\tests\Publish-InsuranceFoundation.Tests.ps1'
) -PassThru -Output Detailed
if ($result.Result -ne 'Passed') { throw 'Metadata convergence tests failed.' }
```

Expected: all tests pass.

- [ ] **Step 6: Commit**

```powershell
git add scripts/solution/Publish-InsuranceFoundation.ps1 scripts/solution/tests/Publish-InsuranceFoundation.Tests.ps1
git commit -m "fix(dataverse): await metadata convergence in one run (US-708)"
```

### Task 5: Add read-only security-role verification and administrator runbook

**Files:**
- Create: `scripts/solution/Test-InsuranceSecurityRoles.ps1`
- Create: `scripts/solution/tests/Test-InsuranceSecurityRoles.Tests.ps1`
- Create: `docs/runbooks/insurance-foundation-security-role-bootstrap.md`

- [ ] **Step 1: Write failing role verifier tests**

Create `scripts/solution/tests/Test-InsuranceSecurityRoles.Tests.ps1`:

```powershell
BeforeAll {
    . (Join-Path $PSScriptRoot '../Test-InsuranceSecurityRoles.ps1')
}

Describe 'Compare-InsuranceRolePrivileges' {
    It 'reports Ready when exact privileges and depth match' {
        Compare-InsuranceRolePrivileges `
            -RoleName 'Reader' `
            -Expected @([pscustomobject]@{
                Name='prvReadAccount'; Depth='Global'
            }) `
            -Actual @([pscustomobject]@{
                Name='prvReadAccount'; Depth='Global'
            }) |
            Select-Object -ExpandProperty State |
            Should -Be 'Ready'
    }

    It 'fails closed for an unexpected privilege' {
        $result = Compare-InsuranceRolePrivileges `
            -RoleName 'Reader' `
            -Expected @([pscustomobject]@{
                Name='prvReadAccount'; Depth='Global'
            }) `
            -Actual @(
                [pscustomobject]@{ Name='prvReadAccount'; Depth='Global' },
                [pscustomobject]@{ Name='prvDeleteAccount'; Depth='Global' }
            )
        $result.State | Should -Be 'ContractConflict'
        $result.Unexpected | Should -Contain 'prvDeleteAccount'
    }
}
```

- [ ] **Step 2: Run tests and verify RED**

Run:

```powershell
Invoke-Pester .\scripts\solution\tests\Test-InsuranceSecurityRoles.Tests.ps1 -Output Detailed
```

Expected: FAIL because the verifier does not exist.

- [ ] **Step 3: Implement the comparison and online verifier**

Create `scripts/solution/Test-InsuranceSecurityRoles.ps1` with:

```powershell
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$EnvironmentUrl,
    [Parameter(Mandatory)] [string]$ContractPath
)

$ErrorActionPreference = 'Stop'

function Compare-InsuranceRolePrivileges {
    param(
        [Parameter(Mandatory)] [string]$RoleName,
        [object[]]$Expected = @(),
        [object[]]$Actual = @()
    )
    $expectedNames = @($Expected.Name)
    $actualNames = @($Actual.Name)
    $missing = @($expectedNames | Where-Object { $_ -notin $actualNames })
    $unexpected = @($actualNames | Where-Object { $_ -notin $expectedNames })
    $wrongDepth = @(
        foreach ($expectedPrivilege in $Expected) {
            $actualPrivilege = $Actual |
                Where-Object Name -eq $expectedPrivilege.Name |
                Select-Object -First 1
            if ($null -ne $actualPrivilege -and
                $actualPrivilege.Depth -ne $expectedPrivilege.Depth) {
                $expectedPrivilege.Name
            }
        }
    )
    [pscustomobject]@{
        Role = $RoleName
        State = if ($missing.Count -eq 0 -and
            $unexpected.Count -eq 0 -and
            $wrongDepth.Count -eq 0) { 'Ready' } else { 'ContractConflict' }
        Missing = $missing
        Unexpected = $unexpected
        WrongDepth = $wrongDepth
    }
}
```

Reuse the exact schema-name and privilege-resolution logic from
`Invoke-RoleReconciliation`, but issue GET requests only:

1. query each root role by name;
2. verify solution membership through `solutioncomponents`;
3. resolve expected privilege names through
   `EntityDefinitions(...)?$select=SchemaName,Privileges`;
4. read assigned privileges through `RetrieveRolePrivilegesRole`;
5. call `Compare-InsuranceRolePrivileges`;
6. emit one JSON result per role and exit 2 unless every state is `Ready`.

Do not call `SetLocLabels`, `AddPrivilegesRole`, `ReplacePrivilegesRole`, or
`POST /roles`.

- [ ] **Step 4: Write the administrator runbook**

Create `docs/runbooks/insurance-foundation-security-role-bootstrap.md` with:

```markdown
# Insurance Foundation security-role bootstrap

## Purpose

Create the two reviewed DEV roles once without granting GitHub CI permanent
security-role administration.

## Preconditions

- Authorized Power Platform administrator.
- DEV environment only: `https://crmshowdev.crm.dynamics.com`.
- Reviewed contract:
  `solution/schema/insurance-foundation.json`.
- No credentials or access tokens are copied into GitHub.

## Procedure

1. Sign in interactively with the authorized administrator.
2. Run the authoring script locally with the explicit privileged scope:

   ```powershell
   az login --tenant b829e4ef-1a9f-45ba-80e5-48408aa421a9 --allow-no-subscriptions
   .\scripts\solution\Publish-InsuranceFoundation.ps1 `
     -EnvironmentUrl 'https://crmshowdev.crm.dynamics.com' `
     -ContractPath '.\solution\schema\insurance-foundation.json' `
     -Scope SecurityRoles `
     -Confirm
   ```

3. Review each `ShouldProcess` confirmation. The run may change only:
   - `CRM Showcase Insurance Reader`;
   - `CRM Showcase Insurance Data Steward`;
   - their localized labels/descriptions;
   - privileges declared by the reviewed contract.
4. Run read-only verification:

   ```powershell
   .\scripts\solution\Test-InsuranceSecurityRoles.ps1 `
     -EnvironmentUrl 'https://crmshowdev.crm.dynamics.com' `
     -ContractPath '.\solution\schema\insurance-foundation.json'
   ```
5. Attach the verifier output to issue #40.
6. Trigger `Author insurance foundation in DEV`.

## Rollback

If verification reports an unexpected privilege, stop. Do not delete the role.
Correct the reviewed contract or role assignment under administrator review,
rerun verification, and record the evidence.
```

- [ ] **Step 5: Run tests**

Run:

```powershell
Invoke-Pester .\scripts\solution\tests\Test-InsuranceSecurityRoles.Tests.ps1 -Output Detailed
git diff --check
```

Expected: tests pass and documentation has no whitespace errors.

- [ ] **Step 6: Commit**

```powershell
git add scripts/solution/Test-InsuranceSecurityRoles.ps1 scripts/solution/tests/Test-InsuranceSecurityRoles.Tests.ps1 docs/runbooks/insurance-foundation-security-role-bootstrap.md
git commit -m "feat(dataverse): verify manually bootstrapped roles (US-702)"
```

### Task 6: Add a read-only full convergence gate

**Files:**
- Create: `scripts/solution/Test-InsuranceFoundationConvergence.ps1`
- Create: `scripts/solution/tests/Test-InsuranceFoundationConvergence.Tests.ps1`

- [ ] **Step 1: Write failing summary tests**

Create `scripts/solution/tests/Test-InsuranceFoundationConvergence.Tests.ps1`:

```powershell
BeforeAll {
    . (Join-Path $PSScriptRoot '../Test-InsuranceFoundationConvergence.ps1')
}

Describe 'New-ConvergenceSummary' {
    It 'is Ready only when every component is Ready' {
        New-ConvergenceSummary -Results @(
            [pscustomobject]@{ Component='choices'; State='Ready' },
            [pscustomobject]@{ Component='tables'; State='Ready' },
            [pscustomobject]@{ Component='roles'; State='Ready' }
        ) | Select-Object -ExpandProperty State |
            Should -Be 'Ready'
    }

    It 'preserves the first blocking classification' {
        $summary = New-ConvergenceSummary -Results @(
            [pscustomobject]@{ Component='choices'; State='Ready' },
            [pscustomobject]@{
                Component='roles'; State='ManualPrerequisite'
            }
        )
        $summary.State | Should -Be 'ManualPrerequisite'
        $summary.BlockingComponents | Should -Contain 'roles'
    }
}
```

- [ ] **Step 2: Run tests and verify RED**

Run:

```powershell
Invoke-Pester .\scripts\solution\tests\Test-InsuranceFoundationConvergence.Tests.ps1 -Output Detailed
```

Expected: FAIL because the convergence script does not exist.

- [ ] **Step 3: Implement the convergence summary**

Create the script with:

```powershell
function New-ConvergenceSummary {
    param([Parameter(Mandatory)] [object[]]$Results)
    $blocking = @($Results | Where-Object State -ne 'Ready')
    [pscustomobject]@{
        State = if ($blocking.Count -eq 0) {
            'Ready'
        } else {
            [string]$blocking[0].State
        }
        BlockingComponents = @($blocking.Component)
        Results = @($Results)
        MutationOccurred = $false
    }
}
```

The online entry point must dot-source
`Publish-InsuranceFoundation.ps1` to reuse its pure contract and semantic
comparison functions, then perform GET-only checks for:

- required languages;
- both solutions;
- all choices and options;
- Account/Contact extensions;
- all tables, columns, relationships, cascades, keys, views, and forms;
- both security roles through `Test-InsuranceSecurityRoles.ps1`.

Dot-source safely with:

```powershell
. (Join-Path $PSScriptRoot 'Publish-InsuranceFoundation.ps1') `
    -EnvironmentUrl $EnvironmentUrl `
    -ContractPath $ContractPath
```

The publisher entry point is already guarded by
`$MyInvocation.InvocationName -ne '.'`; dot-sourcing must not mutate. The
convergence script must not call `Invoke-PlannedRequest`,
`Invoke-ChoiceReconciliation`, `Invoke-TableReconciliation`, or
`Invoke-RoleReconciliation`.

The entry point emits JSON and exits:

- `0` for `Ready`;
- `2` for `ManualPrerequisite` or `Precondition`;
- `3` for `ContractConflict`;
- `1` for transport failure.

- [ ] **Step 4: Add a no-mutation test**

Mock the verifier transport, invoke the online function, and assert:

```powershell
Assert-MockCalled Invoke-ConvergenceDataverseRequest `
    -ParameterFilter { $Method -ne 'GET' } -Times 0
```

- [ ] **Step 5: Run all solution tests**

Run:

```powershell
$result = Invoke-Pester .\scripts\solution\tests -PassThru -Output Normal
if ($result.Result -ne 'Passed') { throw 'Solution tests failed.' }
```

Expected: all tests pass.

- [ ] **Step 6: Commit**

```powershell
git add scripts/solution/Test-InsuranceFoundationConvergence.ps1 scripts/solution/tests/Test-InsuranceFoundationConvergence.Tests.ps1
git commit -m "feat(dataverse): add read-only convergence gate (US-707)"
```

### Task 7: Extract exact package export into a tested script

**Files:**
- Create: `scripts/solution/Export-InsuranceFoundationPackages.ps1`
- Create: `scripts/solution/tests/Export-InsuranceFoundationPackages.Tests.ps1`
- Modify: `.github/workflows/solution-author-dev.yml`

- [ ] **Step 1: Write failing export tests**

Create `scripts/solution/tests/Export-InsuranceFoundationPackages.Tests.ps1`:

```powershell
BeforeAll {
    . (Join-Path $PSScriptRoot '../Export-InsuranceFoundationPackages.ps1')
}

Describe 'Get-InsuranceFoundationExports' {
    It 'returns the exact four reviewed packages' {
        @((Get-InsuranceFoundationExports).File | Sort-Object) |
            Should -Be @(
                'crmshow_DataModel.zip',
                'crmshow_DataModel_managed.zip',
                'crmshow_Foundation.zip',
                'crmshow_Foundation_managed.zip'
            )
    }
}

Describe 'Assert-InsuranceFoundationPackageSet' {
    It 'rejects a missing package' {
        {
            Assert-InsuranceFoundationPackageSet -FileNames @(
                'crmshow_Foundation.zip'
            )
        } | Should -Throw '*Unexpected authored package set*'
    }

    It 'rejects an additional package' {
        {
            Assert-InsuranceFoundationPackageSet -FileNames @(
                (Get-InsuranceFoundationExports).File + 'unexpected.zip'
            )
        } | Should -Throw '*Unexpected authored package set*'
    }
}
```

- [ ] **Step 2: Run tests and verify RED**

Run:

```powershell
Invoke-Pester .\scripts\solution\tests\Export-InsuranceFoundationPackages.Tests.ps1 -Output Detailed
```

Expected: FAIL because the export script does not exist.

- [ ] **Step 3: Implement export and exact verification**

Create `scripts/solution/Export-InsuranceFoundationPackages.ps1`:

```powershell
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)] [string]$EnvironmentUrl,
    [Parameter(Mandatory)] [string]$OutputDirectory
)

$ErrorActionPreference = 'Stop'

function Get-InsuranceFoundationExports {
    @(
        [pscustomobject]@{
            Name='crmshow_Foundation'; Managed=$false
            File='crmshow_Foundation.zip'
        },
        [pscustomobject]@{
            Name='crmshow_Foundation'; Managed=$true
            File='crmshow_Foundation_managed.zip'
        },
        [pscustomobject]@{
            Name='crmshow_DataModel'; Managed=$false
            File='crmshow_DataModel.zip'
        },
        [pscustomobject]@{
            Name='crmshow_DataModel'; Managed=$true
            File='crmshow_DataModel_managed.zip'
        }
    )
}

function Assert-InsuranceFoundationPackageSet {
    param([Parameter(Mandatory)] [string[]]$FileNames)
    $expected = @((Get-InsuranceFoundationExports).File | Sort-Object)
    $actual = @($FileNames | Sort-Object)
    if (($actual -join '|') -ne ($expected -join '|')) {
        throw "Unexpected authored package set: $($actual -join ', ')."
    }
}

if ($MyInvocation.InvocationName -ne '.') {
    New-Item -ItemType Directory -Path $OutputDirectory -Force |
        Out-Null
    foreach ($export in Get-InsuranceFoundationExports) {
        $path = Join-Path $OutputDirectory $export.File
        if ($PSCmdlet.ShouldProcess($path, "Export $($export.Name)")) {
            & pac solution export `
                --environment $EnvironmentUrl `
                --name $export.Name `
                --path $path `
                --managed $export.Managed.ToString().ToLowerInvariant() `
                --overwrite
            if ($LASTEXITCODE -ne 0) {
                throw "Export failure for '$($export.File)'."
            }
        }
    }
    Assert-InsuranceFoundationPackageSet -FileNames @(
        Get-ChildItem -LiteralPath $OutputDirectory -File |
            ForEach-Object Name
    )
}
```

- [ ] **Step 4: Run tests and verify GREEN**

Run:

```powershell
Invoke-Pester .\scripts\solution\tests\Export-InsuranceFoundationPackages.Tests.ps1 -Output Detailed
```

Expected: all export tests pass.

- [ ] **Step 5: Commit**

```powershell
git add scripts/solution/Export-InsuranceFoundationPackages.ps1 scripts/solution/tests/Export-InsuranceFoundationPackages.Tests.ps1
git commit -m "refactor(dataverse): test exact solution export set (US-708)"
```

### Task 8: Rebuild the DEV workflow around preflight and explicit gates

**Files:**
- Modify: `.github/workflows/solution-author-dev.yml`
- Modify: `scripts/solution/tests/Publish-InsuranceFoundation.Tests.ps1`

- [ ] **Step 1: Write failing workflow-order and privilege-boundary tests**

Add to `Describe 'Publisher entry point safety'`:

```powershell
It 'runs read-only preflight before every Dataverse mutation' {
    $workflow = Get-Content (Join-Path $script:repoRoot `
        '.github/workflows/solution-author-dev.yml') -Raw
    $preflight = $workflow.IndexOf('- name: Run authoring preflight')
    $languages = $workflow.IndexOf('- name: Reconcile Dataverse languages')
    $metadata = $workflow.IndexOf('- name: Reconcile demo-safe metadata')
    $preflight | Should -BeGreaterOrEqual 0
    $preflight | Should -BeLessThan $languages
    $preflight | Should -BeLessThan $metadata
}

It 'uses Demo scope and never requests role authoring' {
    $workflow = Get-Content (Join-Path $script:repoRoot `
        '.github/workflows/solution-author-dev.yml') -Raw
    $workflow | Should -Match '-Scope Demo'
    $workflow | Should -Not -Match '-Scope (?:All|SecurityRoles)'
}

It 'validates convergence before exporting packages' {
    $workflow = Get-Content (Join-Path $script:repoRoot `
        '.github/workflows/solution-author-dev.yml') -Raw
    $validation = $workflow.IndexOf(
        '- name: Validate complete demo convergence'
    )
    $export = $workflow.IndexOf(
        '- name: Export managed and unmanaged solutions'
    )
    $validation | Should -BeGreaterOrEqual 0
    $validation | Should -BeLessThan $export
}
```

- [ ] **Step 2: Run publisher tests and verify RED**

Run:

```powershell
Invoke-Pester .\scripts\solution\tests\Publish-InsuranceFoundation.Tests.ps1 -Output Detailed
```

Expected: workflow assertions fail.

- [ ] **Step 3: Update the workflow**

Keep top-level permissions:

```yaml
permissions:
  contents: read
  id-token: write
```

Set checkout to avoid persisting credentials:

```yaml
- name: Check out reviewed commit
  uses: actions/checkout@v4
  with:
    persist-credentials: false
```

After PAC authentication and before language reconciliation, add:

```yaml
- name: Run authoring preflight
  shell: pwsh
  run: |
    $root = $env:GITHUB_WORKSPACE
    & (Join-Path $root 'scripts/solution/Test-InsuranceAuthoringPreflight.ps1') `
      -EnvironmentUrl $env:POWER_PLATFORM_ENV_URL `
      -ContractPath (Join-Path $root 'solution/schema/insurance-foundation.json')
    if ($LASTEXITCODE -eq 2) {
      throw 'Manual prerequisite: create and verify the reviewed DEV security roles using docs/runbooks/insurance-foundation-security-role-bootstrap.md.'
    }
    if ($LASTEXITCODE -ne 0) { throw 'Authoring preflight failed.' }
```

Rename and constrain metadata authoring:

```yaml
- name: Reconcile demo-safe metadata
  shell: pwsh
  run: |
    $root = $env:GITHUB_WORKSPACE
    & (Join-Path $root 'scripts/solution/Publish-InsuranceFoundation.ps1') `
      -EnvironmentUrl $env:POWER_PLATFORM_ENV_URL `
      -ContractPath (Join-Path $root 'solution/schema/insurance-foundation.json') `
      -Scope Demo `
      -Confirm:$false
    if ($LASTEXITCODE -ne 0) { throw 'Demo-safe metadata reconciliation failed.' }
```

Add the read-only export gate:

```yaml
- name: Validate complete demo convergence
  shell: pwsh
  run: |
    $root = $env:GITHUB_WORKSPACE
    & (Join-Path $root 'scripts/solution/Test-InsuranceFoundationConvergence.ps1') `
      -EnvironmentUrl $env:POWER_PLATFORM_ENV_URL `
      -ContractPath (Join-Path $root 'solution/schema/insurance-foundation.json')
    if ($LASTEXITCODE -ne 0) { throw 'Demo convergence validation failed.' }
```

Replace inline export logic with:

```yaml
- name: Export managed and unmanaged solutions
  shell: pwsh
  run: |
    $root = $env:GITHUB_WORKSPACE
    $artifact = Join-Path $env:RUNNER_TEMP 'insurance-foundation-authoring'
    & (Join-Path $root 'scripts/solution/Export-InsuranceFoundationPackages.ps1') `
      -EnvironmentUrl $env:POWER_PLATFORM_ENV_URL `
      -OutputDirectory $artifact `
      -Confirm:$false
    if ($LASTEXITCODE -ne 0) { throw 'Solution package export failed.' }
```

Remove the redundant inline package verification step because the tested export
script performs exact verification.

- [ ] **Step 4: Update the offline test list**

Include all new suites:

```powershell
$targeted = Invoke-Pester -Path @(
  (Join-Path $root 'scripts/solution/tests/InsuranceFoundationContract.Tests.ps1'),
  (Join-Path $root 'scripts/solution/tests/Publish-InsuranceFoundation.Tests.ps1'),
  (Join-Path $root 'scripts/solution/tests/Test-InsuranceAuthoringPreflight.Tests.ps1'),
  (Join-Path $root 'scripts/solution/tests/Test-InsuranceSecurityRoles.Tests.ps1'),
  (Join-Path $root 'scripts/solution/tests/Test-InsuranceFoundationConvergence.Tests.ps1'),
  (Join-Path $root 'scripts/solution/tests/Export-InsuranceFoundationPackages.Tests.ps1'),
  (Join-Path $root 'infra/scripts/tests/Set-DataverseLanguages.Tests.ps1')
) -PassThru -Output Detailed
```

- [ ] **Step 5: Run local workflow contract tests**

Run:

```powershell
$result = Invoke-Pester -Path @(
  '.\scripts\solution\tests\Publish-InsuranceFoundation.Tests.ps1',
  '.\scripts\solution\tests\Test-InsuranceAuthoringPreflight.Tests.ps1',
  '.\scripts\solution\tests\Test-InsuranceSecurityRoles.Tests.ps1',
  '.\scripts\solution\tests\Test-InsuranceFoundationConvergence.Tests.ps1',
  '.\scripts\solution\tests\Export-InsuranceFoundationPackages.Tests.ps1'
) -PassThru -Output Detailed
if ($result.Result -ne 'Passed') { throw 'Workflow contract tests failed.' }
```

Expected: all tests pass.

- [ ] **Step 6: Review Actions security**

Verify:

- no `pull_request_target`, `workflow_run`, or `issue_comment` trigger;
- top-level permissions remain `contents: read` and `id-token: write`;
- no untrusted `${{ github.event.* }}` value appears in a `run:` block;
- OIDC remains the only cloud authentication method;
- `persist-credentials: false` is set;
- no secret or token is logged.

Run:

```powershell
rg "pull_request_target|workflow_run|issue_comment|github\.event|client-secret|password" .github/workflows/solution-author-dev.yml
```

Expected: no unsafe trigger, interpolation, or credential matches.

- [ ] **Step 7: Commit**

```powershell
git add .github/workflows/solution-author-dev.yml scripts/solution/tests/Publish-InsuranceFoundation.Tests.ps1
git commit -m "ci(dataverse): gate DEV authoring by tenant capability (US-708)"
```

### Task 9: Validate the administrator gate and complete DEV export

**Files:**
- Modify: `docs/runbooks/insurance-foundation-security-role-bootstrap.md`
- Modify: `docs/superpowers/plans/2026-08-08-insurance-foundation.md`
- GitHub evidence: issue #8 and issue #40

- [ ] **Step 1: Run the complete offline suite**

Run:

```powershell
Import-Module Pester -RequiredVersion 6.0.1
$result = Invoke-Pester -Path @(
  '.\scripts\solution\tests',
  '.\infra\scripts\tests'
) -PassThru -Output Normal
if ($result.Result -ne 'Passed') { throw 'Offline suites failed.' }
```

Expected: every suite passes.

- [ ] **Step 2: Push a PR and wait for both existing CI gates**

Run:

```powershell
git push -u origin HEAD
gh pr create `
  --base main `
  --title "feat(dataverse): add demo-feasible DEV authoring gates" `
  --body "Implements US-702 and US-708 under ADR-0023. Adds read-only preflight, demo-safe authoring, bounded metadata convergence, manual role bootstrap verification, and exact export gating. Relates to #8 and #40."
gh pr checks --watch
```

Expected: both `gate1` checks pass.

- [ ] **Step 3: Merge and run the workflow before administrator bootstrap**

Run:

```powershell
gh pr merge --squash --delete-branch
gh workflow run solution-author-dev.yml --ref main
$runId = gh run list --workflow solution-author-dev.yml --limit 1 --json databaseId --jq '.[0].databaseId'
gh run watch $runId --exit-status
```

Expected when roles are still absent:

- preflight stops before `Reconcile Dataverse languages`;
- no schema mutation step runs;
- failure message identifies the manual security-role prerequisite;
- issue #40 receives the run URL.

- [ ] **Step 4: Perform the administrator prerequisite**

An authorized Power Platform administrator follows
`docs/runbooks/insurance-foundation-security-role-bootstrap.md`.

Expected:

- both roles exist in `crmshow_Foundation`;
- role verification returns `Ready`;
- no GitHub identity is elevated.

- [ ] **Step 5: Rerun DEV authoring**

Run:

```powershell
gh workflow run solution-author-dev.yml --ref main
$runId = gh run list --workflow solution-author-dev.yml --limit 1 --json databaseId --jq '.[0].databaseId'
gh run watch $runId --exit-status
```

Expected:

- preflight passes;
- metadata converges in one run;
- convergence validation passes;
- exactly four packages are uploaded.

- [ ] **Step 6: Download and verify the artifact**

Run:

```powershell
$runId = gh run list --workflow solution-author-dev.yml --limit 1 --json databaseId --jq '.[0].databaseId'
$output = Join-Path $env:TEMP "insurance-foundation-$runId"
gh run download $runId -n insurance-foundation-authoring -D $output
$actual = @(Get-ChildItem -LiteralPath $output -File | Sort-Object Name | ForEach-Object Name)
$expected = @(
  'crmshow_DataModel.zip',
  'crmshow_DataModel_managed.zip',
  'crmshow_Foundation.zip',
  'crmshow_Foundation_managed.zip'
)
if (($actual -join '|') -ne ($expected -join '|')) {
  throw "Unexpected package set: $($actual -join ', ')"
}
```

Expected: exact match.

- [ ] **Step 7: Prove steady-state idempotency**

Trigger the workflow a second time without changing permissions or metadata:

```powershell
gh workflow run solution-author-dev.yml --ref main
$runId = gh run list --workflow solution-author-dev.yml --limit 1 --json databaseId --jq '.[0].databaseId'
gh run watch $runId --exit-status
```

Expected:

- no `POST /roles`;
- no `AddPrivilegesRole` or `ReplacePrivilegesRole`;
- schema reports unchanged/updated localization only;
- export succeeds again.

- [ ] **Step 8: Record evidence and close the bootstrap blocker**

Comment on issue #8 with:

- successful first-run URL;
- successful idempotency-run URL;
- four package names;
- Pester count;
- statement that TEST promotion remains deferred.

Comment on issue #40 with:

- administrator bootstrap evidence;
- read-only role verifier output;
- confirmation that normal CI retained `System Customizer`.

Close issue #40 only after both successful runs.

- [ ] **Step 9: Update the original Sprint 3 plan**

In `docs/superpowers/plans/2026-08-08-insurance-foundation.md`, mark the
completed DEV authoring/export steps and add:

```markdown
Managed TEST promotion, TEST deployment evidence, fixtures, and persona
security smoke tests remain separate follow-up work. Sprint 3 demo evidence
is limited to the approved DEV package-authoring boundary in ADR-0023.
```

- [ ] **Step 10: Commit evidence documentation**

```powershell
git add docs/runbooks/insurance-foundation-security-role-bootstrap.md docs/superpowers/plans/2026-08-08-insurance-foundation.md
git commit -m "docs(sprint-3): record DEV authoring evidence (US-708)"
```

## Completion criteria

The plan is complete only when:

- normal GitHub CI never attempts security-role mutation;
- missing roles are reported before any environment mutation;
- an authorized administrator creates the roles without sharing credentials;
- metadata converges in one workflow run;
- read-only validation passes before export;
- exactly four packages are uploaded;
- a second run succeeds under the steady-state `System Customizer` identity;
- issue #8 contains the evidence;
- issue #40 is closed with bootstrap and rollback evidence;
- no claim is made that TEST promotion or automated privileged bootstrap is
  delivered.
