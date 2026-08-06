<#
.SYNOPSIS
    Load and (optionally) validate the solution manifest.
.PARAMETER Path
    Absolute or relative path to solution/manifest.json.
.PARAMETER Validate
    If specified, validates the loaded object against solution/manifest.schema.json.
#>
[CmdletBinding()]
param(
    [string]$Path,
    [switch]$Validate
)

function Get-Manifest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        [switch]$Validate
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Manifest not found: $Path"
    }

    try {
        $raw = Get-Content -Raw -Path $Path
        $obj = $raw | ConvertFrom-Json -ErrorAction Stop
    } catch {
        throw "Invalid JSON in $Path : $_"
    }

    if ($Validate) {
        $schemaPath = Join-Path (Split-Path -Parent $Path) 'manifest.schema.json'
        if (-not (Test-Path -LiteralPath $schemaPath)) {
            throw "Schema not found next to manifest: $schemaPath"
        }
        # Minimal built-in validation. Full JSON-Schema validation is deferred to CI where npx ajv is available.
        if (-not $obj.publisher) { throw "Manifest missing 'publisher'" }
        if (-not $obj.versioning) { throw "Manifest missing 'versioning'" }
        if (-not $obj.solutions -or $obj.solutions.Count -eq 0) { throw "Manifest missing 'solutions'" }
        foreach ($s in $obj.solutions) {
            foreach ($f in 'uniqueName','displayName','path','version','dependsOn','owner') {
                if (-not $s.PSObject.Properties.Name.Contains($f)) {
                    throw "Solution '$($s.uniqueName)' missing '$f'"
                }
            }
            if ($s.version -notmatch '^\d+\.\d+\.\d+\.\d+$') {
                throw "Solution '$($s.uniqueName)' has invalid version '$($s.version)'"
            }
        }
    }

    return $obj
}

if ($MyInvocation.InvocationName -ne '.' -and $PSBoundParameters.ContainsKey('Path')) {
    Get-Manifest -Path $Path -Validate:$Validate
}