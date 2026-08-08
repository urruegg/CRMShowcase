# Mobiliar Prototype Intake and Data-Model Baseline Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Export and sanitize the Mobiliar prototype solution, generate a reusable artefact BOM and domain map, and document the CRM Showcase target data-model delta without deploying prototype components or records.

**Architecture:** The unmanaged source solution is exported to ignored temporary storage and unpacked into an ignored local `intake/mobiliar/source/` snapshot. Focused PowerShell scripts verify source-environment targeting, identify unsafe content, and derive deterministic sanitized JSON/CSV inventories from `Solution.xml`, entity metadata, and component folders. Review outputs map prototype evidence to the existing six target solution containers without changing those deployable solutions.

**Tech Stack:** Power Platform CLI 1.43.6, PowerShell 5.1+, Pester 5, XML/JSON/CSV, GitHub CLI.

**Reference spec:** [`docs/superpowers/specs/2026-08-08-mobiliar-prototype-intake-design.md`](../specs/2026-08-08-mobiliar-prototype-intake-design.md)

---

## File structure

```text
.gitignore
intake/mobiliar/
  README.md
  source/
  bom/
    artefacts.json
    artefacts.csv
    README.md
  mappings/
    domain-map.csv
scripts/solution/
  Export-Solution.ps1
  New-SolutionBom.ps1
  Test-IntakeSnapshot.ps1
  tests/
    New-SolutionBom.Tests.ps1
    Test-IntakeSnapshot.Tests.ps1
docs/
  BACKLOG.md
  design/mobiliar-data-model-extension.md
  superpowers/plans/2026-08-08-mobiliar-prototype-intake.md
```

`intake/mobiliar/source/` is local evidence only and is ignored because the
repository is public. The deployment manifest does not reference it.

---

### Task 1: Establish the quarantine boundary

**Files:**
- Modify: `.gitignore`
- Create: `intake/mobiliar/README.md`
- Modify: `docs/BACKLOG.md`

- [ ] **Step 1: Add ignored raw-export locations**

Append:

```gitignore
# Prototype intake raw exports and scan logs
intake/**/.raw/
intake/**/*.zip
intake/**/.scan/
intake/**/source/
```

- [ ] **Step 2: Document the evidence-only boundary**

Create `intake/mobiliar/README.md` stating that the folder contains a sanitized
unpacked prototype snapshot, is never deployed, contains no Dataverse records,
and must be regenerated with the scripts in this plan.

- [ ] **Step 3: Add stable stories**

Add Epic 6 with `US-601` through `US-606`: source export, safety scan, BOM,
domain map, target data-model design, and feature issue/evidence.

- [ ] **Step 4: Commit**

```powershell
git add .gitignore intake/mobiliar/README.md docs/BACKLOG.md
git commit -m "chore(sprint-2): establish prototype intake boundary"
```

Expected: only documentation, ignore rules, and backlog change.

---

### Task 2: Make source selection explicit

**Files:**
- Modify: `scripts/solution/Export-Solution.ps1`
- Test: existing solution script tests plus direct CLI verification

- [ ] **Step 1: Add explicit environment and organization parameters**

Add:

```powershell
[Parameter(Mandatory)] [string]$Environment,
[Parameter(Mandatory)] [string]$ExpectedOrganization
```

Before export, run:

```powershell
$orgOutput = (& pac org who --environment $Environment 2>&1 | Out-String)
if ($LASTEXITCODE -ne 0) {
    throw "Unable to verify Dataverse organization for the requested environment."
}
if ($orgOutput -notmatch [regex]::Escape($ExpectedOrganization)) {
    throw "Connected organization does not match expected organization '$ExpectedOrganization'."
}
```

Pass `--environment $Environment` to `pac solution export`.

- [ ] **Step 2: Verify wrong-target protection**

Run with a deliberately incorrect expected organization:

```powershell
./scripts/solution/Export-Solution.ps1 `
  -Environment $env:PROTOTYPE_SOURCE_ENV_URL `
  -ExpectedOrganization NotMobiliar `
  -SolutionName Mobiliar `
  -OutFile intake/mobiliar/.raw/rejected.zip
```

Expected: command throws before export.

- [ ] **Step 3: Commit**

```powershell
git add scripts/solution/Export-Solution.ps1
git commit -m "feat(intake): require explicit Dataverse source verification"
```

---

### Task 3: Build deterministic BOM generation

**Files:**
- Create: `scripts/solution/New-SolutionBom.ps1`
- Create: `scripts/solution/tests/New-SolutionBom.Tests.ps1`

- [ ] **Step 1: Write failing tests**

Tests create a temporary unpacked fixture containing `Other/Solution.xml`,
`Other/Customizations.xml`, one entity, one attribute, one relationship, and
one workflow file. Assert:

