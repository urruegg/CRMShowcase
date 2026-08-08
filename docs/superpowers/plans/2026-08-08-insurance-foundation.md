# Insurance Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deliver Sprint 3's multilingual Insurance Foundation as unmanaged solutions in DEV and managed solutions in TEST, with repeatable language readiness, schema, security, fixtures, validation, and deployment evidence.

**Architecture:** Terraform owns the required Dataverse language set, while an idempotent PowerShell control reconciles additional languages through the documented `LanguageLocale` Web API. `crmshow_Foundation` owns shared choices and security roles; `crmshow_DataModel` owns Account/Contact extensions and the three insurance tables. Initial schema authoring occurs in DEV through a declarative, solution-aware Web API script, after which the exported/unpacked solution source becomes the only deployment artefact.

**Tech Stack:** Terraform 1.9.8, `microsoft/power-platform` provider 3.9.1, PowerShell 5.1-compatible scripts, Pester 5.5+, PAC CLI, Dataverse Web API v9.2, GitHub Actions OIDC, unpacked Dataverse solution XML.

---

## Scope and task ownership

| Task | Primary agent | Required reviewers |
| --- | --- | --- |
| 1. Traceability and version baseline | Product Owner | Enterprise Architect |
| 2. Language desired state and reconciliation | SecDevOps | Enterprise Architect |
| 3. Explicit managed import modes | Integration Engineer | SecDevOps |
| 4. Insurance metadata contract | Dataverse Modeler | CRM Domain, Insurance Domain, Responsible AI |
| 5. DEV schema authoring and solution capture | Dataverse Modeler | Enterprise Architect |
| 6. Metadata/source validation | Developer | Dataverse Modeler, Responsible AI |
| 7. Fixtures and environment smoke tests | Developer | CRM Domain, Insurance Domain |
| 8. DEV and TEST deployment workflows | SecDevOps | Integration Engineer |
| 9. End-to-end deployment evidence | Developer | Product Owner, Enterprise Architect |

The implementation branch must be created in an isolated worktree using the
`using-git-worktrees` skill. Preserve the untracked
`intake/mobiliar/ideas/` and `.superpowers/` directories.

## File map

| Path | Responsibility |
| --- | --- |
| `docs/BACKLOG.md` | Epic 7 stories US-701 through US-709 and issue #8 linkage |
| `solution/manifest.json` | Foundation/DataModel semantic versions |
| `infra/terraform/variables.tf` | Root language desired-state type |
| `infra/terraform/terraform.tfvars.example` | Safe EN/DE/FR/IT example values |
| `infra/terraform/main.tf` | Pass language state into Power Platform module |
| `infra/terraform/modules/powerplatform/variables.tf` | Module language input contract |
| `infra/terraform/modules/powerplatform/outputs.tf` | Environment language contract output |
| `infra/terraform/outputs.tf` | Root language contract output |
| `infra/scripts/Set-DataverseLanguages.ps1` | Idempotent read/activate/verify control |
| `infra/scripts/tests/Set-DataverseLanguages.Tests.ps1` | Language-control unit tests |
| `infra/terraform/modules/entra/main.tf` | Dedicated Reader/Data Steward smoke identities |
| `infra/terraform/modules/github/main.tf` | Expose smoke identity client IDs to environment-scoped workflows |
| `infra/scripts/add-ci-app-users.ps1` | Create smoke application users and assign showcase roles |
| `scripts/solution/Import-Solution.ps1` | Install/update/stage/apply import modes |
| `scripts/solution/tests/Import-Solution.Tests.ps1` | PAC argument unit tests |
| `solution/schema/insurance-foundation.schema.json` | JSON Schema for authoring contract |
| `solution/schema/insurance-foundation.json` | Tables, columns, choices, roles and localized semantic metadata |
| `scripts/solution/Publish-InsuranceFoundation.ps1` | DEV-only solution-aware metadata authoring |
| `scripts/solution/tests/Publish-InsuranceFoundation.Tests.ps1` | Request-shape and idempotency tests |
| `.github/workflows/solution-author-dev.yml` | Approved OIDC-only initial DEV authoring and export |
| `solution/core/foundation/**` | Exported shared choices and security roles |
| `solution/core/datamodel/**` | Exported native extensions, tables, relationships, rules and keys |
| `scripts/solution/Test-SemanticMetadata.ps1` | Offline EN/DE/FR/IT source validation |
| `scripts/solution/tests/Test-SemanticMetadata.Tests.ps1` | Validator unit tests |
| `fixtures/insurance-foundation.json` | Synthetic deterministic fixture contract |
| `scripts/solution/Set-InsuranceFoundationFixtures.ps1` | Alternate-key upsert fixture loader |
| `scripts/solution/Test-InsuranceFoundation.ps1` | Online language/schema/CRUD/security smoke tests |
| `scripts/solution/tests/InsuranceFoundation.Tests.ps1` | Fixture/smoke helper unit tests |
| `.github/workflows/solution-ci.yml` | Offline schema and metadata gates |
| `.github/workflows/solution-deploy-dev.yml` | OIDC, language reconcile, unmanaged deploy, fixtures, smoke |
| `.github/workflows/solution-deploy-test.yml` | Approval, preflight, managed install/update, smoke |
| `docs/runbooks/insurance-foundation-deployment.md` | Operator inputs, evidence and rollback |

### Task 1: Establish Sprint 3 traceability and versions

**Files:**
- Modify: `docs/BACKLOG.md`
- Modify: `solution/manifest.json`
- Modify: `solution/core/foundation/Other/Solution.xml`
- Modify: `solution/core/datamodel/Other/Solution.xml`

