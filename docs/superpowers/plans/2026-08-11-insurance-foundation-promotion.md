# Proof #2 — Insurance Foundation Promotion Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Run the Insurance Foundation through the Proof #1 delegation pattern to a managed TEST (prod-equivalent) deployment — excluding all plug-ins and business rules from the promoted slice and capturing the effective-date decision as an ADR — using three delegated streams (one attended DESIGN-SENSITIVE, two headless EXECUTION-ONLY).

**Architecture:** Stream A (attended) writes `ADR-0024` (effective-date integrity options) and re-points OR-001. Stream B (headless) builds a machine-readable promotion component contract from `solution/schema/insurance-foundation.json` (excluding `businessRules` and reporting views), plus a two-job `solution-promote-test.yml` (export managed from DEV → assert exclusion → import managed to TEST under protected-environment approval). Stream C (headless) builds an offline-testable TEST smoke evaluator. All scripts follow the repo's PS 5.1 + Pester 6 conventions and reuse the existing `Export-Solution.ps1` / `Import-Solution.ps1` (which already expose `InstallOrUpdate`/`StageForUpgrade`/`ApplyUpgrade`).

**Tech Stack:** PowerShell 5.1-compatible, Pester 6.0.1, Power Platform CLI (`pac solution export/import/unpack`), GitHub Actions with OIDC (`azure/login`, `pac auth create --githubFederated`) and protected environments, the Proof #1 orchestration toolchain (`scripts/orchestration/*`).

---

## Delivery boundary

Implements **Proof #2** from
`docs/superpowers/specs/2026-08-11-insurance-foundation-promotion-design.md`.
The promoted managed slice contains only tables, columns, choices, alternate
keys, relationships, EN/DE/FR/IT localization, Administration views/forms and
security roles. It **excludes** all effective-date `businessRules` and the
`OverlapReporting` / `InvalidDateReporting` views, and **any plug-in**. No PROD
slot, no destructive upgrade, no Sprint-4 tables.

The delegated streams **build and test** the promotion; the **live DEV→TEST
deploy runs in GitHub Actions** under the `test` protected-environment approval
(ADR-0004). Actually triggering that deploy is a **gated** step.

## File map

