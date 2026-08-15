# Pester tests for the Advisor Cockpit seed loader (Sprint 3, Phase 5).
# The script is dot-sourced (non-mandatory params, auto-invoke guard), so no
# Dataverse environment is touched: Get-SeedPlan and the request builders are
# validated purely in-memory.

BeforeAll {
    . "$PSScriptRoot/../seed-advisor-cockpit.ps1"
}

Describe 'seed-advisor-cockpit' {
    It 'returns one upsert group per fixture' {
        $plan = Get-SeedPlan
        @($plan).Count | Should -Be 7
        $fixtures = @($plan | ForEach-Object { $_.Fixture })
        foreach ($expected in @('measures.json', 'accounts-contacts.json', 'leads.json', 'activities.json', 'nba.json', 'policies.json', 'claims.json')) {
            $fixtures | Should -Contain $expected
        }
    }

    It 'keys every group by a non-empty alternate key and loads records' {
        foreach ($group in Get-SeedPlan) {
            @($group.AlternateKey).Count | Should -BeGreaterThan 0
            [string]($group.AlternateKey[0]) | Should -Not -BeNullOrEmpty
            $group.Count | Should -BeGreaterThan 0
            $group.EntitySet | Should -Not -BeNullOrEmpty
        }
    }

    It 'maps the measure group to the analytics projection alternate key' {
        $measure = Get-SeedPlan | Where-Object { $_.Shape -eq 'measure' }
        $measure.EntitySet | Should -Be 'crmshow_measuresnapshots'
        $measure.AlternateKey | Should -Be @('crmshow_subject', 'crmshow_metric', 'crmshow_asofdate')
    }

    It 'throws when a fixture is missing' {
        { Get-SeedPlan -FixtureRoot $TestDrive } | Should -Throw
    }

    It 'converts a measure row to its Dataverse column body' {
        $row = [pscustomobject]@{
            subject = 'GA-Bern-Mittelland'; subjectType = 'ga'; metric = 'GoalAttainment'
            region = 'Mittelland'; productLine = $null; asOfDate = '2026-06-30'
            value = 96; unit = 'percent'; externalSystem = 'databricks-mock'
        }
        $body = ConvertTo-MeasureUpsertBody -Row $row
        $body.crmshow_subject | Should -Be 'GA-Bern-Mittelland'
        $body.crmshow_metric | Should -Be 'GoalAttainment'
        $body.crmshow_value | Should -Be 96
        $body.crmshow_region | Should -Be 'Mittelland'
        $body.Contains('crmshow_productline') | Should -BeFalse
    }

    It 'builds an idempotent PATCH upsert against the alternate key' {
        $req = New-DataverseUpsertRequest -EntitySet 'crmshow_measuresnapshots' `
            -AlternateKey ([ordered]@{ crmshow_subject = 'GA-Bern-Mittelland'; crmshow_metric = 'NPS'; crmshow_asofdate = '2026-06-30' }) `
            -Body @{ crmshow_value = 42 }
        $req.Method | Should -Be 'PATCH'
        $req.Path | Should -Be "/crmshow_measuresnapshots(crmshow_subject='GA-Bern-Mittelland',crmshow_metric='NPS',crmshow_asofdate='2026-06-30')"
    }

    It 'builds one analytics upsert request per measure row' {
        $requests = @(Get-MeasureUpsertRequests)
        $measureCount = (Get-SeedPlan | Where-Object { $_.Shape -eq 'measure' }).Count
        $requests.Count | Should -Be $measureCount
        $requests | ForEach-Object { $_.Method | Should -Be 'PATCH' }
    }

    It 'keys claims and policies by the composite external-system/external-id alternate key' {
        foreach ($fixture in @('claims.json', 'policies.json')) {
            $group = Get-SeedPlan | Where-Object { $_.Fixture -eq $fixture }
            $group.AlternateKey | Should -Be @('crmshow_externalsystem', 'crmshow_externalid')
        }
    }

    It 'converts a claim row to its Dataverse column body, resolving the account by key' {
        $row = [pscustomobject]@{
            key = 'ANL-204902'; externalId = 'ANL-204902'; caseType = 'Anliegen'
            accountKey = 'ACC-BRUNNER'; productLine = 'HouseholdContents'
            title = 'Adressänderung'; channel = 'Portal'; status = 'Offen'
            openedDate = '2026-05-31'; slaHours = 26; externalSystem = 'claims-admin-mock'
        }
        $map = @{ 'ACC-BRUNNER' = '11111111-1111-1111-1111-111111111111' }
        $body = ConvertTo-ClaimUpsertBody -Row $row -AccountKeyMap $map
        $body.crmshow_name | Should -Be 'Adressänderung'
        $body.'crmshow_accountid@odata.bind' | Should -Be '/accounts(11111111-1111-1111-1111-111111111111)'
        $body.crmshow_externalsystem | Should -Be 'claims-admin-mock'
        $body.crmshow_externalid | Should -Be 'ANL-204902'
        $body.crmshow_title | Should -Be 'Adressänderung'
        $body.crmshow_status | Should -Be 'Offen'
        $body.crmshow_openeddate | Should -Be '2026-05-31'
        $body.crmshow_productline | Should -Be 'HouseholdContents'
        $body.crmshow_channel | Should -Be 'Portal'
        $body.crmshow_slahours | Should -Be 26
    }

    It 'omits optional claim fields that are absent from the fixture row' {
        $row = [pscustomobject]@{
            externalId = 'SCH-1'; accountKey = 'ACC-X'; title = 'Test'
            status = 'Offen'; openedDate = '2026-01-01'; externalSystem = 'claims-admin-mock'
        }
        $body = ConvertTo-ClaimUpsertBody -Row $row -AccountKeyMap @{ 'ACC-X' = '22222222-2222-2222-2222-222222222222' }
        $body.Contains('crmshow_productline') | Should -BeFalse
        $body.Contains('crmshow_channel') | Should -BeFalse
        $body.Contains('crmshow_slahours') | Should -BeFalse
    }

    It 'throws rather than upserting a claim whose account key is not in the map' {
        $row = [pscustomobject]@{ externalId = 'SCH-1'; accountKey = 'ACC-UNKNOWN'; title = 'Test'; status = 'Offen'; openedDate = '2026-01-01'; externalSystem = 'claims-admin-mock' }
        { ConvertTo-ClaimUpsertBody -Row $row -AccountKeyMap @{ 'ACC-X' = '33333333-3333-3333-3333-333333333333' } } |
            Should -Throw "*ACC-UNKNOWN*"
    }

    It 'builds one claim upsert request per claim row when every account key resolves' {
        $claimCount = (Get-SeedPlan | Where-Object { $_.Fixture -eq 'claims.json' }).Count
        $map = @{ 'ACC-AEBISCHER' = '44444444-4444-4444-4444-444444444444'; 'ACC-BRUNNER' = '55555555-5555-5555-5555-555555555555' }
        $requests = @(Get-ClaimUpsertRequests -AccountKeyMap $map)
        $requests.Count | Should -Be $claimCount
        $requests | ForEach-Object { $_.Method | Should -Be 'PATCH' }
        $requests[0].Path | Should -Match '^/crmshow_claimprojections\(crmshow_externalsystem=''[^'']+'',crmshow_externalid=''[^'']+''\)$'
    }

    It 'returns no claim upserts and warns when no AccountKeyMap is supplied' {
        $requests = @(Get-ClaimUpsertRequests -WarningAction SilentlyContinue)
        $requests.Count | Should -Be 0
    }

    It 'includes claim upserts alongside analytics upserts when Invoke-AdvisorCockpitSeed is given an AccountKeyMap' {
        $map = @{ 'ACC-AEBISCHER' = '44444444-4444-4444-4444-444444444444'; 'ACC-BRUNNER' = '55555555-5555-5555-5555-555555555555' }
        Mock -CommandName az -MockWith { $global:LASTEXITCODE = 0 }
        Invoke-AdvisorCockpitSeed -EnvironmentUrl 'https://example.crm.dynamics.com' -AccountKeyMap $map -Confirm:$false
        $measureCount = (Get-SeedPlan | Where-Object { $_.Shape -eq 'measure' }).Count
        $claimCount = (Get-SeedPlan | Where-Object { $_.Fixture -eq 'claims.json' }).Count
        Should -Invoke -CommandName az -Times ($measureCount + $claimCount) -Exactly
    }

    It 'builds an account key map from live accounts with a resolved crmshow_seedkey' {
        Mock -CommandName az -MockWith {
            '{"value":[{"accountid":"11111111-1111-1111-1111-111111111111","crmshow_seedkey":"ACC-BRUNNER"},{"accountid":"44444444-4444-4444-4444-444444444444","crmshow_seedkey":"ACC-AEBISCHER"}]}'
        }
        $map = Get-AccountKeyMap -EnvironmentUrl 'https://example.crm.dynamics.com'
        $map['ACC-BRUNNER'] | Should -Be '11111111-1111-1111-1111-111111111111'
        $map['ACC-AEBISCHER'] | Should -Be '44444444-4444-4444-4444-444444444444'
    }

    It 'returns an empty map when no accounts have a resolved crmshow_seedkey yet' {
        Mock -CommandName az -MockWith { '{"value":[]}' }
        $map = Get-AccountKeyMap -EnvironmentUrl 'https://example.crm.dynamics.com'
        $map.Count | Should -Be 0
    }

    It 'auto-resolves the AccountKeyMap via Get-AccountKeyMap when the caller supplies none' {
        Mock -CommandName az -MockWith { $global:LASTEXITCODE = 0 }
        Mock -CommandName Get-AccountKeyMap -MockWith {
            @{ 'ACC-AEBISCHER' = '44444444-4444-4444-4444-444444444444'; 'ACC-BRUNNER' = '55555555-5555-5555-5555-555555555555' }
        }
        Invoke-AdvisorCockpitSeed -EnvironmentUrl 'https://example.crm.dynamics.com' -Confirm:$false
        Should -Invoke -CommandName Get-AccountKeyMap -Times 1 -Exactly
        $measureCount = (Get-SeedPlan | Where-Object { $_.Shape -eq 'measure' }).Count
        $claimCount = (Get-SeedPlan | Where-Object { $_.Fixture -eq 'claims.json' }).Count
        Should -Invoke -CommandName az -Times ($measureCount + $claimCount) -Exactly
    }
}
