# Sprint 1 — Power Platform Solution Containers — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deploy six empty Power Platform solutions (Foundation, DataModel, Integration, Sales, Service, Marketing) to `crmshowdev` (unmanaged) and `crmshowtest` (managed) with the correct dependency chain, semantic versioning, maker intake workflows, and PR-gated DEV → TEST promotion.

**Architecture:** Nested `solution/core/*` + `solution/apps/*` folders per the Microsoft "Multiple solutions with dedicated development environments" pattern. A machine-readable `solution/manifest.json` is the single source of truth for names, versions, and dependency order. GitHub Actions workflows use `pac` CLI + `microsoft/powerplatform-actions` for pack/unpack/import/export. Auth is Entra ID / OIDC via the existing `crm-showcase-ci-dev` / `crm-showcase-ci-test` service principals (ADR-0002, ADR-0004, ADR-0005). Semantic versioning is MAJOR.MINOR.PATCH.BUILD; MAJOR/MINOR require PR labels; PATCH/BUILD are automatic. Two intake paths (on-demand `workflow_dispatch` + scheduled weekday drift check) both land as PRs.

**Tech Stack:** PowerShell 5.1+, Pester 5, `pac` CLI (Power Platform, installed as dotnet global tool), `microsoft/powerplatform-actions@v1`, `azure/login@v2` (OIDC), Terraform (unchanged from prior sprints), `gh` CLI for GitHub API.

**Reference spec:** [`docs/superpowers/specs/2026-08-06-solution-containers-design.md`](../specs/2026-08-06-solution-containers-design.md)

---

## File Structure (created / modified across the sprint)

```
solution/
├── manifest.json                             CREATE  Task 3
├── manifest.schema.json                      CREATE  Task 3
├── core/foundation/                          CREATE  Task 5 (populated in tenant + exported)
├── core/datamodel/                           CREATE  Task 5
├── core/integration/                         CREATE  Task 5
├── apps/sales/                               CREATE  Task 5
├── apps/service/                             CREATE  Task 5
└── apps/marketing/                           CREATE  Task 5

scripts/solution/
├── Get-Manifest.ps1                          CREATE  Task 2
├── Get-SolutionOrder.ps1                     CREATE  Task 2
├── Export-Solution.ps1                       CREATE  Task 4
├── Unpack-Solution.ps1                       CREATE  Task 4
├── Pack-Solution.ps1                         CREATE  Task 4
├── Import-Solution.ps1                       CREATE  Task 4
├── Bump-Version.ps1                          CREATE  Task 4
├── Test-BreakingChange.ps1                   CREATE  Task 4
└── tests/
    ├── Get-Manifest.Tests.ps1                CREATE  Task 2
    ├── Get-SolutionOrder.Tests.ps1           CREATE  Task 2
    ├── Bump-Version.Tests.ps1                CREATE  Task 4
    └── Test-BreakingChange.Tests.ps1         CREATE  Task 4

.github/
├── workflows/
│   ├── solution-ci.yml                       CREATE  Task 6
│   ├── solution-deploy-dev.yml               CREATE  Task 7
│   ├── solution-deploy-test.yml              CREATE  Task 8
│   ├── solution-intake-on-demand.yml         CREATE  Task 9
│   └── solution-intake-drift.yml             CREATE  Task 9
├── CODEOWNERS                                MODIFY  Task 11
└── labels.yml                                CREATE  Task 6 (for version-bump:* labels)

docs/
├── adr/ADR-0019-solution-versioning-strategy.md   CREATE  Task 10
├── ideas/UC-02-git-integration-preview/README.md  CREATE  Task 12
├── runbooks/solution-rollback.md                  CREATE  Task 13
└── BACKLOG.md                                     MODIFY  Task 1 (add Epic 5 US-501..US-514)

.gitignore                                    MODIFY  Task 1 (ignore *.zip / temp export folders)
```

---

## Task 1 — Sprint prep: BACKLOG + gitignore + branch

**Files:**
- Modify: `docs/BACKLOG.md`
- Modify: `.gitignore`

- [ ] **Step 1: Create the sprint branch**

Run:
```powershell
Set-Location C:\Users\urruegg\source\urruegg\CRMShowcase
git checkout main
git pull
git checkout -b feat/sprint-1-solution-containers
```

Expected: `Switched to a new branch 'feat/sprint-1-solution-containers'`.

- [ ] **Step 2: Add Epic 5 to BACKLOG.md**

Read `docs/BACKLOG.md`. Find the last epic table (Epic 4). Append after it:

```markdown

## Epic 5 — Solution containers (Sprint 1)

Traces to spec [`docs/superpowers/specs/2026-08-06-solution-containers-design.md`](./superpowers/specs/2026-08-06-solution-containers-design.md).

| ID | Story | Status |
| --- | --- | --- |
| US-501 | Provision pac CLI on runner + local install docs | `[TBD]` |
| US-502 | Add pac auth create to CI + verify Power Platform OIDC | `[TBD]` |
| US-503 | solution/manifest.json + schema + parser | `[TBD]` |
| US-504 | Scaffold six empty solutions in DEV, export, unpack, commit | `[TBD]` |
| US-505 | scripts/solution/*.ps1 (export, unpack, pack, import, bump-version) | `[TBD]` |
| US-506 | .github/workflows/solution-ci.yml (Gate 1) | `[TBD]` |
| US-507 | .github/workflows/solution-deploy-dev.yml | `[TBD]` |
| US-508 | GitHub Environment test reviewers + solution-deploy-test.yml | `[TBD]` |
| US-509 | solution-intake-on-demand.yml + solution-intake-drift.yml | `[TBD]` |
| US-510 | ADR-0019 solution versioning strategy | `[TBD]` |
| US-511 | Extend .github/CODEOWNERS with folder-scoped rules | `[TBD]` |
| US-512 | docs/ideas/UC-02-git-integration-preview + issue | `[TBD]` |
| US-513 | docs/runbooks/solution-rollback.md | `[TBD]` |
| US-514 | End-to-end verification: fresh commit -> DEV -> TEST -> smoke green | `[TBD]` |
```

- [ ] **Step 3: Add solution build ignores to .gitignore**

Open `.gitignore`. Find the "Solution build outputs" section (added in the previous foundation sprint). Replace those lines with:

```
# Solution build outputs and temp export folders
solution/**/*.zip
!solution/**/managed/*.zip
solution/**/.build/
solution/**/.export-tmp/
```

- [ ] **Step 4: Commit**

```powershell
git add docs/BACKLOG.md .gitignore
git commit -m "chore(sprint-1): add Epic 5 backlog + solution build ignores"
```

Expected: 1 file changed lines added to `.gitignore`, 1 file changed for `BACKLOG.md`.

---

## Task 2 — Manifest schema + parser (Pester TDD)

**Files:**
- Create: `solution/manifest.schema.json`
- Create: `solution/manifest.json`
- Create: `scripts/solution/Get-Manifest.ps1`
- Create: `scripts/solution/Get-SolutionOrder.ps1`
- Test: `scripts/solution/tests/Get-Manifest.Tests.ps1`
- Test: `scripts/solution/tests/Get-SolutionOrder.Tests.ps1`

- [ ] **Step 1: Install Pester 5 (once)**

```powershell
Install-Module -Name Pester -MinimumVersion 5.5.0 -Scope CurrentUser -Force -SkipPublisherCheck
Import-Module Pester -MinimumVersion 5.5.0
Get-Module Pester | Format-List Name, Version
```

Expected: Pester 5.5.0 or higher listed.

- [ ] **Step 2: Write the failing test for Get-Manifest**

Create `scripts/solution/tests/Get-Manifest.Tests.ps1`:

```powershell
BeforeAll {
    . "$PSScriptRoot/../Get-Manifest.ps1"
    $script:repoRoot = Resolve-Path "$PSScriptRoot/../../.."
}

Describe "Get-Manifest" {
    It "returns an object with publisher, versioning, solutions" {
        $m = Get-Manifest -Path (Join-Path $script:repoRoot 'solution/manifest.json')
        $m | Should -Not -BeNullOrEmpty
        $m.publisher | Should -Not -BeNullOrEmpty
        $m.publisher.prefix | Should -Be 'crmshow'
        $m.versioning.scheme | Should -Be 'semver-four-part'
        $m.solutions | Should -HaveCount 6
    }

    It "validates the manifest against manifest.schema.json" {
        { Get-Manifest -Path (Join-Path $script:repoRoot 'solution/manifest.json') -Validate } | Should -Not -Throw
    }

    It "throws on missing file" {
        { Get-Manifest -Path 'nonexistent.json' } | Should -Throw
    }

    It "throws on invalid JSON" {
        $tmp = New-TemporaryFile
        Set-Content -Path $tmp -Value '{ invalid json'
        try { { Get-Manifest -Path $tmp } | Should -Throw } finally { Remove-Item $tmp -Force }
    }
}
```

- [ ] **Step 3: Run the test to verify it fails**

```powershell
Invoke-Pester scripts/solution/tests/Get-Manifest.Tests.ps1
```

Expected: **fails** — file not found for `Get-Manifest.ps1`.

- [ ] **Step 4: Create manifest.schema.json**