| Path | Stream | Responsibility |
| --- | --- | --- |
| `docs/adr/ADR-0024-effective-date-integrity-options.md` | A | Records the effective-date integrity decision + 3 options; supersedes OR-001 framing |
| `docs/requirements/OR-001-effective-date-integrity.md` | A | Re-pointed to ADR-0024 |
| `docs/superpowers/specs/2026-08-08-insurance-foundation-design.md` | A | Scope-refinement note (Proof #2 excludes effective-date artifacts) |
| `scripts/solution/Get-PromotionComponents.ps1` | B | Derives the in-scope/excluded component contract from the schema |
| `scripts/solution/tests/Get-PromotionComponents.Tests.ps1` | B | Contract tests |
| `.github/workflows/solution-promote-test.yml` | B | Two-job export-from-DEV → import-to-TEST promotion |
| `scripts/solution/Get-PromotionSmokeResult.ps1` | C | Offline-testable TEST smoke evaluator |
| `scripts/solution/tests/Get-PromotionSmokeResult.Tests.ps1` | C | Smoke evaluator tests |
| `docs/superpowers/sprints/sprint-002-insurance-foundation-promotion/sprint.md` | — | Charter |
| `docs/superpowers/sprints/sprint-002-insurance-foundation-promotion/STATUS.md` | — | Status board |

## Conventions (verified in-repo)

- Scripts: `<# .SYNOPSIS #>` + `[CmdletBinding()]` + non-mandatory top-level
  `param()` (mandatory only inside the function) + `throw`. Tests dot-source via
  `BeforeAll { . "$PSScriptRoot/../X.ps1" }`; helper functions go in `BeforeAll`.
- Run one test file: `Invoke-Pester -Path scripts/solution/tests/X.Tests.ps1`.
- Workflow auth mirrors `.github/workflows/solution-author-dev.yml` (OIDC
  `azure/login@v2`, `pac auth create --githubFederated`, `environment:` gating).

---

### Task 1 (Stream A — DESIGN-SENSITIVE, attended): ADR-0024 + re-points

> This stream is `DESIGN-SENSITIVE`: it is authored/reviewed **attended**, never
> launched headless. It records a design decision, so a human reviews the option.

**Files:**
- Create: `docs/adr/ADR-0024-effective-date-integrity-options.md`
- Modify: `docs/requirements/OR-001-effective-date-integrity.md`
- Modify: `docs/superpowers/specs/2026-08-08-insurance-foundation-design.md`

- [ ] **Step 1: Write ADR-0024** with the standard header table (Status
      Accepted; Date 2026-08-11; Topic area A8; Deciders Enterprise Architect +
      Responsible-AI Officer; CAF Govern/Manage; WAF Reliability/Security; Zero
      Trust; Responsible AI accountability) and these sections:
  - **Context:** effective-date integrity (`validTo` blank or ≥ `validFrom`) for
    `crmshow_accountcontactrole` and `crmshow_policypartyrole`; Proof #2 promotes
    a schema slice and must not ship a plug-in or business rule.
  - **Decision:** Proof #2 **excludes** all effective-date enforcement and
    reporting views from the promoted managed slice; enforcement is **not built**
    and remains an option set. Detection stays a payload-validation / steward
    concern outside the promoted package.
  - **Options (record all three, with trade-offs):** (1) synchronous validation
    plug-in in `crmshow_Integration`; (2) Maker-Studio table-scoped business
    rules captured through the governed export/intake pipeline; (3) source /
    integration-contract enforcement with Dataverse detection as defence in
    depth.
  - **Consequences:** OR-001 remains open and points here; selecting an option
    later is a governance-changing event needing its own ADR update; no upgrade
    impact in Proof #2.
  - **Related:** OR-001, issue #9, the Insurance Foundation spec, this Proof #2
    spec.

- [ ] **Step 2: Re-point OR-001** — in
      `docs/requirements/OR-001-effective-date-integrity.md`, change the
      "Options for the later feature" preamble to state the decision record now
      lives in **ADR-0024**, and add ADR-0024 to its header `Related`/`Feature`
      context. Keep the requirement Open.

- [ ] **Step 3: Add a scope-refinement note** to
      `docs/superpowers/specs/2026-08-08-insurance-foundation-design.md` (a short
      subsection under §5.5 or §12) stating: *Proof #2 promotes the schema slice
      to TEST and excludes the effective-date `businessRules` and the
      `OverlapReporting`/`InvalidDateReporting` views from the managed package;
      see ADR-0024 and `2026-08-11-insurance-foundation-promotion-design.md`.*

- [ ] **Step 4: Commit** (attended review first)

```bash
git add docs/adr/ADR-0024-effective-date-integrity-options.md docs/requirements/OR-001-effective-date-integrity.md docs/superpowers/specs/2026-08-08-insurance-foundation-design.md
git commit -m "docs(adr): ADR-0024 effective-date integrity options; exclude from Proof #2 slice"
```

---

### Task 2 (Stream B — EXECUTION-ONLY): promotion component contract

**Files:**
- Create: `scripts/solution/Get-PromotionComponents.ps1`
- Test: `scripts/solution/tests/Get-PromotionComponents.Tests.ps1`

- [ ] **Step 1: Write the failing test**

Create `scripts/solution/tests/Get-PromotionComponents.Tests.ps1`:

```powershell
BeforeAll {
    . "$PSScriptRoot/../Get-PromotionComponents.ps1"

    function New-Schema {
        $p = Join-Path $TestDrive 'schema.json'
        $json = @'
{
  "solutions": ["crmshow_Foundation", "crmshow_DataModel"],
  "tables": [
    {
      "logicalName": "crmshow_accountcontactrole",
      "businessRules": [ { "name": "crmshow_accountcontactrolevaliddateorder" } ],
      "views": [
        { "name": "crmshow_accountcontactroleadminview", "purpose": "Administration" },
        { "name": "crmshow_accountcontactroleoverlapview", "purpose": "OverlapReporting" }
      ]
    }
  ]
}
'@
        Set-Content -LiteralPath $p -Value $json
        return $p
    }
}

Describe "Get-PromotionComponents" {
    It "excludes business rules and reporting views, keeps admin views" {
        $c = Get-PromotionComponents -SchemaPath (New-Schema)
        $c.Tables                | Should -Contain 'crmshow_accountcontactrole'
        $c.InScopeViews          | Should -Contain 'crmshow_accountcontactroleadminview'
        $c.ExcludedViews         | Should -Contain 'crmshow_accountcontactroleoverlapview'
        $c.ExcludedBusinessRules | Should -Contain 'crmshow_accountcontactrolevaliddateorder'
        $c.ExcludedComponents    | Should -Contain 'crmshow_accountcontactroleoverlapview'
        $c.ExcludedComponents    | Should -Contain 'crmshow_accountcontactrolevaliddateorder'
    }

    It "flags a package that contains an excluded component" {
        $c = Get-PromotionComponents -SchemaPath (New-Schema)
        $violations = Test-PromotionPackageComponents `
            -PackageComponentNames @('crmshow_accountcontactrole','crmshow_accountcontactroleoverlapview') `
            -ExcludedComponents $c.ExcludedComponents
        $violations | Should -Contain 'crmshow_accountcontactroleoverlapview'
    }

    It "passes a clean package" {
        $c = Get-PromotionComponents -SchemaPath (New-Schema)
        $violations = Test-PromotionPackageComponents `
            -PackageComponentNames @('crmshow_accountcontactrole','crmshow_accountcontactroleadminview') `
            -ExcludedComponents $c.ExcludedComponents
        @($violations).Count | Should -Be 0
    }

    It "throws when the schema is missing" {
        { Get-PromotionComponents -SchemaPath (Join-Path $TestDrive 'nope.json') } | Should -Throw
    }
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `Invoke-Pester -Path scripts/solution/tests/Get-PromotionComponents.Tests.ps1`
Expected: FAIL — script missing.

- [ ] **Step 3: Write the implementation**

Create `scripts/solution/Get-PromotionComponents.ps1`:

```powershell
<#
.SYNOPSIS
    Derive the Proof #2 promotion component contract from the insurance schema.
.DESCRIPTION
    Reads the insurance-foundation contract JSON and returns the in-scope and
    excluded component sets. Effective-date business rules and reporting views
    (OverlapReporting / InvalidDateReporting) are excluded from the promoted
    managed slice; Administration views and forms stay in scope.
#>
[CmdletBinding()]
param(
    [string]$SchemaPath,
    [string[]]$ExcludedViewPurposes = @('OverlapReporting', 'InvalidDateReporting')
)

function Get-PromotionComponents {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string]$SchemaPath,
        [string[]]$ExcludedViewPurposes = @('OverlapReporting', 'InvalidDateReporting')
    )

    if (-not (Test-Path -LiteralPath $SchemaPath)) {
        throw "Schema not found: $SchemaPath"
    }
    $schema = Get-Content -Raw -LiteralPath $SchemaPath | ConvertFrom-Json

    $tables = @()
    $inScopeViews = @()
    $excludedViews = @()
    $excludedRules = @()

    foreach ($t in $schema.tables) {
        $tables += $t.logicalName
        foreach ($r in $t.businessRules) { $excludedRules += $r.name }
        foreach ($v in $t.views) {
            if ($ExcludedViewPurposes -contains $v.purpose) { $excludedViews += $v.name }
            else { $inScopeViews += $v.name }
        }
    }

    [pscustomobject]@{
        Solutions             = @($schema.solutions)
        Tables                = $tables
        InScopeViews          = $inScopeViews
        ExcludedViews         = $excludedViews
        ExcludedBusinessRules = $excludedRules
        ExcludedComponents    = @($excludedViews + $excludedRules)
    }
}