- [ ] **Step 1: Add Epic 7 to the backlog**

Add this table before “Bootstrap stories already delivered”:

```markdown
## Epic 7 — Insurance Foundation (Sprint 3)

Traces to [GitHub issue #8](https://github.com/urruegg/CRMShowcase/issues/8)
and the
[Sprint 3 design](./superpowers/specs/2026-08-08-insurance-foundation-design.md).

| ID | Story | Status |
| --- | --- | --- |
| US-701 | Reconcile EN/DE/FR/IT environment languages as IaC desired state | Planned — [#8](https://github.com/urruegg/CRMShowcase/issues/8) |
| US-702 | Deliver shared insurance choices and security roles | Planned — [#8](https://github.com/urruegg/CRMShowcase/issues/8) |
| US-703 | Extend Account and Contact | Planned — [#8](https://github.com/urruegg/CRMShowcase/issues/8) |
| US-704 | Deliver effective-dated AccountContactRole | Planned — [#8](https://github.com/urruegg/CRMShowcase/issues/8) |
| US-705 | Deliver Account-owned PolicyProjection | Planned — [#8](https://github.com/urruegg/CRMShowcase/issues/8) |
| US-706 | Deliver effective-dated PolicyPartyRole | Planned — [#8](https://github.com/urruegg/CRMShowcase/issues/8) |
| US-707 | Validate schema and multilingual semantic metadata | Planned — [#8](https://github.com/urruegg/CRMShowcase/issues/8) |
| US-708 | Deploy unmanaged to DEV and managed to TEST | Planned — [#8](https://github.com/urruegg/CRMShowcase/issues/8) |
| US-709 | Load synthetic fixtures and publish smoke evidence | Planned — [#8](https://github.com/urruegg/CRMShowcase/issues/8) |
```

- [ ] **Step 2: Write a failing version assertion**

Add to `scripts/solution/tests/Get-Manifest.Tests.ps1`:

```powershell
It "versions the Sprint 3 Foundation and DataModel solutions at 1.1.0.0" {
    $m = Get-Manifest -Path (Join-Path $script:repoRoot 'solution/manifest.json')
    ($m.solutions | Where-Object uniqueName -eq 'crmshow_Foundation').version |
        Should -Be '1.1.0.0'
    ($m.solutions | Where-Object uniqueName -eq 'crmshow_DataModel').version |
        Should -Be '1.1.0.0'
}
```

- [ ] **Step 3: Run the test and verify failure**

Run:

```powershell
Invoke-Pester .\scripts\solution\tests\Get-Manifest.Tests.ps1 -Output Detailed
```

Expected: the new assertion fails because both versions are `1.0.0.0`.

- [ ] **Step 4: Bump the manifest and solution XML**

Set Foundation and DataModel to `1.1.0.0` in `solution/manifest.json` and in
their `Other/Solution.xml` files. Do not change the other four solutions.

- [ ] **Step 5: Re-run the test**

Expected: all `Get-Manifest.Tests.ps1` tests pass.

- [ ] **Step 6: Commit**

```powershell
git add docs/BACKLOG.md solution/manifest.json solution/core/foundation/Other/Solution.xml solution/core/datamodel/Other/Solution.xml scripts/solution/tests/Get-Manifest.Tests.ps1
git commit -m "chore(sprint-3): establish insurance foundation baseline (US-701)"
```

### Task 2: Implement Dataverse language desired state

**Files:**
- Modify: `infra/terraform/variables.tf`
- Modify: `infra/terraform/terraform.tfvars.example`
- Modify: `infra/terraform/main.tf`
- Modify: `infra/terraform/modules/powerplatform/variables.tf`
- Modify: `infra/terraform/modules/powerplatform/outputs.tf`
- Modify: `infra/terraform/outputs.tf`
- Create: `infra/scripts/Set-DataverseLanguages.ps1`
- Create: `infra/scripts/tests/Set-DataverseLanguages.Tests.ps1`
- Modify: `infra/terraform/README.md`

- [ ] **Step 1: Write failing language-contract tests**

Create `infra/scripts/tests/Set-DataverseLanguages.Tests.ps1`:

```powershell
BeforeAll {
    . "$PSScriptRoot/../Set-DataverseLanguages.ps1" -EnvironmentUrl 'https://example.crm.dynamics.com' -LocaleId 1033 -WhatIf
}

Describe 'Get-NormalizedLocaleIds' {
    It 'returns unique sorted supported locale IDs' {
        Get-NormalizedLocaleIds -LocaleId @(1040, 1033, 1031, 1036, 1033) |
            Should -Be @(1031, 1033, 1036, 1040)
    }

    It 'rejects an unsupported locale ID' {
        { Get-NormalizedLocaleIds -LocaleId @(1033, 9999) } |
            Should -Throw '*Unsupported Dataverse locale ID*'
    }
}

Describe 'Get-LanguageTransition' {
    It 'skips an active language' {
        Get-LanguageTransition -LocaleId 1031 -StateCode 0 | Should -Be 'Unchanged'
    }

    It 'activates an inactive language' {
        Get-LanguageTransition -LocaleId 1031 -StateCode 1 | Should -Be 'Activate'
    }
}
```

- [ ] **Step 2: Run the test and verify failure**

Run:

```powershell
Invoke-Pester .\infra\scripts\tests\Set-DataverseLanguages.Tests.ps1 -Output Detailed
```

Expected: failure because the script/functions do not exist.

- [ ] **Step 3: Add the Terraform language contract**

Add `required_languages` to each environment object in both root and module
variable definitions:

