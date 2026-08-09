BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
    $script:contractPath = Join-Path $script:repoRoot 'solution/schema/insurance-foundation.json'
    $script:preflightPath = Join-Path $script:repoRoot 'scripts/solution/Test-InsuranceAuthoringPreflight.ps1'
    $script:childPowerShellPath = if (Get-Command pwsh -ErrorAction SilentlyContinue) {
        (Get-Command pwsh -ErrorAction Stop).Source
    }
    else {
        (Get-Command powershell -ErrorAction Stop).Source
    }
    . $script:preflightPath -EnvironmentUrl 'https://unit.crm.dynamics.com' -ContractPath $script:contractPath
    $script:contract = Get-Content -LiteralPath $script:contractPath -Raw -Encoding UTF8 |
        ConvertFrom-Json

function script:New-PreflightEntryContract {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$RootPath
    )

    $contract = [ordered]@{
        languages = @(1033, 1031, 1036, 1040)
        solutions = @('crmshow_Foundation', 'crmshow_DataModel')
        roles     = @(
            [ordered]@{ name = 'CRM Showcase Insurance Reader' },
            [ordered]@{ name = 'CRM Showcase Insurance Data Steward' }
        )
    }

    $path = Join-Path $RootPath 'insurance-authoring-entry-contract.json'
    Set-Content -LiteralPath $path -Value ($contract | ConvertTo-Json -Depth 10) -Encoding UTF8
    return $path
}

function script:New-PreflightAzShim {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$RootPath
    )
    $shimScriptPath = Join-Path $RootPath 'az.ps1'
    $shimCommandPath = Join-Path $RootPath 'az'

    $shimScript = @'
#!/usr/bin/env pwsh
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Arguments
)

$ErrorActionPreference = 'Stop'

function Get-ArgumentValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string[]]$InputArguments,

        [Parameter(Mandatory)]
        [string]$Name
    )

    $index = [Array]::IndexOf($InputArguments, $Name)
    if ($index -lt 0 -or $index -ge ($InputArguments.Count - 1)) {
        throw "Missing required argument: $Name"
    }

    return $InputArguments[$index + 1]
}

function Write-Json {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Value
    )

    $Value | ConvertTo-Json -Compress -Depth 10
}

$url = Get-ArgumentValue -InputArguments $Arguments -Name '--url'
$prefix = '/api/data/v9.2'
$prefixIndex = $url.IndexOf($prefix, [System.StringComparison]::OrdinalIgnoreCase)
if ($prefixIndex -ge 0) {
    $path = $url.Substring($prefixIndex + $prefix.Length)
}
else {
    $path = $url
}

$roles = @(
    [pscustomobject]@{
        roleid = '00000000-0000-0000-0000-000000000001'
        name   = 'CRM Showcase Insurance Reader'
    }
)
if ($env:TEST_INSURANCE_PREFLIGHT_SCENARIO -ne 'MissingRoles') {
    $roles += [pscustomobject]@{
        roleid = '00000000-0000-0000-0000-000000000002'
        name   = 'CRM Showcase Insurance Data Steward'
    }
}