function Test-PromotionPackageComponents {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string[]]$PackageComponentNames,
        [Parameter(Mandatory)] [string[]]$ExcludedComponents
    )
    $violations = @($PackageComponentNames | Where-Object { $ExcludedComponents -contains $_ })
    return , $violations
}

if ($MyInvocation.InvocationName -ne '.') {
    Get-PromotionComponents @PSBoundParameters
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `Invoke-Pester -Path scripts/solution/tests/Get-PromotionComponents.Tests.ps1`
Expected: PASS (4 tests).

- [ ] **Step 5: Sanity-run against the real schema**

Run: `. ./scripts/solution/Get-PromotionComponents.ps1; Get-PromotionComponents -SchemaPath ./solution/schema/insurance-foundation.json | Format-List`
Expected: `ExcludedBusinessRules` and `ExcludedViews` are non-empty; `Tables` lists the three custom tables.

- [ ] **Step 6: Commit**

```bash
git add scripts/solution/Get-PromotionComponents.ps1 scripts/solution/tests/Get-PromotionComponents.Tests.ps1
git commit -m "feat(solution): promotion component contract excluding effective-date artifacts"
```

---

### Task 3 (Stream B — EXECUTION-ONLY): the TEST promotion workflow

**Files:**
- Create: `.github/workflows/solution-promote-test.yml`

- [ ] **Step 1: Write the workflow** (two jobs: export-from-DEV, then import-to-TEST under the protected environment). Create `.github/workflows/solution-promote-test.yml`:

```yaml
name: Promote insurance foundation to TEST

on:
  workflow_dispatch:
    inputs:
      mode:
        description: Import mode
        type: choice
        options: [InstallOrUpdate, StageForUpgrade]
        default: InstallOrUpdate

permissions:
  contents: read
  id-token: write

jobs:
  export-from-dev:
    runs-on: ubuntu-latest
    environment: dev
    env:
      AZURE_CLIENT_ID: ${{ vars.AZURE_CLIENT_ID }}
      AZURE_TENANT_ID: ${{ vars.AZURE_TENANT_ID }}
      POWER_PLATFORM_ENV_URL: ${{ vars.POWER_PLATFORM_ENV_URL }}
    steps:
      - uses: actions/checkout@v4
      - name: Sign in with workload identity
        uses: azure/login@v2
        with:
          client-id: ${{ env.AZURE_CLIENT_ID }}
          tenant-id: ${{ env.AZURE_TENANT_ID }}
          allow-no-subscriptions: true
      - name: Install Power Platform CLI
        uses: microsoft/powerplatform-actions/actions-install@v1
      - name: Install Pester 6.0.1
        shell: pwsh
        run: |
          Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
          Install-Module Pester -RequiredVersion 6.0.1 -Scope CurrentUser -Force -SkipPublisherCheck
      - name: Offline promotion contract tests
        shell: pwsh
        run: |
          $r = Invoke-Pester -Path @(
            './scripts/solution/tests/Get-PromotionComponents.Tests.ps1',
            './scripts/solution/tests/Get-PromotionSmokeResult.Tests.ps1'
          ) -PassThru -Output Detailed
          if ($r.Result -ne 'Passed') { throw 'Offline promotion tests failed.' }
      - name: Authenticate Power Platform CLI (DEV)
        shell: pwsh
        run: |
          . ./scripts/solution/Resolve-PacCommand.ps1
          $pac = Resolve-PacCommand
          & $pac auth create --name promote-dev --githubFederated `
            --applicationId $env:AZURE_CLIENT_ID --tenant $env:AZURE_TENANT_ID `
            --environment $env:POWER_PLATFORM_ENV_URL
          if ($LASTEXITCODE -ne 0) { throw 'PAC federated authentication failed.' }
      - name: Export managed solutions
        shell: pwsh
        run: |
          $out = Join-Path $env:RUNNER_TEMP 'promote'
          New-Item -ItemType Directory -Force -Path $out | Out-Null
          ./scripts/solution/Export-Solution.ps1 -SolutionName crmshow_Foundation -OutFile (Join-Path $out 'crmshow_Foundation_managed.zip') -Managed
          ./scripts/solution/Export-Solution.ps1 -SolutionName crmshow_DataModel  -OutFile (Join-Path $out 'crmshow_DataModel_managed.zip')  -Managed
      - name: Assert excluded components are absent from the package
        shell: pwsh
        run: |
          . ./scripts/solution/Resolve-PacCommand.ps1
          . ./scripts/solution/Get-PromotionComponents.ps1
          $pac = Resolve-PacCommand
          $out = Join-Path $env:RUNNER_TEMP 'promote'
          $contract = Get-PromotionComponents -SchemaPath ./solution/schema/insurance-foundation.json
          $unpacked = Join-Path $env:RUNNER_TEMP 'unpacked'
          & $pac solution unpack --zipfile (Join-Path $out 'crmshow_DataModel_managed.zip') --folder $unpacked --allowDelete
          $names = (Get-ChildItem -Recurse -File $unpacked | Select-String -SimpleMatch -Pattern $contract.ExcludedComponents) 
          if ($names) { throw "Excluded effective-date components present in package: $($names.Pattern -join ', ')" }
          Write-Host 'Package excludes all effective-date components.'
      - name: Upload managed artifacts
        uses: actions/upload-artifact@v4
        with:
          name: managed-solutions
          path: ${{ runner.temp }}/promote/*.zip

  import-to-test:
    runs-on: ubuntu-latest
    needs: export-from-dev
    environment: test
    env:
      AZURE_CLIENT_ID: ${{ vars.AZURE_CLIENT_ID }}
      AZURE_TENANT_ID: ${{ vars.AZURE_TENANT_ID }}
      POWER_PLATFORM_ENV_URL: ${{ vars.POWER_PLATFORM_ENV_URL }}
    steps:
      - uses: actions/checkout@v4
      - name: Sign in with workload identity
        uses: azure/login@v2
        with:
          client-id: ${{ env.AZURE_CLIENT_ID }}
          tenant-id: ${{ env.AZURE_TENANT_ID }}
          allow-no-subscriptions: true
      - name: Install Power Platform CLI
        uses: microsoft/powerplatform-actions/actions-install@v1
      - name: Download managed artifacts
        uses: actions/download-artifact@v4
        with:
          name: managed-solutions
          path: ${{ runner.temp }}/promote
      - name: Authenticate Power Platform CLI (TEST)
        shell: pwsh
        run: |
          . ./scripts/solution/Resolve-PacCommand.ps1
          $pac = Resolve-PacCommand
          & $pac auth create --name promote-test --githubFederated `
            --applicationId $env:AZURE_CLIENT_ID --tenant $env:AZURE_TENANT_ID `
            --environment $env:POWER_PLATFORM_ENV_URL
          if ($LASTEXITCODE -ne 0) { throw 'PAC federated authentication failed.' }
      - name: Preflight languages
        shell: pwsh
        run: |
          & ./infra/scripts/Set-DataverseLanguages.ps1 -EnvironmentUrl $env:POWER_PLATFORM_ENV_URL -LocaleId 1033,1031,1036,1040
          if ($LASTEXITCODE -ne 0) { throw 'TEST language preflight failed.' }
      - name: Import managed (Foundation then DataModel)
        shell: pwsh
        run: |
          $out = Join-Path $env:RUNNER_TEMP 'promote'
          ./scripts/solution/Import-Solution.ps1 -ZipFile (Join-Path $out 'crmshow_Foundation_managed.zip') -Mode ${{ inputs.mode }} -PublishChanges
          ./scripts/solution/Import-Solution.ps1 -ZipFile (Join-Path $out 'crmshow_DataModel_managed.zip')  -Mode ${{ inputs.mode }} -PublishChanges
      - name: Smoke evidence
        shell: pwsh
        run: |
          Write-Host 'Managed import complete; run Get-PromotionSmokeResult against TEST facts here.'
```

- [ ] **Step 2: Lint the YAML** — Run: `Get-Content .github/workflows/solution-promote-test.yml | Out-Null` and confirm indentation is valid (2-space). Optionally validate with `actionlint` if available.

- [ ] **Step 3: Commit**

```bash
git add .github/workflows/solution-promote-test.yml
git commit -m "ci(solution): add DEV->TEST managed promotion workflow with exclusion gate"
```

---

### Task 4 (Stream C — EXECUTION-ONLY): TEST smoke evaluator

**Files:**
- Create: `scripts/solution/Get-PromotionSmokeResult.ps1`
- Test: `scripts/solution/tests/Get-PromotionSmokeResult.Tests.ps1`

- [ ] **Step 1: Write the failing test**

Create `scripts/solution/tests/Get-PromotionSmokeResult.Tests.ps1`:

```powershell
BeforeAll {
    . "$PSScriptRoot/../Get-PromotionSmokeResult.ps1"

    function New-Facts {
        [pscustomobject]@{
            ActiveLocales     = @(1033, 1031, 1036, 1040)
            Solutions         = @(
                [pscustomobject]@{ Name = 'crmshow_Foundation'; Version = '1.1.0.0'; IsManaged = $true },
                [pscustomobject]@{ Name = 'crmshow_DataModel';  Version = '1.1.0.0'; IsManaged = $true }
            )
            Tables            = @('crmshow_accountcontactrole','crmshow_policyprojection','crmshow_policypartyrole')
            ReaderCanMutate   = $false
            StewardCanAdmin   = $false
            LocalizedLabels   = $true
        }
    }
}

Describe "Get-PromotionSmokeResult" {
    It "passes when all facts meet expectations" {
        $r = Get-PromotionSmokeResult -Facts (New-Facts) `
            -ExpectedLocales @(1033,1031,1036,1040) `
            -ExpectedSolutions @('crmshow_Foundation','crmshow_DataModel') `
            -ExpectedTables @('crmshow_accountcontactrole','crmshow_policyprojection','crmshow_policypartyrole')
        $r.Overall | Should -BeTrue
        ($r.Checks | Where-Object { -not $_.Pass }) | Should -BeNullOrEmpty
    }

    It "fails overall when a language is inactive" {
        $facts = New-Facts
        $facts.ActiveLocales = @(1033, 1031, 1036)   # IT missing
        $r = Get-PromotionSmokeResult -Facts $facts `
            -ExpectedLocales @(1033,1031,1036,1040) `
            -ExpectedSolutions @('crmshow_Foundation','crmshow_DataModel') `
            -ExpectedTables @('crmshow_accountcontactrole')
        $r.Overall | Should -BeFalse
        ($r.Checks | Where-Object { $_.Name -eq 'LanguagesActive' }).Pass | Should -BeFalse
    }

    It "fails when Reader can mutate" {
        $facts = New-Facts
        $facts.ReaderCanMutate = $true
        $r = Get-PromotionSmokeResult -Facts $facts `
            -ExpectedLocales @(1033,1031,1036,1040) `
            -ExpectedSolutions @('crmshow_Foundation','crmshow_DataModel') `
            -ExpectedTables @('crmshow_accountcontactrole')
        ($r.Checks | Where-Object { $_.Name -eq 'ReaderReadOnly' }).Pass | Should -BeFalse
        $r.Overall | Should -BeFalse
    }
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `Invoke-Pester -Path scripts/solution/tests/Get-PromotionSmokeResult.Tests.ps1`
Expected: FAIL — script missing.

