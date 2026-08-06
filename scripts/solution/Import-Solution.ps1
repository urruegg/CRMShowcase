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

if (-not (Get-Command pac -ErrorAction SilentlyContinue)) {
    $env:PATH = "$env:USERPROFILE\.dotnet\tools;$env:PATH"
    if (-not (Get-Command pac -ErrorAction SilentlyContinue)) {
        throw "pac CLI not found. Install: dotnet tool install --global Microsoft.PowerApps.CLI.Tool --version 1.43.6"
    }
}

# NOTE: $args is a reserved PowerShell automatic variable, so we use $pacArgs instead.
$pacArgs = @('solution','import','--path', $ZipFile,'--force-overwrite')
if ($Async) { $pacArgs += '--async' }
if ($PublishChanges) { $pacArgs += '--publish-changes' }

Write-Host "Importing $ZipFile ..."
pac @pacArgs
if ($LASTEXITCODE -ne 0) { throw "pac solution import failed for $ZipFile" }
Write-Host "Imported: $ZipFile"