```hcl
required_languages = optional(set(string), ["1033", "1031", "1036", "1040"])
```

Add this validation to the root `environments` variable:

```hcl
validation {
  condition = alltrue([
    for env in values(var.environments) :
    contains(env.required_languages, env.language) &&
    alltrue([for lcid in env.required_languages : contains(["1033", "1031", "1036", "1040"], lcid)])
  ])
  error_message = "Each environment must include its base language and may use only 1033, 1031, 1036 and 1040."
}
```

Pass the environment map unchanged to the module. Add module and root outputs:

```hcl
output "required_languages" {
  description = "Required Dataverse LCIDs keyed by environment slot."
  value       = { for slot, env in var.environments : slot => sort(tolist(env.required_languages)) }
}
```

Add this to DEV and TEST in `terraform.tfvars.example`:

```hcl
required_languages = ["1033", "1031", "1036", "1040"]
```

- [ ] **Step 4: Implement the idempotent reconciliation script**

Create `infra/scripts/Set-DataverseLanguages.ps1` with these public
parameters and functions:

```powershell
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)] [ValidatePattern('^https://[^/]+\.crm\d*\.dynamics\.com/?$')]
    [string]$EnvironmentUrl,
    [Parameter(Mandatory)] [int[]]$LocaleId
)

$ErrorActionPreference = 'Stop'
$script:SupportedLocaleIds = @(1031, 1033, 1036, 1040)

function Get-NormalizedLocaleIds {
    param([int[]]$LocaleId)
    $unsupported = @($LocaleId | Where-Object { $_ -notin $script:SupportedLocaleIds })
    if ($unsupported.Count -gt 0) {
        throw "Unsupported Dataverse locale ID: $($unsupported -join ', ')."
    }
    return @($LocaleId | Sort-Object -Unique)
}

function Get-LanguageTransition {
    param([int]$LocaleId, [int]$StateCode)
    if ($StateCode -eq 0) { return 'Unchanged' }
    if ($StateCode -eq 1) { return 'Activate' }
    throw "Unexpected statecode '$StateCode' for locale '$LocaleId'."
}

function Wait-DataverseLanguage {
    param(
        [string]$BaseUrl,
        [int]$LocaleId,
        [int]$TimeoutSeconds = 3600,
        [int]$PollSeconds = 30
    )
    $deadline = [DateTimeOffset]::UtcNow.AddSeconds($TimeoutSeconds)
    do {
        $verify = Invoke-DataverseRest -Method GET -Url "$BaseUrl/api/data/v9.2/languagelocale?`$select=localeid,statecode&`$filter=localeid eq $LocaleId"
        if ($verify.value.Count -eq 1 -and $verify.value[0].statecode -eq 0) { return }
        Start-Sleep -Seconds $PollSeconds
    } while ([DateTimeOffset]::UtcNow -lt $deadline)
    throw "Locale '$LocaleId' did not become active within $TimeoutSeconds seconds."
}

function Invoke-DataverseRest {
    param([string]$Method, [string]$Url, [object]$Body)
    $resource = $EnvironmentUrl.TrimEnd('/') + '/'
    $arguments = @('rest', '--method', $Method, '--url', $Url, '--resource', $resource, '--only-show-errors')
    $temp = $null
    try {
        if ($null -ne $Body) {
            $temp = New-TemporaryFile
            $Body | ConvertTo-Json -Depth 5 | Set-Content $temp -Encoding utf8
            $arguments += @('--body', "@$temp", '--headers', 'Content-Type=application/json')
        }
        $result = & az @arguments
        if ($LASTEXITCODE -ne 0) { throw "Dataverse request failed: $Method $Url" }
        if ($result) { return $result | ConvertFrom-Json }
    } finally {
        if ($temp) { Remove-Item $temp -Force -ErrorAction SilentlyContinue }
    }
}

if ($MyInvocation.InvocationName -ne '.') {
    $base = $EnvironmentUrl.TrimEnd('/')
    $required = Get-NormalizedLocaleIds -LocaleId $LocaleId
    foreach ($lcid in $required) {
        $query = "$base/api/data/v9.2/languagelocale?`$select=languagelocaleid,localeid,statecode,statuscode&`$filter=localeid eq $lcid"
        $response = Invoke-DataverseRest -Method GET -Url $query
        if ($response.value.Count -ne 1) { throw "Locale '$lcid' is unavailable in $base." }
        $language = $response.value[0]
        if ((Get-LanguageTransition -LocaleId $lcid -StateCode $language.statecode) -eq 'Activate') {
            if ($PSCmdlet.ShouldProcess("$base locale $lcid", 'Activate Dataverse language')) {
                $url = "$base/api/data/v9.2/languagelocale($($language.languagelocaleid))"
                Invoke-DataverseRest -Method PATCH -Url $url -Body @{ statecode = 0; statuscode = 1 } | Out-Null
            }
        }
    }
    foreach ($lcid in $required) {
        Wait-DataverseLanguage -BaseUrl $base -LocaleId $lcid
        Write-Output ([pscustomobject]@{ Environment = $base; LocaleId = $lcid; State = 'Active' })
    }
}
```

Add Pester tests with `Mock Start-Sleep` proving that polling succeeds after an
inactive read and throws after a short test timeout. Production defaults remain
one hour and 30 seconds.

- [ ] **Step 5: Run tests and Terraform validation**

Run:

```powershell
Invoke-Pester .\infra\scripts\tests\Set-DataverseLanguages.Tests.ps1 -Output Detailed
terraform -chdir=infra/terraform fmt -recursive
terraform -chdir=infra/terraform init -backend=false
terraform -chdir=infra/terraform validate
```

