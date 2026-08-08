<#
.SYNOPSIS
    Unpack a Dataverse solution zip into a source-controllable folder tree.
.DESCRIPTION
    Thin wrapper around `pac solution unpack`. Kept minimal on purpose: the pac 1.43.x
    flags `--allowDelete/--allowWrite/--clobber` accept boolean values (not bare switches),
    so we do not project them through the wrapper. Callers who need special behaviour
    can invoke pac directly.
.PARAMETER ZipFile
    Path to the solution zip previously produced by `pac solution export`.
.PARAMETER Folder
    Destination folder for the unpacked component tree. Created if it does not exist.
.PARAMETER PackageType
    Unmanaged (default), Managed, or Both. Must match how the zip was exported.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$ZipFile,
    [Parameter(Mandatory)] [string]$Folder,
    [ValidateSet('Unmanaged','Managed','Both')] [string]$PackageType = 'Unmanaged'
)

. "$PSScriptRoot/Resolve-PacCommand.ps1"
$pacCommand = Resolve-PacCommand

New-Item -ItemType Directory -Force -Path $Folder | Out-Null
Write-Host "Unpacking $ZipFile -> $Folder ($PackageType)"
& $pacCommand solution unpack --zipfile $ZipFile --folder $Folder --packagetype $PackageType
if ($LASTEXITCODE -ne 0) { throw "pac solution unpack failed" }
Write-Host "Unpacked: $Folder"