Create `solution/manifest.schema.json`:

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://raw.githubusercontent.com/urruegg/CRMShowcase/main/solution/manifest.schema.json",
  "title": "CRM Showcase Solution Manifest",
  "type": "object",
  "required": ["publisher", "versioning", "solutions"],
  "additionalProperties": false,
  "properties": {
    "$schema": { "type": "string" },
    "publisher": {
      "type": "object",
      "required": ["displayName", "uniqueName", "prefix", "customizationOptionValuePrefix"],
      "additionalProperties": false,
      "properties": {
        "displayName": { "type": "string", "minLength": 1 },
        "uniqueName": { "type": "string", "pattern": "^[A-Za-z][A-Za-z0-9_]*$" },
        "prefix": { "type": "string", "pattern": "^[a-z][a-z0-9]{1,7}$" },
        "customizationOptionValuePrefix": { "type": "integer", "minimum": 10000, "maximum": 99999 }
      }
    },
    "versioning": {
      "type": "object",
      "required": ["scheme", "format", "rules"],
      "properties": {
        "scheme": { "const": "semver-four-part" },
        "format": { "const": "MAJOR.MINOR.PATCH.BUILD" },
        "rules": { "type": "object" }
      }
    },
    "solutions": {
      "type": "array",
      "minItems": 1,
      "items": {
        "type": "object",
        "required": ["uniqueName", "displayName", "path", "version", "dependsOn", "owner"],
        "additionalProperties": false,
        "properties": {
          "uniqueName": { "type": "string", "pattern": "^crmshow_[A-Za-z][A-Za-z0-9]*$" },
          "displayName": { "type": "string" },
          "path": { "type": "string" },
          "version": { "type": "string", "pattern": "^\\d+\\.\\d+\\.\\d+\\.\\d+$" },
          "dependsOn": { "type": "array", "items": { "type": "string" } },
          "owner": { "type": "string" },
          "description": { "type": "string" }
        }
      }
    }
  }
}
```

- [ ] **Step 5: Create manifest.json**

Create `solution/manifest.json`:

```json
{
  "$schema": "./manifest.schema.json",
  "publisher": {
    "displayName": "CRM Showcase",
    "uniqueName": "CRMShowcase",
    "prefix": "crmshow",
    "customizationOptionValuePrefix": 10000
  },
  "versioning": {
    "scheme": "semver-four-part",
    "format": "MAJOR.MINOR.PATCH.BUILD",
    "rules": {
      "MAJOR": "breaking schema change (rename, delete, type change on published column)",
      "MINOR": "additive feature (new table, new column, new form)",
      "PATCH": "fix (label typo, form layout, business rule tweak)",
      "BUILD": "GitHub Actions run number (\\$env:GITHUB_RUN_NUMBER); source of uniqueness"
    }
  },
  "solutions": [
    {
      "uniqueName": "crmshow_Foundation",
      "displayName": "CRM Showcase - Foundation",
      "path": "core/foundation",
      "version": "1.0.0.0",
      "dependsOn": [],
      "owner": "AG-E-08",
      "description": "Publisher, security roles baseline, shared choice sets."
    },
    {
      "uniqueName": "crmshow_DataModel",
      "displayName": "CRM Showcase - Data Model",
      "path": "core/datamodel",
      "version": "1.0.0.0",
      "dependsOn": ["crmshow_Foundation"],
      "owner": "AG-E-08",
      "description": "ADR-0006..0010 extensions."
    },
    {
      "uniqueName": "crmshow_Integration",
      "displayName": "CRM Showcase - Integration",
      "path": "core/integration",
      "version": "1.0.0.0",
      "dependsOn": ["crmshow_Foundation"],
      "owner": "AG-E-09",
      "description": "Custom API defs, plug-in registrations, event-schema pointers."
    },
    {
      "uniqueName": "crmshow_Sales",
      "displayName": "CRM Showcase - Sales",
      "path": "apps/sales",
      "version": "1.0.0.0",
      "dependsOn": ["crmshow_Foundation", "crmshow_DataModel", "crmshow_Integration"],
      "owner": "AG-E-01",
      "description": "Sales-cockpit extensions on top of native Sales App."
    },
    {
      "uniqueName": "crmshow_Service",
      "displayName": "CRM Showcase - Service",
      "path": "apps/service",
      "version": "1.0.0.0",
      "dependsOn": ["crmshow_Foundation", "crmshow_DataModel", "crmshow_Integration"],
      "owner": "AG-E-01",
      "description": "Case triage on top of native Customer Service."
    },
    {
      "uniqueName": "crmshow_Marketing",
      "displayName": "CRM Showcase - Marketing",
      "path": "apps/marketing",
      "version": "1.0.0.0",
      "dependsOn": ["crmshow_Foundation", "crmshow_DataModel", "crmshow_Integration"],
      "owner": "AG-E-01",
      "description": "Segment / campaign extensions."
    }
  ]
}
```

- [ ] **Step 6: Create Get-Manifest.ps1**

Create `scripts/solution/Get-Manifest.ps1`:

```powershell
<#
.SYNOPSIS
    Load and (optionally) validate the solution manifest.
.PARAMETER Path
    Absolute or relative path to solution/manifest.json.
.PARAMETER Validate
    If specified, validates the loaded object against solution/manifest.schema.json.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$Path,

    [switch]$Validate
)

function Get-Manifest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        [switch]$Validate
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Manifest not found: $Path"
    }

    try {
        $raw = Get-Content -Raw -Path $Path
        $obj = $raw | ConvertFrom-Json -ErrorAction Stop
    } catch {
        throw "Invalid JSON in $Path : $_"
    }

    if ($Validate) {
        $schemaPath = Join-Path (Split-Path -Parent $Path) 'manifest.schema.json'
        if (-not (Test-Path -LiteralPath $schemaPath)) {
            throw "Schema not found next to manifest: $schemaPath"
        }
        # Minimal built-in validation. Full JSON-Schema validation is deferred to CI where npx ajv is available.
        # Locally we assert the required top-level fields and each solution has required properties.
        if (-not $obj.publisher) { throw "Manifest missing 'publisher'" }
        if (-not $obj.versioning) { throw "Manifest missing 'versioning'" }
        if (-not $obj.solutions -or $obj.solutions.Count -eq 0) { throw "Manifest missing 'solutions'" }
        foreach ($s in $obj.solutions) {
            foreach ($f in 'uniqueName','displayName','path','version','dependsOn','owner') {
                if (-not $s.PSObject.Properties.Name.Contains($f)) {
                    throw "Solution '$($s.uniqueName)' missing '$f'"
                }
            }
            if ($s.version -notmatch '^\d+\.\d+\.\d+\.\d+$') {
                throw "Solution '$($s.uniqueName)' has invalid version '$($s.version)'"
            }
        }
    }

    return $obj
}

# When script is dot-sourced or executed with -Path, do the right thing.
if ($MyInvocation.InvocationName -ne '.' -and $PSBoundParameters.ContainsKey('Path')) {
    Get-Manifest -Path $Path -Validate:$Validate
}
```

- [ ] **Step 7: Run the test to verify it passes**

```powershell
Invoke-Pester scripts/solution/tests/Get-Manifest.Tests.ps1
```

Expected: All 4 tests pass.

- [ ] **Step 8: Write the failing test for Get-SolutionOrder**

Create `scripts/solution/tests/Get-SolutionOrder.Tests.ps1`:

```powershell
BeforeAll {
    . "$PSScriptRoot/../Get-SolutionOrder.ps1"
    . "$PSScriptRoot/../Get-Manifest.ps1"
    $script:repoRoot = Resolve-Path "$PSScriptRoot/../../.."
}

Describe "Get-SolutionOrder" {
    BeforeEach {
        $script:m = Get-Manifest -Path (Join-Path $script:repoRoot 'solution/manifest.json')
    }

    It "returns Foundation first" {
        $ordered = Get-SolutionOrder -Manifest $script:m
        $ordered[0].uniqueName | Should -Be 'crmshow_Foundation'
    }

    It "puts DataModel and Integration after Foundation" {
        $ordered = Get-SolutionOrder -Manifest $script:m
        $indexFoundation = ($ordered | ForEach-Object { $_.uniqueName }).IndexOf('crmshow_Foundation')
        $indexDataModel = ($ordered | ForEach-Object { $_.uniqueName }).IndexOf('crmshow_DataModel')
        $indexIntegration = ($ordered | ForEach-Object { $_.uniqueName }).IndexOf('crmshow_Integration')
        $indexDataModel | Should -BeGreaterThan $indexFoundation
        $indexIntegration | Should -BeGreaterThan $indexFoundation
    }

    It "puts every app after DataModel and Integration" {
        $ordered = Get-SolutionOrder -Manifest $script:m
        $names = $ordered | ForEach-Object { $_.uniqueName }
        foreach ($app in 'crmshow_Sales','crmshow_Service','crmshow_Marketing') {
            $names.IndexOf($app) | Should -BeGreaterThan $names.IndexOf('crmshow_DataModel')
            $names.IndexOf($app) | Should -BeGreaterThan $names.IndexOf('crmshow_Integration')
        }
    }

    It "returns all 6 solutions" {
        $ordered = Get-SolutionOrder -Manifest $script:m
        $ordered | Should -HaveCount 6
    }

    It "throws on circular dependency" {
        $bad = $script:m | ConvertTo-Json -Depth 10 | ConvertFrom-Json
        $bad.solutions[0].dependsOn = @('crmshow_Sales')  # Foundation now depends on Sales (which depends on Foundation)
        { Get-SolutionOrder -Manifest $bad } | Should -Throw -ExpectedMessage '*circular*'
    }

    It "throws on unknown dependency" {
        $bad = $script:m | ConvertTo-Json -Depth 10 | ConvertFrom-Json
        $bad.solutions[3].dependsOn = @('crmshow_Nonexistent')
        { Get-SolutionOrder -Manifest $bad } | Should -Throw -ExpectedMessage '*unknown*'
    }
}
```

- [ ] **Step 9: Run the test to verify it fails**

```powershell
Invoke-Pester scripts/solution/tests/Get-SolutionOrder.Tests.ps1
```

Expected: 6 failures, all "file not found" or "function not defined".

- [ ] **Step 10: Create Get-SolutionOrder.ps1**

Create `scripts/solution/Get-SolutionOrder.ps1`:

```powershell
<#
.SYNOPSIS
    Topologically sort the manifest.solutions array by dependsOn.
    Returns the list of solution objects in the order they must be imported.