Expected: Pester passes and Terraform reports `Success! The configuration is valid.`

- [ ] **Step 6: Document ordering and security**

Update `infra/terraform/README.md`: application users are created first,
`Set-DataverseLanguages.ps1` runs second, and solution import runs third.
Document that tokens are acquired by `az rest`, never stored in Terraform
state, and languages are never automatically disabled.

- [ ] **Step 7: Commit**

```powershell
git add infra
git commit -m "feat(infra): reconcile Dataverse languages as desired state (US-701)"
```

### Task 3: Add explicit managed solution import modes

**Files:**
- Modify: `scripts/solution/Import-Solution.ps1`
- Create: `scripts/solution/tests/Import-Solution.Tests.ps1`

- [ ] **Step 1: Write failing PAC argument tests**

Create `scripts/solution/tests/Import-Solution.Tests.ps1`:

```powershell
BeforeAll { . "$PSScriptRoot/../Import-Solution.ps1" }

Describe 'Get-SolutionImportArguments' {
    It 'uses normal import for install or update' {
        Get-SolutionImportArguments -ZipFile 'a.zip' -Mode InstallOrUpdate |
            Should -Be @('solution','import','--path','a.zip')
    }

    It 'uses a holding solution for staged upgrade' {
        Get-SolutionImportArguments -ZipFile 'a.zip' -Mode StageForUpgrade |
            Should -Be @('solution','import','--path','a.zip','--import-as-holding')
    }

    It 'builds apply-upgrade arguments from a unique name' {
        Get-SolutionUpgradeArguments -SolutionName 'crmshow_DataModel' |
            Should -Be @('solution','upgrade','--solution-name','crmshow_DataModel')
    }
}
```

- [ ] **Step 2: Run the test and verify failure**

Expected: functions or `Mode` parameter are missing.

- [ ] **Step 3: Replace force-overwrite with explicit modes**

Add:

```powershell
[CmdletBinding(SupportsShouldProcess)]
[ValidateSet('InstallOrUpdate','StageForUpgrade','ApplyUpgrade')]
[string]$Mode = 'InstallOrUpdate',
[string]$SolutionName
```

Implement:

```powershell
function Get-SolutionImportArguments {
    param([string]$ZipFile, [string]$Mode)
    $result = @('solution','import','--path',$ZipFile)
    if ($Mode -eq 'StageForUpgrade') { $result += '--import-as-holding' }
    return $result
}

function Get-SolutionUpgradeArguments {
    param([string]$SolutionName)
    if ([string]::IsNullOrWhiteSpace($SolutionName)) {
        throw 'SolutionName is required for ApplyUpgrade.'
    }
    return @('solution','upgrade','--solution-name',$SolutionName)
}
```

When `Mode` is `ApplyUpgrade`, require `SolutionName` and do not require
`ZipFile`. Preserve `Async` and `PublishChanges` only for import modes. Remove
`--force-overwrite`. Put top-level PAC execution behind:

```powershell
if ($MyInvocation.InvocationName -ne '.') {
    # Validate parameters, build arguments, call PAC under ShouldProcess.
}
```

- [ ] **Step 4: Run tests**

Run:

```powershell
Invoke-Pester .\scripts\solution\tests\Import-Solution.Tests.ps1 -Output Detailed
```

Expected: all tests pass.

- [ ] **Step 5: Commit**

```powershell
git add scripts/solution/Import-Solution.ps1 scripts/solution/tests/Import-Solution.Tests.ps1
git commit -m "feat(alm): add explicit managed import modes (US-708)"
```

### Task 4: Create the reviewed insurance metadata contract

**Files:**
- Create: `solution/schema/insurance-foundation.schema.json`
- Create: `solution/schema/insurance-foundation.json`
- Create: `scripts/solution/tests/InsuranceFoundationContract.Tests.ps1`

- [ ] **Step 1: Define a failing contract test**

The test must assert the exact required component set:

```powershell
BeforeAll {
    $script:contractPath = Join-Path $PSScriptRoot '../../../solution/schema/insurance-foundation.json'
}

Describe 'Insurance Foundation contract' {
    It 'contains the required languages' {
        $c = Get-Content $script:contractPath -Raw | ConvertFrom-Json
        @($c.languages) | Should -Be @('1033','1031','1036','1040')
    }

    It 'contains exactly three custom tables' {
        $c = Get-Content $script:contractPath -Raw | ConvertFrom-Json
        @($c.tables.logicalName) | Should -Be @(
            'crmshow_accountcontactrole',
            'crmshow_policyprojection',
            'crmshow_policypartyrole'
        )
    }

    It 'uses a Customer lookup for the policy party' {
        $c = Get-Content $script:contractPath -Raw | ConvertFrom-Json
        $table = $c.tables | Where-Object logicalName -eq 'crmshow_policypartyrole'
        ($table.columns | Where-Object logicalName -eq 'crmshow_partyid').type |
            Should -Be 'Customer'
    }
}
```

- [ ] **Step 2: Run the test and verify failure**

Expected: failure because the contract files do not exist.

- [ ] **Step 3: Create the JSON Schema**

Require:

```json
{
  "required": ["languages", "solutions", "choices", "nativeExtensions", "tables", "roles"],
  "properties": {
    "languages": {
      "type": "array",
      "const": ["1033", "1031", "1036", "1040"]
    },
    "localizedText": {
      "type": "object",
      "required": ["1033", "1031", "1036", "1040"],
      "additionalProperties": false
    }
  }
}
```