- [ ] **Step 3: Write the implementation**

Create `scripts/solution/Get-PromotionSmokeResult.ps1`:

```powershell
<#
.SYNOPSIS
    Evaluate TEST promotion smoke checks from gathered environment facts.
.DESCRIPTION
    Pure evaluator: given injected facts about the TEST environment, returns a
    per-check pass/fail result plus an overall verdict. A thin live wrapper (run
    in the promotion workflow) gathers the facts; this function is unit-testable
    offline.
#>
[CmdletBinding()]
param(
    $Facts,
    [int[]]$ExpectedLocales = @(1033, 1031, 1036, 1040),
    [string[]]$ExpectedSolutions = @('crmshow_Foundation', 'crmshow_DataModel'),
    [string[]]$ExpectedTables = @()
)

function Get-PromotionSmokeResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] $Facts,
        [int[]]$ExpectedLocales = @(1033, 1031, 1036, 1040),
        [string[]]$ExpectedSolutions = @('crmshow_Foundation', 'crmshow_DataModel'),
        [string[]]$ExpectedTables = @()
    )

    $checks = @()
    function New-Check($name, $pass, $detail) {
        [pscustomobject]@{ Name = $name; Pass = [bool]$pass; Detail = $detail }
    }

    $missingLocales = @($ExpectedLocales | Where-Object { $Facts.ActiveLocales -notcontains $_ })
    $checks += New-Check 'LanguagesActive' ($missingLocales.Count -eq 0) "missing: $($missingLocales -join ',')"

    $presentSolutions = @($Facts.Solutions | ForEach-Object { $_.Name })
    $missingSolutions = @($ExpectedSolutions | Where-Object { $presentSolutions -notcontains $_ })
    $unmanaged = @($Facts.Solutions | Where-Object { -not $_.IsManaged } | ForEach-Object { $_.Name })
    $checks += New-Check 'SolutionsManagedPresent' (($missingSolutions.Count -eq 0) -and ($unmanaged.Count -eq 0)) "missing: $($missingSolutions -join ','); unmanaged: $($unmanaged -join ',')"

    $missingTables = @($ExpectedTables | Where-Object { $Facts.Tables -notcontains $_ })
    $checks += New-Check 'TablesPresent' ($missingTables.Count -eq 0) "missing: $($missingTables -join ',')"

    $checks += New-Check 'ReaderReadOnly'    (-not $Facts.ReaderCanMutate) 'Reader must not create/update/delete'
    $checks += New-Check 'StewardNoSecAdmin' (-not $Facts.StewardCanAdmin) 'Data Steward must not administer security'
    $checks += New-Check 'LocalizedLabels'   ([bool]$Facts.LocalizedLabels) 'labels retrievable for all four LCIDs'

    [pscustomobject]@{
        Overall = (@($checks | Where-Object { -not $_.Pass }).Count -eq 0)
        Checks  = $checks
    }
}

if ($MyInvocation.InvocationName -ne '.') {
    Get-PromotionSmokeResult @PSBoundParameters
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `Invoke-Pester -Path scripts/solution/tests/Get-PromotionSmokeResult.Tests.ps1`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add scripts/solution/Get-PromotionSmokeResult.ps1 scripts/solution/tests/Get-PromotionSmokeResult.Tests.ps1
git commit -m "feat(solution): offline-testable TEST promotion smoke evaluator"
```

