<#
.SYNOPSIS
    Export a Dataverse solution from a Power Platform environment as a zip.
.DESCRIPTION
    Thin wrapper around `pac solution export`. The active pac auth profile determines
    the source environment (`pac auth select --index <n>` beforehand).
.PARAMETER SolutionName
    Unique name of the solution to export (e.g. crmshow_core).
.PARAMETER OutFile
    Absolute or relative path where the zip should be written. Parent folder is created.
.PARAMETER Managed
    When present, exports the managed variant. Otherwise exports unmanaged.
.PARAMETER Environment
    Optional explicit Dataverse environment URL or ID. Use with ExpectedOrganization
    for source-intake operations. Existing CI callers may continue to use the active
    pac auth profile by omitting both parameters.
.PARAMETER ExpectedOrganization
    Expected organization friendly name. Export aborts when `pac org who` does not
    report this value. Must be supplied together with Environment.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$SolutionName,
    [Parameter(Mandatory)] [string]$OutFile,
    [string]$Environment,
    [string]$ExpectedOrganization,
    [switch]$Managed
)

. "$PSScriptRoot/Resolve-PacCommand.ps1"
$pacCommand = Resolve-PacCommand

if ([string]::IsNullOrWhiteSpace($Environment) -xor [string]::IsNullOrWhiteSpace($ExpectedOrganization)) {
    throw "Environment and ExpectedOrganization must be supplied together."
}

if ($Environment) {
    $orgOutput = (& $pacCommand org who --environment $Environment 2>&1 | Out-String)
    if ($LASTEXITCODE -ne 0) {
        throw "Unable to verify Dataverse organization for the requested environment."
    }
    if ($orgOutput -notmatch [regex]::Escape($ExpectedOrganization)) {
        throw "Connected organization does not match expected organization '$ExpectedOrganization'."
    }
}

$type = if ($Managed) { 'Managed' } else { 'Unmanaged' }
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $OutFile) | Out-Null

Write-Host "Exporting $SolutionName ($type) to $OutFile"
$environmentArgs = if ($Environment) { @('--environment', $Environment) } else { @() }
if ($Managed) {
    & $pacCommand solution export @environmentArgs --name $SolutionName --path $OutFile --managed true --overwrite
} else {
    & $pacCommand solution export @environmentArgs --name $SolutionName --path $OutFile --managed false --overwrite
}
if ($LASTEXITCODE -ne 0) { throw "pac solution export failed for $SolutionName" }
Write-Host "Exported: $OutFile"
