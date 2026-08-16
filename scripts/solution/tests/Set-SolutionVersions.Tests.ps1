# Pester tests for the solution-version sync script (repo-wide ALM gap:
# manifest.json declares versions that were never pushed to live Dataverse).
# Dot-sourced (non-mandatory params, auto-invoke guard), so no Dataverse
# environment is touched by these tests.

BeforeAll {
    . "$PSScriptRoot/../Set-SolutionVersions.ps1"
}

Describe 'Set-SolutionVersions' {
    It 'loads the manifest and lists every declared solution' {
        $manifest = Get-Manifest -Path (Join-Path $PSScriptRoot '../../../solution/manifest.json') -Validate
        @($manifest.solutions).Count | Should -Be 6
        ($manifest.solutions | Where-Object { $_.uniqueName -eq 'crmshow_Sales' }).version | Should -Be '1.1.0.0'
    }

    It 'computes target versions and only flags solutions whose live version differs' {
        $solutions = @(
            [pscustomobject]@{ uniqueName = 'crmshow_Foundation'; version = '1.1.0.0' }
            [pscustomobject]@{ uniqueName = 'crmshow_Sales'; version = '1.1.0.0' }
        )
        $liveSolutions = @{
            'crmshow_Foundation' = @{ Id = '11111111-1111-1111-1111-111111111111'; Version = '1.1.0.42' }
            'crmshow_Sales'      = @{ Id = '22222222-2222-2222-2222-222222222222'; Version = '1.1.0.100' }
        }
        $updates = @(Get-SolutionVersionUpdates -Solutions $solutions -LiveSolutions $liveSolutions -Build 100)
        @($updates).Count | Should -Be 1
        $updates[0].UniqueName | Should -Be 'crmshow_Foundation'
        $updates[0].SolutionId | Should -Be '11111111-1111-1111-1111-111111111111'
        $updates[0].TargetVersion | Should -Be '1.1.0.100'
    }

    It 'returns no updates when every live version already matches the manifest-derived target' {
        $solutions = @([pscustomobject]@{ uniqueName = 'crmshow_Sales'; version = '1.1.0.0' })
        $liveSolutions = @{ 'crmshow_Sales' = @{ Id = '22222222-2222-2222-2222-222222222222'; Version = '1.1.0.100' } }
        $updates = @(Get-SolutionVersionUpdates -Solutions $solutions -LiveSolutions $liveSolutions -Build 100)
        $updates | Should -BeNullOrEmpty
    }

    It 'throws when a manifest-declared solution is not found live, rather than silently skipping it' {
        $solutions = @([pscustomobject]@{ uniqueName = 'crmshow_Missing'; version = '1.0.0.0' })
        { Get-SolutionVersionUpdates -Solutions $solutions -LiveSolutions @{} -Build 1 } | Should -Throw '*crmshow_Missing*'
    }

    It 'issues a GET and returns the parsed JSON response' {
        Mock -CommandName az -MockWith { '{"value":[{"solutionid":"33333333-3333-3333-3333-333333333333","version":"1.0.0.0","uniquename":"crmshow_Sales"}]}' }
        $result = Invoke-SolutionVersionRequest -BaseUrl 'https://example.crm.dynamics.com' -Method 'GET' -Path "/solutions?`$select=solutionid,version,uniquename&`$filter=uniquename eq 'crmshow_Sales'"
        $result.value[0].solutionid | Should -Be '33333333-3333-3333-3333-333333333333'
    }

    It 'issues a PATCH with a body and returns null' {
        Mock -CommandName az -MockWith { $global:LASTEXITCODE = 0 }
        $result = Invoke-SolutionVersionRequest -BaseUrl 'https://example.crm.dynamics.com' -Method 'PATCH' -Path '/solutions(33333333-3333-3333-3333-333333333333)' -Body @{ version = '1.1.0.100' }
        $result | Should -BeNullOrEmpty
        Should -Invoke -CommandName az -Times 1 -Exactly
    }

    It 'does not send an If-Match header on PATCH, so the update is not accidentally blocked' {
        Mock -CommandName az -MockWith { $global:LASTEXITCODE = 0 }
        Invoke-SolutionVersionRequest -BaseUrl 'https://example.crm.dynamics.com' -Method 'PATCH' -Path '/solutions(33333333-3333-3333-3333-333333333333)' -Body @{ version = '1.1.0.100' } | Out-Null
        Should -Invoke -CommandName az -Times 1 -Exactly -ParameterFilter {
            ($args -join ' ') -notmatch 'If-Match'
        }
    }

    It 'syncs every manifest solution end to end, updating only the ones that differ' {
        Mock -CommandName Invoke-SolutionVersionRequest -MockWith {
            switch -Regex ($Path) {
                "uniquename eq 'crmshow_Foundation'"  { return [pscustomobject]@{ value = @(@{ solutionid = '11111111-1111-1111-1111-111111111111'; version = '1.0.9.5'; uniquename = 'crmshow_Foundation' }) } }
                "uniquename eq 'crmshow_DataModel'"   { return [pscustomobject]@{ value = @(@{ solutionid = '22222222-2222-2222-2222-222222222222'; version = '1.2.0.100'; uniquename = 'crmshow_DataModel' }) } }
                "uniquename eq 'crmshow_Integration'" { return [pscustomobject]@{ value = @(@{ solutionid = '33333333-3333-3333-3333-333333333333'; version = '1.0.0.0'; uniquename = 'crmshow_Integration' }) } }
                "uniquename eq 'crmshow_Sales'"       { return [pscustomobject]@{ value = @(@{ solutionid = '44444444-4444-4444-4444-444444444444'; version = '1.0.0.0'; uniquename = 'crmshow_Sales' }) } }
                "uniquename eq 'crmshow_Service'"     { return [pscustomobject]@{ value = @(@{ solutionid = '55555555-5555-5555-5555-555555555555'; version = '1.0.0.0'; uniquename = 'crmshow_Service' }) } }
                "uniquename eq 'crmshow_Marketing'"   { return [pscustomobject]@{ value = @(@{ solutionid = '66666666-6666-6666-6666-666666666666'; version = '1.0.0.0'; uniquename = 'crmshow_Marketing' }) } }
                default                                { return $null }
            }
        }

        Invoke-SolutionVersionSync -EnvironmentUrl 'https://example.crm.dynamics.com' -Build 100 -Confirm:$false

        # crmshow_DataModel already matches 1.2.0.100 -> no PATCH expected for it.
        Should -Invoke -CommandName Invoke-SolutionVersionRequest -ParameterFilter { $Method -eq 'PATCH' -and $Path -eq '/solutions(22222222-2222-2222-2222-222222222222)' } -Times 0 -Exactly
        # Every other manifest solution's live version differs -> PATCH expected for each.
        Should -Invoke -CommandName Invoke-SolutionVersionRequest -ParameterFilter { $Method -eq 'PATCH' -and $Path -eq '/solutions(11111111-1111-1111-1111-111111111111)' -and $Body.version -eq '1.1.0.100' } -Times 1 -Exactly
        Should -Invoke -CommandName Invoke-SolutionVersionRequest -ParameterFilter { $Method -eq 'PATCH' -and $Path -eq '/solutions(44444444-4444-4444-4444-444444444444)' -and $Body.version -eq '1.1.0.100' } -Times 1 -Exactly
    }
}