Define reusable `$defs` for localized label/description pairs, columns,
lookups, choices, alternate keys, relationships, validation requirements and
roles.
Set `additionalProperties: false` at every object boundary.

The existing `businessRules` contract entries describe the deferred
effective-date requirement and its localized semantics. Sprint 3 validators
consume them for fixture/import checks and reporting; the authoring script does
not create workflow/business-rule components. Universal write-path enforcement
is tracked by OR-001 and issue #9.

- [ ] **Step 4: Create the complete contract**

`insurance-foundation.json` must encode, without environment GUIDs:

- five global choices from the design;
- Account `crmshow_accounttype`;
- Contact `crmshow_lifecyclestage`;
- all columns, lookups and alternate keys for the three tables;
- fixture/import date-order validation and environment data-quality reporting;
- Reader and Data Steward roles using this exact privilege matrix:

| Table | Reader | Data Steward |
| --- | --- | --- |
| Account and Contact | Organization Read | Organization Read |
| AccountContactRole | Organization Read | Organization Create, Read, Write, Append and Append To |
| PolicyProjection | Organization Read | Organization Create, Read, Write, Append and Append To |
| PolicyPartyRole | Organization Read | Organization Create, Read, Write, Append and Append To |

Neither role receives Delete, Assign, Share, security-role administration,
solution customization, bulk-delete or audit-partition administration
privileges.
- EN/DE/FR/IT label and semantic-description objects for every component;
- ownership (`UserOwned`), auditing, activity flags and solution ownership.

Use stable English logical names from the design. Do not invent Mobiliar
licensing claims, customer names or source-system codes. Translations must be
reviewed by the CRM Domain Expert, Insurance Domain Expert and
Responsible-AI Officer before this task is accepted.

- [ ] **Step 5: Record translation acceptance**

Run the three required custom-agent reviews against
`solution/schema/insurance-foundation.json`. Record reviewer name, reviewed
commit SHA, languages, blocking findings and approval in issue #8. A machine
translation output without this evidence does not pass the task.

- [ ] **Step 6: Validate and test**

Run:

```powershell
. .\scripts\solution\Get-Manifest.ps1
Test-Json (Get-Content .\solution\schema\insurance-foundation.json -Raw) -SchemaFile .\solution\schema\insurance-foundation.schema.json
Invoke-Pester .\scripts\solution\tests\InsuranceFoundationContract.Tests.ps1 -Output Detailed
```

Expected: JSON Schema validation returns `True`; Pester passes.

- [ ] **Step 7: Commit**

```powershell
git add solution/schema scripts/solution/tests/InsuranceFoundationContract.Tests.ps1
git commit -m "feat(datamodel): define insurance foundation metadata contract (US-702 US-703 US-704 US-705 US-706)"
```

### Task 5: Author the schema in DEV and capture solution source

**Files:**
- Create: `scripts/solution/Publish-InsuranceFoundation.ps1`
- Create: `scripts/solution/tests/Publish-InsuranceFoundation.Tests.ps1`
- Create: `.github/workflows/solution-author-dev.yml`
- Modify: `solution/core/foundation/**`
- Modify: `solution/core/datamodel/**`

- [ ] **Step 1: Write failing request-shape tests**

Test pure functions for:

```powershell
Get-DataverseHeaders -SolutionUniqueName 'crmshow_DataModel'
# Must include:
# MSCRM.SolutionUniqueName = crmshow_DataModel
# MSCRM.SuppressDuplicateDetection = false

Get-TableCreateRequest -Table $contract.tables[0]
# Must contain all ordinary lookup columns in the initial EntityDefinitions POST.

Get-CustomerRelationshipRequest -Table $policyPartyTable -Column $partyColumn
# Must call CreateCustomerRelationships immediately after the owning table is created.

Get-AlternateKeyRequest -TableLogicalName 'crmshow_policyprojection' -Columns @('crmshow_externalsystem','crmshow_externalid')
# Must target EntityDefinitions(LogicalName='crmshow_policyprojection')/Keys.
```

Mock `Invoke-DataverseRequest` and assert:

- existing components are read and compared, not recreated;
- conflicting existing types throw;
- table creation sends all ordinary lookup attributes in one request;
- the Customer lookup uses Dataverse `CreateCustomerRelationships` once,
  immediately after table creation, and is never deleted/recreated;
- component requests carry the owning solution header.

- [ ] **Step 2: Run tests and verify failure**

Expected: failure because the publisher script does not exist.

- [ ] **Step 3: Implement solution-aware authoring**

`Publish-InsuranceFoundation.ps1` accepts:

```powershell
param(
    [Parameter(Mandatory)] [string]$EnvironmentUrl,
    [Parameter(Mandatory)] [string]$ContractPath,
    [ValidateSet('Foundation','DataModel','All')] [string]$Scope = 'All'
)
```

The script:

1. validates the contract against its JSON Schema;
2. uses `az rest --resource "$EnvironmentUrl/"`;
3. resolves components by logical name;
4. creates missing choices in `crmshow_Foundation`;
5. creates native attributes and custom tables in `crmshow_DataModel`;
6. includes every ordinary lookup in the initial table create request;
7. creates the PolicyPartyRole Customer lookup with the documented
   `CreateCustomerRelationships` action immediately after its table exists;
8. creates keys, a minimal administration form/view per custom table and an
   overlap/invalid-date reporting system view;
9. creates/updates the two security roles from named privileges and depths;
10. publishes all customizations;
11. fails on any type/target mismatch instead of silently replacing metadata.

