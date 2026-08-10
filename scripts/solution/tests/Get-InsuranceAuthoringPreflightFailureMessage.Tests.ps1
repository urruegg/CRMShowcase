BeforeAll {
    . "$PSScriptRoot/../Get-InsuranceAuthoringPreflightFailureMessage.ps1"

    function script:Assert-SafeDiagnosticLine {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            [string]$Text,

            [int]$MaxLength = 600
        )

        $Text | Should -Not -Match '[\x00-\x1F\x7F-\x9F]'
        $Text | Should -Not -Match '(^|[\r\n])::'
        $Text.Length | Should -BeLessThan ($MaxLength + 1)
    }
}

Describe 'Get-InsuranceAuthoringPreflightFailureMessage' {
    It 'points ManualPrerequisite to the role bootstrap runbook and missing roles' {
        $json = [ordered]@{
            State        = 'ManualPrerequisite'
            MissingRoles = @('CRM Showcase Insurance Data Steward')
        } | ConvertTo-Json -Depth 10

        $message = Get-InsuranceAuthoringPreflightFailureMessage `
            -ExitCode 2 `
            -JsonText $json

        $message | Should -Match 'ManualPrerequisite'
        $message | Should -Match (
            [regex]::Escape(
                'MissingRoles=["CRM Showcase Insurance Data Steward"]'
            )
        )
        $message | Should -Match (
            [regex]::Escape(
                'docs/runbooks/insurance-foundation-security-role-bootstrap.md'
            )
        )
    }

    It 'reports Precondition prerequisites without role bootstrap guidance' {
        $json = [ordered]@{
            State               = 'Precondition'
            MissingSolutions    = @('crmshow_DataModel')
            MissingLanguageLcid = @(1031, 1036)
            LanguageAction      = 'Reconcile'
        } | ConvertTo-Json -Depth 10

        $message = Get-InsuranceAuthoringPreflightFailureMessage `
            -ExitCode 2 `
            -JsonText $json

        $message | Should -Match 'Required solution/environment prerequisites are missing'
        $message | Should -Match (
            [regex]::Escape('MissingSolutions=["crmshow_DataModel"]')
        )
        $message | Should -Match (
            [regex]::Escape('MissingLanguageLcid=["1031", "1036"]')
        )
        $message | Should -Match (
            [regex]::Escape('LanguageAction="Reconcile"')
        )
        $message | Should -Match 'preflight diagnostics above'
        $message | Should -Not -Match (
            'insurance-foundation-security-role-bootstrap'
        )
    }

    It 'reports UnsupportedInTenant identity guidance without role bootstrap guidance' {
        $json = [ordered]@{
            State             = 'UnsupportedInTenant'
            AssignedRoleNames = @('Basic User', 'Environment Maker')
        } | ConvertTo-Json -Depth 10

        $message = Get-InsuranceAuthoringPreflightFailureMessage `
            -ExitCode 2 `
            -JsonText $json

        $message | Should -Match 'UnsupportedInTenant'
        $message | Should -Match 'CI identity or tenant capability is unsupported'
        $message | Should -Match (
            [regex]::Escape(
                'AssignedRoleNames=["Basic User", "Environment Maker"]'
            )
        )
        $message | Should -Match 'Escalate for identity correction or tenant capability review'
        $message | Should -Not -Match (
            'insurance-foundation-security-role-bootstrap'
        )
    }

    It 'uses a generic non-ready message for unknown states without privileged action guidance' {
        $json = [ordered]@{
            State = 'UnexpectedState'
        } | ConvertTo-Json -Depth 10

        $message = Get-InsuranceAuthoringPreflightFailureMessage `
            -ExitCode 2 `
            -JsonText $json

        $message | Should -Match 'non-ready state'
        $message | Should -Match 'preflight diagnostics above'
        $message | Should -Match (
            [regex]::Escape('State="UnexpectedState"')
        )
        $message | Should -Not -Match (
            'insurance-foundation-security-role-bootstrap'
        )
    }

    It 'uses a generic non-ready message for unparseable JSON without privileged action guidance' {
        $message = Get-InsuranceAuthoringPreflightFailureMessage `
            -ExitCode 2 `
            -JsonText 'not-json'

        $message | Should -Match 'non-ready state'
        $message | Should -Match 'preflight diagnostics above'
        $message | Should -Not -Match (
            'insurance-foundation-security-role-bootstrap'
        )
    }

    It 'uses a generic transport failure for other nonzero exits' {
        $message = Get-InsuranceAuthoringPreflightFailureMessage `
            -ExitCode 1 `
            -JsonText '{"State":"ManualPrerequisite"}'

        $message | Should -Be (
            'Authoring preflight transport or execution failed. Review the error output above.'
        )
    }

    It 'reports ContractConflict ownership guidance on exit three without bootstrap instructions' {
        $json = [ordered]@{
            State             = 'ContractConflict'
            MissingSolutions  = @('crmshow_DataModel')
            SolutionConflicts = @(
                "Solution 'crmshow_Foundation' publisher metadata does not match solution/manifest.json: publisher.uniquename expected 'CRMShowcase' but was 'Contoso'."
            )
            RoleConflicts     = @(
                "Role 'CRM Showcase Insurance Reader': Role 'CRM Showcase Insurance Reader' reviewed-solution membership expected 'crmshow_Foundation'; actual reviewed membership was 'crmshow_Foundation, crmshow_DataModel'."
            )
        } | ConvertTo-Json -Depth 10

        $message = Get-InsuranceAuthoringPreflightFailureMessage `
            -ExitCode 3 `
            -JsonText $json

        Assert-SafeDiagnosticLine -Text $message -MaxLength 600
        $message | Should -Match 'ContractConflict'
        $message | Should -Match (
            'Reviewed publisher or role ownership differs from the contract'
        )
        $message | Should -Match (
            [regex]::Escape('MissingSolutions=["crmshow_DataModel"]')
        )
        $message | Should -Match 'No mutation was performed'
        $message | Should -Not -Match (
            'insurance-foundation-security-role-bootstrap'
        )
    }

    It 'sanitizes hostile ManualPrerequisite names to a single safe line' {
        $json = [ordered]@{
            State        = 'ManualPrerequisite'
            MissingRoles = @(
                "`n::warning::owned`trole$([char]1)",
                "CRM`rShowcase$([char]0x85)Operator"
            )
        } | ConvertTo-Json -Depth 10

        $message = Get-InsuranceAuthoringPreflightFailureMessage `
            -ExitCode 2 `
            -JsonText $json

        Assert-SafeDiagnosticLine -Text $message -MaxLength 350
        $message | Should -Match 'ManualPrerequisite'
        $message | Should -Match 'warning::owned role'
        $message | Should -Match 'CRM Showcase Operator'
    }

    It 'bounds long diagnostic lists to avoid log flooding' {
        $veryLongName = 'Role-' + ('Z' * 240)
        $json = [ordered]@{
            State        = 'ManualPrerequisite'
            MissingRoles = @(
                $veryLongName,
                ('Role-B-' + ('Y' * 240)),
                ('Role-C-' + ('X' * 240)),
                ('Role-D-' + ('W' * 240)),
                ('Role-E-' + ('V' * 240))
            )
        } | ConvertTo-Json -Depth 10

        $message = Get-InsuranceAuthoringPreflightFailureMessage `
            -ExitCode 2 `
            -JsonText $json

        Assert-SafeDiagnosticLine -Text $message -MaxLength 450
        $message | Should -Match 'ManualPrerequisite'
        $message | Should -Match '\.\.\. \(\+\d+ more\)'
        $message | Should -Not -Match (
            [regex]::Escape(('Z' * 150))
        )
    }
}

