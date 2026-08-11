<#
.SYNOPSIS
    Derive the Proof #2 promotion component contract from the insurance schema.
.DESCRIPTION
    Reads the insurance-foundation contract JSON and returns the in-scope and
    excluded component sets. Effective-date business rules and reporting views
    (OverlapReporting / InvalidDateReporting) are excluded from the promoted
    managed slice; Administration views and forms stay in scope.
#>
[CmdletBinding()]
param(
    [string]$SchemaPath,
    [string[]]$ExcludedViewPurposes = @('OverlapReporting', 'InvalidDateReporting')
)

function Get-PromotionComponents {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string]$SchemaPath,
        [string[]]$ExcludedViewPurposes = @('OverlapReporting', 'InvalidDateReporting')
    )

    if (-not (Test-Path -LiteralPath $SchemaPath)) {
        throw "Schema not found: $SchemaPath"
    }
    $schema = Get-Content -Raw -LiteralPath $SchemaPath | ConvertFrom-Json

    $tables = @()
    $inScopeViews = @()
    $excludedViews = @()
    $excludedRules = @()

    foreach ($t in $schema.tables) {
        $tables += $t.logicalName
        foreach ($r in $t.businessRules) { $excludedRules += $r.name }
        foreach ($v in $t.views) {
            if ($ExcludedViewPurposes -contains $v.purpose) { $excludedViews += $v.name }
            else { $inScopeViews += $v.name }
        }
    }

    [pscustomobject]@{
        Solutions             = @($schema.solutions)
        Tables                = $tables
        InScopeViews          = $inScopeViews
        ExcludedViews         = $excludedViews
        ExcludedBusinessRules = $excludedRules
        ExcludedComponents    = @($excludedViews + $excludedRules)
    }
}

function Test-PromotionPackageComponents {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string[]]$PackageComponentNames,
        [Parameter(Mandatory)] [string[]]$ExcludedComponents
    )
    $violations = @($PackageComponentNames | Where-Object { $ExcludedComponents -contains $_ })
    return , $violations
}

if ($MyInvocation.InvocationName -ne '.') {
    Get-PromotionComponents @PSBoundParameters
}
