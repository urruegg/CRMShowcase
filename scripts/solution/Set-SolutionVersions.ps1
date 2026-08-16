<#
.SYNOPSIS
    Syncs each Dataverse solution declared in solution/manifest.json to its
    manifest-declared version.
.DESCRIPTION
    Manifest.json declares a semver-four-part version per solution, but
    nothing previously pushed that version to the live Dataverse solution
    record -- every solution stayed at 1.0.0.0 regardless of what the
    manifest said. This script closes that gap: for each declared solution,
    it computes the target version as the manifest's MAJOR.MINOR.PATCH with
    BUILD stamped from the live CI run number (Bump-Version -Kind build),
    matching the convention manifest.json's own "versioning" section already
    documents, and PATCHes the live solution only when the version differs.

    Safe to dot-source for testing: the top-level parameters are
    non-mandatory and the sync action runs only when the script is invoked
    directly with an -EnvironmentUrl and -Build.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$EnvironmentUrl,
    [string]$ManifestPath,
    [int]$Build
)

$ErrorActionPreference = 'Stop'

if (-not $ManifestPath) {
    $ManifestPath = (Resolve-Path (Join-Path $PSScriptRoot '../../solution/manifest.json')).Path
}
$script:ManifestPath = $ManifestPath

. (Join-Path $PSScriptRoot 'Get-Manifest.ps1')
. (Join-Path $PSScriptRoot 'Bump-Version.ps1')

# Pure function: given the manifest's declared solutions and a map of their
# live { Id; Version }, returns only the solutions whose live version
# doesn't already match the manifest-derived target -- so the caller can
# skip a PATCH entirely when nothing changed. Throws immediately naming any
# manifest-declared solution missing from $LiveSolutions, rather than
# silently skipping it (a missing solution means something is fundamentally
# wrong with the environment, not a "nothing to do" case).
function Get-SolutionVersionUpdates {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] $Solutions,
        [Parameter(Mandatory)] [System.Collections.IDictionary]$LiveSolutions,
        [Parameter(Mandatory)] [int]$Build
    )

    foreach ($solution in @($Solutions)) {
        $live = $LiveSolutions[[string]$solution.uniqueName]
        if (-not $live) {
            throw "Solution '$($solution.uniqueName)' not found live -- cannot sync its version."
        }
        $target = Bump-Version -Current $solution.version -Kind 'build' -Build $Build
        if ($target -ne $live.Version) {
            [pscustomobject]@{
                UniqueName    = [string]$solution.uniqueName
                SolutionId    = [string]$live.Id
                TargetVersion = $target
            }
        }
    }
}

# The only function that calls az directly. GET requests return the parsed
# JSON response; mutating requests (PATCH) write the body to a temp file and
# return null. This single choke point is what every test in this file
# mocks, instead of mocking az itself for each differently-shaped call.
function Invoke-SolutionVersionRequest {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)] [string]$BaseUrl,
        [Parameter(Mandatory)] [string]$Method,
        [Parameter(Mandatory)] [string]$Path,
        $Body
    )

    $url = "$BaseUrl/api/data/v9.2$Path"
    if ($Method -eq 'GET') {
        $response = az rest --method GET --url $url --resource "$BaseUrl/" --only-show-errors
        if ([string]::IsNullOrWhiteSpace($response)) { return $null }
        return ($response | ConvertFrom-Json)
    }

    if (-not $PSCmdlet.ShouldProcess($url, $Method)) { return $null }
    $tmp = [System.IO.Path]::GetTempFileName()
    try {
        ($Body | ConvertTo-Json -Depth 6) | Set-Content -LiteralPath $tmp -Encoding UTF8
        # No If-Match header -- this is a plain update (the solution always
        # already exists), not an upsert that needs create/update guarding.
        az rest --method $Method --url $url --resource "$BaseUrl/" `
            --headers 'Content-Type=application/json' --body "@$tmp" --only-show-errors | Out-Null
    }
    finally {
        Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
    }
    return $null
}

function Invoke-SolutionVersionSync {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)] [string]$EnvironmentUrl,
        [Parameter(Mandatory)] [int]$Build
    )

    $baseUrl = $EnvironmentUrl.TrimEnd('/')
    $manifest = Get-Manifest -Path $script:ManifestPath -Validate

    $liveSolutions = [ordered]@{}
    foreach ($solution in $manifest.solutions) {
        $response = Invoke-SolutionVersionRequest -BaseUrl $baseUrl -Method 'GET' -Path "/solutions?`$select=solutionid,version,uniquename&`$filter=uniquename eq '$($solution.uniqueName)'"
        if (@($response.value).Count -lt 1) {
            throw "Solution '$($solution.uniqueName)' not found in $EnvironmentUrl -- cannot sync its version."
        }
        $record = $response.value[0]
        $liveSolutions[[string]$solution.uniqueName] = @{ Id = [string]$record.solutionid; Version = [string]$record.version }
    }

    $updates = @(Get-SolutionVersionUpdates -Solutions $manifest.solutions -LiveSolutions $liveSolutions -Build $Build)
    foreach ($update in $updates) {
        Invoke-SolutionVersionRequest -BaseUrl $baseUrl -Method 'PATCH' -Path "/solutions($($update.SolutionId))" -Body @{ version = $update.TargetVersion } | Out-Null
        Write-Output "Synced $($update.UniqueName): $($update.TargetVersion)"
    }
    if (@($updates).Count -eq 0) {
        Write-Output 'All solution versions already match the manifest.'
    }
}

if ($MyInvocation.InvocationName -ne '.') {
    if ($EnvironmentUrl -and $PSBoundParameters.ContainsKey('Build')) {
        Invoke-SolutionVersionSync -EnvironmentUrl $EnvironmentUrl -Build $Build
    }
    else {
        $manifest = Get-Manifest -Path $script:ManifestPath -Validate
        Write-Output ("Manifest loaded: {0} solution(s) declared." -f @($manifest.solutions).Count)
    }
}
