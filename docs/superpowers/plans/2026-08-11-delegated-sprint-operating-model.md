# Delegated Sprint Operating Model Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build proof #1 of the delegated sprint pattern — the Sprint Operating Model docs, the handover/intake contracts, the GitHub issue templates, and a tested PowerShell orchestration toolchain that turns an approved sprint plan into parallel Copilot CLI worktree streams and re-integrates them through the existing PR-to-protected-`main` gates — then prove the mechanism end to end with one smoke stream.

**Architecture:** A control plane (this repo trunk) designs and plans; a delegated plane runs local GitHub Copilot CLI sessions inside git worktrees under `C:\Users\urruegg\source\urruegg\wt`. Each stream carries a handover packet declaring an autonomy class. `EXECUTION-ONLY` streams run headless autopilot with a `git push`/`rm`/`git reset` deny-list so they cannot self-integrate; `DESIGN-SENSITIVE` streams run attended. Every script builds a command plan and only executes when not `-DryRun`, and reads injected git output in tests, so the whole toolchain is unit-testable without touching real git, `gh`, or `copilot`.

**Tech Stack:** PowerShell 5.1-compatible scripts, Pester 6.0.1, git worktrees, GitHub Copilot CLI (`copilot -p`, `--allow-all-tools`, `--deny-tool`), GitHub CLI (`gh pr create`), Markdown contracts/ADRs.

---

## Delivery boundary

This plan implements **proof #1** from
`docs/superpowers/specs/2026-08-11-delegated-sprint-operating-model-design.md`.
It ships documentation and tooling only — no Power Platform solution change and
no Test/PROD deploy. Proof #2 (Insurance Foundation to Test/PROD through this
pattern) gets its own spec and plan.

The autopilot guardrail is a hard property of the toolchain, not a convention:
`Invoke-StreamDelegation.ps1` **refuses** to build a headless command for a
`DESIGN-SENSITIVE` packet, and every headless command carries the
`git push` / `rm` / `git reset` deny-list.

## File map

