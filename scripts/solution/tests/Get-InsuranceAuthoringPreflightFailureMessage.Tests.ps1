BeforeAll {
    . "$PSScriptRoot/../Get-InsuranceAuthoringPreflightFailureMessage.ps1"
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
            [regex]::Escape('MissingRoles=[CRM Showcase Insurance Data Steward]')
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
            [regex]::Escape('MissingSolutions=[crmshow_DataModel]')
        )
        $message | Should -Match (
            [regex]::Escape('MissingLanguageLcid=[1031, 1036]')
        )
        $message | Should -Match 'LanguageAction=Reconcile'
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
            [regex]::Escape('AssignedRoleNames=[Basic User, Environment Maker]')
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
        $message | Should -Match 'State=UnexpectedState'
        $message | Should -Match 'JSON echoed above'
        $message | Should -Not -Match (
            'insurance-foundation-security-role-bootstrap'
        )
    }

    It 'uses a generic non-ready message for unparseable JSON without privileged action guidance' {
        $message = Get-InsuranceAuthoringPreflightFailureMessage `
            -ExitCode 2 `
            -JsonText 'not-json'

        $message | Should -Match 'non-ready state'
        $message | Should -Match 'JSON echoed above'
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
}