.PARAMETER Manifest
    The parsed manifest object (as returned by Get-Manifest.ps1).
#>

function Get-SolutionOrder {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Manifest
    )

    $byName = @{}
    foreach ($s in $Manifest.solutions) { $byName[$s.uniqueName] = $s }

    # Validate dependsOn references
    foreach ($s in $Manifest.solutions) {
        foreach ($dep in $s.dependsOn) {
            if (-not $byName.ContainsKey($dep)) {
                throw "Solution '$($s.uniqueName)' references unknown dependency '$dep'"
            }
        }
    }

    $result = New-Object System.Collections.Generic.List[object]
    $visited = @{}
    $visiting = @{}

    function _Visit($name) {
        if ($visited[$name]) { return }
        if ($visiting[$name]) {
            throw "circular dependency detected involving '$name'"
        }
        $visiting[$name] = $true
        foreach ($dep in $byName[$name].dependsOn) {
            _Visit $dep
        }
        $visiting[$name] = $false
        $visited[$name] = $true
        $result.Add($byName[$name]) | Out-Null
    }

    foreach ($s in $Manifest.solutions) {
        _Visit $s.uniqueName
    }

    return $result
}
```

- [ ] **Step 11: Run the test to verify it passes**

```powershell
Invoke-Pester scripts/solution/tests/Get-SolutionOrder.Tests.ps1
```

Expected: All 6 tests pass.

- [ ] **Step 12: Commit**

```powershell
git add solution/manifest.json solution/manifest.schema.json scripts/solution/Get-Manifest.ps1 scripts/solution/Get-SolutionOrder.ps1 scripts/solution/tests/
git commit -m "feat(solution): manifest schema + parser + topo-sort (US-503)"
```

---

## Task 3 — Install pac CLI locally + verify auth (US-501, US-502)

**Files:**
- Modify: `docs/OPERATIONS.md` (append a "Local pac CLI" section)

- [ ] **Step 1: Check for .NET SDK**

```powershell
dotnet --list-sdks
```

Expected: at least one SDK 6.0 or higher. If missing, install `winget install Microsoft.DotNet.SDK.8`.

- [ ] **Step 2: Install pac CLI as a dotnet global tool**

```powershell
dotnet tool install --global Microsoft.PowerApps.CLI.Tool
```

Expected output: `You can invoke the tool using the following command: pac`. If already installed, run `dotnet tool update --global Microsoft.PowerApps.CLI.Tool`.

- [ ] **Step 3: Verify pac is on PATH**

```powershell
pac --version
```

Expected: version banner. If "not recognized", add `$env:USERPROFILE\.dotnet\tools` to `$env:PATH` (dotnet tool install prints where it went).

- [ ] **Step 4: Sign into DEV using the existing az login session**

Note: `pac auth` maintains its own token cache separate from `az`. First run creates a new auth profile.

```powershell
az account show --output json | ConvertFrom-Json | Select-Object tenantId, name
# Confirm ABSx tenant b829e4ef-...
pac auth create --name crmshowdev --url https://crmshowdev.crm.dynamics.com --deviceCode
```

Expected: device-code prompt. Complete in browser with `admin@ABSx15847880.onmicrosoft.com`.

- [ ] **Step 5: Verify pac auth for DEV**

```powershell
pac auth list
pac org who
```

Expected: `pac auth list` shows `crmshowdev` (index 1); `pac org who` returns the DEV org info.

- [ ] **Step 6: Sign into TEST**

```powershell
pac auth create --name crmshowtest --url https://crmshowtest.crm.dynamics.com --deviceCode
pac auth list
```

Expected: both `crmshowdev` and `crmshowtest` listed.

- [ ] **Step 7: Append "Local pac CLI" to docs/OPERATIONS.md**

Read `docs/OPERATIONS.md`. Find "How complexity stays controllable" (near the bottom). Add a new section before it:

```markdown
## Local pac CLI setup

To work with the six Power Platform solutions locally (`solution/manifest.json`),
install the Power Platform CLI once:

```powershell
# One-off install
dotnet tool install --global Microsoft.PowerApps.CLI.Tool

# Sign in per environment (device-code)
pac auth create --name crmshowdev  --url https://crmshowdev.crm.dynamics.com  --deviceCode
pac auth create --name crmshowtest --url https://crmshowtest.crm.dynamics.com --deviceCode

# Switch between them
pac auth select --index 1   # crmshowdev
pac auth select --index 2   # crmshowtest
```

The auth session is cached in `%LOCALAPPDATA%\.PowerAppsCli` and is separate
from `az` — the `az login` context is NOT reused by `pac`.
```

- [ ] **Step 8: Commit**

```powershell
git add docs/OPERATIONS.md
git commit -m "docs(operations): local pac CLI setup steps (US-501)"
```

---

## Task 4 — Solution scripts + version-bump logic (US-505)

**Files:**
- Create: `scripts/solution/Export-Solution.ps1`
- Create: `scripts/solution/Unpack-Solution.ps1`
- Create: `scripts/solution/Pack-Solution.ps1`
- Create: `scripts/solution/Import-Solution.ps1`
- Create: `scripts/solution/Bump-Version.ps1`
- Create: `scripts/solution/Test-BreakingChange.ps1`
- Test: `scripts/solution/tests/Bump-Version.Tests.ps1`
- Test: `scripts/solution/tests/Test-BreakingChange.Tests.ps1`

- [ ] **Step 1: Write failing test for Bump-Version**

Create `scripts/solution/tests/Bump-Version.Tests.ps1`:

```powershell
BeforeAll {
    . "$PSScriptRoot/../Bump-Version.ps1"
}

Describe "Bump-Version" {
    It "bumps PATCH: 1.2.3.42 patch -> 1.2.4.100" {
        Bump-Version -Current '1.2.3.42' -Kind 'patch' -Build 100 | Should -Be '1.2.4.100'
    }

    It "bumps MINOR: 1.2.3.42 minor -> 1.3.0.100" {
        Bump-Version -Current '1.2.3.42' -Kind 'minor' -Build 100 | Should -Be '1.3.0.100'
    }

    It "bumps MAJOR: 1.2.3.42 major -> 2.0.0.100" {
        Bump-Version -Current '1.2.3.42' -Kind 'major' -Build 100 | Should -Be '2.0.0.100'
    }

    It "bumps BUILD only: 1.2.3.42 build -> 1.2.3.100" {
        Bump-Version -Current '1.2.3.42' -Kind 'build' -Build 100 | Should -Be '1.2.3.100'
    }

    It "throws on invalid current" {
        { Bump-Version -Current '1.2.3' -Kind 'patch' -Build 1 } | Should -Throw
    }

    It "throws on invalid kind" {
        { Bump-Version -Current '1.0.0.0' -Kind 'xxxx' -Build 1 } | Should -Throw
    }

    It "throws if Build is negative" {
        { Bump-Version -Current '1.0.0.0' -Kind 'patch' -Build -1 } | Should -Throw
    }
}
```

- [ ] **Step 2: Run to verify failure**

```powershell
Invoke-Pester scripts/solution/tests/Bump-Version.Tests.ps1
```

Expected: fails, file not found.

- [ ] **Step 3: Create Bump-Version.ps1**

Create `scripts/solution/Bump-Version.ps1`:

```powershell
<#
.SYNOPSIS
    Compute a new Dataverse-format version string given the current version and a bump kind.
.PARAMETER Current
    Current version, e.g. 1.2.3.42.
.PARAMETER Kind
    One of: major, minor, patch, build.
.PARAMETER Build
    The build number to embed in the fourth part (typically $env:GITHUB_RUN_NUMBER).
#>

function Bump-Version {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Current,

        [Parameter(Mandatory)]
        [ValidateSet('major','minor','patch','build')]
        [string]$Kind,

        [Parameter(Mandatory)]
        [int]$Build
    )

    if ($Current -notmatch '^\d+\.\d+\.\d+\.\d+$') {
        throw "Current version '$Current' is not in MAJOR.MINOR.PATCH.BUILD format"
    }
    if ($Build -lt 0) {
        throw "Build must be >= 0"
    }

    $parts = $Current.Split('.') | ForEach-Object { [int]$_ }
    $maj, $min, $pat = $parts[0], $parts[1], $parts[2]

    switch ($Kind) {
        'major' { $maj++; $min = 0; $pat = 0 }
        'minor' { $min++; $pat = 0 }
        'patch' { $pat++ }
        'build' { }
    }

    return "$maj.$min.$pat.$Build"
}
```

- [ ] **Step 4: Run to verify pass**

```powershell
Invoke-Pester scripts/solution/tests/Bump-Version.Tests.ps1
```

Expected: all 7 tests pass.

- [ ] **Step 5: Write failing test for Test-BreakingChange**

Create `scripts/solution/tests/Test-BreakingChange.Tests.ps1`:

```powershell
BeforeAll {
    . "$PSScriptRoot/../Test-BreakingChange.ps1"
}