Use `MSCRM.SolutionUniqueName` on every create/update request. Never delete or
recreate a lookup. Log logical names and statuses only; never log tokens or
record payloads.

- [ ] **Step 4: Run unit tests**

Expected: all publisher request-shape tests pass.

- [ ] **Step 5: Add the controlled authoring workflow**

`solution-author-dev.yml` is manual-dispatch only, uses GitHub Environment
`dev`, `azure/login@v2` with `allow-no-subscriptions: true`, installs PAC CLI,
reconciles languages, runs the publisher, exports both managed and unmanaged
variants, and uploads them as one `insurance-foundation-authoring` artifact.
It has `contents: read` and `id-token: write`; it never commits or pushes.

The workflow runs:

```powershell
.\infra\scripts\Set-DataverseLanguages.ps1 `
  -EnvironmentUrl $env:POWER_PLATFORM_ENV_URL `
  -LocaleId 1033,1031,1036,1040

.\scripts\solution\Publish-InsuranceFoundation.ps1 `
  -EnvironmentUrl $env:POWER_PLATFORM_ENV_URL `
  -ContractPath .\solution\schema\insurance-foundation.json
```

Expected: all components report `Created`, `Updated` or `Unchanged`; no lookup
is deleted/recreated.

- [ ] **Step 6: Run controlled authoring and download exports**

Dispatch the authoring workflow against the implementation commit. Download
the artifact containing these four files:

```powershell
crmshow_Foundation.zip
crmshow_Foundation_managed.zip
crmshow_DataModel.zip
crmshow_DataModel_managed.zip
```

Unpack each adjacent unmanaged/managed pair with `PackageType Both` and replace
only the matching tracked solution folder:

```powershell
.\scripts\solution\Unpack-Solution.ps1 -ZipFile .artifacts\crmshow_Foundation.zip -Folder solution\core\foundation -PackageType Both
.\scripts\solution\Unpack-Solution.ps1 -ZipFile .artifacts\crmshow_DataModel.zip -Folder solution\core\datamodel -PackageType Both
```

Inspect the diff for environment URLs, GUID-only noise, unrelated components,
real customer content and duplicate lookup columns. Remove only generated
transient artefacts; do not hand-edit away required component IDs.

- [ ] **Step 7: Pack both variants**

```powershell
.\scripts\solution\Pack-Solution.ps1 -Folder solution\core\foundation -OutFile .artifacts\crmshow_Foundation.zip -PackageType Both
.\scripts\solution\Pack-Solution.ps1 -Folder solution\core\datamodel -OutFile .artifacts\crmshow_DataModel.zip -PackageType Both
```

Expected: both packs succeed.

- [ ] **Step 8: Commit**

```powershell
git add scripts/solution/Publish-InsuranceFoundation.ps1 scripts/solution/tests/Publish-InsuranceFoundation.Tests.ps1 solution/core/foundation solution/core/datamodel
git commit -m "feat(datamodel): add multilingual insurance foundation schema (US-702 US-703 US-704 US-705 US-706)"
```

### Task 6: Enforce semantic metadata offline

**Files:**
- Create: `scripts/solution/Test-SemanticMetadata.ps1`
- Create: `scripts/solution/tests/Test-SemanticMetadata.Tests.ps1`
- Modify: `.github/workflows/solution-ci.yml`

- [ ] **Step 1: Write failing validator tests**

Create fixtures in `$TestDrive` and assert rejection of:

- a missing LCID;
- blank descriptions;
- description equal to display name;
- draft-marker text such as `TO` + `DO` or `TB` + `D`;
- a user-visible choice value missing one translation;
- a logical name without the `crmshow_` prefix.

Assert acceptance of one complete four-language table fixture.

- [ ] **Step 2: Run tests and verify failure**

Expected: the validator command is missing.

- [ ] **Step 3: Implement the validator**

The script accepts:

```powershell
param(
    [string]$ContractPath = 'solution/schema/insurance-foundation.json',
    [string[]]$SolutionPath = @('solution/core/foundation','solution/core/datamodel')
)
```

It validates the contract, scans unpacked XML for all expected logical names,
and emits one error object per component:

```powershell
[pscustomobject]@{
    Component = $logicalName
    Language  = $lcid
    Rule      = 'MissingDescription'
    Path      = $sourcePath
}
```

Exit non-zero if any error exists. Keep the rule set deterministic; do not call
an LLM or translation service in CI.

- [ ] **Step 4: Add CI gates**

In `solution-ci.yml`, add `solution/schema/**`, `infra/scripts/**` and
`fixtures/**` to path filters. Run:

```yaml
- name: Validate insurance semantic metadata
  shell: pwsh
  run: |
    ./scripts/solution/Test-SemanticMetadata.ps1
```

Change Solution Checker from `continue-on-error: true` to a blocking step for
Foundation/DataModel packages. If existing empty app packages produce known
noise, pass only the two changed package paths rather than suppressing failure.

- [ ] **Step 5: Run all offline gates**

```powershell
$r = Invoke-Pester -Path .\scripts\solution\tests,.\infra\scripts\tests -PassThru -Output Detailed
if ($r.FailedCount -gt 0) { throw "$($r.FailedCount) tests failed." }
.\scripts\solution\Test-SemanticMetadata.ps1
```

Expected: all tests and metadata validation pass.

- [ ] **Step 6: Commit**

```powershell
git add scripts/solution/Test-SemanticMetadata.ps1 scripts/solution/tests/Test-SemanticMetadata.Tests.ps1 .github/workflows/solution-ci.yml
git commit -m "test(datamodel): enforce multilingual semantic metadata (US-707)"
```

