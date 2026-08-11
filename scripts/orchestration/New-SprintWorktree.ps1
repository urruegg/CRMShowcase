<#
.SYNOPSIS
    Create a sprint stream worktree and scaffold its handover packet.
.DESCRIPTION
    Plans (or runs, unless -DryRun) `git worktree add` for a new stream branch
    under the worktree root, and fills the handover packet template.
#>
[CmdletBinding()]
param(
    [string]$SprintId,
    [string]$StreamId,
    [int]$IssueNumber,
    [ValidateSet('EXECUTION-ONLY','DESIGN-SENSITIVE')] [string]$AutonomyClass = 'EXECUTION-ONLY',
    [string]$RepoRoot,
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