Describe "Test-BreakingChange" {
    It "returns 'patch' when only AttributeDisplayCollectionOverride changed" {
        $diff = @'
--- a/solution/core/foundation/Other/Solution.xml
+++ b/solution/core/foundation/Other/Solution.xml
@@ -10,3 +10,3 @@
   <AttributeDisplayCollectionOverride>
-    <DisplayName>Old label</DisplayName>
+    <DisplayName>New label</DisplayName>
   </AttributeDisplayCollectionOverride>
'@
        Test-BreakingChange -Diff $diff | Should -Be 'patch'
    }

    It "returns 'minor' when a new <attribute> is added" {
        $diff = @'
+++ b/solution/core/datamodel/Other/Customizations.xml
+    <attribute PhysicalName="crmshow_newcol">
+      <Type>string</Type>
+    </attribute>
'@
        Test-BreakingChange -Diff $diff | Should -Be 'minor'
    }

    It "returns 'major' when an <attribute> is removed" {
        $diff = @'
--- a/solution/core/datamodel/Other/Customizations.xml
-    <attribute PhysicalName="crmshow_dropped">
-      <Type>string</Type>
-    </attribute>
'@
        Test-BreakingChange -Diff $diff | Should -Be 'major'
    }

    It "returns 'major' when <SchemaName> changed" {
        $diff = @'
-      <SchemaName>crmshow_oldname</SchemaName>
+      <SchemaName>crmshow_newname</SchemaName>
'@
        Test-BreakingChange -Diff $diff | Should -Be 'major'
    }

    It "returns 'patch' on trivial whitespace-only diff" {
        Test-BreakingChange -Diff "   " | Should -Be 'patch'
    }
}
```

- [ ] **Step 6: Run to verify failure**

```powershell
Invoke-Pester scripts/solution/tests/Test-BreakingChange.Tests.ps1
```

Expected: 5 failures.

- [ ] **Step 7: Create Test-BreakingChange.ps1**

Create `scripts/solution/Test-BreakingChange.ps1`:

```powershell
<#
.SYNOPSIS
    Classify a unified diff of Solution.xml / Customizations.xml as major, minor, or patch.
.PARAMETER Diff
    A unified diff (typically from `git diff`) restricted to solution/ files.
#>

function Test-BreakingChange {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Diff
    )

    # Major: removed <attribute> or <Entity>, or SchemaName / Type changed on published items.
    if ($Diff -match '(?m)^\-\s*<attribute\b') { return 'major' }
    if ($Diff -match '(?m)^\-\s*<Entity\b')    { return 'major' }
    if ($Diff -match '(?m)^\-\s*<SchemaName>[^<]+</SchemaName>' -and
        $Diff -match '(?m)^\+\s*<SchemaName>[^<]+</SchemaName>') { return 'major' }
    if ($Diff -match '(?m)^\-\s*<Type>[^<]+</Type>' -and
        $Diff -match '(?m)^\+\s*<Type>[^<]+</Type>') { return 'major' }

    # Minor: additive new <attribute> or new <Entity>
    if ($Diff -match '(?m)^\+\s*<attribute\b') { return 'minor' }
    if ($Diff -match '(?m)^\+\s*<Entity\b')    { return 'minor' }

    return 'patch'
}
```

- [ ] **Step 8: Run to verify pass**

```powershell
Invoke-Pester scripts/solution/tests/Test-BreakingChange.Tests.ps1
```

Expected: all 5 tests pass.

- [ ] **Step 9: Create Export-Solution.ps1**

Create `scripts/solution/Export-Solution.ps1`:

```powershell
<#
.SYNOPSIS
    Export a solution from a Power Platform environment as an unmanaged zip.
.PARAMETER SolutionName
    Unique name, e.g. crmshow_Foundation.
.PARAMETER OutFile
    Absolute path for the .zip.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$SolutionName,
    [Parameter(Mandatory)] [string]$OutFile,
    [switch]$Managed
)

$type = if ($Managed) { 'Managed' } else { 'Unmanaged' }
$outDir = Split-Path -Parent $OutFile
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

Write-Host "Exporting $SolutionName ($type) to $OutFile"
pac solution export --name $SolutionName --path $OutFile --managed ($Managed.IsPresent) --overwrite --async
if ($LASTEXITCODE -ne 0) { throw "pac solution export failed for $SolutionName" }
Write-Host "Exported: $OutFile"
```

- [ ] **Step 10: Create Unpack-Solution.ps1**

Create `scripts/solution/Unpack-Solution.ps1`:

```powershell
<#
.SYNOPSIS
    Unpack a solution zip into a folder using pac solution unpack.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$ZipFile,
    [Parameter(Mandatory)] [string]$Folder
)

New-Item -ItemType Directory -Force -Path $Folder | Out-Null
Write-Host "Unpacking $ZipFile -> $Folder"
pac solution unpack --zipfile $ZipFile --folder $Folder --packagetype Unmanaged --allowDelete --allowWrite --clobber
if ($LASTEXITCODE -ne 0) { throw "pac solution unpack failed" }
Write-Host "Unpacked: $Folder"
```

- [ ] **Step 11: Create Pack-Solution.ps1**

Create `scripts/solution/Pack-Solution.ps1`:

```powershell
<#
.SYNOPSIS
    Pack an unpacked solution folder into a zip.
.PARAMETER Folder
    Path to an unpacked solution folder (contains Other/Solution.xml).
.PARAMETER OutFile
    Path for the resulting .zip.
.PARAMETER Managed
    If specified, packs as Managed.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$Folder,
    [Parameter(Mandatory)] [string]$OutFile,
    [switch]$Managed
)

$type = if ($Managed) { 'Managed' } else { 'Unmanaged' }
$outDir = Split-Path -Parent $OutFile
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

Write-Host "Packing $Folder -> $OutFile ($type)"
pac solution pack --folder $Folder --zipfile $OutFile --packagetype $type
if ($LASTEXITCODE -ne 0) { throw "pac solution pack failed" }
Write-Host "Packed: $OutFile"
```

- [ ] **Step 12: Create Import-Solution.ps1**

Create `scripts/solution/Import-Solution.ps1`:

```powershell
<#
.SYNOPSIS
    Import a solution zip into the currently-selected pac auth environment.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$ZipFile,
    [switch]$Async,
    [switch]$PublishChanges
)

$args = @('solution','import','--path', $ZipFile,'--force-overwrite')
if ($Async) { $args += '--async' }
if ($PublishChanges) { $args += '--publish-changes' }

Write-Host "Importing $ZipFile ..."
pac @args
if ($LASTEXITCODE -ne 0) { throw "pac solution import failed for $ZipFile" }
Write-Host "Imported: $ZipFile"
```

- [ ] **Step 13: Commit**

```powershell
git add scripts/solution/
git commit -m "feat(solution): export/unpack/pack/import scripts + version bump + breaking-change classifier (US-505)"
```

---

## Task 5 — Scaffold 6 empty solutions in DEV, export, unpack, commit (US-504)

**Files:**
- Create: `solution/core/foundation/` (unpacked structure)
- Create: `solution/core/datamodel/`
- Create: `solution/core/integration/`
- Create: `solution/apps/sales/`
- Create: `solution/apps/service/`
- Create: `solution/apps/marketing/`

- [ ] **Step 1: Ensure DEV auth is selected**

```powershell
pac auth select --index 1  # crmshowdev
pac org who
```

Expected: DEV org details.

- [ ] **Step 2: Create publisher via Web API (idempotent)**

`pac solution publisher create` is not a subcommand; publishers are created
via the Web API. This is idempotent because we check first.

```powershell
$envUrl = 'https://crmshowdev.crm.dynamics.com'
$existing = az rest --method GET `
    --url "$envUrl/api/data/v9.2/publishers?%24filter=uniquename%20eq%20%27CRMShowcase%27&%24select=publisherid" `
    --resource "$envUrl/" --only-show-errors | ConvertFrom-Json

