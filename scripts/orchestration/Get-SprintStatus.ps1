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
    [string]$RepoRoot,
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