### Task 7: Add synthetic fixtures and online smoke tests

**Files:**
- Create: `fixtures/insurance-foundation.json`
- Create: `scripts/solution/Set-InsuranceFoundationFixtures.ps1`
- Create: `scripts/solution/Test-InsuranceFoundation.ps1`
- Create: `scripts/solution/tests/InsuranceFoundation.Tests.ps1`

- [ ] **Step 1: Write failing fixture-contract tests**

Assert:

- every name contains `Synthetic` or `Contoso`;
- no email, phone or address matches a real-looking fixture pattern;
- every projected source ID starts with `SYN-`;
- rerun keys are unique;
- policy owner references an Account key, never a Contact key;
- party-role examples include different owner/driver/payer/policyholder parties.

- [ ] **Step 2: Create the fixture contract**

Use only:

- `Synthetic Contoso Household`;
- `Synthetic Contoso Business`;
- `Synthetic Contoso Broker`;
- fictional Contacts named by role, for example
  `Synthetic Household Adult A`;
- external IDs such as `SYN-POL-HH-001`.

Do not include email addresses, telephone numbers, street addresses, contract
values or Mobiliar source identifiers.

Assign fixed RFC 4122 GUIDs under the repository's synthetic namespace to
every Account and Contact fixture. Use those GUIDs as the Dataverse primary
keys so repeated `PATCH accounts(<guid>)` and `PATCH contacts(<guid>)` requests
are deterministic without adding business alternate keys to native tables.

- [ ] **Step 3: Implement idempotent fixture upsert**

The loader accepts `EnvironmentUrl` and `FixturePath`, uses `az rest`, resolves
Accounts/Contacts by deterministic synthetic keys, and upserts:

- Accounts and Contacts;
- AccountContactRole through its alternate key;
- PolicyProjection through `externalSystem + externalId`;
- PolicyPartyRole through `sourceSystem + sourceId`.

Use lowercase navigation-property schema names in every `@odata.bind`.
Throw if a referenced key cannot be resolved. Never catch and continue.

- [ ] **Step 4: Implement online smoke tests**

`Test-InsuranceFoundation.ps1` must fail unless:

- LCIDs 1033/1031/1036/1040 are active;
- Foundation and DataModel versions are `1.1.0.BUILD` or later;
- expected custom tables, columns, relationships and alternate keys exist;
- required localized labels/descriptions are retrievable;
- fixture counts remain stable after a second load;
- fixture/import writes with invalid date order fail before mutation;
- environment checks report invalid date order from other write paths;
- Reader mutation is denied and Data Steward create/update succeeds when
  separate test identities are supplied.

Security tests accept optional Reader/Data Steward client IDs and fail with a
clear `Security identities not configured` result in deployment workflows
rather than silently skipping.

- [ ] **Step 5: Run unit tests**

Expected: all fixture-contract and helper tests pass without tenant access.

- [ ] **Step 6: Commit**

```powershell
git add fixtures/insurance-foundation.json scripts/solution/Set-InsuranceFoundationFixtures.ps1 scripts/solution/Test-InsuranceFoundation.ps1 scripts/solution/tests/InsuranceFoundation.Tests.ps1
git commit -m "test(datamodel): add insurance fixtures and smoke tests (US-709)"
```

### Task 8: Add DEV and TEST deployment workflows

**Files:**
- Create: `.github/workflows/solution-deploy-dev.yml`
- Create: `.github/workflows/solution-deploy-test.yml`
- Create: `docs/runbooks/insurance-foundation-deployment.md`

- [ ] **Step 1: Create the DEV workflow**

Trigger on merge/push to `main` when Foundation, DataModel, language scripts,
fixtures or solution scripts change. Use GitHub Environment `dev` and:

1. checkout;
2. `azure/login@v2` with environment variables;
   set `allow-no-subscriptions: true`;
3. install PAC CLI and Pester;
4. stamp `1.1.0.${{ github.run_number }}` into the workspace manifest and
   both Solution.xml files with `Bump-Version.ps1 -Kind build`;
5. reconcile required languages;
6. run offline tests;
7. pack Foundation/DataModel as `Both` in dependency order;
8. import unmanaged packages with `InstallOrUpdate`;
9. load fixtures twice and prove stable counts;
10. run smoke tests, including overlap reporting and source-removal
    end-dating/deactivation;
11. upload the exact unmanaged and managed packages, stamped manifest, PAC
    logs and JSON smoke evidence as `insurance-foundation-${{ github.sha }}`.

The permissions block is:

```yaml
permissions:
  contents: read
  id-token: write
```

Never use a client secret or connection string.

- [ ] **Step 2: Create the TEST workflow**

Trigger only with `workflow_dispatch` and require GitHub Environment `test`.
Inputs:

```yaml
mode:
  type: choice
  options: [InstallOrUpdate, StageForUpgrade]
  default: InstallOrUpdate
```

The workflow:

1. checks that the requested commit has a successful DEV deployment;
2. downloads the exact `insurance-foundation-${commit_sha}` artifact from that
   DEV run instead of rebuilding;
3. signs in through TEST OIDC with `allow-no-subscriptions: true`;
4. reconciles languages and verifies installed versions;
5. imports the downloaded managed Foundation package before DataModel;
6. rejects non-monotonic versions;
7. verifies both packages are managed and no unmanaged active layer exists;
8. loads synthetic fixtures twice and proves stable counts;
9. runs metadata, CRUD, overlap, source-removal and security smoke tests;
10. uploads evidence.

Do not run `ApplyUpgrade` automatically. A later controlled workflow dispatch
may call it only after Stage-for-Upgrade evidence and approval.

