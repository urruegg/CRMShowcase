<#
.SYNOPSIS
    Pack an unpacked Dataverse solution folder tree back into a deployable zip.
.DESCRIPTION
    Thin wrapper around `pac solution pack`. The counterpart of Unpack-Solution.ps1.
.PARAMETER Folder
    Root folder produced by `pac solution unpack` (containing Other/Solution.xml).
.PARAMETER OutFile
    Path where the packed zip should be written. Parent folder is created.
.PARAMETER PackageType
    Unmanaged (default), Managed, or Both. Must match how the source was unpacked.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$Folder,
    [Parameter(Mandatory)] [string]$OutFile,
    [ValidateSet('Unmanaged','Managed','Both')] [string]$PackageType = 'Unmanaged'
)

. "$PSScriptRoot/Resolve-PacCommand.ps1"
$pacCommand = Resolve-PacCommand

New-Item -ItemType Directory -Force -Path (Split-Path -Parent $OutFile) | Out-Null
Write-Host "Packing $Folder -> $OutFile ($PackageType)"
& $pacCommand solution pack --folder $Folder --zipfile $OutFile --packagetype $PackageType
if ($LASTEXITCODE -ne 0) { throw "pac solution pack failed" }
Write-Host "Packed: $OutFile"
