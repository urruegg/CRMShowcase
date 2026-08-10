$script:InsuranceAuthoringPreflightMaxValueLength = 120
$script:InsuranceAuthoringPreflightMaxListLength = 240
$script:InsuranceAuthoringPreflightMaxRawLength = 240

function ConvertTo-InsuranceAuthoringPreflightSafeLiteral {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [object]$Value,

        [ValidateRange(16, 4096)]
        [int]$MaxLength = $script:InsuranceAuthoringPreflightMaxValueLength
    )

    if ($null -eq $Value) {
        return $null
    }

    $text = [string]$Value
    $text = [regex]::Replace($text, '[\x00-\x1F\x7F-\x9F]', ' ')
    $text = [regex]::Replace($text, '\s+', ' ')
    $text = $text.Trim()

    if ([string]::IsNullOrWhiteSpace($text)) {
        return $null
    }

    if ($text.StartsWith('::')) {
        $text = "[literal] $text"
    }

    if ($text.Length -gt $MaxLength) {
        $text = $text.Substring(0, $MaxLength - 3) + '...'
    }

    return $text | ConvertTo-Json -Compress
}

function Format-InsuranceAuthoringPreflightValue {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [object]$Value,

        [string]$Fallback = '(not reported)',

        [ValidateRange(16, 4096)]
        [int]$MaxLength = $script:InsuranceAuthoringPreflightMaxValueLength
    )

    $literal = ConvertTo-InsuranceAuthoringPreflightSafeLiteral `
        -Value $Value `
        -MaxLength $MaxLength
    if ($null -ne $literal) {
        return $literal
    }

    return ConvertTo-InsuranceAuthoringPreflightSafeLiteral `
        -Value $Fallback `
        -MaxLength $MaxLength
}

