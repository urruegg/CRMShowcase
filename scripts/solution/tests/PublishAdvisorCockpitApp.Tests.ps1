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

    It 'resolves a known component type label to its Dataverse numeric value' {
        ConvertTo-ComponentTypeValue -Type 'Sitemap' | Should -Be 62
    }

    It 'throws on an unknown component type rather than guessing a value' {
        { ConvertTo-ComponentTypeValue -Type 'Dashboard' } | Should -Throw '*Dashboard*'
    }

    It 'builds a custom-page uniquename to GUID map from a live canvasapps query' {
        Mock -CommandName az -MockWith {
            '{"value":[{"canvasappid":"22222222-2222-2222-2222-222222222222","name":"crmshow_advisorcockpitpage"},{"canvasappid":"33333333-3333-3333-3333-333333333333","name":"crmshow_salesleaderdashboardpage"}]}'
        }
        $map = Get-CustomPageIdMap -EnvironmentUrl 'https://example.crm.dynamics.com' -PageUniqueNames @('crmshow_advisorcockpitpage', 'crmshow_salesleaderdashboardpage')
        $map['crmshow_advisorcockpitpage'] | Should -Be '22222222-2222-2222-2222-222222222222'
        $map['crmshow_salesleaderdashboardpage'] | Should -Be '33333333-3333-3333-3333-333333333333'
    }

    It 'throws when a referenced custom page does not exist yet in the environment' {
        Mock -CommandName az -MockWith { '{"value":[]}' }
        { Get-CustomPageIdMap -EnvironmentUrl 'https://example.crm.dynamics.com' -PageUniqueNames @('crmshow_missingpage') } |
            Should -Throw '*crmshow_missingpage*'
    }

    It 'builds an AddAppComponents request for every contract component not already attached' {
        $contract = Get-AdvisorCockpitAppContract -Path (Join-Path $PSScriptRoot '../../../solution/schema/advisor-cockpit-app.json')
        $resolvedIds = @{
            'crmshow_advisorcockpitsitemap'      = '44444444-4444-4444-4444-444444444444'
            'crmshow_advisorcockpitpage'         = '22222222-2222-2222-2222-222222222222'
            'crmshow_salesleaderdashboardpage'   = '33333333-3333-3333-3333-333333333333'
        }
        $req = Get-AppComponentAddRequests -Components $contract.components -ResolvedIds $resolvedIds -ExistingObjectIds @() -AppId '55555555-5555-5555-5555-555555555555'
        $req.AppId | Should -Be '55555555-5555-5555-5555-555555555555'
        @($req.Components).Count | Should -Be 3
        ($req.Components | Where-Object { $_.sitemapid -eq '44444444-4444-4444-4444-444444444444' }).'@odata.type' | Should -Be 'Microsoft.Dynamics.CRM.sitemap'
    }

    It 'excludes components already attached to the app' {
        $contract = Get-AdvisorCockpitAppContract -Path (Join-Path $PSScriptRoot '../../../solution/schema/advisor-cockpit-app.json')
        $resolvedIds = @{
            'crmshow_advisorcockpitsitemap'      = '44444444-4444-4444-4444-444444444444'
            'crmshow_advisorcockpitpage'         = '22222222-2222-2222-2222-222222222222'
            'crmshow_salesleaderdashboardpage'   = '33333333-3333-3333-3333-333333333333'
        }
        $req = Get-AppComponentAddRequests -Components $contract.components -ResolvedIds $resolvedIds -ExistingObjectIds @('44444444-4444-4444-4444-444444444444') -AppId '55555555-5555-5555-5555-555555555555'
        @($req.Components).Count | Should -Be 2
    }

    It 'returns a null AddAppComponents request when every component is already attached' {
        $contract = Get-AdvisorCockpitAppContract -Path (Join-Path $PSScriptRoot '../../../solution/schema/advisor-cockpit-app.json')
        $resolvedIds = @{
            'crmshow_advisorcockpitsitemap'      = '44444444-4444-4444-4444-444444444444'
            'crmshow_advisorcockpitpage'         = '22222222-2222-2222-2222-222222222222'
            'crmshow_salesleaderdashboardpage'   = '33333333-3333-3333-3333-333333333333'
        }
        $req = Get-AppComponentAddRequests -Components $contract.components -ResolvedIds $resolvedIds -ExistingObjectIds @('44444444-4444-4444-4444-444444444444', '22222222-2222-2222-2222-222222222222', '33333333-3333-3333-3333-333333333333') -AppId '55555555-5555-5555-5555-555555555555'
        $req | Should -BeNullOrEmpty
    }

    It 'builds an associate request for each contract security role not already associated' {
        $roleIds = @{ 'CRM Showcase Insurance Reader' = '66666666-6666-6666-6666-666666666666' }
        $reqs = @(Get-AppRoleAssociationRequests -SecurityRoles @('CRM Showcase Insurance Reader') -RoleIds $roleIds -ExistingRoleIds @() -AppId '55555555-5555-5555-5555-555555555555' -BaseUrl 'https://example.crm.dynamics.com')
        $reqs.Count | Should -Be 1
        $reqs[0].Path | Should -Be "/appmodules(55555555-5555-5555-5555-555555555555)/appmoduleroles_association/`$ref"
        $reqs[0].Body.'@odata.id' | Should -Be 'https://example.crm.dynamics.com/api/data/v9.2/roles(66666666-6666-6666-6666-666666666666)'
    }

    It 'skips a role that is already associated' {
        $roleIds = @{ 'CRM Showcase Insurance Reader' = '66666666-6666-6666-6666-666666666666' }
        $reqs = @(Get-AppRoleAssociationRequests -SecurityRoles @('CRM Showcase Insurance Reader') -RoleIds $roleIds -ExistingRoleIds @('66666666-6666-6666-6666-666666666666') -AppId '55555555-5555-5555-5555-555555555555' -BaseUrl 'https://example.crm.dynamics.com')
        $reqs.Count | Should -Be 0
    }

    It 'throws when a contract security role does not resolve to a live role id' {
        { Get-AppRoleAssociationRequests -SecurityRoles @('Unknown Role') -RoleIds @{} -ExistingRoleIds @() -AppId '55555555-5555-5555-5555-555555555555' -BaseUrl 'https://example.crm.dynamics.com' } |
            Should -Throw '*Unknown Role*'
    }

    It 'issues a GET and returns the parsed JSON response' {
        Mock -CommandName az -MockWith { '{"appmoduleid":"55555555-5555-5555-5555-555555555555"}' }
        $result = Invoke-AdvisorCockpitAppRequest -BaseUrl 'https://example.crm.dynamics.com' -Method 'GET' -Path "/appmodules(uniquename='crmshow_advisorcockpitapp')?`$select=appmoduleid"
        $result.appmoduleid | Should -Be '55555555-5555-5555-5555-555555555555'
    }

    It 'issues a PATCH with a body and returns null' {
        Mock -CommandName az -MockWith { $global:LASTEXITCODE = 0 }
        $result = Invoke-AdvisorCockpitAppRequest -BaseUrl 'https://example.crm.dynamics.com' -Method 'PATCH' -Path "/sitemaps(sitemapnameunique='x')" -Body @{ sitemapname = 'x' }
        $result | Should -BeNullOrEmpty
        Should -Invoke -CommandName az -Times 1 -Exactly
    }

    It 'does not send an If-Match header on PATCH, so upserts can still create a new record' {
        # If-Match: * on an upsert PATCH forces Dataverse to reject creates with a
        # 404 (Microsoft Learn, "Perform conditional operations using the Web API").
        Mock -CommandName az -MockWith { $global:LASTEXITCODE = 0 }
        Invoke-AdvisorCockpitAppRequest -BaseUrl 'https://example.crm.dynamics.com' -Method 'PATCH' -Path "/sitemaps(sitemapnameunique='x')" -Body @{ sitemapname = 'x' } | Out-Null
        Should -Invoke -CommandName az -Times 1 -Exactly -ParameterFilter {
            ($args -join ' ') -notmatch 'If-Match'
        }
    }

    It 'publishes the sitemap, app module, components and role association end to end' {
        Mock -CommandName Get-AdvisorCockpitAppContract -MockWith {
            # appModule.clientType/formFactor are still Task 1's unresolved
            # "<CONFIRM-IN-TASK-1>" placeholders in the real contract file (the
            # same known gap the ConvertTo-AppModuleUpsertBody test above works
            # around with a synthetic fixture) -- read the real contract
            # directly (not via the function under mock, to avoid recursing
            # into this same mock) and substitute test doubles for just those
            # two fields so the orchestrator can be exercised end to end ahead
            # of Task 1 landing.
            $contract = Get-Content -LiteralPath (Join-Path $PSScriptRoot '../../../solution/schema/advisor-cockpit-app.json') -Raw -Encoding UTF8 | ConvertFrom-Json
            $contract.appModule.clientType = 0
            $contract.appModule.formFactor = 1
            return $contract
        }
        Mock -CommandName Get-CustomPageIdMap -MockWith {
            @{
                'crmshow_advisorcockpitpage'       = '22222222-2222-2222-2222-222222222222'
                'crmshow_salesleaderdashboardpage' = '33333333-3333-3333-3333-333333333333'
            }
        }
        Mock -CommandName Invoke-AdvisorCockpitAppRequest -MockWith {
            switch -Regex ($Path) {
                "appmodules\(uniquename=" { return [pscustomobject]@{ appmoduleid = '55555555-5555-5555-5555-555555555555' } }
                "sitemaps\(sitemapnameunique=" { return [pscustomobject]@{ sitemapid = '44444444-4444-4444-4444-444444444444' } }
                '/appmodulecomponents'         { return [pscustomobject]@{ value = @() } }
                'appmoduleroles_association'   { return [pscustomobject]@{ value = @() } }
                default                        { return $null }
            }
        }

        Invoke-AdvisorCockpitAppPublish -EnvironmentUrl 'https://example.crm.dynamics.com' -PublisherId '11111111-1111-1111-1111-111111111111' -RoleIds @{ 'CRM Showcase Insurance Reader' = '66666666-6666-6666-6666-666666666666' } -Confirm:$false

        Should -Invoke -CommandName Invoke-AdvisorCockpitAppRequest -ParameterFilter { $Method -eq 'PATCH' -and $Path -match 'sitemaps' } -Times 1 -Exactly
        Should -Invoke -CommandName Invoke-AdvisorCockpitAppRequest -ParameterFilter { $Method -eq 'PATCH' -and $Path -match 'appmodules' } -Times 1 -Exactly
        Should -Invoke -CommandName Invoke-AdvisorCockpitAppRequest -ParameterFilter { $Method -eq 'POST' -and $Path -eq '/AddAppComponents' } -Times 1 -Exactly
        Should -Invoke -CommandName Invoke-AdvisorCockpitAppRequest -ParameterFilter { $Method -eq 'POST' -and $Path -match 'appmoduleroles_association' } -Times 1 -Exactly
        Should -Invoke -CommandName Invoke-AdvisorCockpitAppRequest -ParameterFilter { $Path -match 'ValidateApp' } -Times 1 -Exactly
        Should -Invoke -CommandName Invoke-AdvisorCockpitAppRequest -ParameterFilter { $Path -eq '/PublishAllXml' } -Times 1 -Exactly
    }

    It 'skips AddAppComponents entirely when every component is already attached' {
        Mock -CommandName Get-AdvisorCockpitAppContract -MockWith {
            # See the previous test's comment: substitutes real-value test
            # doubles for the still-unresolved Task 1 clientType/formFactor
            # placeholders only; everything else comes from the real contract.
            $contract = Get-Content -LiteralPath (Join-Path $PSScriptRoot '../../../solution/schema/advisor-cockpit-app.json') -Raw -Encoding UTF8 | ConvertFrom-Json
            $contract.appModule.clientType = 0
            $contract.appModule.formFactor = 1
            return $contract
        }
        Mock -CommandName Get-CustomPageIdMap -MockWith {
            @{
                'crmshow_advisorcockpitpage'       = '22222222-2222-2222-2222-222222222222'
                'crmshow_salesleaderdashboardpage' = '33333333-3333-3333-3333-333333333333'
            }
        }
        Mock -CommandName Invoke-AdvisorCockpitAppRequest -MockWith {
            switch -Regex ($Path) {
                "appmodules\(uniquename=" { return [pscustomobject]@{ appmoduleid = '55555555-5555-5555-5555-555555555555' } }
                "sitemaps\(sitemapnameunique=" { return [pscustomobject]@{ sitemapid = '44444444-4444-4444-4444-444444444444' } }
                '/appmodulecomponents'         { return [pscustomobject]@{ value = @(@{ objectid = '44444444-4444-4444-4444-444444444444' }, @{ objectid = '22222222-2222-2222-2222-222222222222' }, @{ objectid = '33333333-3333-3333-3333-333333333333' }) } }
                'appmoduleroles_association'   { return [pscustomobject]@{ value = @(@{ roleid = '66666666-6666-6666-6666-666666666666' }) } }
                default                        { return $null }
            }
        }

        Invoke-AdvisorCockpitAppPublish -EnvironmentUrl 'https://example.crm.dynamics.com' -PublisherId '11111111-1111-1111-1111-111111111111' -RoleIds @{ 'CRM Showcase Insurance Reader' = '66666666-6666-6666-6666-666666666666' } -Confirm:$false

        Should -Invoke -CommandName Invoke-AdvisorCockpitAppRequest -ParameterFilter { $Path -eq '/AddAppComponents' } -Times 0 -Exactly
        Should -Invoke -CommandName Invoke-AdvisorCockpitAppRequest -ParameterFilter { $Method -eq 'POST' -and $Path -match 'appmoduleroles_association' } -Times 0 -Exactly
    }
}
