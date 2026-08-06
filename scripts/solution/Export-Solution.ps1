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
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$SolutionName,
    [Parameter(Mandatory)] [string]$OutFile,
    [switch]$Managed
)

if (-not (Get-Command pac -ErrorAction SilentlyContinue)) {
    $env:PATH = "$env:USERPROFILE\.dotnet\tools;$env:PATH"
    if (-not (Get-Command pac -ErrorAction SilentlyContinue)) {
        throw "pac CLI not found. Install: dotnet tool install --global Microsoft.PowerApps.CLI.Tool --version 1.43.6"
    }
}

$type = if ($Managed) { 'Managed' } else { 'Unmanaged' }
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $OutFile) | Out-Null

Write-Host "Exporting $SolutionName ($type) to $OutFile"
if ($Managed) {
    pac solution export --name $SolutionName --path $OutFile --managed true  --overwrite
} else {
    pac solution export --name $SolutionName --path $OutFile --managed false --overwrite
}
if ($LASTEXITCODE -ne 0) { throw "pac solution export failed for $SolutionName" }
Write-Host "Exported: $OutFile"
