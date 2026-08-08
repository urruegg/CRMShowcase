<#
.SYNOPSIS
    Import a Dataverse solution zip into the currently-selected pac auth environment.
.DESCRIPTION
    Thin wrapper around managed `pac solution import` and `pac solution upgrade`
    operations. The active pac auth profile determines the target environment
    (`pac auth select --index <n>` beforehand).
.PARAMETER ZipFile
    Path to the solution zip. Required for InstallOrUpdate and StageForUpgrade.
.PARAMETER Mode
    Install or update a managed solution, stage it as a holding solution, or
    apply a previously staged upgrade.
.PARAMETER SolutionName
    Unique solution name. Required for ApplyUpgrade.
.PARAMETER Async
    Run an import asynchronously. Not valid for ApplyUpgrade.
.PARAMETER PublishChanges
    Publish customizations after an import. Not valid for ApplyUpgrade.
#>
[CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'Import')]
param(
    [Parameter(ParameterSetName = 'Import')]
    [string]$ZipFile,

    [ValidateSet('InstallOrUpdate', 'StageForUpgrade', 'ApplyUpgrade')]
    [string]$Mode = 'InstallOrUpdate',

    [Parameter(ParameterSetName = 'Upgrade')]
    [string]$SolutionName,

    [switch]$Async,
    [switch]$PublishChanges
)

function Get-SolutionImportArguments {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ZipFile,

        [Parameter(Mandatory)]
        [ValidateSet('InstallOrUpdate', 'StageForUpgrade')]
        [string]$Mode
    )

    if ([string]::IsNullOrWhiteSpace($ZipFile)) {
        throw 'ZipFile is required for solution import.'
    }

    $result = @('solution', 'import', '--path', $ZipFile)
    if ($Mode -eq 'StageForUpgrade') {
        $result += '--import-as-holding'
    }
    return $result
}

function Get-SolutionUpgradeArguments {
    [CmdletBinding()]
    param(
        [AllowEmptyString()]
        [string]$SolutionName
    )

    if ([string]::IsNullOrWhiteSpace($SolutionName)) {
        throw 'SolutionName is required for ApplyUpgrade.'
    }

    return @('solution', 'upgrade', '--solution-name', $SolutionName)
}

if ($MyInvocation.InvocationName -ne '.') {
    if ($Mode -eq 'ApplyUpgrade') {
        if (-not [string]::IsNullOrWhiteSpace($ZipFile)) {
            throw 'ZipFile is not valid for ApplyUpgrade.'
        }
        if ($Async -or $PublishChanges) {
            throw 'Async and PublishChanges are only valid for solution import modes, not ApplyUpgrade.'
        }

        $pacArgs = Get-SolutionUpgradeArguments -SolutionName $SolutionName
        $target = $SolutionName
        $action = 'Apply managed solution upgrade'
        $failureMessage = "pac solution upgrade failed for $SolutionName"
        $successMessage = "Applied upgrade: $SolutionName"
    }
    else {
        if ([string]::IsNullOrWhiteSpace($ZipFile)) {
            throw "ZipFile is required for $Mode."
        }
        if (-not [string]::IsNullOrWhiteSpace($SolutionName)) {
            throw "SolutionName is only valid for ApplyUpgrade."
        }
        if (-not (Test-Path -LiteralPath $ZipFile -PathType Leaf)) {
            throw "Solution zip file not found: $ZipFile"
        }

        $pacArgs = Get-SolutionImportArguments -ZipFile $ZipFile -Mode $Mode
        if ($Async) { $pacArgs += '--async' }
        if ($PublishChanges) { $pacArgs += '--publish-changes' }
        $target = $ZipFile
        $action = "Import managed solution ($Mode)"
        $failureMessage = "pac solution import failed for $ZipFile"
        $successMessage = "Imported: $ZipFile"
    }

    if ($PSCmdlet.ShouldProcess($target, $action)) {
        . "$PSScriptRoot/Resolve-PacCommand.ps1"
        $pacCommand = Resolve-PacCommand

        Write-Host "$action`: $target ..."
        & $pacCommand @pacArgs
        if ($LASTEXITCODE -ne 0) { throw $failureMessage }
        Write-Host $successMessage
    }
}