switch ($path) {
    '/WhoAmI' {
        Write-Json ([pscustomobject]@{
                UserId = '11111111-1111-1111-1111-111111111111'
            })
        exit 0
    }
    '/systemusers(11111111-1111-1111-1111-111111111111)/systemuserroles_association?$select=name' {
        Write-Json ([pscustomobject]@{
                value = @(
                    [pscustomobject]@{ name = 'System Customizer' }
                )
            })
        exit 0
    }
    '/RetrieveProvisionedLanguages()' {
        Write-Json ([pscustomobject]@{
                RetrieveProvisionedLanguages = @(1033, 1031, 1036, 1040)
            })
        exit 0
    }
    '/solutions?$select=uniquename&$filter=uniquename eq ''crmshow_Foundation'' or uniquename eq ''crmshow_DataModel''' {
        Write-Json ([pscustomobject]@{
                value = @(
                    [pscustomobject]@{ uniquename = 'crmshow_Foundation' },
                    [pscustomobject]@{ uniquename = 'crmshow_DataModel' }
                )
            })
        exit 0
    }
    '/roles?$select=roleid,name&$filter=_parentrootroleid_value eq null and (name eq ''CRM Showcase Insurance Reader'' or name eq ''CRM Showcase Insurance Data Steward'')' {
        Write-Json ([pscustomobject]@{
                value = @($roles)
            })
        exit 0
    }
    default {
        Write-Error "Unexpected az rest URL: $url"
        exit 1
    }
}
'@

    $shimScript = $shimScript -replace "`r`n", "`n"
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)

    [System.IO.File]::WriteAllText($shimScriptPath, $shimScript, $utf8NoBom)
    [System.IO.File]::WriteAllText($shimCommandPath, $shimScript, $utf8NoBom)

    if ([System.IO.Path]::DirectorySeparatorChar -eq '/') {
        & chmod +x -- $shimCommandPath
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to make az shim executable: $shimCommandPath"
        }
    }
}

function script:Invoke-PreflightEntryScript {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Ready', 'MissingRoles')]
        [string]$Scenario
    )

    $testRoot = Join-Path (Get-PSDrive -Name TestDrive).Root ([guid]::NewGuid().Guid)
    $null = New-Item -ItemType Directory -Path $testRoot -Force

    $contractPath = script:New-PreflightEntryContract -RootPath $testRoot
    script:New-PreflightAzShim -RootPath $testRoot

    $previousPath = $env:PATH
    $previousScenario = [Environment]::GetEnvironmentVariable(
        'TEST_INSURANCE_PREFLIGHT_SCENARIO',
        'Process'
    )

    try {
        $pathSeparator = [System.IO.Path]::PathSeparator
        $env:PATH = if ([string]::IsNullOrEmpty($previousPath)) {
            $testRoot
        }
        else {
            "$testRoot$pathSeparator$previousPath"
        }
        $env:TEST_INSURANCE_PREFLIGHT_SCENARIO = $Scenario

        $output = & $script:childPowerShellPath `
            -NoLogo `
            -NoProfile `
            -NonInteractive `
            -File $script:preflightPath `
            -EnvironmentUrl 'https://unit.crm.dynamics.com' `
            -ContractPath $contractPath 2>&1
        $exitCode = $LASTEXITCODE
    }
    finally {
        $env:PATH = $previousPath
        if ($null -eq $previousScenario) {
            Remove-Item Env:TEST_INSURANCE_PREFLIGHT_SCENARIO -ErrorAction SilentlyContinue
        }
        else {
            $env:TEST_INSURANCE_PREFLIGHT_SCENARIO = $previousScenario
        }
    }

    return [pscustomobject]@{
        ExitCode = $exitCode
        Output   = (@($output | ForEach-Object { $_.ToString() }) -join [Environment]::NewLine).Trim()
    }
}
}

