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
}