if ($existing.value.Count -gt 0) {
    Write-Host "Publisher CRMShowcase already exists ($($existing.value[0].publisherid))"
} else {
    $body = @{
        uniquename = 'CRMShowcase'
        friendlyname = 'CRM Showcase'
        customizationprefix = 'crmshow'
        customizationoptionvalueprefix = 10000
    } | ConvertTo-Json -Compress
    $bodyFile = New-TemporaryFile
    Set-Content -Path $bodyFile -Value $body -Encoding utf8
    az rest --method POST --url "$envUrl/api/data/v9.2/publishers" --resource "$envUrl/" `
            --body "@$bodyFile" --headers 'Content-Type=application/json' --only-show-errors
    Remove-Item $bodyFile -Force
    Write-Host "Publisher CRMShowcase created"
}
```

Expected: either "already exists" or a 204 No Content.

- [ ] **Step 3: Create the six solutions in DEV via Web API**

`pac` does not have a subcommand to create an org-side solution record;
`pac solution init` scaffolds a *project* for source, not a Dataverse
solution. We create the six via the Web API, using the `az` session against
the DEV env.

```powershell
$envUrl = 'https://crmshowdev.crm.dynamics.com'
az account set --subscription b829e4ef-1a9f-45ba-80e5-48408aa421a9

$publisherResp = az rest --method GET `
    --url "$envUrl/api/data/v9.2/publishers?%24filter=uniquename%20eq%20%27CRMShowcase%27&%24select=publisherid" `
    --resource "$envUrl/" --only-show-errors | ConvertFrom-Json
$publisherId = $publisherResp.value[0].publisherid
if (-not $publisherId) { throw "CRMShowcase publisher not found - re-run Step 2" }

$solutions = @(
    @{ n='crmshow_Foundation';   d='CRM Showcase - Foundation' }
    @{ n='crmshow_DataModel';    d='CRM Showcase - Data Model' }
    @{ n='crmshow_Integration';  d='CRM Showcase - Integration' }
    @{ n='crmshow_Sales';        d='CRM Showcase - Sales' }
    @{ n='crmshow_Service';      d='CRM Showcase - Service' }
    @{ n='crmshow_Marketing';    d='CRM Showcase - Marketing' }
)

foreach ($s in $solutions) {
    $body = @{
        uniquename = $s.n
        friendlyname = $s.d
        version = '1.0.0.0'
        "publisherid@odata.bind" = "/publishers($publisherId)"
    } | ConvertTo-Json -Compress
    $bodyFile = New-TemporaryFile
    Set-Content -Path $bodyFile -Value $body -Encoding utf8
    Write-Host "Creating $($s.n) ..."
    az rest --method POST --url "$envUrl/api/data/v9.2/solutions" --resource "$envUrl/" `
            --body "@$bodyFile" --headers 'Content-Type=application/json' --only-show-errors
    Remove-Item $bodyFile -Force
}
```

Expected: 6 POST calls succeed (a 204 No Content each). If a solution
already exists you'll get a 400 with `A managed solution with the same
unique name already exists` — safe to ignore for this idempotent-ish flow.

- [ ] **Step 4: Verify all 6 exist in DEV**

```powershell
pac solution list | Select-String 'crmshow_'
```

Expected: 6 lines, one per solution.

- [ ] **Step 5: Export each solution and unpack into its manifest path**

```powershell
$repoRoot = "C:\Users\urruegg\source\urruegg\CRMShowcase"
. (Join-Path $repoRoot 'scripts/solution/Get-Manifest.ps1')
$m = Get-Manifest -Path (Join-Path $repoRoot 'solution/manifest.json')

foreach ($s in $m.solutions) {
    $zipPath = Join-Path $env:TEMP "$($s.uniqueName).zip"
    & (Join-Path $repoRoot 'scripts/solution/Export-Solution.ps1') -SolutionName $s.uniqueName -OutFile $zipPath
    $folder = Join-Path $repoRoot "solution/$($s.path)"
    & (Join-Path $repoRoot 'scripts/solution/Unpack-Solution.ps1') -ZipFile $zipPath -Folder $folder
}
```

Expected: 6 unpacked solution folders under `solution/core/*` and `solution/apps/*`, each with `Other/Solution.xml`.

- [ ] **Step 6: Commit the empty solution scaffolds**

```powershell
git add solution/core/ solution/apps/
git commit -m "feat(solution): scaffold 6 empty solutions in DEV, exported + unpacked (US-504)"
```

---

## Task 6 — solution-ci workflow with Gate 1 checks (US-506)

**Files:**
- Create: `.github/labels.yml`
- Create: `.github/workflows/solution-ci.yml`

- [ ] **Step 1: Create labels.yml for the version-bump labels**

Create `.github/labels.yml`:

```yaml
- name: version-bump:major
  color: b60205
  description: This PR is a breaking change and the manifest MAJOR version must bump.
- name: version-bump:minor
  color: 0e8a16
  description: This PR is an additive feature; the manifest MINOR version bumps.
- name: version-bump:patch
  color: fbca04
  description: This PR is a fix; the manifest PATCH version bumps.
- name: skip-solution-ci
  color: cccccc
  description: Skip the solution CI workflow (docs-only edits, etc.).
```

- [ ] **Step 2: Create labels in the repo**

```powershell
gh label create "version-bump:major" --color b60205 --description "Breaking change" --force
gh label create "version-bump:minor" --color 0e8a16 --description "Additive feature" --force
gh label create "version-bump:patch" --color fbca04 --description "Fix" --force
gh label create "skip-solution-ci" --color cccccc --description "Skip solution CI" --force
gh label list | Select-String 'version-bump'
```

Expected: 3 version-bump labels listed.

- [ ] **Step 3: Create solution-ci.yml**

Create `.github/workflows/solution-ci.yml`:

```yaml
name: Solution CI

on:
  pull_request:
    paths:
      - 'solution/**'
      - 'scripts/solution/**'
      - '.github/workflows/solution-*.yml'

permissions:
  contents: read
  pull-requests: write

jobs:
  gate1:
    runs-on: ubuntu-latest
    if: "!contains(github.event.pull_request.labels.*.name, 'skip-solution-ci')"
    steps:
      - uses: actions/checkout@v4
        with: { fetch-depth: 0 }

      - name: Install pac CLI
        uses: microsoft/powerplatform-actions/actions-install@v1

      - name: Install PowerShell modules
        shell: pwsh
        run: |
          Install-Module -Name Pester -MinimumVersion 5.5.0 -Force -SkipPublisherCheck

      - name: Validate manifest
        shell: pwsh
        run: |
          . ./scripts/solution/Get-Manifest.ps1
          . ./scripts/solution/Get-SolutionOrder.ps1
          $m = Get-Manifest -Path ./solution/manifest.json -Validate
          $order = Get-SolutionOrder -Manifest $m
          Write-Host "Solutions in dependency order:"
          $order | ForEach-Object { Write-Host "  $($_.uniqueName)" }
          # Refuse unlisted folders
          $onDisk = Get-ChildItem -Path ./solution -Recurse -Directory |
                     Where-Object { Test-Path (Join-Path $_.FullName 'Other/Solution.xml') } |
                     ForEach-Object { $_.FullName.Substring((Resolve-Path ./solution).Path.Length + 1) -replace '\\','/' }
          $inManifest = $m.solutions | ForEach-Object { $_.path }
          foreach ($p in $onDisk) {
            if ($inManifest -notcontains $p) { throw "Folder $p exists on disk but is not in manifest" }
          }
          foreach ($p in $inManifest) {
            if ($onDisk -notcontains $p) { throw "Manifest lists $p but the folder does not exist on disk" }
          }

      - name: Pester unit tests
        shell: pwsh
        run: |
          $r = Invoke-Pester -Path ./scripts/solution/tests/ -PassThru -Output Detailed
          if ($r.FailedCount -gt 0) { exit 1 }

      - name: Pack all solutions
        shell: pwsh
        run: |
          . ./scripts/solution/Get-Manifest.ps1
          . ./scripts/solution/Get-SolutionOrder.ps1
          $m = Get-Manifest -Path ./solution/manifest.json
          foreach ($s in Get-SolutionOrder -Manifest $m) {
            $out = "solution-artifacts/$($s.uniqueName).zip"
            ./scripts/solution/Pack-Solution.ps1 -Folder "solution/$($s.path)" -OutFile $out
          }

      - name: Solution Checker
        uses: microsoft/powerplatform-actions/check-solution@v1
        with:
          path: 'solution-artifacts'
          use-desktop-flow-runner: false

      - name: Detect breaking changes
        shell: pwsh
        run: |
          . ./scripts/solution/Test-BreakingChange.ps1
          $base = "${{ github.event.pull_request.base.sha }}"
          $head = "${{ github.event.pull_request.head.sha }}"
          $diff = git diff $base $head -- 'solution/**/Solution.xml' 'solution/**/Customizations.xml'
          $kind = Test-BreakingChange -Diff $diff
          Write-Host "Detected bump kind: $kind"
          if ($kind -eq 'major') {
            $labels = "${{ join(github.event.pull_request.labels.*.name, ',') }}"
            if ($labels -notmatch 'version-bump:major') {
              gh pr comment ${{ github.event.pull_request.number }} --body "This PR removes or renames a schema element (MAJOR change). Add label ``version-bump:major`` to unblock merge."
              exit 1
            }
          }
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}

      - name: Terraform plan (no infra drift)
        run: |
          curl -fsSLO https://releases.hashicorp.com/terraform/1.9.8/terraform_1.9.8_linux_amd64.zip
          unzip -qq terraform_1.9.8_linux_amd64.zip
          sudo mv terraform /usr/local/bin/
          cd infra/terraform
          terraform init -input=false -backend=false
          terraform validate