| Path | Responsibility |
| --- | --- |
| `docs/adr/ADR-0023-delegated-sprint-operating-model.md` | Records the control-plane/delegated-plane decision and its guardrails |
| `docs/superpowers/SPRINT-OPERATING-MODEL.md` | The standard, repeatable sprint process (centrepiece) |
| `docs/superpowers/contracts/HANDOVER-CONTRACT.md` | Packet schema + autonomy-class definitions |
| `docs/superpowers/contracts/INTAKE-CONTRACT.md` | Merge-back criteria and gates |
| `docs/superpowers/contracts/handover-packet.template.md` | Fill-in packet template (source of truth for the scaffolder + parser) |
| `.github/ISSUE_TEMPLATE/sprint-charter.md` | Sprint-level GitHub issue template |
| `.github/ISSUE_TEMPLATE/stream-handover.md` | Per-stream GitHub issue template |
| `scripts/orchestration/Read-HandoverPacket.ps1` | Shared packet parser (used by delegation, status, intake) |
| `scripts/orchestration/New-SprintWorktree.ps1` | Create `wt/<sprint>-<stream>` worktree + scaffold packet |
| `scripts/orchestration/Invoke-StreamDelegation.ps1` | Dispatch wrapper: class → headless/attended command |
| `scripts/orchestration/Complete-StreamIntake.ps1` | Push branch + open PR (never merges) |
| `scripts/orchestration/Get-SprintStatus.ps1` | Worktree + branch + class status board |
| `scripts/orchestration/Remove-SprintWorktree.ps1` | Retire a worktree, guarding uncommitted/unpushed work |
| `scripts/orchestration/tests/*.Tests.ps1` | Pester 6 tests for each script |
| `docs/superpowers/sprints/sprint-001-delegated-pattern/sprint.md` | Sprint-001 charter (mirrors issue #S) |
| `docs/superpowers/sprints/sprint-001-delegated-pattern/STATUS.md` | Live status board + evidence |
| `docs/sprints/README.md`, `docs/plans/README.md` | Repointed at `docs/superpowers/` |

## Conventions to follow (verified in-repo)

- Scripts open with a `<# .SYNOPSIS ... #>` block, then `[CmdletBinding()]` +
  `param(...)`, and define a function of the same name. Errors use `throw`.
- Path checks use `Test-Path -LiteralPath`. JSON via `ConvertFrom-Json`.
- Tests dot-source the script: `BeforeAll { . "$PSScriptRoot/../X.ps1" }`, then
  `Describe`/`It`/`Should`, using `$TestDrive` for scratch files.
- Run one test file: `Invoke-Pester -Path scripts/orchestration/tests/X.Tests.ps1`.

---

### Task 1: Record the decision (ADR-0023)

**Files:**
- Create: `docs/adr/ADR-0023-delegated-sprint-operating-model.md`

- [ ] **Step 1: Write the ADR**

Create `docs/adr/ADR-0023-delegated-sprint-operating-model.md`:

```markdown
# ADR-0023 - Delegated sprint operating model (Copilot CLI control plane)

| Field | Value |
| --- | --- |
| **Status** | Accepted |
| **Date** | 2026-08-11 |
| **Decision mode** | Reversible process decision, proven by execution |
| **Confidence** | High for process and CLI mechanics; medium for headless ergonomics |
| **Deciders** | Enterprise Architect, SecDevOps, repo owner |
| **Topic area** | A8 - lifecycle, deployment, rollback; A9 - responsibility split |
| **Use case** | Sprint-001 delegated pattern |
| **Licence** | Own build - scripts and Markdown; Copilot CLI entitlement per operator |
| **Upgrade impact** | Low platform; Medium way-of-working; additive and reversible |
| **CAF methodology** | Govern, Secure, Manage |
| **WAF pillar(s)** | Operational Excellence, Security, Reliability |
| **Zero Trust** | Verify explicitly, least privilege, assume breach |
| **Responsible AI** | Accountability (human merges), transparency (autonomy class recorded) |

## Context

The showcase must demonstrate parallel, agent-driven delivery without weakening
governance. Work is designed and planned on the trunk, then delegated to local
GitHub Copilot CLI sessions running in git worktrees.

## Decision

Adopt a two-plane model: a control plane (trunk: brainstorm -> design -> plan ->
GitHub issue) and a delegated plane (worktrees under
`C:\Users\urruegg\source\urruegg\wt`, one per stream, each driven by Copilot
CLI). Streams carry a handover packet with an autonomy class. `EXECUTION-ONLY`
streams may run headless autopilot with a `git push`/`rm`/`git reset` deny-list;
`DESIGN-SENSITIVE` streams run attended. Intake is a PR to protected `main`; no
script merges.

## Guardrails

- Design is never autopilot-approved. A packet requires an approved-design ref;
  a `DESIGN-SENSITIVE` packet cannot be launched headless; a stream that meets a
  new design decision stops and asks in the chat.
- The deny-list prevents any stream from self-integrating or rewriting history.

## Consequences

- Adds `scripts/orchestration/*` and `docs/superpowers/{SPRINT-OPERATING-MODEL,
  contracts,sprints}`.
- Reuses existing branch protection, CODEOWNERS, CI and eval gates unchanged
  (ADR-0004, ADR-0017).

## Related

ADR-0001, ADR-0004, ADR-0014, ADR-0017;
`docs/superpowers/specs/2026-08-11-delegated-sprint-operating-model-design.md`.
```

- [ ] **Step 2: Verify links resolve**

Run: `Test-Path docs/adr/ADR-0023-delegated-sprint-operating-model.md`
Expected: `True`

- [ ] **Step 3: Commit**

```bash
git add docs/adr/ADR-0023-delegated-sprint-operating-model.md
git commit -m "docs(adr): ADR-0023 delegated sprint operating model"
```

---

### Task 2: Handover packet template (source of truth)

The template is created first because the scaffolder writes it and the parser
reads it — they must agree on the field syntax `- **Field:** value`.

**Files:**
- Create: `docs/superpowers/contracts/handover-packet.template.md`

- [ ] **Step 1: Write the template**

Create `docs/superpowers/contracts/handover-packet.template.md`:

```markdown
# Handover Packet - {{STREAM_ID}}

- **Sprint:** {{SPRINT_ID}}
- **Stream:** {{STREAM_ID}}
- **GitHub issue:** #{{ISSUE}}
- **Autonomy class:** {{CLASS}}
- **Branch:** {{BRANCH}}
- **Worktree:** {{WORKTREE}}
- **Approved design ref:** {{DESIGN_REF}}

## Goal / Definition of Done

{{GOAL}}

## Allowed scope (paths)

{{SCOPE}}

## Verification commands

```
{{VERIFY}}
```

## Guardrails

Inherit SUPERPOWERS_CONTRACT.md section 1. Headless streams additionally deny
`shell(git push)`, `shell(rm)`, `shell(git reset)`.

## Escalation rule

If a new design decision is needed -> STOP, write `BLOCKED: needs design`,
surface the question to the control-plane chat. Never self-approve.
```

- [ ] **Step 2: Verify the field lines are greppable**

Run: `Select-String -Path docs/superpowers/contracts/handover-packet.template.md -Pattern '^\- \*\*Autonomy class:\*\*'`
Expected: one match.

- [ ] **Step 3: Commit**

```bash
git add docs/superpowers/contracts/handover-packet.template.md
git commit -m "docs(contract): add handover packet template"
```

---

### Task 3: Shared packet parser `Read-HandoverPacket.ps1`

**Files:**
- Create: `scripts/orchestration/Read-HandoverPacket.ps1`
- Test: `scripts/orchestration/tests/Read-HandoverPacket.Tests.ps1`

- [ ] **Step 1: Write the failing test**

Create `scripts/orchestration/tests/Read-HandoverPacket.Tests.ps1`:

```powershell
BeforeAll {
    . "$PSScriptRoot/../Read-HandoverPacket.ps1"
}

Describe "Read-HandoverPacket" {
    BeforeEach {
        $script:packet = Join-Path $TestDrive 'stream-A.md'
        @(
            '# Handover Packet - stream-A'
            ''
            '- **Sprint:** sprint-001'
            '- **Stream:** stream-A'
            '- **GitHub issue:** #42'
            '- **Autonomy class:** EXECUTION-ONLY'
            '- **Branch:** feat/sprint-001-stream-A'
            '- **Worktree:** C:\wt\sprint-001-stream-A'
            '- **Approved design ref:** ADR-0023'
        ) | Set-Content -LiteralPath $script:packet
    }

    It "parses the required fields" {
        $p = Read-HandoverPacket -Path $script:packet
        $p.Sprint        | Should -Be 'sprint-001'
        $p.Stream        | Should -Be 'stream-A'
        $p.Issue         | Should -Be 42
        $p.AutonomyClass | Should -Be 'EXECUTION-ONLY'
        $p.Branch        | Should -Be 'feat/sprint-001-stream-A'
        $p.Worktree      | Should -Be 'C:\wt\sprint-001-stream-A'
    }

    It "throws when the packet is missing" {
        { Read-HandoverPacket -Path (Join-Path $TestDrive 'nope.md') } |
            Should -Throw
    }

    It "throws on an unknown autonomy class" {
        (Get-Content -LiteralPath $script:packet) -replace 'EXECUTION-ONLY','BOGUS' |
            Set-Content -LiteralPath $script:packet
        { Read-HandoverPacket -Path $script:packet } | Should -Throw
    }
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `Invoke-Pester -Path scripts/orchestration/tests/Read-HandoverPacket.Tests.ps1`
Expected: FAIL — `Read-HandoverPacket.ps1` does not exist.

- [ ] **Step 3: Write the minimal implementation**

Create `scripts/orchestration/Read-HandoverPacket.ps1`:

```powershell
<#
.SYNOPSIS
    Parse a handover packet markdown file into a structured object.
.PARAMETER Path
    Path to the stream handover packet.
#>
[CmdletBinding()]
param([string]$Path)

function Read-HandoverPacket {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Handover packet not found: $Path"
    }

    $lines = Get-Content -LiteralPath $Path
    function Get-Field($name) {
        $pattern = '^\- \*\*' + [regex]::Escape($name) + ':\*\*\s*(.+?)\s*$'
        foreach ($line in $lines) {
            $m = [regex]::Match($line, $pattern)
            if ($m.Success) { return $m.Groups[1].Value }
        }
        return $null
    }

    $class = Get-Field 'Autonomy class'
    $valid = @('EXECUTION-ONLY', 'DESIGN-SENSITIVE')
    if ($valid -notcontains $class) {
        throw "Invalid or missing autonomy class '$class'. Expected one of: $($valid -join ', ')."
    }

    $issueRaw = Get-Field 'GitHub issue'
    $issue = 0
    if ($issueRaw) { [void][int]::TryParse(($issueRaw -replace '[^0-9]', ''), [ref]$issue) }

    [pscustomobject]@{
        Sprint        = Get-Field 'Sprint'
        Stream        = Get-Field 'Stream'
        Issue         = $issue
        AutonomyClass = $class
        Branch        = Get-Field 'Branch'
        Worktree      = Get-Field 'Worktree'
        DesignRef     = Get-Field 'Approved design ref'
        Path          = (Resolve-Path -LiteralPath $Path).Path
    }
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `Invoke-Pester -Path scripts/orchestration/tests/Read-HandoverPacket.Tests.ps1`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add scripts/orchestration/Read-HandoverPacket.ps1 scripts/orchestration/tests/Read-HandoverPacket.Tests.ps1
git commit -m "feat(orchestration): parse handover packets"
```

---

### Task 4: `New-SprintWorktree.ps1`

**Files:**
- Create: `scripts/orchestration/New-SprintWorktree.ps1`
- Test: `scripts/orchestration/tests/New-SprintWorktree.Tests.ps1`

- [ ] **Step 1: Write the failing test**

Create `scripts/orchestration/tests/New-SprintWorktree.Tests.ps1`:

```powershell
BeforeAll {
    . "$PSScriptRoot/../New-SprintWorktree.ps1"
}

Describe "New-SprintWorktree" {
    BeforeEach {
        $script:repo = Join-Path $TestDrive 'repo'
        $script:tmpl = Join-Path $script:repo 'docs/superpowers/contracts'
        New-Item -ItemType Directory -Force -Path $script:tmpl | Out-Null
        '- **Autonomy class:** {{CLASS}}' + "`n" + '- **GitHub issue:** #{{ISSUE}}' + "`n" + '- **Worktree:** {{WORKTREE}}' + "`n" + '- **Branch:** {{BRANCH}}' |
            Set-Content -LiteralPath (Join-Path $script:tmpl 'handover-packet.template.md')
        $script:wtRoot = Join-Path $TestDrive 'wt'
    }

    It "plans a git worktree add and scaffolds the packet" {
        $r = New-SprintWorktree -SprintId 'sprint-001' -StreamId 'stream-A' `
            -IssueNumber 42 -AutonomyClass 'EXECUTION-ONLY' `
            -RepoRoot $script:repo -WorktreeRoot $script:wtRoot -DryRun

        $r.Branch       | Should -Be 'feat/sprint-001-stream-A'
        $r.WorktreePath | Should -Be (Join-Path $script:wtRoot 'sprint-001-stream-A')
        $r.GitCommand   | Should -Match 'worktree add -b feat/sprint-001-stream-A'
        Test-Path -LiteralPath $r.PacketPath | Should -BeTrue
        (Get-Content -Raw -LiteralPath $r.PacketPath) | Should -Match 'EXECUTION-ONLY'
        (Get-Content -Raw -LiteralPath $r.PacketPath) | Should -Match '#42'
    }

    It "rejects an invalid autonomy class" {
        { New-SprintWorktree -SprintId 's' -StreamId 'a' -IssueNumber 1 `
            -AutonomyClass 'BOGUS' -RepoRoot $script:repo -WorktreeRoot $script:wtRoot -DryRun } |
            Should -Throw
    }
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `Invoke-Pester -Path scripts/orchestration/tests/New-SprintWorktree.Tests.ps1`
Expected: FAIL — script missing.

- [ ] **Step 3: Write the minimal implementation**

Create `scripts/orchestration/New-SprintWorktree.ps1`:

```powershell
<#
.SYNOPSIS
    Create a sprint stream worktree and scaffold its handover packet.
.DESCRIPTION
    Plans (or runs, unless -DryRun) `git worktree add` for a new stream branch
    under the worktree root, and fills the handover packet template.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$SprintId,
    [Parameter(Mandatory)] [string]$StreamId,
    [Parameter(Mandatory)] [int]$IssueNumber,
    [ValidateSet('EXECUTION-ONLY','DESIGN-SENSITIVE')] [string]$AutonomyClass = 'EXECUTION-ONLY',
    [string]$RepoRoot = (Resolve-Path "$PSScriptRoot/../..").Path,
    [string]$WorktreeRoot = 'C:\Users\urruegg\source\urruegg\wt',
    [string]$BaseRef = 'main',
    [string]$DesignRef = 'ADR-0023',
    [switch]$DryRun
)

function New-SprintWorktree {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string]$SprintId,
        [Parameter(Mandatory)] [string]$StreamId,
        [Parameter(Mandatory)] [int]$IssueNumber,
        [ValidateSet('EXECUTION-ONLY','DESIGN-SENSITIVE')] [string]$AutonomyClass = 'EXECUTION-ONLY',
        [string]$RepoRoot = (Resolve-Path "$PSScriptRoot/../..").Path,
        [string]$WorktreeRoot = 'C:\Users\urruegg\source\urruegg\wt',
        [string]$BaseRef = 'main',
        [string]$DesignRef = 'ADR-0023',
        [switch]$DryRun
    )

    $branch       = "feat/$SprintId-$StreamId"
    $worktreePath = Join-Path $WorktreeRoot "$SprintId-$StreamId"
    $gitCommand   = "git -C `"$RepoRoot`" worktree add -b $branch `"$worktreePath`" $BaseRef"

    $templatePath = Join-Path $RepoRoot 'docs/superpowers/contracts/handover-packet.template.md'
    if (-not (Test-Path -LiteralPath $templatePath)) {
        throw "Packet template not found: $templatePath"
    }
    $streamsDir = Join-Path $RepoRoot "docs/superpowers/sprints/$SprintId/streams"
    New-Item -ItemType Directory -Force -Path $streamsDir | Out-Null
    $packetPath = Join-Path $streamsDir "$StreamId.md"

    $content = (Get-Content -Raw -LiteralPath $templatePath).
        Replace('{{SPRINT_ID}}', $SprintId).
        Replace('{{STREAM_ID}}', $StreamId).
        Replace('{{ISSUE}}', "$IssueNumber").
        Replace('{{CLASS}}', $AutonomyClass).
        Replace('{{BRANCH}}', $branch).
        Replace('{{WORKTREE}}', $worktreePath).
        Replace('{{DESIGN_REF}}', $DesignRef)
    Set-Content -LiteralPath $packetPath -Value $content

    if (-not $DryRun) {
        Invoke-Expression $gitCommand
    }

    [pscustomobject]@{
        SprintId     = $SprintId
        StreamId     = $StreamId
        Branch       = $branch
        WorktreePath = $worktreePath
        PacketPath   = $packetPath
        GitCommand   = $gitCommand
        DryRun       = [bool]$DryRun
    }
}

if ($MyInvocation.InvocationName -ne '.') {
    New-SprintWorktree @PSBoundParameters
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `Invoke-Pester -Path scripts/orchestration/tests/New-SprintWorktree.Tests.ps1`
Expected: PASS (2 tests).

- [ ] **Step 5: Commit**

```bash
git add scripts/orchestration/New-SprintWorktree.ps1 scripts/orchestration/tests/New-SprintWorktree.Tests.ps1
git commit -m "feat(orchestration): scaffold sprint stream worktrees"
```

---

### Task 5: `Invoke-StreamDelegation.ps1` (guardrail-critical)

**Files:**
- Create: `scripts/orchestration/Invoke-StreamDelegation.ps1`
- Test: `scripts/orchestration/tests/Invoke-StreamDelegation.Tests.ps1`

- [ ] **Step 1: Write the failing test**

Create `scripts/orchestration/tests/Invoke-StreamDelegation.Tests.ps1`:

```powershell
BeforeAll {
    . "$PSScriptRoot/../Invoke-StreamDelegation.ps1"
}

Describe "Invoke-StreamDelegation" {
    BeforeEach {
        $script:dir = Join-Path $TestDrive 'streams'
        New-Item -ItemType Directory -Force -Path $script:dir | Out-Null
    }

    function New-Packet($class) {
        $p = Join-Path $script:dir "packet-$class.md"
        @(
            '- **Sprint:** sprint-001'
            '- **Stream:** stream-A'
            '- **GitHub issue:** #42'
            "- **Autonomy class:** $class"
            '- **Branch:** feat/sprint-001-stream-A'
            '- **Worktree:** C:\wt\sprint-001-stream-A'
            '- **Approved design ref:** ADR-0023'
        ) | Set-Content -LiteralPath $p
        return $p
    }

    It "builds a denied-listed headless command for EXECUTION-ONLY" {
        $r = Invoke-StreamDelegation -PacketPath (New-Packet 'EXECUTION-ONLY') -DryRun
        $r.Mode    | Should -Be 'Headless'
        $r.Command | Should -Match 'copilot -p'
        $r.Command | Should -Match '--allow-all-tools'
        $r.Command | Should -Match "--deny-tool='shell\(git push\)'"
        $r.Command | Should -Match "--deny-tool='shell\(rm\)'"
        $r.Command | Should -Match "--deny-tool='shell\(git reset\)'"
    }

    It "returns an attended plan for DESIGN-SENSITIVE and no allow-all command" {
        $r = Invoke-StreamDelegation -PacketPath (New-Packet 'DESIGN-SENSITIVE') -DryRun
        $r.Mode    | Should -Be 'Attended'
        $r.Command | Should -Not -Match '--allow-all-tools'
    }

    It "refuses to force a DESIGN-SENSITIVE packet headless" {
        { Invoke-StreamDelegation -PacketPath (New-Packet 'DESIGN-SENSITIVE') -Headless -DryRun } |
            Should -Throw
    }
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `Invoke-Pester -Path scripts/orchestration/tests/Invoke-StreamDelegation.Tests.ps1`
Expected: FAIL — script missing.

- [ ] **Step 3: Write the minimal implementation**

Create `scripts/orchestration/Invoke-StreamDelegation.ps1`:

```powershell
<#
.SYNOPSIS
    Dispatch a sprint stream to GitHub Copilot CLI according to its autonomy class.
.DESCRIPTION
    EXECUTION-ONLY packets build a headless autopilot command with a
    git push / rm / git reset deny-list. DESIGN-SENSITIVE packets are never
    launched headless; the function returns an attended launch plan instead.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$PacketPath,
    [switch]$Headless,
    [switch]$DryRun
)

function Invoke-StreamDelegation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string]$PacketPath,
        [switch]$Headless,
        [switch]$DryRun
    )

    . "$PSScriptRoot/Read-HandoverPacket.ps1"
    $packet = Read-HandoverPacket -Path $PacketPath

    if ($packet.AutonomyClass -eq 'DESIGN-SENSITIVE') {
        if ($Headless) {
            throw "Refusing to launch DESIGN-SENSITIVE stream '$($packet.Stream)' headless. Design must be human-reviewed."
        }
        $attended = "copilot   # interactive; press Shift+Tab for plan mode, then paste: $($packet.Path)"
        $result = [pscustomobject]@{
            Mode    = 'Attended'
            Command = $attended
            Packet  = $packet
        }
        if (-not $DryRun) { Write-Host $attended }
        return $result
    }

    # EXECUTION-ONLY -> headless autopilot with deny-list
    $denies = @("--deny-tool='shell(git push)'", "--deny-tool='shell(rm)'", "--deny-tool='shell(git reset)'")
    $command = "copilot -p `"@$($packet.Path)`" --allow-all-tools $($denies -join ' ') --add-dir `"$($packet.Worktree)`""
    $result = [pscustomobject]@{
        Mode    = 'Headless'
        Command = $command
        Packet  = $packet
    }
    if (-not $DryRun) {
        Push-Location -LiteralPath $packet.Worktree
        try { Invoke-Expression $command } finally { Pop-Location }
    }
    return $result
}

if ($MyInvocation.InvocationName -ne '.') {
    Invoke-StreamDelegation @PSBoundParameters
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `Invoke-Pester -Path scripts/orchestration/tests/Invoke-StreamDelegation.Tests.ps1`
Expected: PASS (3 tests). The refusal test proves the autopilot guardrail.

- [ ] **Step 5: Commit**

```bash
git add scripts/orchestration/Invoke-StreamDelegation.ps1 scripts/orchestration/tests/Invoke-StreamDelegation.Tests.ps1
git commit -m "feat(orchestration): dispatch streams with autonomy-class guardrail"
```

---

### Task 6: `Complete-StreamIntake.ps1`

**Files:**
- Create: `scripts/orchestration/Complete-StreamIntake.ps1`
- Test: `scripts/orchestration/tests/Complete-StreamIntake.Tests.ps1`

- [ ] **Step 1: Write the failing test**

Create `scripts/orchestration/tests/Complete-StreamIntake.Tests.ps1`:

```powershell
BeforeAll {
    . "$PSScriptRoot/../Complete-StreamIntake.ps1"
}

Describe "Complete-StreamIntake" {
    It "plans a branch push and a PR against main, never a merge" {
        $r = Complete-StreamIntake -WorktreePath 'C:\wt\sprint-001-stream-A' `
            -Branch 'feat/sprint-001-stream-A' -IssueNumber 42 `
            -Title 'stream-A: smoke' -DryRun

        $r.PushCommand | Should -Match 'push -u origin feat/sprint-001-stream-A'
        $r.PrCommand   | Should -Match 'gh pr create --base main'
        $r.PrCommand   | Should -Match '--head feat/sprint-001-stream-A'
        $r.Commands -join ' ' | Should -Not -Match 'pr merge'
    }
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `Invoke-Pester -Path scripts/orchestration/tests/Complete-StreamIntake.Tests.ps1`
Expected: FAIL — script missing.

- [ ] **Step 3: Write the minimal implementation**

Create `scripts/orchestration/Complete-StreamIntake.ps1`:

```powershell
<#
.SYNOPSIS
    Intake a completed stream: push its branch and open a PR against main.
.DESCRIPTION
    Never merges. Merge stays a human act gated by branch protection, CODEOWNERS,
    CI and evals. Returns the planned commands; executes them unless -DryRun.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$WorktreePath,
    [Parameter(Mandatory)] [string]$Branch,
    [Parameter(Mandatory)] [int]$IssueNumber,
    [Parameter(Mandatory)] [string]$Title,
    [string]$Body = '',
    [switch]$DryRun
)

function Complete-StreamIntake {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string]$WorktreePath,
        [Parameter(Mandatory)] [string]$Branch,
        [Parameter(Mandatory)] [int]$IssueNumber,
        [Parameter(Mandatory)] [string]$Title,
        [string]$Body = '',
        [switch]$DryRun
    )

    if (-not $Body) { $Body = "Closes #$IssueNumber. Delegated stream intake. See sprint STATUS.md for evidence." }
    $pushCommand = "git -C `"$WorktreePath`" push -u origin $Branch"
    $prCommand   = "gh pr create --base main --head $Branch --title `"$Title`" --body `"$Body`""

    if (-not $DryRun) {
        Invoke-Expression $pushCommand
        Invoke-Expression $prCommand
    }

    [pscustomobject]@{
        PushCommand = $pushCommand
        PrCommand   = $prCommand
        Commands    = @($pushCommand, $prCommand)
        DryRun      = [bool]$DryRun
    }
}

if ($MyInvocation.InvocationName -ne '.') {
    Complete-StreamIntake @PSBoundParameters
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `Invoke-Pester -Path scripts/orchestration/tests/Complete-StreamIntake.Tests.ps1`
Expected: PASS (1 test).

- [ ] **Step 5: Commit**

```bash
git add scripts/orchestration/Complete-StreamIntake.ps1 scripts/orchestration/tests/Complete-StreamIntake.Tests.ps1
git commit -m "feat(orchestration): intake streams via PR to main, never merge"
```

---

### Task 7: `Get-SprintStatus.ps1`

**Files:**
- Create: `scripts/orchestration/Get-SprintStatus.ps1`
- Test: `scripts/orchestration/tests/Get-SprintStatus.Tests.ps1`

- [ ] **Step 1: Write the failing test**

Create `scripts/orchestration/tests/Get-SprintStatus.Tests.ps1`:

```powershell
BeforeAll {
    . "$PSScriptRoot/../Get-SprintStatus.ps1"
}

Describe "Get-SprintStatus" {
    It "maps porcelain worktree output under the worktree root to streams" {
        $porcelain = @(
            'worktree C:/Users/urruegg/source/urruegg/wt/sprint-001-stream-A'
            'HEAD abc123'
            'branch refs/heads/feat/sprint-001-stream-A'
            ''
            'worktree C:/Users/urruegg/source/urruegg/CRMShowcase'
            'HEAD def456'
            'branch refs/heads/main'
            ''
        ) -join "`n"

        $rows = Get-SprintStatus -WorktreeRoot 'C:/Users/urruegg/source/urruegg/wt' -WorktreeListText $porcelain
        $rows.Count      | Should -Be 1
        $rows[0].Stream  | Should -Be 'sprint-001-stream-A'
        $rows[0].Branch  | Should -Be 'feat/sprint-001-stream-A'
    }
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `Invoke-Pester -Path scripts/orchestration/tests/Get-SprintStatus.Tests.ps1`
Expected: FAIL — script missing.

- [ ] **Step 3: Write the minimal implementation**

Create `scripts/orchestration/Get-SprintStatus.ps1`:

```powershell
<#
.SYNOPSIS
    Report the status of sprint stream worktrees under the worktree root.
.DESCRIPTION
    Parses `git worktree list --porcelain`. For tests, pass -WorktreeListText to
    parse a provided string instead of invoking git.
#>
[CmdletBinding()]
param(
    [string]$WorktreeRoot = 'C:\Users\urruegg\source\urruegg\wt',
    [string]$RepoRoot = (Resolve-Path "$PSScriptRoot/../..").Path,
    [string]$WorktreeListText
)

function Get-SprintStatus {
    [CmdletBinding()]
    param(
        [string]$WorktreeRoot = 'C:\Users\urruegg\source\urruegg\wt',
        [string]$RepoRoot = (Resolve-Path "$PSScriptRoot/../..").Path,
        [string]$WorktreeListText
    )

    if (-not $WorktreeListText) {
        $WorktreeListText = (& git -C $RepoRoot worktree list --porcelain) -join "`n"
    }

    $rootNorm = $WorktreeRoot.Replace('\', '/').TrimEnd('/')
    $rows = @()
    $current = $null
    foreach ($line in ($WorktreeListText -split "`n")) {
        if ($line -match '^worktree\s+(.+)$') {
            $path = $Matches[1].Trim().Replace('\', '/')
            if ($path.StartsWith($rootNorm + '/')) {
                $current = [pscustomobject]@{
                    Path   = $path
                    Stream = $path.Substring($rootNorm.Length + 1)
                    Branch = $null
                }
            } else {
                $current = $null
            }
        } elseif ($current -and $line -match '^branch\s+refs/heads/(.+)$') {
            $current.Branch = $Matches[1].Trim()
            $rows += $current
            $current = $null
        }
    }
    return ,$rows
}

if ($MyInvocation.InvocationName -ne '.') {
    Get-SprintStatus @PSBoundParameters | Format-Table -AutoSize
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `Invoke-Pester -Path scripts/orchestration/tests/Get-SprintStatus.Tests.ps1`
Expected: PASS (1 test).

- [ ] **Step 5: Commit**

```bash
git add scripts/orchestration/Get-SprintStatus.ps1 scripts/orchestration/tests/Get-SprintStatus.Tests.ps1
git commit -m "feat(orchestration): report sprint worktree status"
```

---

### Task 8: `Remove-SprintWorktree.ps1`

**Files:**
- Create: `scripts/orchestration/Remove-SprintWorktree.ps1`
- Test: `scripts/orchestration/tests/Remove-SprintWorktree.Tests.ps1`

- [ ] **Step 1: Write the failing test**

Create `scripts/orchestration/tests/Remove-SprintWorktree.Tests.ps1`:

```powershell
BeforeAll {
    . "$PSScriptRoot/../Remove-SprintWorktree.ps1"
}

Describe "Remove-SprintWorktree" {
    It "refuses when the worktree has uncommitted changes and -Force is absent" {
        { Remove-SprintWorktree -WorktreePath 'C:\wt\s-a' -RepoRoot 'C:\repo' `
            -StatusText ' M some/file.ps1' -DryRun } | Should -Throw
    }

    It "plans a worktree remove when clean" {
        $r = Remove-SprintWorktree -WorktreePath 'C:\wt\s-a' -RepoRoot 'C:\repo' `
            -StatusText '' -DryRun
        $r.GitCommand | Should -Match 'worktree remove'
    }
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `Invoke-Pester -Path scripts/orchestration/tests/Remove-SprintWorktree.Tests.ps1`
Expected: FAIL — script missing.

- [ ] **Step 3: Write the minimal implementation**

Create `scripts/orchestration/Remove-SprintWorktree.ps1`:

```powershell
<#
.SYNOPSIS
    Retire a sprint stream worktree, guarding against uncommitted work.
.DESCRIPTION
    Refuses to remove a worktree with a dirty tree unless -Force. For tests, pass
    -StatusText to supply `git status --porcelain` output instead of calling git.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$WorktreePath,
    [string]$RepoRoot = (Resolve-Path "$PSScriptRoot/../..").Path,
    [string]$StatusText,
    [switch]$Force,
    [switch]$DryRun
)

function Remove-SprintWorktree {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string]$WorktreePath,
        [string]$RepoRoot = (Resolve-Path "$PSScriptRoot/../..").Path,
        [string]$StatusText,
        [switch]$Force,
        [switch]$DryRun
    )

    if ($null -eq $StatusText) {
        $StatusText = (& git -C $WorktreePath status --porcelain) -join "`n"
    }
    if ($StatusText.Trim() -and -not $Force) {
        throw "Worktree '$WorktreePath' has uncommitted changes. Commit/push or pass -Force."
    }

    $gitCommand = "git -C `"$RepoRoot`" worktree remove `"$WorktreePath`""
    if ($Force) { $gitCommand += ' --force' }
    if (-not $DryRun) { Invoke-Expression $gitCommand }

    [pscustomobject]@{
        WorktreePath = $WorktreePath
        GitCommand   = $gitCommand
        DryRun       = [bool]$DryRun
    }
}

if ($MyInvocation.InvocationName -ne '.') {
    Remove-SprintWorktree @PSBoundParameters
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `Invoke-Pester -Path scripts/orchestration/tests/Remove-SprintWorktree.Tests.ps1`
Expected: PASS (2 tests).

- [ ] **Step 5: Commit**

```bash
git add scripts/orchestration/Remove-SprintWorktree.ps1 scripts/orchestration/tests/Remove-SprintWorktree.Tests.ps1
git commit -m "feat(orchestration): retire worktrees with dirty-tree guard"
```

---

### Task 9: Run the full orchestration test suite

**Files:** none (verification only)

- [ ] **Step 1: Run every orchestration test**

Run: `Invoke-Pester -Path scripts/orchestration/tests -Output Detailed`
Expected: all tests PASS, 0 failed.

- [ ] **Step 2: Commit nothing if green** (checkpoint only). If red, fix the
      offending script and re-run before proceeding.

---

### Task 10: The contracts and the operating-model doc

**Files:**
- Create: `docs/superpowers/contracts/HANDOVER-CONTRACT.md`
- Create: `docs/superpowers/contracts/INTAKE-CONTRACT.md`
- Create: `docs/superpowers/SPRINT-OPERATING-MODEL.md`

- [ ] **Step 1: Write `HANDOVER-CONTRACT.md`**

Content requirements (write in full prose, no placeholders):
- The packet schema table from the spec (§6), field by field.
- The two autonomy classes and the rule that `DESIGN-SENSITIVE` is never
  headless.
- A worked example packet (an `EXECUTION-ONLY` and a `DESIGN-SENSITIVE` one).
- A pointer to `handover-packet.template.md` as the machine-readable source.

- [ ] **Step 2: Write `INTAKE-CONTRACT.md`**

Content requirements:
- The four intake conditions from the spec (§7).
- The explicit statement that no script merges; merge is human via branch
  protection + CODEOWNERS + CI + evals.
- The retirement rule (`Remove-SprintWorktree.ps1` guards dirty trees).

- [ ] **Step 3: Write `SPRINT-OPERATING-MODEL.md`**

Content requirements:
- The two-plane model + the mermaid diagram from the spec (§4).
- The phase walkthrough: brainstorm → design spec → plan → sprint-charter issue
  → stream issues + packets → `New-SprintWorktree` → `Invoke-StreamDelegation`
  → build in worktree → `Complete-StreamIntake` → human merge → retire.
- The exact commands an operator runs, referencing the five scripts.
- The autopilot guardrail (§9) stated as operator rules.
- Links to the two contracts, the ADR, and the spec.

- [ ] **Step 4: Verify all three exist and cross-link**

Run: `Get-ChildItem docs/superpowers/contracts, docs/superpowers/SPRINT-OPERATING-MODEL.md`
Expected: three files listed.

- [ ] **Step 5: Commit**

```bash
git add docs/superpowers/SPRINT-OPERATING-MODEL.md docs/superpowers/contracts
git commit -m "docs(sprint): operating model + handover/intake contracts"
```

---

### Task 11: GitHub issue templates

**Files:**
- Create: `.github/ISSUE_TEMPLATE/sprint-charter.md`
- Create: `.github/ISSUE_TEMPLATE/stream-handover.md`

- [ ] **Step 1: Write `sprint-charter.md`**

Create `.github/ISSUE_TEMPLATE/sprint-charter.md`:

```markdown
---
name: Sprint charter
about: Log a sprint designed on the trunk, ready to delegate into streams.
labels: sprint-charter
---

**Sprint ID:** sprint-###

**Design spec:** docs/superpowers/specs/YYYY-MM-DD-…-design.md
**Plan:** docs/superpowers/plans/YYYY-MM-DD-….md
**ADR(s):**

## Outcome

## Streams (each becomes a stream-handover issue)

| Stream | Autonomy class | Goal |
| --- | --- | --- |
| stream-A | EXECUTION-ONLY / DESIGN-SENSITIVE | |

## Definition of done (sprint)

- [ ] All streams merged to main via PR
- [ ] Evidence captured in the sprint STATUS.md
```

- [ ] **Step 2: Write `stream-handover.md`**

Create `.github/ISSUE_TEMPLATE/stream-handover.md`:

```markdown
---
name: Stream handover
about: A single delegated stream within a sprint.
labels: stream-handover
---

**Sprint:** sprint-###
**Stream:** stream-X
**Autonomy class:** EXECUTION-ONLY / DESIGN-SENSITIVE
**Approved design ref (ADR/spec):**
**Branch:** feat/sprint-###-stream-X

## Goal / Definition of Done

## Allowed scope (paths)

## Verification commands

## Escalation

If a new design decision is needed, STOP and raise it in the control-plane chat.
```

- [ ] **Step 3: Verify**

Run: `Get-ChildItem .github/ISSUE_TEMPLATE`
Expected: `governance-escalation.md`, `sprint-charter.md`, `stream-handover.md`.

- [ ] **Step 4: Commit**

```bash
git add .github/ISSUE_TEMPLATE/sprint-charter.md .github/ISSUE_TEMPLATE/stream-handover.md
git commit -m "chore(github): add sprint charter + stream handover issue templates"
```

---

### Task 12: Sprint-001 folder + repoint stray placeholders

**Files:**
- Create: `docs/superpowers/sprints/sprint-001-delegated-pattern/sprint.md`
- Create: `docs/superpowers/sprints/sprint-001-delegated-pattern/STATUS.md`
- Modify: `docs/sprints/README.md`
- Modify: `docs/plans/README.md`

- [ ] **Step 1: Write `sprint.md`** — the charter mirroring the GitHub sprint
      issue: outcome, the stream list (at minimum the `smoke` stream and the
      `toolchain` stream), and the sprint definition of done from the spec §12.

- [ ] **Step 2: Write `STATUS.md`** — a table with columns
      `Stream | Issue | Class | Branch | PR | State | Evidence`, one row per
      stream, initially `planned`.

- [ ] **Step 3: Repoint `docs/sprints/README.md` and `docs/plans/README.md`**
      to state the workflow now lives under `docs/superpowers/` and link to
      `SPRINT-OPERATING-MODEL.md`.

- [ ] **Step 4: Verify + Commit**

```bash
git add docs/superpowers/sprints/sprint-001-delegated-pattern docs/sprints/README.md docs/plans/README.md
git commit -m "docs(sprint): add sprint-001 charter + status, repoint placeholders"
```

---

### Task 13: Smoke stream — prove the mechanism end to end

This task exercises the real toolchain. It is the proof-#1 acceptance evidence.

**Files:**
- Create (via the tools): a worktree under `C:\Users\urruegg\source\urruegg\wt\sprint-001-smoke`
- Modify: `docs/superpowers/sprints/sprint-001-delegated-pattern/STATUS.md`

- [ ] **Step 1: Create the sprint charter + stream issues on GitHub**

Run:
```
gh issue create --title "sprint-001: delegated pattern" --label sprint-charter --body-file docs/superpowers/sprints/sprint-001-delegated-pattern/sprint.md
gh issue create --title "sprint-001 / stream-smoke: EXECUTION-ONLY mechanism proof" --label stream-handover --body "Autonomy class: EXECUTION-ONLY. Add a dated line to STATUS.md proving a delegated commit."
```
Record the two issue numbers (`#S`, `#N`) in `STATUS.md`.

- [ ] **Step 2: Create the smoke worktree + packet (real run)**

Run:
```
. scripts/orchestration/New-SprintWorktree.ps1
New-SprintWorktree -SprintId 'sprint-001' -StreamId 'smoke' -IssueNumber <#N> -AutonomyClass 'EXECUTION-ONLY'
```
Expected: `wt\sprint-001-smoke` exists on branch `feat/sprint-001-smoke`; packet at `docs/superpowers/sprints/sprint-001/streams/smoke.md`.

- [ ] **Step 3: Prove the guardrail refuses a headless design-sensitive launch**

Run:
```
. scripts/orchestration/Invoke-StreamDelegation.ps1
# temporarily craft a DESIGN-SENSITIVE packet copy and attempt -Headless; expect a throw
```
Expected: the call throws "Refusing to launch DESIGN-SENSITIVE ... headless". Capture the message as evidence in `STATUS.md`.

- [ ] **Step 4: Dispatch the smoke stream headless**

Run:
```
Invoke-StreamDelegation -PacketPath 'docs/superpowers/sprints/sprint-001/streams/smoke.md'
```
The Copilot CLI session, inside the worktree, appends one dated line to
`STATUS.md` in that worktree and commits it. Because the deny-list blocks
`git push`, it cannot integrate itself.

- [ ] **Step 5: Intake the smoke stream**

Run:
```
. scripts/orchestration/Complete-StreamIntake.ps1
Complete-StreamIntake -WorktreePath 'C:\Users\urruegg\source\urruegg\wt\sprint-001-smoke' -Branch 'feat/sprint-001-smoke' -IssueNumber <#N> -Title 'sprint-001/stream-smoke: mechanism proof'
```
Expected: branch pushed, PR opened against `main`. Do **not** merge automatically.

- [ ] **Step 6: Retire the worktree after the PR merges**

Run:
```
. scripts/orchestration/Remove-SprintWorktree.ps1
Remove-SprintWorktree -WorktreePath 'C:\Users\urruegg\source\urruegg\wt\sprint-001-smoke'
```
Expected: worktree removed; guard passes because the branch is pushed/clean.

- [ ] **Step 7: Record evidence + Commit STATUS.md on the trunk branch**

Update `STATUS.md` with issue numbers, PR link, the guardrail-refusal message,
and mark the smoke stream `merged`.

```bash
git add docs/superpowers/sprints/sprint-001-delegated-pattern/STATUS.md
git commit -m "docs(sprint): capture smoke-stream end-to-end evidence"
```

---

### Task 14: Open the proof-#1 PR to main

**Files:** none (integration)

- [ ] **Step 1: Push the trunk design branch**

Run: `git push -u origin docs/delegated-sprint-operating-model`

- [ ] **Step 2: Open the PR using the repo template**

Run:
```
gh pr create --base main --head docs/delegated-sprint-operating-model --title "Delegated sprint operating model (proof #1)" --body-file .github/pull_request_template.md
```
Fill Traceability (topic A8/A9, ADR-0023, the sprint issue) and link the smoke
STATUS.md evidence.

- [ ] **Step 3: Verify CI is green, then hand to a human to merge.** No script
      merges — merge is the human gate.

---

## Self-review

**Spec coverage:**
- Spec §1 outcome → Tasks 10, 12 (operating model, sprint folder).
- Spec §2 two proofs → this plan is proof #1; proof #2 named in Task 14 hand-off note and spec §13.
- Spec §4 two planes/diagram → Task 10 SPRINT-OPERATING-MODEL.md.
- Spec §5 layout → all tasks; the exact file map is reproduced above.
- Spec §6 handover contract → Tasks 2, 3, 10.
- Spec §7 intake contract → Tasks 6, 10.
- Spec §8 dispatch mechanics → Task 5 (verified flags: `-p`, `--allow-all-tools`, `--deny-tool`).
- Spec §9 autopilot guardrail → Task 5 refusal test + Task 13 Step 3 live proof.
- Spec §10 traceability → Task 11 issue templates + Task 13 issue creation.
- Spec §11 frameworks → Task 1 ADR-0023.
- Spec §12 acceptance → Tasks 9, 13, 14.

**Placeholder scan:** doc-only tasks (10, 12) state explicit content requirements
rather than final prose; all code tasks contain complete, runnable code. No
`TODO`/`TBD` left in code.

**Type consistency:** `Read-HandoverPacket` returns `AutonomyClass`, `Worktree`,
`Branch`, `Path`, `Stream`, `Issue` — consumed unchanged by
`Invoke-StreamDelegation` (Task 5) and matched by the parser test (Task 3).
`New-SprintWorktree` writes the same field syntax the parser reads (Task 2
template ↔ Task 3 regex).

## Execution handoff

After this plan is approved, execution options:

1. **Subagent-Driven (recommended)** — dispatch a fresh subagent per task with
   review between tasks. Note the dog-food nicety: Tasks 4–8 build the very
   toolchain that Task 13 then uses to delegate the smoke stream.
2. **Inline Execution** — execute tasks in this session with checkpoints.