---

### Task 5: sprint-002 charter + status board

**Files:**
- Create: `docs/superpowers/sprints/sprint-002-insurance-foundation-promotion/sprint.md`
- Create: `docs/superpowers/sprints/sprint-002-insurance-foundation-promotion/STATUS.md`

- [ ] **Step 1: Write `sprint.md`** — charter mirroring the sprint issue:
      outcome (promote Insurance Foundation to TEST via the pattern, plug-ins &
      business rules excluded), the three-stream table (A DESIGN-SENSITIVE,
      B/C EXECUTION-ONLY), and the acceptance criteria from the Proof #2 spec §9.

- [ ] **Step 2: Write `STATUS.md`** — table
      `Stream | Issue | Class | Branch | PR | State | Evidence` with rows for
      `adr` (DESIGN-SENSITIVE), `promote` (EXECUTION-ONLY), `smoke`
      (EXECUTION-ONLY), all `#TBD` / `planned`.

- [ ] **Step 3: Commit**

```bash
git add docs/superpowers/sprints/sprint-002-insurance-foundation-promotion
git commit -m "docs(sprint): add sprint-002 charter + status board"
```

---

### Task 6: Run the full solution test suite

- [ ] **Step 1:** Run: `Invoke-Pester -Path scripts/solution/tests -Output Detailed`
      Expected: all pass, including the two new files. Fix any regression before
      proceeding.

