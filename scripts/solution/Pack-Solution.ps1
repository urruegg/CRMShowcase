<#
.SYNOPSIS
    Pack an unpacked Dataverse solution folder tree back into a deployable zip.
.DESCRIPTION
    Thin wrapper around `pac solution pack`. The counterpart of Unpack-Solution.ps1.
.PARAMETER Folder
    Root folder produced by `pac solution unpack` (containing Other/Solution.xml).
.PARAMETER ZipFile
    Path where the packed zip should be written. Parent folder is created.
.PARAMETER PackageType
    Unmanaged (default), Managed, or Both. Must match how the source was unpacked.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$Folder,
    [Parameter(Mandatory)] [string]$ZipFile,
    [ValidateSet('Unmanaged','Managed','Both')] [string]$PackageType = 'Unmanaged'
)

if (-not (Get-Command pac -ErrorAction SilentlyContinue)) {
    $env:PATH = "$env:USERPROFILE\.dotnet\tools;$env:PATH"
    if (-not (Get-Command pac -ErrorAction SilentlyContinue)) {
        throw "pac CLI not found. Install: dotnet tool install --global Microsoft.PowerApps.CLI.Tool --version 1.43.6"
    }
}

New-Item -ItemType Directory -Force -Path (Split-Path -Parent $ZipFile) | Out-Null
Write-Host "Packing $Folder -> $ZipFile ($PackageType)"
pac solution pack --folder $Folder --zipfile $ZipFile --packagetype $PackageType
if ($LASTEXITCODE -ne 0) { throw "pac solution pack failed" }
Write-Host "Packed: $ZipFile"
