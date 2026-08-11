<#
.SYNOPSIS
    Retire a sprint stream worktree, guarding against uncommitted work.
.DESCRIPTION
    Refuses to remove a worktree with a dirty tree unless -Force. For tests, pass
    -StatusText to supply `git status --porcelain` output instead of calling git.
#>
[CmdletBinding()]
param(
    [string]$WorktreePath,
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
