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

Describe 'Get-LanguageTransition' {
    It 'returns Unchanged for an active language' {
        Get-LanguageTransition -LocaleId 1033 -StateCode 0 | Should -Be 'Unchanged'
    }

    It 'returns Activate for an inactive language' {
        Get-LanguageTransition -LocaleId 1031 -StateCode 1 | Should -Be 'Activate'
    }

    It 'rejects an unexpected state code' {
        { Get-LanguageTransition -LocaleId 1036 -StateCode 2 } |
            Should -Throw -ExpectedMessage "*Unexpected statecode '2' for locale '1036'*"
    }
}

Describe 'Wait-DataverseLanguage' {
    BeforeEach {
        $script:readCount = 0
        Mock Start-Sleep
    }

    It 'polls until the language is active' {
        Mock Invoke-DataverseRest {
            $script:readCount++
            if ($script:readCount -eq 1) {
                return @{ value = @(@{ localeid = 1031; statecode = 1 }) }
            }
            return @{ value = @(@{ localeid = 1031; statecode = 0 }) }
        }

        Wait-DataverseLanguage -BaseUrl 'https://crmshowdev.crm.dynamics.com' `
            -LocaleId 1031 -TimeoutSeconds 5 -PollSeconds 1

        Should -Invoke Invoke-DataverseRest -Times 2 -Exactly
        Should -Invoke Start-Sleep -Times 1 -Exactly -ParameterFilter { $Seconds -eq 1 }
    }

    It 'throws after its bounded timeout without real sleeping' {
        Mock Invoke-DataverseRest {
            return @{ value = @(@{ localeid = 1040; statecode = 1 }) }
        }

        {
            Wait-DataverseLanguage -BaseUrl 'https://orgd0d886ca.crm.dynamics.com' `
                -LocaleId 1040 -TimeoutSeconds 0 -PollSeconds 1
        } | Should -Throw -ExpectedMessage "*Locale '1040' did not become active within 0 seconds*"

        Should -Invoke Invoke-DataverseRest -Times 1 -Exactly
        Should -Invoke Start-Sleep -Times 0 -Exactly
    }
}
