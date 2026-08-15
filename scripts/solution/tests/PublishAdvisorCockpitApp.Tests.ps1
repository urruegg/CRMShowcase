# Pester tests for the Advisor Cockpit MDA app publisher (Sprint 3, #64).
# The script is dot-sourced (non-mandatory params, auto-invoke guard), so no
# Dataverse environment is touched by these tests.

BeforeAll {
    . "$PSScriptRoot/../publish-advisor-cockpit-app.ps1"
}

Describe 'publish-advisor-cockpit-app' {
    It 'loads the contract and validates required top-level keys are present' {
        $contract = Get-AdvisorCockpitAppContract -Path (Join-Path $PSScriptRoot '../../../solution/schema/advisor-cockpit-app.json')
        $contract.sitemap | Should -Not -BeNullOrEmpty
        $contract.appModule | Should -Not -BeNullOrEmpty
        $contract.components | Should -Not -BeNullOrEmpty
        $contract.securityRoles | Should -Not -BeNullOrEmpty
    }

    It 'throws a clear error when a required top-level key is missing' {
        $tmp = Join-Path $TestDrive 'bad-contract.json'
        '{"sitemap": {}}' | Set-Content -LiteralPath $tmp -Encoding UTF8
        { Get-AdvisorCockpitAppContract -Path $tmp } | Should -Throw '*appModule*'
    }

    It 'converts the contract sitemap section to a sitemapxml payload referencing both custom pages' {
        $contract = Get-AdvisorCockpitAppContract -Path (Join-Path $PSScriptRoot '../../../solution/schema/advisor-cockpit-app.json')
        $body = ConvertTo-SitemapUpsertBody -Sitemap $contract.sitemap
        $body.sitemapname | Should -Be 'Advisor Cockpit Sitemap'
        $body.sitemapnameunique | Should -Be 'crmshow_advisorcockpitsitemap'
        $body.isappaware | Should -BeTrue
        $body.sitemapxml | Should -Match 'crmshow_advisorcockpitpage'
        $body.sitemapxml | Should -Match 'crmshow_salesleaderdashboardpage'
        $body.sitemapxml | Should -Match '<SiteMap>'
    }

    It 'produces well-formed XML that a strict XML parser can load' {
        $contract = Get-AdvisorCockpitAppContract -Path (Join-Path $PSScriptRoot '../../../solution/schema/advisor-cockpit-app.json')
        $body = ConvertTo-SitemapUpsertBody -Sitemap $contract.sitemap
        { [xml]$body.sitemapxml } | Should -Not -Throw
    }

    It 'escapes XML-significant characters in dynamic sitemap values' {
        $sitemap = [pscustomobject]@{
            name = 'Test'; uniqueName = 'test'; isAppAware = $true
            showHome = $false; showPinned = $false; showRecents = $false; enableCollapsibleGroups = $false
            areas = @([pscustomobject]@{
                id = 'a1'; title = 'R&D <Ops>'
                groups = @([pscustomobject]@{
                    id = 'g1'; title = 'Group "One"'
                    subAreas = @([pscustomobject]@{ id = 's1'; title = "O'Brien"; pageUniqueName = 'pg1' })
                })
            })
        }
        $body = ConvertTo-SitemapUpsertBody -Sitemap $sitemap
        { [xml]$body.sitemapxml } | Should -Not -Throw
        $body.sitemapxml | Should -Match 'R&amp;D &lt;Ops&gt;'
    }

    It 'converts an appModule object to an appmodule upsert body' {
        # Synthetic fixture -- clientType/formFactor are arbitrary test doubles
        # here, NOT confirmed real Dataverse values (those remain unresolved
        # pending the blocked Task 1 research spike). The real contract still
        # carries the "<CONFIRM-IN-TASK-1>" placeholder for both fields by
        # design, so it cannot be used as this test's input.
        # TODO(Task 1): once clientType/formFactor are confirmed and the
        # placeholders in solution/schema/advisor-cockpit-app.json are
        # replaced with real values, switch this test back to loading
        # $contract.appModule via Get-AdvisorCockpitAppContract (see the
        # sitemap tests above for the pattern) instead of this fixture.
        $syntheticAppModule = [pscustomobject]@{
            name           = 'Advisor Cockpit'
            uniqueName     = 'crmshow_advisorcockpitapp'
            description    = 'Sales advisory cockpit and leader dashboard for the CRM Showcase.'
            clientType     = 0
            formFactor     = 1
            navigationType = 0
        }
        $body = ConvertTo-AppModuleUpsertBody -AppModule $syntheticAppModule -PublisherId '11111111-1111-1111-1111-111111111111'
        $body.name | Should -Be 'Advisor Cockpit'
        $body.uniquename | Should -Be 'crmshow_advisorcockpitapp'
        $body.description | Should -Be 'Sales advisory cockpit and leader dashboard for the CRM Showcase.'
        $body.clienttype | Should -Be 0
        $body.formfactor | Should -Be 1
        $body.navigationtype | Should -Be 0
        $body.'publisherid@odata.bind' | Should -Be '/publishers(11111111-1111-1111-1111-111111111111)'
    }
}
