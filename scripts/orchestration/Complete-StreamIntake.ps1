<#
.SYNOPSIS
    Intake a completed stream: push its branch and open a PR against main.
.DESCRIPTION
    Never merges. Merge stays a human act gated by branch protection, CODEOWNERS,
    CI and evals. Returns the planned commands; executes them unless -DryRun.
#>
[CmdletBinding()]
param(
    [string]$WorktreePath,
    [string]$Branch,
    [int]$IssueNumber,
    [string]$Title,
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
