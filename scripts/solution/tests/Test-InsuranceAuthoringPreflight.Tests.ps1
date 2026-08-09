BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
    $script:contractPath = Join-Path $script:repoRoot 'solution/schema/insurance-foundation.json'
    $script:preflightPath = Join-Path $script:repoRoot 'scripts/solution/Test-InsuranceAuthoringPreflight.ps1'
    . $script:preflightPath -EnvironmentUrl 'https://unit.crm.dynamics.com' -ContractPath $script:contractPath
    $script:contract = Get-Content -LiteralPath $script:contractPath -Raw -Encoding UTF8 |
        ConvertFrom-Json
}

Describe 'Get-InsuranceAuthoringPhaseState' {
    It 'returns UnsupportedInTenant when schema capability is not proven' {
        Get-InsuranceAuthoringPhaseState `
            -SolutionsReady $false `
            -SchemaFeasible $false `
            -RolesReady $false |
            Should -Be 'UnsupportedInTenant'
    }

    It 'returns Precondition when required solutions are absent' {
        Get-InsuranceAuthoringPhaseState `
            -SolutionsReady $false `
            -SchemaFeasible $true `
            -RolesReady $true |
            Should -Be 'Precondition'
    }

    It 'returns ManualPrerequisite when a reviewed custom role is absent' {
        Get-InsuranceAuthoringPhaseState `
            -SolutionsReady $true `
            -SchemaFeasible $true `
            -RolesReady $false |
            Should -Be 'ManualPrerequisite'
    }

    It 'returns Ready when schema, solutions and roles are ready' {
        Get-InsuranceAuthoringPhaseState `
            -SolutionsReady $true `
            -SchemaFeasible $true `
            -RolesReady $true |
            Should -Be 'Ready'
    }
}

Describe 'Get-LanguagePreflightAction' {
    It 'returns Reconcile when a required language is missing' {
        Get-LanguagePreflightAction `
            -Required @(1033, 1031, 1036, 1040) `
            -Provisioned @(1033, 1031, 1036) |
            Should -Be 'Reconcile'
    }

    It 'returns None when all required languages are provisioned' {
        Get-LanguagePreflightAction `
            -Required @('1033', '1031', '1036', '1040') `
            -Provisioned @(1040, 1036, 1031, 1033) |
            Should -Be 'None'
    }
}

Describe 'Test-DemoSchemaAuthoringCapability' {
    It 'accepts System Customizer' {
        Test-DemoSchemaAuthoringCapability -AssignedRoleNames @('Basic User', 'System Customizer') |
            Should -BeTrue
    }

    It 'accepts System Administrator' {
        Test-DemoSchemaAuthoringCapability -AssignedRoleNames @('System Administrator') |
            Should -BeTrue
    }

    It 'rejects unproven roles such as Basic User' {
        Test-DemoSchemaAuthoringCapability -AssignedRoleNames @('Basic User') |
            Should -BeFalse
    }
}