```powershell
$items = New-SolutionBom -SourceFolder $fixture
$items.componentType | Should -Contain 'Entity'
$items.componentType | Should -Contain 'Attribute'
$items.componentType | Should -Contain 'Relationship'
$items.componentType | Should -Contain 'Workflow'
($items | Where-Object logicalName -eq 'sample_account').parent |
    Should -BeNullOrEmpty
($items | Where-Object logicalName -eq 'sample_name').parent |
    Should -Be 'sample_account'
```

- [ ] **Step 2: Run the test and observe failure**

```powershell
Invoke-Pester ./scripts/solution/tests/New-SolutionBom.Tests.ps1 -Output Detailed
```

Expected: failure because `New-SolutionBom.ps1` does not exist.

- [ ] **Step 3: Implement the generator**

Define:

```powershell
function New-SolutionBom {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$SourceFolder)
}
```

The function reads `Other/Solution.xml` root components, expands entities from
`Other/Customizations.xml`, inventories remaining component files by their
first relative folder, sorts by `componentType`, `parent`, and `logicalName`,
and returns objects with:

```powershell
[ordered]@{
    componentType = $componentType
    logicalName = $logicalName
    displayName = $displayName
    sourcePath = $relativePath
    parent = $parent
    dependencies = @()
    domain = 'Unclassified pending review'
    targetSolution = 'None'
    disposition = 'Investigate'
    rationale = 'Pending evidence-based review'
    licenceReview = 'Investigate'
    maturityReview = 'Investigate'
    sourceOnly = $true
}
```

Script parameters `-JsonPath` and `-CsvPath` serialize the sorted result.

- [ ] **Step 4: Run tests**

```powershell
Invoke-Pester ./scripts/solution/tests/New-SolutionBom.Tests.ps1 -Output Detailed
```

Expected: all tests pass.

- [ ] **Step 5: Commit**

```powershell
git add scripts/solution/New-SolutionBom.ps1 scripts/solution/tests/New-SolutionBom.Tests.ps1
git commit -m "feat(intake): generate deterministic Dataverse solution BOM"
```

---

### Task 4: Add snapshot safety validation

**Files:**
- Create: `scripts/solution/Test-IntakeSnapshot.ps1`
- Create: `scripts/solution/tests/Test-IntakeSnapshot.Tests.ps1`

- [ ] **Step 1: Write failing tests**

Create safe and unsafe temporary fixtures. Assert that a safe solution XML
passes and that each of these fails: environment-variable current value,
connection string, bearer token, private key marker, and source environment
hostname.

```powershell
{ Test-IntakeSnapshot -Path $safe } | Should -Not -Throw
{ Test-IntakeSnapshot -Path $unsafe } | Should -Throw
```

- [ ] **Step 2: Run the test and observe failure**

```powershell
Invoke-Pester ./scripts/solution/tests/Test-IntakeSnapshot.Tests.ps1 -Output Detailed
```

Expected: failure because the validator does not exist.

- [ ] **Step 3: Implement focused checks**

Define `Test-IntakeSnapshot` with parameters `Path` and
`ForbiddenEnvironmentHost`. Inspect text-like files only and reject:

```text
-----BEGIN * PRIVATE KEY-----
Authorization: Bearer
AccountKey=
SharedAccessSignature=
ClientSecret
<currentvalue>
```

Reject the supplied source hostname case-insensitively. Return a summary object
with file count and match count when safe; throw with relative file paths when
unsafe.

- [ ] **Step 4: Run tests**

```powershell
Invoke-Pester ./scripts/solution/tests/Test-IntakeSnapshot.Tests.ps1 -Output Detailed
```

Expected: all tests pass.

- [ ] **Step 5: Commit**

```powershell
git add scripts/solution/Test-IntakeSnapshot.ps1 scripts/solution/tests/Test-IntakeSnapshot.Tests.ps1
git commit -m "feat(intake): block unsafe prototype snapshot content"
```

---

### Task 5: Export, unpack, sanitize, and inventory Mobiliar

**Files:**
- Create locally: `intake/mobiliar/source/` (ignored)
- Create: `intake/mobiliar/bom/artefacts.json`
- Create: `intake/mobiliar/bom/artefacts.csv`
- Create: `intake/mobiliar/bom/README.md`

- [ ] **Step 1: Verify source and solution**

```powershell
pac org who --environment $env:PROTOTYPE_SOURCE_ENV_URL
pac solution list --environment $env:PROTOTYPE_SOURCE_ENV_URL
```

Expected: organization `Mobiliar` and solution unique name `Mobiliar`.

- [ ] **Step 2: Export to ignored storage**

```powershell
./scripts/solution/Export-Solution.ps1 `
  -Environment $env:PROTOTYPE_SOURCE_ENV_URL `
  -ExpectedOrganization $env:PROTOTYPE_SOURCE_ORG_NAME `
  -SolutionName Mobiliar `
  -OutFile intake/mobiliar/.raw/Mobiliar.zip
```