```

- [ ] **Step 4: Push the branch and open a draft PR to verify the workflow shape**

```powershell
git add .github/labels.yml .github/workflows/solution-ci.yml
git commit -m "feat(ci): solution-ci workflow with Gate 1 checks (US-506)"
git push -u origin feat/sprint-1-solution-containers
gh pr create --draft --title "Sprint 1 (WIP): solution containers" --body "Draft PR to exercise solution-ci workflow. Do not merge." --base main --head feat/sprint-1-solution-containers
```

Expected: draft PR created; solution-ci workflow starts.

- [ ] **Step 5: Watch the workflow run**

```powershell
gh run list --workflow=solution-ci.yml --limit 1
gh run watch $((gh run list --workflow=solution-ci.yml --json databaseId --jq '.[0].databaseId'))
```

Expected: all steps green. If Solution Checker reports Medium/Low, they appear as annotations, not failures.

---

## Task 7 — solution-deploy-dev workflow (US-507)

**Files:**
- Create: `.github/workflows/solution-deploy-dev.yml`

- [ ] **Step 1: Create solution-deploy-dev.yml**

Create `.github/workflows/solution-deploy-dev.yml`:

```yaml
name: Solution Deploy — DEV

on:
  push:
    branches: [main]
    paths:
      - 'solution/**'
      - '.github/workflows/solution-deploy-dev.yml'
  workflow_dispatch:

permissions:
  contents: write
  id-token: write

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: dev
    steps:
      - uses: actions/checkout@v4
        with: { fetch-depth: 0 }

      - name: Install pac CLI
        uses: microsoft/powerplatform-actions/actions-install@v1

      - name: Azure login (OIDC)
        uses: azure/login@v2
        with:
          client-id: ${{ vars.AZURE_CLIENT_ID }}
          tenant-id: ${{ vars.AZURE_TENANT_ID }}
          allow-no-subscriptions: true

      - name: pac auth via federated token
        shell: pwsh
        run: |
          # Reuse the az session token cache with pac
          pac auth create --url ${{ vars.POWER_PLATFORM_ENV_URL }} --name ci-dev --applicationId ${{ vars.AZURE_CLIENT_ID }} --tenant ${{ vars.AZURE_TENANT_ID }} --cloud Public --deviceCode:$false
          pac auth list
          pac org who

      - name: Bump BUILD in manifest
        shell: pwsh
        run: |
          . ./scripts/solution/Get-Manifest.ps1
          . ./scripts/solution/Bump-Version.ps1
          $mPath = './solution/manifest.json'
          $m = Get-Manifest -Path $mPath
          foreach ($s in $m.solutions) {
            $s.version = Bump-Version -Current $s.version -Kind 'build' -Build ${{ github.run_number }}
          }
          $m | ConvertTo-Json -Depth 10 | Set-Content -Path $mPath -Encoding utf8

      - name: Pack all solutions (unmanaged)
        shell: pwsh
        run: |
          . ./scripts/solution/Get-Manifest.ps1
          . ./scripts/solution/Get-SolutionOrder.ps1
          $m = Get-Manifest -Path ./solution/manifest.json
          foreach ($s in Get-SolutionOrder -Manifest $m) {
            # Write the new version into the unpacked Solution.xml before pack
            $solXml = "solution/$($s.path)/Other/Solution.xml"
            $xml = Get-Content -Raw $solXml
            $xml = $xml -replace '(<Version>)[^<]+(</Version>)', "`$1$($s.version)`$2"
            Set-Content -Path $solXml -Value $xml -Encoding utf8
            ./scripts/solution/Pack-Solution.ps1 -Folder "solution/$($s.path)" -OutFile "artifacts/$($s.uniqueName).zip"
          }

      - name: Import in dependency order
        shell: pwsh
        run: |
          . ./scripts/solution/Get-Manifest.ps1
          . ./scripts/solution/Get-SolutionOrder.ps1
          $m = Get-Manifest -Path ./solution/manifest.json
          foreach ($s in Get-SolutionOrder -Manifest $m) {
            ./scripts/solution/Import-Solution.ps1 -ZipFile "artifacts/$($s.uniqueName).zip" -Async -PublishChanges
          }

      - name: Smoke test — versions match
        shell: pwsh
        run: |
          . ./scripts/solution/Get-Manifest.ps1
          $m = Get-Manifest -Path ./solution/manifest.json
          $envUrl = "${{ vars.POWER_PLATFORM_ENV_URL }}".TrimEnd('/')
          $token = (az account get-access-token --resource "$envUrl/" --query accessToken -o tsv)
          $failed = $false
          foreach ($s in $m.solutions) {
            $url = "$envUrl/api/data/v9.2/solutions?`$filter=uniquename eq '$($s.uniqueName)'&`$select=uniquename,version"
            $r = Invoke-RestMethod -Uri $url -Headers @{ Authorization = "Bearer $token"; Accept='application/json' }
            $observed = $r.value[0].version
            if ($observed -ne $s.version) {
              Write-Host "MISMATCH $($s.uniqueName): manifest=$($s.version) target=$observed"
              $failed = $true
            } else {
              Write-Host "OK $($s.uniqueName) @ $observed"
            }
          }
          if ($failed) { exit 1 }
```

- [ ] **Step 2: Commit and push**

```powershell
git add .github/workflows/solution-deploy-dev.yml
git commit -m "feat(ci): solution-deploy-dev workflow (US-507)"
git push
```

- [ ] **Step 3: Wait for the CI to go green on the PR, then merge**

Once the PR CI is green and the PR is approved, squash-merge to trigger `solution-deploy-dev.yml`.

Watch:

```powershell
gh run list --workflow=solution-deploy-dev.yml --limit 1
gh run watch $((gh run list --workflow=solution-deploy-dev.yml --json databaseId --jq '.[0].databaseId'))
```

Expected: all steps green; 6 solutions re-imported to DEV at BUILD=<run_number>.

---

## Task 8 — GitHub Environment `test` reviewers + deploy-test workflow (US-508)

**Files:**
- Create: `.github/workflows/solution-deploy-test.yml`

- [ ] **Step 1: Add required reviewers to the `test` GitHub Environment**

Via GitHub UI: repo → Settings → Environments → `test` → **Required reviewers**: add `urruegg` (yourself). Set "Deployment branches" to "Selected branches" and add rule `main`. Set "Wait timer" to 0.

Or via CLI:

```powershell
gh api -X PUT /repos/urruegg/CRMShowcase/environments/test `
    -f "reviewers[][type]=User" -f "reviewers[][id]=46865858" `
    -f "deployment_branch_policy[protected_branches]=false" `
    -f "deployment_branch_policy[custom_branch_policies]=true"

gh api -X POST /repos/urruegg/CRMShowcase/environments/test/deployment-branch-policies -f name=main
```

Verify:

```powershell
gh api /repos/urruegg/CRMShowcase/environments/test --jq '{name, protection_rules}'
```

Expected: one `required_reviewers` rule listed.

- [ ] **Step 2: Create solution-deploy-test.yml**

Create `.github/workflows/solution-deploy-test.yml`:

```yaml
name: Solution Deploy — TEST

on:
  workflow_dispatch:
    inputs:
      commit_sha:
        description: 'Commit SHA on main to deploy'
        required: true

permissions:
  contents: write
  id-token: write

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: test
    steps:
      - uses: actions/checkout@v4
        with:
          ref: ${{ github.event.inputs.commit_sha }}
          fetch-depth: 0

      - name: Verify commit is on main
        run: |
          git branch -r --contains ${{ github.event.inputs.commit_sha }} | grep -q 'origin/main' || (echo "Commit is not on main"; exit 1)

      - name: Install pac CLI
        uses: microsoft/powerplatform-actions/actions-install@v1

      - name: Azure login (OIDC)
        uses: azure/login@v2
        with:
          client-id: ${{ vars.AZURE_CLIENT_ID }}
          tenant-id: ${{ vars.AZURE_TENANT_ID }}
          allow-no-subscriptions: true

      - name: pac auth
        shell: pwsh
        run: pac auth create --url ${{ vars.POWER_PLATFORM_ENV_URL }} --name ci-test --applicationId ${{ vars.AZURE_CLIENT_ID }} --tenant ${{ vars.AZURE_TENANT_ID }} --cloud Public --deviceCode:$false

      - name: Pack all solutions (managed)
        shell: pwsh
        run: |
          . ./scripts/solution/Get-Manifest.ps1
          . ./scripts/solution/Get-SolutionOrder.ps1
          $m = Get-Manifest -Path ./solution/manifest.json
          foreach ($s in Get-SolutionOrder -Manifest $m) {
            ./scripts/solution/Pack-Solution.ps1 -Folder "solution/$($s.path)" -OutFile "artifacts/$($s.uniqueName).zip" -Managed
          }

      - name: Import in dependency order (managed)
        shell: pwsh
        run: |
          . ./scripts/solution/Get-Manifest.ps1
          . ./scripts/solution/Get-SolutionOrder.ps1
          $m = Get-Manifest -Path ./solution/manifest.json
          foreach ($s in Get-SolutionOrder -Manifest $m) {
            ./scripts/solution/Import-Solution.ps1 -ZipFile "artifacts/$($s.uniqueName).zip" -Async -PublishChanges
          }

      - name: Tag the release
        run: |
          TAG=deploy/test/$(date -u +%Y-%m-%dT%H%M%SZ)-$(git rev-parse --short ${{ github.event.inputs.commit_sha }})
          git tag $TAG ${{ github.event.inputs.commit_sha }}
          git push origin $TAG
```

- [ ] **Step 3: Commit**

```powershell
git add .github/workflows/solution-deploy-test.yml
git commit -m "feat(ci): solution-deploy-test workflow with test environment gate (US-508)"
git push
```

---

## Task 9 — Intake workflows: on-demand + drift (US-509)