Describe 'Get-InsuranceAuthoringPreflightDiagnosticSummary' {
    It 'builds a compact sanitized contract-conflict workflow summary' {
        $json = [ordered]@{
            State             = 'ContractConflict'
            MissingSolutions  = @("crmshow_DataModel`n::warning::owned")
            SolutionConflicts = @(
                "Solution`r`tpublisher$([char]0x85) mismatch"
            )
            RoleConflicts     = @(
                "Role`n::warning::conflict`t$([char]1)"
            )
        } | ConvertTo-Json -Depth 10

        $summary = Get-InsuranceAuthoringPreflightDiagnosticSummary `
            -JsonText $json

        Assert-SafeDiagnosticLine -Text $summary -MaxLength 500
        $summary | Should -Match (
            [regex]::Escape(
                'Authoring preflight diagnostics: State="ContractConflict";'
            )
        )
        $summary | Should -Match 'SolutionConflicts='
        $summary | Should -Match 'RoleConflicts='
        $summary | Should -Match 'warning::owned'
        $summary | Should -Match 'warning::conflict'
    }

    It 'builds a compact sanitized workflow summary from parsed diagnostics' {
        $json = [ordered]@{
            State               = 'Precondition'
            MissingSolutions    = @(
                "crmshow_DataModel`n::warning::owned",
                "crmshow_Foundation`r`t$([char]0x9f)Ready"
            )
            MissingLanguageLcid = @(
                "1031`r::warning::owned",
                "1036`t$([char]0x1f)"
            )
            LanguageAction      = "`n::warning::Reconcile`t$([char]0x85)"
        } | ConvertTo-Json -Depth 10

        $summary = Get-InsuranceAuthoringPreflightDiagnosticSummary `
            -JsonText $json

        Assert-SafeDiagnosticLine -Text $summary -MaxLength 500
        $summary | Should -Match (
            [regex]::Escape('Authoring preflight diagnostics: State="Precondition";')
        )
        $summary | Should -Match 'warning::owned'
        $summary | Should -Match (
            [regex]::Escape('LanguageAction="[literal] ::warning::Reconcile"')
        )
    }

    It 'sanitizes unparseable workflow output without echoing raw multiline text' {
        $summary = Get-InsuranceAuthoringPreflightDiagnosticSummary `
            -JsonText ("`n::warning::boom`t" + ('Q' * 400) + [char]0x85)

        Assert-SafeDiagnosticLine -Text $summary -MaxLength 430
        $summary | Should -Match (
            [regex]::Escape('State="(unparseable)"')
        )
        $summary | Should -Match 'RawResult='
        $summary | Should -Match 'warning::boom'
        $summary | Should -Match '\.\.\.'
    }
}
