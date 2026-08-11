<#
.SYNOPSIS
    Evaluate TEST promotion smoke checks from gathered environment facts.
.DESCRIPTION
    Pure evaluator: given injected facts about the TEST environment, returns a
    per-check pass/fail result plus an overall verdict. A thin live wrapper (run
    in the promotion workflow) gathers the facts; this function is unit-testable
    offline.
#>
[CmdletBinding()]
param(
    $Facts,
    [int[]]$ExpectedLocales = @(1033, 1031, 1036, 1040),
    [string[]]$ExpectedSolutions = @('crmshow_Foundation', 'crmshow_DataModel'),
    [string[]]$ExpectedTables = @()
)

function Get-PromotionSmokeResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] $Facts,
        [int[]]$ExpectedLocales = @(1033, 1031, 1036, 1040),
        [string[]]$ExpectedSolutions = @('crmshow_Foundation', 'crmshow_DataModel'),
        [string[]]$ExpectedTables = @()
    )

    $checks = @()
    function New-Check($name, $pass, $detail) {
        [pscustomobject]@{ Name = $name; Pass = [bool]$pass; Detail = $detail }
    }

    $missingLocales = @($ExpectedLocales | Where-Object { $Facts.ActiveLocales -notcontains $_ })
    $checks += New-Check 'LanguagesActive' ($missingLocales.Count -eq 0) "missing: $($missingLocales -join ',')"

    $presentSolutions = @($Facts.Solutions | ForEach-Object { $_.Name })
    $missingSolutions = @($ExpectedSolutions | Where-Object { $presentSolutions -notcontains $_ })
    $unmanaged = @($Facts.Solutions | Where-Object { -not $_.IsManaged } | ForEach-Object { $_.Name })
    $checks += New-Check 'SolutionsManagedPresent' (($missingSolutions.Count -eq 0) -and ($unmanaged.Count -eq 0)) "missing: $($missingSolutions -join ','); unmanaged: $($unmanaged -join ',')"

    $missingTables = @($ExpectedTables | Where-Object { $Facts.Tables -notcontains $_ })
    $checks += New-Check 'TablesPresent' ($missingTables.Count -eq 0) "missing: $($missingTables -join ',')"

    $checks += New-Check 'ReaderReadOnly'    (-not $Facts.ReaderCanMutate) 'Reader must not create/update/delete'
    $checks += New-Check 'StewardNoSecAdmin' (-not $Facts.StewardCanAdmin) 'Data Steward must not administer security'
    $checks += New-Check 'LocalizedLabels'   ([bool]$Facts.LocalizedLabels) 'labels retrievable for all four LCIDs'

    [pscustomobject]@{
        Overall = (@($checks | Where-Object { -not $_.Pass }).Count -eq 0)
        Checks  = $checks
    }
}

if ($MyInvocation.InvocationName -ne '.') {
    Get-PromotionSmokeResult @PSBoundParameters
}