function Format-InsuranceAuthoringPreflightList {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [object[]]$Value,

        [ValidateRange(32, 4096)]
        [int]$MaxLength = $script:InsuranceAuthoringPreflightMaxListLength
    )

    $items = New-Object 'System.Collections.Generic.List[string]'
    foreach ($item in @($Value)) {
        $literal = ConvertTo-InsuranceAuthoringPreflightSafeLiteral -Value $item
        if ($null -eq $literal) {
            continue
        }

        $items.Add($literal)
    }

    if ($items.Count -eq 0) {
        return '[]'
    }

    $fullText = '[{0}]' -f ($items.ToArray() -join ', ')
    if ($fullText.Length -le $MaxLength) {
        return $fullText
    }

    $displayItems = New-Object 'System.Collections.Generic.List[string]'
    for ($index = 0; $index -lt $items.Count; $index++) {
        $remaining = $items.Count - $index - 1
        $displayItems.Add($items[$index])

        $candidateItems = @($displayItems.ToArray())
        if ($remaining -gt 0) {
            $candidateItems += ConvertTo-InsuranceAuthoringPreflightSafeLiteral `
                -Value "... (+$remaining more)"
        }

        $candidate = '[{0}]' -f ($candidateItems -join ', ')
        if ($candidate.Length -gt $MaxLength) {
            $displayItems.RemoveAt($displayItems.Count - 1)
            break
        }
    }

    if ($displayItems.Count -eq 0) {
        return '[{0}]' -f (
            ConvertTo-InsuranceAuthoringPreflightSafeLiteral `
                -Value "... (+$($items.Count) items omitted)"
        )
    }

    $omitted = $items.Count - $displayItems.Count
    if ($omitted -le 0) {
        return '[{0}]' -f ($displayItems.ToArray() -join ', ')
    }

    $suffix = ConvertTo-InsuranceAuthoringPreflightSafeLiteral `
        -Value "... (+$omitted more)"
    while ($displayItems.Count -gt 0 -and
        ('[{0}]' -f ((@($displayItems.ToArray()) + $suffix) -join ', ')).Length -gt $MaxLength) {
        $displayItems.RemoveAt($displayItems.Count - 1)
        $omitted = $items.Count - $displayItems.Count
        $suffix = ConvertTo-InsuranceAuthoringPreflightSafeLiteral `
            -Value "... (+$omitted more)"
    }

    if ($displayItems.Count -eq 0) {
        return '[{0}]' -f (
            ConvertTo-InsuranceAuthoringPreflightSafeLiteral `
                -Value "... (+$($items.Count) items omitted)"
        )
    }

    return '[{0}]' -f ((@($displayItems.ToArray()) + $suffix) -join ', ')
}

function Get-InsuranceAuthoringPreflightDiagnosticSummary {
    [CmdletBinding()]
    param(
        [AllowEmptyString()]
        [string]$JsonText
    )

    try {
        $result = $JsonText | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        $stateText = Format-InsuranceAuthoringPreflightValue -Value '(unparseable)'
        $rawText = Format-InsuranceAuthoringPreflightValue `
            -Value $JsonText `
            -Fallback '(not reported)' `
            -MaxLength $script:InsuranceAuthoringPreflightMaxRawLength
        return "Authoring preflight diagnostics: State=$stateText; RawResult=$rawText."
    }

    $stateText = Format-InsuranceAuthoringPreflightValue -Value $result.State
    switch ([string]$result.State) {
        'ContractConflict' {
            $missingSolutions = Format-InsuranceAuthoringPreflightList -Value @(
                $result.MissingSolutions
            )
            $solutionConflicts = Format-InsuranceAuthoringPreflightList -Value @(
                $result.SolutionConflicts
            )
            $roleConflicts = Format-InsuranceAuthoringPreflightList -Value @(
                $result.RoleConflicts
            )
            return "Authoring preflight diagnostics: State=$stateText; MissingSolutions=$missingSolutions; SolutionConflicts=$solutionConflicts; RoleConflicts=$roleConflicts."
        }
        'ManualPrerequisite' {
            $missingRoles = Format-InsuranceAuthoringPreflightList -Value @(
                $result.MissingRoles
            )
            return "Authoring preflight diagnostics: State=$stateText; MissingRoles=$missingRoles."
        }
        'Precondition' {
            $missingSolutions = Format-InsuranceAuthoringPreflightList -Value @(
                $result.MissingSolutions
            )
            $missingLanguageLcid = Format-InsuranceAuthoringPreflightList -Value @(
                $result.MissingLanguageLcid
            )
            $languageAction = Format-InsuranceAuthoringPreflightValue `
                -Value $result.LanguageAction

            return "Authoring preflight diagnostics: State=$stateText; MissingSolutions=$missingSolutions; MissingLanguageLcid=$missingLanguageLcid; LanguageAction=$languageAction."
        }
        'UnsupportedInTenant' {
            $assignedRoleNames = Format-InsuranceAuthoringPreflightList -Value @(
                $result.AssignedRoleNames
            )
            return "Authoring preflight diagnostics: State=$stateText; AssignedRoleNames=$assignedRoleNames."
        }
        default {
            return "Authoring preflight diagnostics: State=$stateText."
        }
    }
}

function Get-InsuranceAuthoringPreflightFailureMessage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [int]$ExitCode,

        [AllowEmptyString()]
        [string]$JsonText
    )

    if ($ExitCode -ne 2 -and $ExitCode -ne 3) {
        return 'Authoring preflight transport or execution failed. Review the error output above.'
    }

    try {
        $result = $JsonText | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        if ($ExitCode -eq 3) {
            return 'Authoring preflight reported ContractConflict. Review the preflight diagnostics above for the reviewed contract conflict details. No mutation was performed.'
        }
        return 'Authoring preflight reported a non-ready state. Review the preflight diagnostics above for details.'
    }

    if ($ExitCode -eq 3) {
        $missingSolutions = Format-InsuranceAuthoringPreflightList -Value @(
            $result.MissingSolutions
        )
        $solutionConflicts = Format-InsuranceAuthoringPreflightList -Value @(
            $result.SolutionConflicts
        )
        $roleConflicts = Format-InsuranceAuthoringPreflightList -Value @(
            $result.RoleConflicts
        )

        return "Authoring preflight reported ContractConflict. Reviewed publisher or role ownership differs from the contract. MissingSolutions=$missingSolutions. SolutionConflicts=$solutionConflicts. RoleConflicts=$roleConflicts. Review the preflight diagnostics above. No mutation was performed."
    }

    switch ([string]$result.State) {
        'ManualPrerequisite' {
            $missingRoles = Format-InsuranceAuthoringPreflightList -Value @(
                $result.MissingRoles
            )
            return "Authoring preflight reported ManualPrerequisite. MissingRoles=$missingRoles. Follow docs/runbooks/insurance-foundation-security-role-bootstrap.md, then rerun."
        }
        'Precondition' {
            $missingSolutions = Format-InsuranceAuthoringPreflightList -Value @(
                $result.MissingSolutions
            )
            $missingLanguageLcid = Format-InsuranceAuthoringPreflightList -Value @(
                $result.MissingLanguageLcid
            )
            $languageAction = Format-InsuranceAuthoringPreflightValue `
                -Value $result.LanguageAction

            return "Authoring preflight reported Precondition. Required solution/environment prerequisites are missing. MissingSolutions=$missingSolutions. MissingLanguageLcid=$missingLanguageLcid. LanguageAction=$languageAction. Review the preflight diagnostics above, satisfy the prerequisites, and rerun."
        }
        'UnsupportedInTenant' {
            $assignedRoleNames = Format-InsuranceAuthoringPreflightList -Value @(
                $result.AssignedRoleNames
            )
            return "Authoring preflight reported UnsupportedInTenant. The CI identity or tenant capability is unsupported for demo schema authoring. AssignedRoleNames=$assignedRoleNames. Escalate for identity correction or tenant capability review, then rerun."
        }
        default {
            $stateText = Format-InsuranceAuthoringPreflightValue `
                -Value $result.State

            return "Authoring preflight reported a non-ready state. State=$stateText. Review the preflight diagnostics above for details."
        }
    }
}