---

### Task 7 (GATED — GitHub mutations): create issues + delegate the streams

> Requires user go-ahead (creates issues, worktrees, headless dispatch).

- [ ] **Step 1: Create issues** — `gh issue create` a sprint-charter (`#S`) and
      three stream issues (`adr` DESIGN-SENSITIVE, `promote` EXECUTION-ONLY,
      `smoke` EXECUTION-ONLY). Record numbers in `STATUS.md`.

- [ ] **Step 2: Create worktrees** with the Proof #1 toolchain, based off this
      branch:
```
. scripts/orchestration/New-SprintWorktree.ps1
New-SprintWorktree -SprintId 'sprint-002' -StreamId 'adr'     -IssueNumber <#> -AutonomyClass 'DESIGN-SENSITIVE' -BaseRef 'docs/insurance-foundation-promotion'
New-SprintWorktree -SprintId 'sprint-002' -StreamId 'promote' -IssueNumber <#> -AutonomyClass 'EXECUTION-ONLY'   -BaseRef 'docs/insurance-foundation-promotion'
New-SprintWorktree -SprintId 'sprint-002' -StreamId 'smoke'   -IssueNumber <#> -AutonomyClass 'EXECUTION-ONLY'   -BaseRef 'docs/insurance-foundation-promotion'
```