Describe 'Invoke-PreflightDataverseRequest' {
    AfterEach {
        Remove-Item Function:\az -ErrorAction SilentlyContinue
    }

    It 'rejects non-GET methods' {
        {
            Invoke-PreflightDataverseRequest `
                -Method POST `
                -EnvironmentUrl 'https://unit.crm.dynamics.com' `
                -Path '/WhoAmI'
        } | Should -Throw
    }

    It 'uses az rest GET against Dataverse v9.2 and parses JSON' {
        $script:azArguments = @()
        function global:az {
            $script:azArguments = @($args)
            $global:LASTEXITCODE = 0
            '{"UserId":"11111111-1111-1111-1111-111111111111"}'
        }

        $result = Invoke-PreflightDataverseRequest `
            -Method GET `
            -EnvironmentUrl 'https://unit.crm.dynamics.com' `
            -Path '/WhoAmI'

        $result.UserId | Should -Be '11111111-1111-1111-1111-111111111111'
        $script:azArguments | Should -Be @(
            'rest',
            '--method', 'get',
            '--url', 'https://unit.crm.dynamics.com/api/data/v9.2/WhoAmI',
            '--resource', 'https://unit.crm.dynamics.com/',
            '--only-show-errors'
        )
    }

    It 'throws a transport error with the GET path and az output on nonzero exit' {
        function global:az {
            $global:LASTEXITCODE = 9
            'Permission denied'
        }

        {
            Invoke-PreflightDataverseRequest `
                -Method GET `
                -EnvironmentUrl 'https://unit.crm.dynamics.com' `
                -Path '/WhoAmI'
        } | Should -Throw '*GET /WhoAmI*Permission denied*'
    }
}

Describe 'Invoke-InsuranceAuthoringPreflight' {
    BeforeEach {
        $script:calls = [System.Collections.Generic.List[object]]::new()
        $script:userId = '11111111-1111-1111-1111-111111111111'
        $script:assignedRoleNames = @('System Customizer')
        $script:provisionedLanguages = @(1033, 1031, 1036, 1040)
        $script:availableSolutions = @('crmshow_Foundation', 'crmshow_DataModel')
        $script:availableRoles = @(
            'CRM Showcase Insurance Reader',
            'CRM Showcase Insurance Data Steward'
        )

        Mock Invoke-PreflightDataverseRequest {
            param($EnvironmentUrl, $Method, $Path)

            [void]$script:calls.Add([pscustomobject]@{
                    EnvironmentUrl = $EnvironmentUrl
                    Method         = $Method
                    Path           = $Path
                })

            switch ($Path) {
                '/WhoAmI' {
                    return [pscustomobject]@{ UserId = $script:userId }
                }
                "/systemusers($($script:userId))/systemuserroles_association?`$select=name" {
                    return [pscustomobject]@{
                        value = @($script:assignedRoleNames | ForEach-Object {
                                [pscustomobject]@{ name = $_ }
                            })
                    }
                }
                '/RetrieveProvisionedLanguages()' {
                    return [pscustomobject]@{
                        RetrieveProvisionedLanguages = @($script:provisionedLanguages)
                    }
                }
                "/solutions?`$select=uniquename&`$filter=uniquename eq 'crmshow_Foundation' or uniquename eq 'crmshow_DataModel'" {
                    return [pscustomobject]@{
                        value = @($script:availableSolutions | ForEach-Object {
                                [pscustomobject]@{ uniquename = $_ }
                            })
                    }
                }
                "/roles?`$select=roleid,name&`$filter=name eq 'CRM Showcase Insurance Reader' or name eq 'CRM Showcase Insurance Data Steward'" {
                    $index = 0
                    return [pscustomobject]@{
                        value = @($script:availableRoles | ForEach-Object {
                                $index++
                                [pscustomobject]@{
                                    roleid = '00000000-0000-0000-0000-{0:D12}' -f $index
                                    name   = $_
                                }
                            })
                    }
                }
                default {
                    throw "Unexpected mocked preflight path: $Path"
                }
            }
        }
    }

    It 'returns a ready result with GET-only transport and no mutation' {
        $result = Invoke-InsuranceAuthoringPreflight `
            -EnvironmentUrl 'https://unit.crm.dynamics.com' `
            -Contract $script:contract

        $result.State | Should -Be 'Ready'
        $result.UserId | Should -Be $script:userId
        $result.SolutionsReady | Should -BeTrue
        $result.LanguagesReady | Should -BeTrue
        $result.LanguageAction | Should -Be 'None'
        $result.RolesReady | Should -BeTrue
        @($result.AssignedRoleNames) | Should -Be @('System Customizer')
        @($result.MissingRoles) | Should -Be @()
        $result.MutationOccurred | Should -BeFalse

        Should -Invoke Invoke-PreflightDataverseRequest -Times 5 -Exactly `
            -ParameterFilter { $Method -eq 'GET' }
        Should -Invoke Invoke-PreflightDataverseRequest -Times 0 -Exactly `
            -ParameterFilter { $Method -ne 'GET' }
        @($script:calls.Path) | Should -Be @(
            '/WhoAmI',
            "/systemusers(11111111-1111-1111-1111-111111111111)/systemuserroles_association?`$select=name",
            '/RetrieveProvisionedLanguages()',
            "/solutions?`$select=uniquename&`$filter=uniquename eq 'crmshow_Foundation' or uniquename eq 'crmshow_DataModel'",
            "/roles?`$select=roleid,name&`$filter=name eq 'CRM Showcase Insurance Reader' or name eq 'CRM Showcase Insurance Data Steward'"
        )
    }

    It 'classifies a missing solution as Precondition' {
        $script:availableSolutions = @('crmshow_Foundation')

        $result = Invoke-InsuranceAuthoringPreflight `
            -EnvironmentUrl 'https://unit.crm.dynamics.com' `
            -Contract $script:contract

        $result.State | Should -Be 'Precondition'
        $result.SolutionsReady | Should -BeFalse
    }

    It 'classifies a missing reviewed role as ManualPrerequisite and reports MissingRoles' {
        $script:availableRoles = @('CRM Showcase Insurance Reader')

        $result = Invoke-InsuranceAuthoringPreflight `
            -EnvironmentUrl 'https://unit.crm.dynamics.com' `
            -Contract $script:contract

        $result.State | Should -Be 'ManualPrerequisite'
        $result.RolesReady | Should -BeFalse
        @($result.MissingRoles) | Should -Be @('CRM Showcase Insurance Data Steward')
    }

    It 'classifies Basic User as UnsupportedInTenant even when reviewed roles are absent' {
        $script:assignedRoleNames = @('Basic User')
        $script:availableRoles = @()

        $result = Invoke-InsuranceAuthoringPreflight `
            -EnvironmentUrl 'https://unit.crm.dynamics.com' `
            -Contract $script:contract

        $result.State | Should -Be 'UnsupportedInTenant'
        $result.RolesReady | Should -BeFalse
        @($result.MissingRoles) | Should -Be @(
            'CRM Showcase Insurance Reader',
            'CRM Showcase Insurance Data Steward'
        )
    }
}

Describe 'Preflight entry point safety' {
    It 'does not invoke az when dot-sourced with unit arguments' {
        $text = @'
function az { throw 'az was called' }
. '__SCRIPT__' -EnvironmentUrl 'https://unit.crm.dynamics.com' -ContractPath '__CONTRACT__'
'@.Replace('__SCRIPT__', $script:preflightPath.Replace("'", "''")).
            Replace('__CONTRACT__', $script:contractPath.Replace("'", "''"))

        & ([scriptblock]::Create($text))
    }
}