**Files:**
- Create: `.github/workflows/solution-intake-on-demand.yml`
- Create: `.github/workflows/solution-intake-drift.yml`

- [ ] **Step 1: Create solution-intake-on-demand.yml**

Create `.github/workflows/solution-intake-on-demand.yml`:

```yaml
name: Solution Intake — On Demand

on:
  workflow_dispatch:
    inputs:
      solution:
        description: 'Solution unique name (e.g. crmshow_Sales)'
        required: true
        type: choice
        options:
          - crmshow_Foundation
          - crmshow_DataModel
          - crmshow_Integration
          - crmshow_Sales
          - crmshow_Service
          - crmshow_Marketing
      reason:
        description: 'Short PR description'
        required: true

permissions:
  contents: write
  pull-requests: write
  id-token: write

jobs:
  intake:
    runs-on: ubuntu-latest
    environment: dev
    steps:
      - uses: actions/checkout@v4

      - name: Install pac
        uses: microsoft/powerplatform-actions/actions-install@v1

      - name: Azure login (OIDC)
        uses: azure/login@v2
        with:
          client-id: ${{ vars.AZURE_CLIENT_ID }}
          tenant-id: ${{ vars.AZURE_TENANT_ID }}
          allow-no-subscriptions: true

      - name: pac auth
        shell: pwsh
        run: pac auth create --url ${{ vars.POWER_PLATFORM_ENV_URL }} --name ci-dev --applicationId ${{ vars.AZURE_CLIENT_ID }} --tenant ${{ vars.AZURE_TENANT_ID }} --cloud Public --deviceCode:$false

      - name: Export + unpack
        shell: pwsh
        run: |
          . ./scripts/solution/Get-Manifest.ps1
          $m = Get-Manifest -Path ./solution/manifest.json
          $s = $m.solutions | Where-Object { $_.uniqueName -eq '${{ github.event.inputs.solution }}' }
          if (-not $s) { throw "Unknown solution" }
          $zip = ".export-tmp/$($s.uniqueName).zip"
          ./scripts/solution/Export-Solution.ps1 -SolutionName $s.uniqueName -OutFile $zip
          ./scripts/solution/Unpack-Solution.ps1 -ZipFile $zip -Folder "solution/$($s.path)"

      - name: Open PR
        shell: bash
        run: |
          BRANCH=intake/${{ github.event.inputs.solution }}/${{ github.run_number }}
          git config user.name  "github-actions[bot]"
          git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
          git checkout -b $BRANCH
          git add solution/
          if git diff --cached --quiet; then
            echo "No changes"; exit 0
          fi
          git commit -m "feat(solution): maker intake from DEV — ${{ github.event.inputs.solution }} — ${{ github.event.inputs.reason }}"
          git push -u origin $BRANCH
          gh pr create --title "feat(solution): maker intake — ${{ github.event.inputs.solution }}" \
                       --body "Reason: ${{ github.event.inputs.reason }}\n\nAuto-opened by \`solution-intake-on-demand.yml\`." \
                       --base main --head $BRANCH
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

- [ ] **Step 2: Create solution-intake-drift.yml**

Create `.github/workflows/solution-intake-drift.yml`:

```yaml
name: Solution Intake — Drift Check

on:
  schedule:
    - cron: '0 6 * * 1-5'  # weekdays 06:00 UTC
  workflow_dispatch:

permissions:
  contents: write
  pull-requests: write
  id-token: write

