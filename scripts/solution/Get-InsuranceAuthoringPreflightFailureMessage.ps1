function Format-InsuranceAuthoringPreflightList {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [object[]]$Value
    )

    $items = foreach ($item in @($Value)) {
        if ($null -eq $item) {
            continue
        }

        $text = [string]$item
        if ([string]::IsNullOrWhiteSpace($text)) {
            continue
        }

        $text.Trim()
    }

    return '[{0}]' -f (@($items) -join ', ')
}

function Get-InsuranceAuthoringPreflightFailureMessage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [int]$ExitCode,

        [AllowEmptyString()]
        [string]$JsonText
    )

    if ($ExitCode -ne 2) {
        return 'Authoring preflight transport or execution failed. Review the error output above.'
    }

    try {
        $result = $JsonText | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        return 'Authoring preflight reported a non-ready state. Review the preflight JSON echoed above for details.'
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
            $languageAction = if ([string]::IsNullOrWhiteSpace([string]$result.LanguageAction)) {
                '(not reported)'
            }
            else {
                [string]$result.LanguageAction
            }

            return "Authoring preflight reported Precondition. Required solution/environment prerequisites are missing. MissingSolutions=$missingSolutions. MissingLanguageLcid=$missingLanguageLcid. LanguageAction=$languageAction. Review the preflight JSON echoed above, satisfy the prerequisites, and rerun."
        }
        'UnsupportedInTenant' {
            $assignedRoleNames = Format-InsuranceAuthoringPreflightList -Value @(
                $result.AssignedRoleNames
            )
            return "Authoring preflight reported UnsupportedInTenant. The CI identity or tenant capability is unsupported for demo schema authoring. AssignedRoleNames=$assignedRoleNames. Escalate for identity correction or tenant capability review, then rerun."
        }
        default {
            $stateText = if ([string]::IsNullOrWhiteSpace([string]$result.State)) {
                '(not reported)'
            }
            else {
                [string]$result.State
            }

            return "Authoring preflight reported a non-ready state. State=$stateText. Review the preflight JSON echoed above for details."
        }
    }
}