- [ ] **Step 3: Fill each packet's Goal/Scope/Verify** with the corresponding
      Task 1 / 2+3 / 4 content, then dispatch:
      - `adr` is DESIGN-SENSITIVE → `Invoke-StreamDelegation` prints the attended
        launch (never headless); author + human-review ADR-0024.
      - `promote` and `smoke` → headless `Invoke-StreamDelegation` (autopilot with
        the deny-list).

- [ ] **Step 4: Intake** each stream to the trunk (merge to
      `docs/insurance-foundation-promotion`), retire the worktrees via
      `Remove-SprintWorktree.ps1`, and record evidence in `STATUS.md`.

---

### Task 8 (GATED — deploy + PR): live TEST promotion + proof-#2 PR

> Requires user go-ahead (network + PR).

- [ ] **Step 1: Push the branch** and open the proof-#2 PR to `main` (rebase
      onto `main` first if PR #45 has merged). Use the repo PR template with
      traceability to ADR-0024 and the sprint issue.

- [ ] **Step 2: Trigger the live promotion** —
      `gh workflow run solution-promote-test.yml` — and **approve the `test`
      protected environment** when GitHub requests it (the human gate). Confirm
      both jobs succeed and the exclusion gate passed.

- [ ] **Step 3: Capture evidence** — link the workflow run, package versions,
      and smoke result in `STATUS.md` and the PR; a human merges after CI green.