- [ ] **Step 3: Provision automated security-smoke identities**

Extend the Entra Terraform module with four OIDC-only app registrations:

- `crm-showcase-smoke-reader-dev`;
- `crm-showcase-smoke-steward-dev`;
- `crm-showcase-smoke-reader-test`;
- `crm-showcase-smoke-steward-test`.

Expose their client IDs as protected GitHub Environment variables
`DATAVERSE_READER_CLIENT_ID` and `DATAVERSE_STEWARD_CLIENT_ID` in the matching
slot. Extend `add-ci-app-users.ps1` to create their Dataverse application users
and assign only `CRM Showcase Insurance Reader` or
`CRM Showcase Insurance Data Steward`. Deployment workflows use separate
OIDC-authenticated jobs for Reader-negative and Data-Steward-positive CRUD
tests. No identity receives both roles.

- [ ] **Step 4: Write the runbook**

Document exact workflow inputs, required GitHub environment variables,
expected artefacts, install-versus-update behavior, failure triage, and the
additive rollback/correct-forward rule from the design. Explicitly state that
uninstalling a data-bearing managed solution requires backup evidence and an
ADR.

- [ ] **Step 5: Validate workflow syntax and scripts**

Run the existing repository workflow validation if present. Otherwise use:

```powershell
git diff --check
$r = Invoke-Pester -Path .\scripts\solution\tests,.\infra\scripts\tests -PassThru -Output Detailed
if ($r.FailedCount -gt 0) { throw "$($r.FailedCount) tests failed." }
```

Expected: no whitespace errors and all tests pass.

- [ ] **Step 6: Commit**

```powershell
git add .github/workflows/solution-deploy-dev.yml .github/workflows/solution-deploy-test.yml infra/terraform infra/scripts/add-ci-app-users.ps1 docs/runbooks/insurance-foundation-deployment.md
git commit -m "feat(ci): deploy insurance foundation to DEV and TEST (US-708)"
```

### Task 9: Execute end-to-end deployment and close Sprint 3 evidence

**Files:**
- Modify: `docs/BACKLOG.md`
- Modify: GitHub issue `#8`
- Evidence: GitHub Actions workflow runs and PR checks

- [ ] **Step 1: Run the full local gate**

```powershell
terraform -chdir=infra/terraform fmt -check -recursive
terraform -chdir=infra/terraform init -backend=false
terraform -chdir=infra/terraform validate
$r = Invoke-Pester -Path .\scripts\solution\tests,.\infra\scripts\tests -PassThru -Output Detailed
if ($r.FailedCount -gt 0) { throw "$($r.FailedCount) tests failed." }
.\scripts\solution\Test-SemanticMetadata.ps1
```

Expected: all commands pass.

- [ ] **Step 2: Open the implementation PR**

The PR must link:

- issue #8;
- US-701 through US-709;
- ADR-0006, ADR-0007, ADR-0008, ADR-0017, ADR-0019, ADR-0020 and ADR-0021;
- the design and this plan;
- licensing and maturity flags;
- WAF, CAF, Zero Trust and Responsible-AI impacts.

- [ ] **Step 3: Deploy to DEV**

Merge only after required reviewers and green CI. Confirm the DEV workflow
reports:

- four active LCIDs;
- unmanaged Foundation/DataModel `1.1.0.BUILD`;
- stable second fixture run;
- green schema, localization, CRUD and configured security tests.

- [ ] **Step 4: Promote to TEST**

Dispatch TEST with `InstallOrUpdate`. Confirm:

- GitHub Environment approval occurred;
- packages are managed;
- installed version is monotonic;
- no unmanaged active layer exists;
- the same smoke evidence passes.

- [ ] **Step 5: Record evidence**

Comment on issue #8 with:

- PR URL;
- DEV and TEST workflow URLs;
- package versions;
- Solution Checker result;
- active LCIDs;
- smoke-test summary;
- explicit statement that fixtures are synthetic;
- Sprint 4 dependency status.

- [ ] **Step 6: Open a traceability-only follow-up PR**

Change US-701 through US-709 statuses to `Done` with links to issue #8 and the
actual implementation PR.

- [ ] **Step 7: Commit and merge the follow-up PR**

```powershell
git add docs/BACKLOG.md
git commit -m "chore(sprint-3): record insurance foundation evidence (US-709)"
```

Open a docs-only PR linked to issue #8. Merge it after DEV and TEST evidence is
available; no environment mutation is performed by this PR.

## Final acceptance checklist

- [ ] Issue #8 links the design, plan, PR and deployment evidence.
- [ ] EN/DE/FR/IT are active in DEV and TEST through the idempotent control.
- [ ] Foundation and DataModel are `1.1.0.BUILD`; other solutions are unchanged.
- [ ] Account owns PolicyProjection; Contact participates only through roles.
- [ ] All three custom tables are user/team owned and audited.
- [ ] PolicyPartyRole uses a Customer lookup.
- [ ] All lookups were created with their owning table and never recreated.
- [ ] EN/DE/FR/IT labels and semantic descriptions pass deterministic CI.
- [ ] Reader/Data Steward roles have only the documented privileges.
- [ ] Fixtures are synthetic and idempotent.
- [ ] DEV is unmanaged; TEST is managed and has no unmanaged active layer.
- [ ] Import modes are explicit and no longer use unconditional force-overwrite.
- [ ] No secret, real customer data, production-tenant connection or autonomous customer action was introduced.
- [ ] Sprint 4 remains a separate feature and starts only after TEST evidence is green.