Expected: unmanaged ZIP exists only under `.raw`.

- [ ] **Step 3: Unpack and validate**

```powershell
Remove-Item intake/mobiliar/source -Recurse -Force -ErrorAction SilentlyContinue
./scripts/solution/Unpack-Solution.ps1 `
  -ZipFile intake/mobiliar/.raw/Mobiliar.zip `
  -Folder intake/mobiliar/source
. ./scripts/solution/Test-IntakeSnapshot.ps1
Test-IntakeSnapshot `
  -Path intake/mobiliar/source `
  -ForbiddenEnvironmentHost ([uri]$env:PROTOTYPE_SOURCE_ENV_URL).Host
```

Expected: no unsafe matches. If matches are found, remove only environment-bound
values or exclude affected customer-content artefacts, then rerun.

- [ ] **Step 4: Generate BOM**

```powershell
./scripts/solution/New-SolutionBom.ps1 `
  -SourceFolder intake/mobiliar/source `
  -JsonPath intake/mobiliar/bom/artefacts.json `
  -CsvPath intake/mobiliar/bom/artefacts.csv
```

Expected: JSON and CSV contain the same item count.

- [ ] **Step 5: Write BOM coverage summary**

Record solution name/version, generation date, component counts by type, safety
scan outcome, unsupported component types, and the explicit statement that no
records were exported.

- [ ] **Step 6: Commit**

```powershell
git add intake/mobiliar/bom
git commit -m "feat(intake): capture sanitized Mobiliar solution inventory"
```

---

### Task 6: Map domains and design the target model

**Files:**
- Create: `intake/mobiliar/mappings/domain-map.csv`
- Create: `docs/design/mobiliar-data-model-extension.md`

- [ ] **Step 1: Classify every BOM item**

Create one domain-map row per BOM item using the exact `componentType`,
`logicalName`, `parent`, and `sourcePath` keys. Assign a domain, target
solution, disposition, rationale, licence review, and maturity review.

- [ ] **Step 2: Verify mapping completeness**

Compare composite keys from BOM and map:

```powershell
$bom = Get-Content intake/mobiliar/bom/artefacts.json -Raw | ConvertFrom-Json
$map = Import-Csv intake/mobiliar/mappings/domain-map.csv
$bomKeys = $bom | ForEach-Object { "$($_.componentType)|$($_.logicalName)|$($_.parent)" }
$mapKeys = $map | ForEach-Object { "$($_.componentType)|$($_.logicalName)|$($_.parent)" }
Compare-Object $bomKeys $mapKeys
```

Expected: no output.

- [ ] **Step 3: Write the model design**

Document:

- source-model observations;
- ADR conflicts and reusable patterns;
- conceptual Account-centred target model;
- table-by-table target proposal;
- mastership and external keys;
- relationships and effective dating;
- consent and Lead rules;
- target solution ownership;
- migration stance: redesign configuration, no record migration;
- security, licensing, maturity, upgrade, test, and open-review items.

Every source table must appear in a source-to-target decision matrix.

- [ ] **Step 4: Commit**

```powershell
git add intake/mobiliar/mappings/domain-map.csv docs/design/mobiliar-data-model-extension.md
git commit -m "docs: map Mobiliar artefacts to CRM Showcase target model"
```

---

### Task 7: Validate evidence and log the feature

**Files:**
- Modify: `docs/BACKLOG.md`
- Create externally: GitHub feature issue

- [ ] **Step 1: Run targeted tests**

```powershell
Invoke-Pester ./scripts/solution/tests/New-SolutionBom.Tests.ps1,./scripts/solution/tests/Test-IntakeSnapshot.Tests.ps1 -Output Detailed
```

Expected: all tests pass.

- [ ] **Step 2: Verify deployable solutions are untouched**

```powershell
git diff 39cf587 -- solution/manifest.json solution/core solution/apps
```

Expected: no output.

- [ ] **Step 3: Run repository checks**

```powershell
git diff --check
git status --short
```

Expected: no whitespace errors; only intended files before the final commit.

- [ ] **Step 4: Create the feature issue**

Use title:

```text
[Feature] Sprint 2 - Mobiliar prototype intake and data-model baseline
```

Apply `enhancement` and `power-platform`. Link the spec, plan, BOM summary,
domain map, data-model design, `US-601` through `US-606`, and acceptance
evidence. State that rebuilding selected artefacts is follow-up work and source
components were not deployed.

- [ ] **Step 5: Link issue and close sprint stories**

Update Epic 6 statuses with the feature issue number and completed evidence.

- [ ] **Step 6: Commit**

```powershell
git add docs/BACKLOG.md
git commit -m "docs: link Sprint 2 prototype intake evidence"
```

- [ ] **Step 7: Final verification**

```powershell
git status --short
git log -7 --oneline
```

Expected: clean worktree and all Sprint 2 commits visible.