---

## Self-review

**Spec coverage:**
- Spec §2 (scope carve-out) → Task 2 (contract) + Task 3 (exclusion gate) + Task 1 (ADR-0024).
- Spec §3 (three streams, both classes) → Tasks 1 (A, DESIGN-SENSITIVE), 2+3 (B), 4 (C); dispatched in Task 7.
- Spec §4 (promotion architecture) → Task 3 workflow (two-job export→import, protected `test`).
- Spec §5/§6 (TEST-as-prod, traceability) → Task 5 + Task 7 issues + Task 8.
- Spec §7 (guardrail) → Task 1 attended; Tasks 2/4 headless; Task 7 Step 3 enforces the class split.
- Spec §9 (acceptance) → Tasks 2 (contract test), 3 (exclusion gate), 4 (smoke), 6 (suite), 8 (live deploy evidence).

**Placeholder scan:** code tasks contain complete, runnable code + tests; Task 1
(ADR, DESIGN-SENSITIVE) and Task 5 (charter) state explicit content
requirements rather than final prose because they are authored/attended. The
`<#>` issue numbers in Task 7 are genuinely not yet assigned.

**Type consistency:** `Get-PromotionComponents` returns `ExcludedComponents`,
consumed by `Test-PromotionPackageComponents` (Task 2) and the workflow
exclusion step (Task 3). `Get-PromotionSmokeResult` returns `Overall` + `Checks`
(with `Name`/`Pass`/`Detail`), matched by the Task 4 tests.

## Execution handoff

After approval, execution options:

1. **Subagent-Driven (recommended)** — dispatch a fresh subagent per task with
   review between tasks, exactly as Proof #1. Stream A (ADR) runs attended;
   Streams B/C headless. Pause before Tasks 7–8 (GitHub mutations + live deploy).
2. **Inline Execution** — execute tasks in this session with checkpoints.