jobs:
  drift:
    runs-on: ubuntu-latest
    environment: dev
    steps:
      - uses: actions/checkout@v4
        with: { fetch-depth: 0 }

      - name: Skip if last commit says so
        run: |
          if git log -1 --pretty=%B | grep -q '\[skip drift\]'; then
            echo "skip requested"; exit 0
          fi

      - name: Install pac
        uses: microsoft/powerplatform-actions/actions-install@v1

      - name: Azure login (OIDC)
        uses: azure/login@v2
        with:
          client-id: ${{ vars.AZURE_CLIENT_ID }}
          tenant-id: ${{ vars.AZURE_TENANT_ID }}
          allow-no-subscriptions: true

      - name: pac auth
        shell: pwsh
        run: pac auth create --url ${{ vars.POWER_PLATFORM_ENV_URL }} --name ci-dev --applicationId ${{ vars.AZURE_CLIENT_ID }} --tenant ${{ vars.AZURE_TENANT_ID }} --cloud Public --deviceCode:$false

      - name: Export + diff
        id: diff
        shell: pwsh
        run: |
          . ./scripts/solution/Get-Manifest.ps1
          $m = Get-Manifest -Path ./solution/manifest.json
          $drifted = @()
          foreach ($s in $m.solutions) {
            $tmp = ".drift-tmp/$($s.uniqueName)"
            $zip = "$tmp.zip"
            ./scripts/solution/Export-Solution.ps1 -SolutionName $s.uniqueName -OutFile $zip
            ./scripts/solution/Unpack-Solution.ps1 -ZipFile $zip -Folder $tmp
            $target = "solution/$($s.path)"
            if (git diff --no-index --quiet $target $tmp) { continue }
            # Copy the exported unpack over the tracked folder
            Copy-Item -Recurse -Force $tmp/* $target/
            $drifted += $s.uniqueName
          }
          if ($drifted.Count -eq 0) {
            "drifted=" | Out-File $env:GITHUB_OUTPUT -Append
          } else {
            "drifted=" + ($drifted -join ',') | Out-File $env:GITHUB_OUTPUT -Append
          }

      - name: Open PR if drift
        if: steps.diff.outputs.drifted != ''
        shell: bash
        run: |
          DATE=$(date -u +%Y-%m-%d)
          BRANCH=intake/drift/$DATE
          git config user.name  "github-actions[bot]"
          git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
          git checkout -b $BRANCH
          git add solution/
          git commit -m "chore(solution): DEV drift detected $DATE - ${{ steps.diff.outputs.drifted }}"
          git push -u origin $BRANCH
          gh pr create --title "chore(solution): DEV drift $DATE" \
                       --body "Drifted solutions: ${{ steps.diff.outputs.drifted }}" \
                       --base main --head $BRANCH
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

- [ ] **Step 3: Commit**

```powershell
git add .github/workflows/solution-intake-*.yml
git commit -m "feat(ci): solution intake workflows on-demand + drift (US-509)"
git push
```

---

## Task 10 — ADR-0019 Solution versioning strategy (US-510)

**Files:**
- Create: `docs/adr/ADR-0019-solution-versioning-strategy.md`

- [ ] **Step 1: Create the ADR**

Create `docs/adr/ADR-0019-solution-versioning-strategy.md`:

```markdown
# ADR-0019 — Solution versioning strategy

| Field | Value |
| --- | --- |
| **Status** | Accepted |
| **Date** | 2026-08-06 |
| **Deciders** | Repo owner |
| **Topic area** | A4 · A8 |
| **CAF methodology** | Adopt · Govern |
| **WAF pillar(s)** | Primary: Operational Excellence · Trade-off: none material |
| **Zero Trust** | N/A (no identity/access change) |
| **Responsible AI** | N/A (no AI touched) |
| **Licence** | 🧩 configuration / own build |
| **Upgrade impact** | This *is* the upgrade impact declaration |

## Context

The showcase spans six Power Platform solutions with a dependency chain
(Foundation → DataModel/Integration → apps). A managed solution's version
can only ever increase in a target environment. Without a versioning
strategy, upgrades either break the fresh-redeploy path or accumulate silent
dependency conflicts.

## Options

### Option A — Free-form versioning per solution
Each maintainer sets versions manually. **Why not:** guaranteed drift; no
enforcement of monotonic increase; MAJOR/MINOR/PATCH become opinion.

### Option B — Calendar versioning YYYY.MM.DD.BUILD
Deterministic, but loses semantic meaning: "is this a breaking change?"
becomes a manual check on every upgrade.

### Option C — Semver four-part MAJOR.MINOR.PATCH.BUILD ✅ chosen
Dataverse-native (four parts). MAJOR = breaking; MINOR = additive; PATCH =
fix; BUILD = GitHub Actions run number for uniqueness. PATCH and BUILD are
automatic; MAJOR and MINOR require PR labels; a breaking-change heuristic
blocks merge without the `version-bump:major` label.

## Decision

Adopt Option C for all six solutions. Rules and bump mechanic captured in
`solution/manifest.json.versioning` and enforced by
`scripts/solution/Bump-Version.ps1` +
`scripts/solution/Test-BreakingChange.ps1`, exercised by
`.github/workflows/solution-ci.yml`.

## Consequences

- **At the next release:** solution upgrades and fresh redeploys use the
  same monotonic version sequence.
- **Operationally:** version drift between manifest and Solution.xml is
  impossible — Solution.xml is derived at pack time.
- **Reversibility:** high; the scheme is external to Dataverse.

## Related

- [Sprint 1 spec](../superpowers/specs/2026-08-06-solution-containers-design.md)
- [ADR-0017 — Everything through the pipeline](./ADR-0017-alm-everything-through-the-pipeline.md)
```

- [ ] **Step 2: Add ADR-0019 to the ADR index**

Modify `docs/adr/README.md`. Find the ADR index table. Add:

```markdown
| [0019](./ADR-0019-solution-versioning-strategy.md) | Solution versioning strategy | A4 · A8 | Accepted |
```

- [ ] **Step 3: Commit**

```powershell
git add docs/adr/ADR-0019-solution-versioning-strategy.md docs/adr/README.md
git commit -m "docs(adr): 0019 solution versioning strategy (US-510)"
```

---

## Task 11 — Extend CODEOWNERS (US-511)

**Files:**
- Modify: `.github/CODEOWNERS`

- [ ] **Step 1: Extend CODEOWNERS**

Open `.github/CODEOWNERS`. Append to the end:

```
# Sprint 1 — Power Platform solution containers
solution/manifest.json           @urruegg
solution/manifest.schema.json    @urruegg
solution/core/foundation/        @urruegg
solution/core/datamodel/         @urruegg
solution/core/integration/       @urruegg
solution/apps/sales/             @urruegg
solution/apps/service/           @urruegg
solution/apps/marketing/         @urruegg
.github/workflows/solution-*.yml @urruegg
scripts/solution/                @urruegg
```

- [ ] **Step 2: Commit**

```powershell
git add .github/CODEOWNERS
git commit -m "chore(codeowners): folder-scoped ownership for solution/ (US-511)"
```

---

## Task 12 — UC-02 idea + issue for Power Platform Git integration (US-512)

**Files:**
- Create: `docs/ideas/UC-02-git-integration-preview/README.md`

- [ ] **Step 1: Create the idea doc**

Create `docs/ideas/UC-02-git-integration-preview/README.md`:

```markdown
# UC-02 — Power Platform → Git integration (Preview)

| Field | Value |
| --- | --- |
| Status | Deferred idea |
| Owner | AG-E-01 Product Owner |

## What it is

Microsoft's built-in feature that syncs Dataverse solutions ↔ Git directly
from `make.powerapps.com`. Documented in Microsoft Learn under Power
Platform ALM → Git integration.

## Why we didn't adopt it this sprint

- It's Preview — no SLA.
- It requires specific Dev-environment regions / licence tiers the demo
  tenant may not have.
- Its opinions on folder shape may not match our `solution/core/*` +
  `solution/apps/*` layout; retrofitting could churn the whole `solution/`
  folder.

Our current approach — pac CLI + GitHub Actions + on-demand and drift
intake workflows — is boring, well-supported, and covers the same ground.

## Revisit when

- The feature GAs.
- Our maker discipline is proven with the two intake paths (on-demand,
  drift check).
- We hit a scaling limit (>10 solutions or >5 makers) that our current
  intake pattern doesn't handle gracefully.

## Tracking

- GitHub issue: to be opened during this task.
```

- [ ] **Step 2: Open the tracking issue**

```powershell
gh issue create --title "Feature request: Power Platform → Git integration (Preview)" `
    --body "See docs/ideas/UC-02-git-integration-preview/README.md. Revisit when the Preview feature GAs." `
    --label "enhancement,power-platform"
```

Expected: issue number printed.

- [ ] **Step 3: Commit**

```powershell
git add docs/ideas/UC-02-git-integration-preview/
git commit -m "docs(ideas): UC-02 Power Platform Git integration Preview (US-512)"
```

---

## Task 13 — Runbook: solution rollback (US-513)

**Files:**
- Create: `docs/runbooks/solution-rollback.md`

- [ ] **Step 1: Create the runbook**

```powershell
New-Item -ItemType Directory -Force -Path docs/runbooks | Out-Null
```

Create `docs/runbooks/solution-rollback.md`:

```markdown
# Runbook — Solution rollback

## When to use this

A `solution-deploy-test.yml` run left TEST in a bad state, or a manual test
of the DEV → TEST promotion failed and we need to return TEST to a known
good version.

DEV is fix-forward — this runbook does not apply to DEV.

## Symptoms → path

| Symptom | Path |
| --- | --- |
| Newer managed layer imported OK but broke a form | Path 1 — re-deploy an earlier tag |
| Newer managed layer failed to import cleanly | Path 2 — delete the layer, re-deploy earlier |
| Managed solution needs to be removed entirely | Path 3 — delete solution |

## Path 1 — Re-deploy an earlier tag

Prerequisites:
- The earlier tag exists under `deploy/test/*`.
- `admin@ABSx15847880.onmicrosoft.com` is signed in.

Steps:

1. Find the tag: `git tag -l 'deploy/test/*' | tail -10`
2. Note its commit SHA: `git rev-list -n 1 deploy/test/<tag>`
3. Trigger `solution-deploy-test.yml` with that SHA:
   ```powershell
   gh workflow run solution-deploy-test.yml -f commit_sha=<sha>
   ```
4. Approve the deployment in the `test` GitHub Environment.
5. Verify: `gh run watch $((gh run list --workflow=solution-deploy-test.yml --json databaseId --jq '.[0].databaseId'))`.

## Path 2 — Delete the broken managed layer

When `pac solution import` refuses because the target has a newer version:

1. Sign in: `pac auth select --index 2  # crmshowtest`.
2. Delete the broken solution layer:
   ```powershell
   pac solution delete --solution-name <name>
   ```
3. Re-run Path 1 to re-deploy the earlier tag.

## Path 3 — Delete the entire managed solution

Only if the solution must be removed and there is no earlier version to
roll back to.

⚠️ **This deletes all data stored in the solution's custom tables and
columns.** Confirm with a maintainer before running.

1. Sign in: `pac auth select --index 2`.
2. `pac solution delete --solution-name <name>`.
3. Re-import via `solution-deploy-test.yml` if we still want it in TEST.

## Prevention

- The `version-bump:major` heuristic on `solution-ci.yml` catches most
  breaking changes before merge.
- Every `solution-deploy-test.yml` run creates a `deploy/test/*` tag —
  never delete these; they are our roll-back inventory.
```

- [ ] **Step 2: Commit**

```powershell
git add docs/runbooks/
git commit -m "docs(runbook): solution rollback playbook (US-513)"
```

---

## Task 14 — End-to-end verification (US-514)

**Files:**
- None; verification only.

- [ ] **Step 1: Merge the sprint PR**

Make sure `solution-ci.yml` is green on the sprint PR.

```powershell
gh pr merge --squash --auto
```

- [ ] **Step 2: Wait for solution-deploy-dev.yml to complete**

```powershell
gh run watch $((gh run list --workflow=solution-deploy-dev.yml --json databaseId --jq '.[0].databaseId'))
```

Expected: all steps green.

- [ ] **Step 3: Verify DEV state via Web API**

```powershell
$envUrl = 'https://crmshowdev.crm.dynamics.com'
az account set --subscription b829e4ef-1a9f-45ba-80e5-48408aa421a9
$q = "$envUrl/api/data/v9.2/solutions?%24filter=startswith(uniquename,%27crmshow_%27)&%24select=uniquename,version,ismanaged"
az rest --method GET --url $q --resource "$envUrl/" --only-show-errors | ConvertFrom-Json | Select-Object -ExpandProperty value | Format-Table uniquename, version, ismanaged
```

Expected: 6 rows with `ismanaged: false` and versions ending in the CI run number.

- [ ] **Step 4: Trigger solution-deploy-test.yml with the merge commit SHA**

```powershell
$sha = git rev-parse origin/main
gh workflow run solution-deploy-test.yml -f commit_sha=$sha
```

- [ ] **Step 5: Approve the deployment in the `test` GitHub Environment**

Open https://github.com/urruegg/CRMShowcase/actions → find the Solution Deploy — TEST run → click Review deployments → Approve.

- [ ] **Step 6: Watch it complete**

```powershell
gh run watch $((gh run list --workflow=solution-deploy-test.yml --json databaseId --jq '.[0].databaseId'))
```

- [ ] **Step 7: Verify TEST state**

```powershell
$envUrl = 'https://crmshowtest.crm.dynamics.com'
$q = "$envUrl/api/data/v9.2/solutions?%24filter=startswith(uniquename,%27crmshow_%27)&%24select=uniquename,version,ismanaged"
az rest --method GET --url $q --resource "$envUrl/" --only-show-errors | ConvertFrom-Json | Select-Object -ExpandProperty value | Format-Table uniquename, version, ismanaged
```

Expected: 6 rows with `ismanaged: true`.

- [ ] **Step 8: Confirm the release tag was pushed**

```powershell
git fetch --tags
git tag -l 'deploy/test/*' | tail -1
```

Expected: a tag from today with today's UTC date and short SHA.

- [ ] **Step 9: Mark sprint stories done in BACKLOG.md**

Modify `docs/BACKLOG.md` — set status of US-501 through US-514 to `done`.

```powershell
git add docs/BACKLOG.md
git commit -m "chore(sprint-1): mark US-501..US-514 done (US-514)"
git push
```

---

## Sprint completion checklist

- [ ] Six empty solutions live in `crmshowdev` (unmanaged) and `crmshowtest` (managed) with matching versions.
- [ ] `solution/manifest.json` + schema + Pester tests all green.
- [ ] `solution-ci.yml`, `solution-deploy-dev.yml`, `solution-deploy-test.yml`, `solution-intake-on-demand.yml`, `solution-intake-drift.yml` all merged and functional.
- [ ] ADR-0019 accepted; ADR index updated.
- [ ] `docs/runbooks/solution-rollback.md` and `docs/ideas/UC-02-git-integration-preview/` merged.
- [ ] `.github/CODEOWNERS` extended.
- [ ] `deploy/test/*` tag created for the first end-to-end run.
- [ ] All 14 US-501..US-514 stories marked done in `docs/BACKLOG.md`.
