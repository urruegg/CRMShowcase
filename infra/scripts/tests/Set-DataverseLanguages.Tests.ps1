BeforeAll {
    $scriptPath = Join-Path $PSScriptRoot '..\Set-DataverseLanguages.ps1'
    . $scriptPath -EnvironmentUrl 'https://crmshowdev.crm.dynamics.com' -LocaleId 1033
}

Describe 'Get-NormalizedLocaleIds' {
    It 'returns unique supported locale IDs in ascending order' {
        $actual = @(Get-NormalizedLocaleIds -LocaleId @(1040, 1033, 1031, 1036, 1033, 1040))

        $actual | Should -Be @(1031, 1033, 1036, 1040)
    }

    It 'rejects an unsupported locale ID with a clear error' {
        { Get-NormalizedLocaleIds -LocaleId @(1033, 9999) } |
            Should -Throw -ExpectedMessage "*Unsupported Dataverse locale ID: 9999*"
    }
}

Describe 'Wait-DataverseLanguage' {
    BeforeEach {
        $script:readCount = 0
        Mock Start-Sleep
    }

    It 'polls until the language is active' {
        Mock Get-ProvisionedLocaleIds {
            $script:readCount++
            if ($script:readCount -eq 1) {
                return @(1033)
            }
            return @(1031, 1033)
        }

        Wait-DataverseLanguage -BaseUrl 'https://crmshowdev.crm.dynamics.com' `
            -LocaleId 1031 -TimeoutSeconds 5 -PollSeconds 1

        Should -Invoke Get-ProvisionedLocaleIds -Times 2 -Exactly
        Should -Invoke Start-Sleep -Times 1 -Exactly -ParameterFilter { $Seconds -eq 1 }
    }

    It 'throws after its bounded timeout without real sleeping' {
        Mock Get-ProvisionedLocaleIds { return @(1033) }

        {
            Wait-DataverseLanguage -BaseUrl 'https://orgd0d886ca.crm.dynamics.com' `
                -LocaleId 1040 -TimeoutSeconds 0 -PollSeconds 1
        } | Should -Throw -ExpectedMessage "*Locale '1040' did not become active within 0 seconds*"

        Should -Invoke Get-ProvisionedLocaleIds -Times 1 -Exactly
        Should -Invoke Start-Sleep -Times 0 -Exactly
    }
}

Describe 'Invoke-DataverseLanguageReconciliation' {
    BeforeEach {
        $script:events = [System.Collections.Generic.List[string]]::new()

        Mock Get-ProvisionedLocaleIds {
            [void]$script:events.Add('GET:PROVISIONED')
            return @(1033)
        }
        Mock Invoke-DataverseRest {
            [void]$script:events.Add("POST:$($Body.Language)")
        }
        Mock Wait-DataverseLanguage {
            [void]$script:events.Add("WAIT:$LocaleId")
        }
    }

    It 'provisions every missing language before starting the first wait' {
        $evidence = @(
            Invoke-DataverseLanguageReconciliation `
                -BaseUrl 'https://crmshowdev.crm.dynamics.com' `
                -RequiredLocaleId @(1031, 1036)
        )

        $script:events | Should -Be @(
            'GET:PROVISIONED'
            'POST:1031'
            'POST:1036'
            'WAIT:1031'
            'WAIT:1036'
        )
        $evidence.LocaleId | Should -Be @(1031, 1036)
        $evidence.State | Should -Be @('Active', 'Active')
    }

    It 'does not reprovision languages returned by RetrieveProvisionedLanguages' {
        Mock Get-ProvisionedLocaleIds { return @(1031, 1033, 1036, 1040) }
        Mock Invoke-DataverseRest
        Mock Wait-DataverseLanguage

        Invoke-DataverseLanguageReconciliation `
            -BaseUrl 'https://crmshowdev.crm.dynamics.com' `
            -RequiredLocaleId @(1031, 1033, 1036, 1040) | Out-Null

        Should -Invoke Invoke-DataverseRest -Times 0 -Exactly
        Should -Invoke Wait-DataverseLanguage -Times 0 -Exactly
    }

    It 'does not provision or wait during WhatIf and preserves requested output order' {
        Mock Get-ProvisionedLocaleIds { return @(1033) }
        Mock Invoke-DataverseRest
        Mock Wait-DataverseLanguage

        $evidence = @(
            Invoke-DataverseLanguageReconciliation `
                -BaseUrl 'https://crmshowdev.crm.dynamics.com' `
                -RequiredLocaleId @(1031, 1033) -WhatIf
        )

        Should -Invoke Invoke-DataverseRest -Times 0 -Exactly
        Should -Invoke Wait-DataverseLanguage -Times 0 -Exactly
        $evidence.LocaleId | Should -Be @(1031, 1033)
        $evidence.State | Should -Be @('Planned', 'Active')
    }
}