Describe 'New-PreflightAzShim' {
    It 'creates a shim that resolves ahead of any real Azure CLI on Windows and Ubuntu pwsh' {
        $testRoot = Join-Path (Get-PSDrive -Name TestDrive).Root ([guid]::NewGuid().Guid)
        $null = New-Item -ItemType Directory -Path $testRoot -Force

        script:New-PreflightAzShim -RootPath $testRoot

        $powershellShimPath = Join-Path $testRoot 'az.ps1'
        $unixShimPath = Join-Path $testRoot 'az'
        $unixShimBytes = [System.IO.File]::ReadAllBytes($unixShimPath)
        $unixShimText = [System.Text.Encoding]::UTF8.GetString($unixShimBytes)

        Test-Path -LiteralPath $powershellShimPath -PathType Leaf | Should -BeTrue
        Test-Path -LiteralPath $unixShimPath -PathType Leaf | Should -BeTrue
        $unixShimText.StartsWith("#!/usr/bin/env pwsh`n") | Should -BeTrue
        $unixShimText.Contains("`r") | Should -BeFalse
        if ($unixShimBytes.Length -ge 3) {
            ($unixShimBytes[0] -eq 0xEF -and
                $unixShimBytes[1] -eq 0xBB -and
                $unixShimBytes[2] -eq 0xBF) | Should -BeFalse
        }

        $previousPath = $env:PATH
        try {
            $pathSeparator = [System.IO.Path]::PathSeparator
            $env:PATH = if ([string]::IsNullOrEmpty($previousPath)) {
                $testRoot
            }
            else {
                "$testRoot$pathSeparator$previousPath"
            }

            $resolved = & $script:childPowerShellPath `
                -NoLogo `
                -NoProfile `
                -NonInteractive `
                -Command @'
$command = Get-Command az -ErrorAction Stop
if ([string]::IsNullOrWhiteSpace($command.Source)) {
    $command.Definition
}
else {
    $command.Source
}
'@
            $exitCode = $LASTEXITCODE
        }
        finally {
            $env:PATH = $previousPath
        }

        $exitCode | Should -Be 0
        $resolvedPath = ($resolved | Out-String).Trim()
        Split-Path -Path $resolvedPath -Parent | Should -Be $testRoot
    }
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
                "/roles?`$select=roleid,name&`$filter=_parentrootroleid_value eq null and (name eq 'CRM Showcase Insurance Reader' or name eq 'CRM Showcase Insurance Data Steward')" {
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
            "/roles?`$select=roleid,name&`$filter=_parentrootroleid_value eq null and (name eq 'CRM Showcase Insurance Reader' or name eq 'CRM Showcase Insurance Data Steward')"
        )
    }

    It 'keeps matching mocked root-role endpoint paths with escaped role names' {
        $script:availableRoles = @('CRM Showcase Insurance Reader', 'CRM Showcase Insurance Data Steward')

        $result = Invoke-InsuranceAuthoringPreflight `
            -EnvironmentUrl 'https://unit.crm.dynamics.com' `
            -Contract $script:contract

        $result.RolesReady | Should -BeTrue
        Should -Invoke Invoke-PreflightDataverseRequest -Times 1 -Exactly -ParameterFilter {
            $Path -eq "/roles?`$select=roleid,name&`$filter=_parentrootroleid_value eq null and (name eq 'CRM Showcase Insurance Reader' or name eq 'CRM Showcase Insurance Data Steward')"
        }
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

    It 'keeps State ready but reconciles when only LCID 1033 is provisioned' {
        $script:provisionedLanguages = @(1033)

        $result = Invoke-InsuranceAuthoringPreflight `
            -EnvironmentUrl 'https://unit.crm.dynamics.com' `
            -Contract $script:contract

        $result.State | Should -Be 'Ready'
        $result.LanguagesReady | Should -BeFalse
        $result.LanguageAction | Should -Be 'Reconcile'
        $result.MutationOccurred | Should -BeFalse
    }
}

Describe 'Preflight direct entry point' {
    It 'emits ready JSON and exits zero when preflight is ready' {
        $invocation = script:Invoke-PreflightEntryScript -Scenario Ready

        $invocation.ExitCode | Should -Be 0
        { $invocation.Output | ConvertFrom-Json -ErrorAction Stop } | Should -Not -Throw

        $result = $invocation.Output | ConvertFrom-Json -ErrorAction Stop
        $result.State | Should -Be 'Ready'
        $result.MutationOccurred | Should -BeFalse
    }

    It 'emits classified non-ready JSON and exits two when root roles are missing' {
        $invocation = script:Invoke-PreflightEntryScript -Scenario MissingRoles

        $invocation.ExitCode | Should -Be 2
        { $invocation.Output | ConvertFrom-Json -ErrorAction Stop } | Should -Not -Throw

        $result = $invocation.Output | ConvertFrom-Json -ErrorAction Stop
        $result.State | Should -Be 'ManualPrerequisite'
        $result.RolesReady | Should -BeFalse
        @($result.MissingRoles) | Should -Be @('CRM Showcase Insurance Data Steward')
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
