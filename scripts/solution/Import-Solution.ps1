<#
.SYNOPSIS
    Import a Dataverse solution zip into the currently-selected pac auth environment.
.DESCRIPTION
    Thin wrapper around `pac solution import`. The active pac auth profile determines
    the target environment (`pac auth select --index <n>` beforehand).
.PARAMETER ZipFile
    Path to the solution zip to import.
.PARAMETER Async
    Run the import asynchronously and return once the server-side operation is queued.
.PARAMETER PublishChanges
    Publish customizations after import completes.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$ZipFile,
    [switch]$Async,
    [switch]$PublishChanges
)

. "$PSScriptRoot/Resolve-PacCommand.ps1"
$pacCommand = Resolve-PacCommand

# NOTE: $args is a reserved PowerShell automatic variable, so we use $pacArgs instead.
$pacArgs = @('solution','import','--path', $ZipFile,'--force-overwrite')
if ($Async) { $pacArgs += '--async' }
if ($PublishChanges) { $pacArgs += '--publish-changes' }

Write-Host "Importing $ZipFile ..."
& $pacCommand @pacArgs
if ($LASTEXITCODE -ne 0) { throw "pac solution import failed for $ZipFile" }
Write-Host "Imported: $ZipFile"
