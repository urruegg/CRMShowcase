BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
    $script:contractPath = Join-Path $script:repoRoot 'solution/schema/insurance-foundation.json'
    $script:manifestPath = Join-Path $script:repoRoot 'solution/manifest.json'
    $script:preflightPath = Join-Path $script:repoRoot 'scripts/solution/Test-InsuranceAuthoringPreflight.ps1'
    $script:childPowerShellPath = if (Get-Command pwsh -ErrorAction SilentlyContinue) {
        (Get-Command pwsh -ErrorAction Stop).Source
    }
    else {
        (Get-Command powershell -ErrorAction Stop).Source
    }
    . $script:preflightPath `
        -EnvironmentUrl 'https://unit.crm.dynamics.com' `
        -ContractPath $script:contractPath `
        -ManifestPath $script:manifestPath
    $script:contract = Get-Content -LiteralPath $script:contractPath -Raw -Encoding UTF8 |
        ConvertFrom-Json
    $script:manifest = Get-Content -LiteralPath $script:manifestPath -Raw -Encoding UTF8 |
        ConvertFrom-Json

    function script:Assert-SafeDiagnosticLine {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            [string]$Text,

            [int]$MaxLength = 600
        )

        $Text | Should -Not -Match '[\x00-\x1F\x7F-\x9F]'
        $Text | Should -Not -Match '(^|[\r\n])::'
        $Text.Length | Should -BeLessThan ($MaxLength + 1)
    }

    function script:Clone-Object {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            $InputObject
        )

        return $InputObject | ConvertTo-Json -Depth 100 | ConvertFrom-Json
    }

    function script:New-PreflightSolutionRecord {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            [string]$SolutionId,

            [Parameter(Mandatory)]
            [string]$UniqueName,

            [Parameter(Mandatory)]
            [string]$PublisherUniqueName,

            [Parameter(Mandatory)]
            [string]$CustomizationPrefix,

            [Parameter(Mandatory)]
            [int]$CustomizationOptionValuePrefix
        )

        return [pscustomobject]@{
            solutionid = $SolutionId
            uniquename = $UniqueName
            publisherid = [pscustomobject]@{
                uniquename                    = $PublisherUniqueName
                customizationprefix           = $CustomizationPrefix
                customizationoptionvalueprefix = $CustomizationOptionValuePrefix
            }
        }
    }

    function script:New-RoleVerificationResult {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            [string]$Role,

            [Parameter(Mandatory)]
            [ValidateSet('Ready', 'ManualPrerequisite', 'ContractConflict')]
            [string]$State,

            [AllowNull()]
            [object[]]$Details = @()
        )

        return [pscustomobject]@{
            Role = $Role
            State = $State
            Missing = @()
            Unexpected = @()
            WrongDepth = @()
            DuplicateExpected = @()
            DuplicateActual = @()
            Details = @($Details)
        }
    }

    function script:New-RoleVerificationSummary {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            [ValidateSet('Ready', 'ManualPrerequisite', 'ContractConflict')]
            [string]$State,

            [AllowNull()]
            [object[]]$Results = @()
        )

        return [pscustomobject]@{
            State = $State
            MutationOccurred = $false
            Results = @($Results)
        }
    }

    function script:New-PreflightEntryContract {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            [string]$RootPath
        )

        $contract = [ordered]@{
            languages = @(1033, 1031, 1036, 1040)
            solutions = @('crmshow_Foundation', 'crmshow_DataModel')
            tables = @(
                [ordered]@{
                    logicalName = 'crmshow_policyprojection'
                    schemaName = 'crmshow_PolicyProjection'
                }
            )
            roles = @(
                [ordered]@{
                    name = 'CRM Showcase Insurance Reader'
                    solution = 'crmshow_Foundation'
                    tablePrivileges = @(
                        [ordered]@{
                            table = 'account'
                            depth = 'Organization'
                            privileges = @('Read')
                        },
                        [ordered]@{
                            table = 'crmshow_policyprojection'
                            depth = 'Organization'
                            privileges = @('Read')
                        }
                    )
                    deniedPrivileges = @(
                        'Delete', 'Assign', 'Share', 'Customize',
                        'SecurityAdministration', 'BulkDelete',
                        'AuditAdministration'
                    )
                },
                [ordered]@{
                    name = 'CRM Showcase Insurance Data Steward'
                    solution = 'crmshow_Foundation'
                    tablePrivileges = @(
                        [ordered]@{
                            table = 'account'
                            depth = 'Organization'
                            privileges = @('Read')
                        },
                        [ordered]@{
                            table = 'crmshow_policyprojection'
                            depth = 'Organization'
                            privileges = @('Create', 'Read', 'Write')
                        }
                    )
                    deniedPrivileges = @(
                        'Delete', 'Assign', 'Share', 'Customize',
                        'SecurityAdministration', 'BulkDelete',
                        'AuditAdministration'
                    )
                }
            )
        }

        $path = Join-Path $RootPath 'insurance-authoring-entry-contract.json'
        Set-Content -LiteralPath $path `
            -Value ($contract | ConvertTo-Json -Depth 20) `
            -Encoding UTF8
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

    $Value | ConvertTo-Json -Compress -Depth 20
}

$method = Get-ArgumentValue -InputArguments $Arguments -Name '--method'
if ($method -cne 'get') {
    Write-Error "Unexpected method: $method"
    exit 1
}

$resource = Get-ArgumentValue -InputArguments $Arguments -Name '--resource'
if ($resource -cne 'https://unit.crm.dynamics.com/') {
    Write-Error "Unexpected resource URL: $resource"
    exit 1
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

$escape = [char]27
if ($env:TEST_INSURANCE_PREFLIGHT_SCENARIO -eq 'TransportFailure') {
    Write-Error (
        "::warning::preflight transport`r`nPermission denied`t" +
        "$escape[31mblocked$escape[0m"
    ) -ErrorAction Continue
    exit 9
}

$readerRoleId = '11111111-1111-1111-1111-111111111111'
$stewardRoleId = '22222222-2222-2222-2222-222222222222'
$foundationPublisher = [pscustomobject]@{
    uniquename = 'CRMShowcase'
    customizationprefix = 'crmshow'
    customizationoptionvalueprefix = 10000
}
$dataModelPublisher = [pscustomobject]@{
    uniquename = 'CRMShowcase'
    customizationprefix = 'crmshow'
    customizationoptionvalueprefix = 10000
}
if ($env:TEST_INSURANCE_PREFLIGHT_SCENARIO -eq 'WrongPublisher') {
    $dataModelPublisher = [pscustomobject]@{
        uniquename = 'Contoso'
        customizationprefix = 'crmshow'
        customizationoptionvalueprefix = 10000
    }
}

switch ($path) {
    '/solutions?$select=solutionid,uniquename&$expand=publisherid($select=uniquename,customizationprefix,customizationoptionvalueprefix)&$filter=uniquename eq ''crmshow_Foundation'' or uniquename eq ''crmshow_DataModel''' {
        Write-Json ([pscustomobject]@{
                value = @(
                    [pscustomobject]@{
                        solutionid = '33333333-3333-3333-3333-333333333333'
                        uniquename = 'crmshow_Foundation'
                        publisherid = $foundationPublisher
                    },
                    [pscustomobject]@{
                        solutionid = '44444444-4444-4444-4444-444444444444'
                        uniquename = 'crmshow_DataModel'
                        publisherid = $dataModelPublisher
                    }
                )
            })
        exit 0
    }
    "/roles?`$select=roleid,name&`$filter=_parentrootroleid_value eq null and name eq 'CRM Showcase Insurance Reader'" {
        Write-Json ([pscustomobject]@{
                value = @([pscustomobject]@{
                        roleid = $readerRoleId
                        name = 'CRM Showcase Insurance Reader'
                    })
            })
        exit 0
    }
    "/roles?`$select=roleid,name&`$filter=_parentrootroleid_value eq null and name eq 'CRM Showcase Insurance Data Steward'" {
        $roles = @()
        if ($env:TEST_INSURANCE_PREFLIGHT_SCENARIO -ne 'MissingRoles') {
            $roles += [pscustomobject]@{
                roleid = $stewardRoleId
                name = 'CRM Showcase Insurance Data Steward'
            }
        }
        Write-Json ([pscustomobject]@{ value = @($roles) })
        exit 0
    }
    "/solutioncomponents?`$select=solutioncomponentid&`$filter=objectid eq $readerRoleId&`$expand=solutionid(`$select=uniquename)" {
        Write-Json ([pscustomobject]@{
                value = @([pscustomobject]@{
                        solutionid = [pscustomobject]@{
                            uniquename = 'crmshow_Foundation'
                        }
                    })
            })
        exit 0
    }
    "/solutioncomponents?`$select=solutioncomponentid&`$filter=objectid eq $stewardRoleId&`$expand=solutionid(`$select=uniquename)" {
        Write-Json ([pscustomobject]@{
                value = @([pscustomobject]@{
                        solutionid = [pscustomobject]@{
                            uniquename = 'crmshow_Foundation'
                        }
                    })
            })
        exit 0
    }
    "/EntityDefinitions(LogicalName='account')?`$select=LogicalName,SchemaName,Privileges" {
        Write-Json ([pscustomobject]@{
                LogicalName = 'account'
                SchemaName = 'Account'
                Privileges = @([pscustomobject]@{
                        Name = 'prvReadAccount'
                        PrivilegeId = 'account-read'
                    })
            })
        exit 0
    }
    "/EntityDefinitions(LogicalName='crmshow_policyprojection')?`$select=LogicalName,SchemaName,Privileges" {
        Write-Json ([pscustomobject]@{
                LogicalName = 'crmshow_policyprojection'
                SchemaName = 'crmshow_PolicyProjection'
                Privileges = @(
                    [pscustomobject]@{
                        Name = 'prvCreatecrmshow_PolicyProjection'
                        PrivilegeId = 'policy-create'
                    },
                    [pscustomobject]@{
                        Name = 'prvReadcrmshow_PolicyProjection'
                        PrivilegeId = 'policy-read'
                    },
                    [pscustomobject]@{
                        Name = 'prvWritecrmshow_PolicyProjection'
                        PrivilegeId = 'policy-write'
                    }
                )
            })
        exit 0
    }
    "/RetrieveRolePrivilegesRole(RoleId=$readerRoleId)" {
        Write-Json ([pscustomobject]@{
                RolePrivileges = @(
                    [pscustomobject]@{
                        PrivilegeName = 'prvReadAccount'
                        PrivilegeId = 'account-read'
                        Depth = 'Global'
                    },
                    [pscustomobject]@{
                        PrivilegeName = 'prvReadcrmshow_PolicyProjection'
                        PrivilegeId = 'policy-read'
                        Depth = 'Global'
                    }
                )
            })
        exit 0
    }
    "/RetrieveRolePrivilegesRole(RoleId=$stewardRoleId)" {
        Write-Json ([pscustomobject]@{
                RolePrivileges = @(
                    [pscustomobject]@{
                        PrivilegeName = 'prvReadAccount'
                        PrivilegeId = 'account-read'
                        Depth = 'Global'
                    },
                    [pscustomobject]@{
                        PrivilegeName = 'prvCreatecrmshow_PolicyProjection'
                        PrivilegeId = 'policy-create'
                        Depth = 'Global'
                    },
                    [pscustomobject]@{
                        PrivilegeName = 'prvReadcrmshow_PolicyProjection'
                        PrivilegeId = 'policy-read'
                        Depth = 'Global'
                    },
                    [pscustomobject]@{
                        PrivilegeName = 'prvWritecrmshow_PolicyProjection'
                        PrivilegeId = 'policy-write'
                        Depth = 'Global'
                    }
                )
            })
        exit 0
    }
    '/WhoAmI' {
        Write-Json ([pscustomobject]@{
                UserId = '55555555-5555-5555-5555-555555555555'
            })
        exit 0
    }
    '/systemusers(55555555-5555-5555-5555-555555555555)/systemuserroles_association?$select=name' {
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
            [ValidateSet('Ready', 'MissingRoles', 'WrongPublisher', 'TransportFailure')]
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

            $previousErrorActionPreference = $ErrorActionPreference
            $ErrorActionPreference = 'Continue'
            try {
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
                $ErrorActionPreference = $previousErrorActionPreference
            }
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
    It 'returns ContractConflict ahead of every later non-ready state' {
        Get-InsuranceAuthoringPhaseState `
            -HasContractConflict $true `
            -SchemaFeasible $false `
            -SolutionsReady $false `
            -RolesReady $false |
            Should -Be 'ContractConflict'
    }

    It 'returns UnsupportedInTenant when schema capability is not proven' {
        Get-InsuranceAuthoringPhaseState `
            -HasContractConflict $false `
            -SolutionsReady $false `
            -SchemaFeasible $false `
            -RolesReady $false |
            Should -Be 'UnsupportedInTenant'
    }

    It 'returns Precondition when required solutions are absent' {
        Get-InsuranceAuthoringPhaseState `
            -HasContractConflict $false `
            -SolutionsReady $false `
            -SchemaFeasible $true `
            -RolesReady $true |
            Should -Be 'Precondition'
    }

    It 'returns ManualPrerequisite when a reviewed custom role is absent' {
        Get-InsuranceAuthoringPhaseState `
            -HasContractConflict $false `
            -SolutionsReady $true `
            -SchemaFeasible $true `
            -RolesReady $false |
            Should -Be 'ManualPrerequisite'
    }

    It 'returns Ready when schema, solutions and roles are ready' {
        Get-InsuranceAuthoringPhaseState `
            -HasContractConflict $false `
            -SolutionsReady $true `
            -SchemaFeasible $true `
            -RolesReady $true |
            Should -Be 'Ready'
    }
}

Describe 'Get-RequiredSolutionsPath' {
    It 'selects reviewed solution identity and expanded publisher ownership' {
        Get-RequiredSolutionsPath -SolutionUniqueName @(
            'crmshow_Foundation',
            'crmshow_DataModel'
        ) | Should -Be (
            "/solutions?`$select=solutionid,uniquename&" +
            "`$expand=publisherid(`$select=uniquename,customizationprefix,customizationoptionvalueprefix)&" +
            "`$filter=uniquename eq 'crmshow_Foundation' or uniquename eq 'crmshow_DataModel'"
        )
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
        Test-DemoSchemaAuthoringCapability -AssignedRoleNames @(
            'Basic User',
            'System Customizer'
        ) | Should -BeTrue
    }

    It 'accepts System Administrator' {
        Test-DemoSchemaAuthoringCapability -AssignedRoleNames @(
            'System Administrator'
        ) | Should -BeTrue
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

    It 'sanitizes hostile az output on nonzero exit' {
        $escape = [char]27
        function global:az {
            Write-Error (
                "::warning::preflight transport`r`nPermission denied`t" +
                "$escape[31mblocked$escape[0m"
            ) -ErrorAction Continue
            $global:LASTEXITCODE = 9
        }

        $message = $null
        try {
            Invoke-PreflightDataverseRequest `
                -Method GET `
                -EnvironmentUrl 'https://unit.crm.dynamics.com' `
                -Path '/WhoAmI'
            throw 'Expected transport failure.'
        }
        catch {
            $message = $_.Exception.Message
        }

        script:Assert-SafeDiagnosticLine -Text $message -MaxLength 400
        $message | Should -Match (
            [regex]::Escape(
                "Dataverse preflight transport failed (GET /WhoAmI); az rest exited with code 9."
            )
        )
        $message | Should -Match 'Output:'
        $message | Should -Match (
            [regex]::Escape(
                '::warning::preflight transport Permission denied blocked'
            )
        )
        $message | Should -Not -Match 'At line:|--method|--url|--resource'
    }
}

Describe 'Test-InsuranceAuthoringPreflightSolutions' {
    BeforeEach {
        $script:solutionsPath = (
            "/solutions?`$select=solutionid,uniquename&" +
            "`$expand=publisherid(`$select=uniquename,customizationprefix,customizationoptionvalueprefix)&" +
            "`$filter=uniquename eq 'crmshow_Foundation' or uniquename eq 'crmshow_DataModel'"
        )
        $script:solutionItems = @(
            (
                script:New-PreflightSolutionRecord `
                    -SolutionId '33333333-3333-3333-3333-333333333333' `
                    -UniqueName 'crmshow_Foundation' `
                    -PublisherUniqueName 'CRMShowcase' `
                    -CustomizationPrefix 'crmshow' `
                    -CustomizationOptionValuePrefix 10000
            ),
            (
                script:New-PreflightSolutionRecord `
                    -SolutionId '44444444-4444-4444-4444-444444444444' `
                    -UniqueName 'crmshow_DataModel' `
                    -PublisherUniqueName 'CRMShowcase' `
                    -CustomizationPrefix 'crmshow' `
                    -CustomizationOptionValuePrefix 10000
            )
        )

        Mock Invoke-PreflightDataverseRequest {
            param($EnvironmentUrl, $Method, $Path)

            if ($Method -ne 'GET') {
                throw "Unexpected method: $Method"
            }
            if ($Path -ne $script:solutionsPath) {
                throw "Unexpected solution path: $Path"
            }

            return [pscustomobject]@{
                value = @($script:solutionItems)
            }
        }
    }

    It 'returns Ready when every contract solution exists once with the manifest publisher' {
        $result = Test-InsuranceAuthoringPreflightSolutions `
            -EnvironmentUrl 'https://unit.crm.dynamics.com' `
            -Contract $script:contract `
            -Manifest $script:manifest

        $result.State | Should -Be 'Ready'
        @($result.MissingSolutions) | Should -Be @()
        @($result.SolutionConflicts) | Should -Be @()
        Should -Invoke Invoke-PreflightDataverseRequest -Times 1 -Exactly -ParameterFilter {
            $Method -eq 'GET' -and $Path -eq $script:solutionsPath
        }
    }

    It 'returns ContractConflict when a reviewed solution publisher differs from the manifest' {
        $script:solutionItems = @(
            (
                script:New-PreflightSolutionRecord `
                    -SolutionId '33333333-3333-3333-3333-333333333333' `
                    -UniqueName 'crmshow_Foundation' `
                    -PublisherUniqueName 'CRMShowcase' `
                    -CustomizationPrefix 'crmshow' `
                    -CustomizationOptionValuePrefix 10000
            ),
            (
                script:New-PreflightSolutionRecord `
                    -SolutionId '44444444-4444-4444-4444-444444444444' `
                    -UniqueName 'crmshow_DataModel' `
                    -PublisherUniqueName 'Contoso' `
                    -CustomizationPrefix 'crmshow' `
                    -CustomizationOptionValuePrefix 10000
            )
        )

        $result = Test-InsuranceAuthoringPreflightSolutions `
            -EnvironmentUrl 'https://unit.crm.dynamics.com' `
            -Contract $script:contract `
            -Manifest $script:manifest

        $result.State | Should -Be 'ContractConflict'
        @($result.MissingSolutions) | Should -Be @()
        @($result.SolutionConflicts).Count | Should -Be 1
        @($result.SolutionConflicts) | Should -Contain (
            "Solution 'crmshow_DataModel' publisher metadata does not match solution/manifest.json: publisher.uniquename expected 'CRMShowcase' but was 'Contoso'."
        )
    }

    It 'returns ContractConflict when a reviewed solution unique name is duplicated' {
        $script:solutionItems = @(
            (
                script:New-PreflightSolutionRecord `
                    -SolutionId '33333333-3333-3333-3333-333333333333' `
                    -UniqueName 'crmshow_Foundation' `
                    -PublisherUniqueName 'CRMShowcase' `
                    -CustomizationPrefix 'crmshow' `
                    -CustomizationOptionValuePrefix 10000
            ),
            (
                script:New-PreflightSolutionRecord `
                    -SolutionId '99999999-9999-9999-9999-999999999999' `
                    -UniqueName 'crmshow_Foundation' `
                    -PublisherUniqueName 'CRMShowcase' `
                    -CustomizationPrefix 'crmshow' `
                    -CustomizationOptionValuePrefix 10000
            ),
            (
                script:New-PreflightSolutionRecord `
                    -SolutionId '44444444-4444-4444-4444-444444444444' `
                    -UniqueName 'crmshow_DataModel' `
                    -PublisherUniqueName 'CRMShowcase' `
                    -CustomizationPrefix 'crmshow' `
                    -CustomizationOptionValuePrefix 10000
            )
        )

        $result = Test-InsuranceAuthoringPreflightSolutions `
            -EnvironmentUrl 'https://unit.crm.dynamics.com' `
            -Contract $script:contract `
            -Manifest $script:manifest

        $result.State | Should -Be 'ContractConflict'
        @($result.SolutionConflicts) | Should -Contain (
            "Solution 'crmshow_Foundation' returned 2 records; expected exactly one reviewed solution."
        )
    }
}

Describe 'Invoke-InsuranceAuthoringPreflight' {
    BeforeEach {
        $script:calls = [System.Collections.Generic.List[object]]::new()
        $script:userId = '11111111-1111-1111-1111-111111111111'
        $script:assignedRoleNames = @('System Customizer')
        $script:provisionedLanguages = @(1033, 1031, 1036, 1040)
        $script:solutionsPath = (
            "/solutions?`$select=solutionid,uniquename&" +
            "`$expand=publisherid(`$select=uniquename,customizationprefix,customizationoptionvalueprefix)&" +
            "`$filter=uniquename eq 'crmshow_Foundation' or uniquename eq 'crmshow_DataModel'"
        )
        $script:solutionItems = @(
            (
                script:New-PreflightSolutionRecord `
                    -SolutionId '33333333-3333-3333-3333-333333333333' `
                    -UniqueName 'crmshow_Foundation' `
                    -PublisherUniqueName 'CRMShowcase' `
                    -CustomizationPrefix 'crmshow' `
                    -CustomizationOptionValuePrefix 10000
            ),
            (
                script:New-PreflightSolutionRecord `
                    -SolutionId '44444444-4444-4444-4444-444444444444' `
                    -UniqueName 'crmshow_DataModel' `
                    -PublisherUniqueName 'CRMShowcase' `
                    -CustomizationPrefix 'crmshow' `
                    -CustomizationOptionValuePrefix 10000
            )
        )
        $script:roleVerification = script:New-RoleVerificationSummary `
            -State 'Ready' `
            -Results @(
                (
                    script:New-RoleVerificationResult `
                        -Role 'CRM Showcase Insurance Reader' `
                        -State 'Ready'
                ),
                (
                    script:New-RoleVerificationResult `
                        -Role 'CRM Showcase Insurance Data Steward' `
                        -State 'Ready'
                )
            )

        Mock Invoke-PreflightDataverseRequest {
            param($EnvironmentUrl, $Method, $Path)

            [void]$script:calls.Add([pscustomobject]@{
                    EnvironmentUrl = $EnvironmentUrl
                    Method         = $Method
                    Path           = $Path
                })

            switch ($Path) {
                $script:solutionsPath {
                    return [pscustomobject]@{
                        value = @($script:solutionItems)
                    }
                }
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
                default {
                    throw "Unexpected mocked preflight path: $Path"
                }
            }
        }

        Mock Invoke-InsuranceSecurityRoleVerification {
            param($EnvironmentUrl, $Contract)

            return $script:roleVerification
        }
    }

    It 'returns a ready result with GET-only transport, manifest ownership, and no mutation' {
        $result = Invoke-InsuranceAuthoringPreflight `
            -EnvironmentUrl 'https://unit.crm.dynamics.com' `
            -Contract $script:contract `
            -Manifest $script:manifest

        $result.State | Should -Be 'Ready'
        $result.UserId | Should -Be $script:userId
        $result.SolutionsReady | Should -BeTrue
        @($result.MissingSolutions) | Should -Be @()
        @($result.SolutionConflicts) | Should -Be @()
        $result.LanguagesReady | Should -BeTrue
        $result.LanguageAction | Should -Be 'None'
        $result.RolesReady | Should -BeTrue
        @($result.AssignedRoleNames) | Should -Be @('System Customizer')
        @($result.MissingRoles) | Should -Be @()
        @($result.RoleConflicts) | Should -Be @()
        $result.MutationOccurred | Should -BeFalse

        Should -Invoke Invoke-PreflightDataverseRequest -Times 4 -Exactly `
            -ParameterFilter { $Method -eq 'GET' }
        Should -Invoke Invoke-PreflightDataverseRequest -Times 0 -Exactly `
            -ParameterFilter { $Method -ne 'GET' }
        Should -Invoke Invoke-InsuranceSecurityRoleVerification -Times 1 -Exactly
        @($script:calls.Path) | Should -Be @(
            $script:solutionsPath,
            '/WhoAmI',
            "/systemusers(11111111-1111-1111-1111-111111111111)/systemuserroles_association?`$select=name",
            '/RetrieveProvisionedLanguages()'
        )
    }

    It 'classifies a missing solution as Precondition' {
        $script:solutionItems = @(
            script:New-PreflightSolutionRecord `
                -SolutionId '33333333-3333-3333-3333-333333333333' `
                -UniqueName 'crmshow_Foundation' `
                -PublisherUniqueName 'CRMShowcase' `
                -CustomizationPrefix 'crmshow' `
                -CustomizationOptionValuePrefix 10000
        )

        $result = Invoke-InsuranceAuthoringPreflight `
            -EnvironmentUrl 'https://unit.crm.dynamics.com' `
            -Contract $script:contract `
            -Manifest $script:manifest

        $result.State | Should -Be 'Precondition'
        $result.SolutionsReady | Should -BeFalse
        @($result.MissingSolutions) | Should -Be @('crmshow_DataModel')
    }

    It 'classifies a missing reviewed role as ManualPrerequisite and reports MissingRoles' {
        $script:roleVerification = script:New-RoleVerificationSummary `
            -State 'ManualPrerequisite' `
            -Results @(
                (
                    script:New-RoleVerificationResult `
                        -Role 'CRM Showcase Insurance Reader' `
                        -State 'Ready'
                ),
                (
                    script:New-RoleVerificationResult `
                        -Role 'CRM Showcase Insurance Data Steward' `
                        -State 'ManualPrerequisite' `
                        -Details @(
                            "Root security role 'CRM Showcase Insurance Data Steward' was not found."
                        )
                )
            )

        $result = Invoke-InsuranceAuthoringPreflight `
            -EnvironmentUrl 'https://unit.crm.dynamics.com' `
            -Contract $script:contract `
            -Manifest $script:manifest

        $result.State | Should -Be 'ManualPrerequisite'
        $result.RolesReady | Should -BeFalse
        @($result.MissingRoles) | Should -Be @('CRM Showcase Insurance Data Steward')
        @($result.RoleConflicts) | Should -Be @()
    }

    It 'classifies Basic User as UnsupportedInTenant even when reviewed roles are absent' {
        $script:assignedRoleNames = @('Basic User')
        $script:roleVerification = script:New-RoleVerificationSummary `
            -State 'ManualPrerequisite' `
            -Results @(
                (
                    script:New-RoleVerificationResult `
                        -Role 'CRM Showcase Insurance Reader' `
                        -State 'ManualPrerequisite' `
                        -Details @(
                            "Root security role 'CRM Showcase Insurance Reader' was not found."
                        )
                ),
                (
                    script:New-RoleVerificationResult `
                        -Role 'CRM Showcase Insurance Data Steward' `
                        -State 'ManualPrerequisite' `
                        -Details @(
                            "Root security role 'CRM Showcase Insurance Data Steward' was not found."
                        )
                )
            )

        $result = Invoke-InsuranceAuthoringPreflight `
            -EnvironmentUrl 'https://unit.crm.dynamics.com' `
            -Contract $script:contract `
            -Manifest $script:manifest

        $result.State | Should -Be 'UnsupportedInTenant'
        $result.RolesReady | Should -BeFalse
        @($result.MissingRoles) | Should -Be @(
            'CRM Showcase Insurance Data Steward',
            'CRM Showcase Insurance Reader'
        )
    }

    It 'keeps State ready but reconciles when only LCID 1033 is provisioned' {
        $script:provisionedLanguages = @(1033)

        $result = Invoke-InsuranceAuthoringPreflight `
            -EnvironmentUrl 'https://unit.crm.dynamics.com' `
            -Contract $script:contract `
            -Manifest $script:manifest

        $result.State | Should -Be 'Ready'
        $result.LanguagesReady | Should -BeFalse
        $result.LanguageAction | Should -Be 'Reconcile'
        $result.MutationOccurred | Should -BeFalse
    }

    It 'returns ContractConflict and stops before schema or language checks on publisher mismatch' {
        $script:solutionItems = @(
            (
                script:New-PreflightSolutionRecord `
                    -SolutionId '33333333-3333-3333-3333-333333333333' `
                    -UniqueName 'crmshow_Foundation' `
                    -PublisherUniqueName 'CRMShowcase' `
                    -CustomizationPrefix 'crmshow' `
                    -CustomizationOptionValuePrefix 10000
            ),
            (
                script:New-PreflightSolutionRecord `
                    -SolutionId '44444444-4444-4444-4444-444444444444' `
                    -UniqueName 'crmshow_DataModel' `
                    -PublisherUniqueName 'Contoso' `
                    -CustomizationPrefix 'crmshow' `
                    -CustomizationOptionValuePrefix 10000
            )
        )

        $result = Invoke-InsuranceAuthoringPreflight `
            -EnvironmentUrl 'https://unit.crm.dynamics.com' `
            -Contract $script:contract `
            -Manifest $script:manifest

        $result.State | Should -Be 'ContractConflict'
        @($result.SolutionConflicts) | Should -Contain (
            "Solution 'crmshow_DataModel' publisher metadata does not match solution/manifest.json: publisher.uniquename expected 'CRMShowcase' but was 'Contoso'."
        )
        @($result.AssignedRoleNames) | Should -Be @()
        $result.LanguageAction | Should -Be 'Skipped'
        Should -Invoke Invoke-PreflightDataverseRequest -Times 0 -Exactly -ParameterFilter {
            $Path -eq '/WhoAmI'
        }
        Should -Invoke Invoke-PreflightDataverseRequest -Times 0 -Exactly -ParameterFilter {
            $Path -eq '/RetrieveProvisionedLanguages()'
        }
    }

    It 'returns ContractConflict and exposes role conflict details before schema or language checks' {
        $script:roleVerification = script:New-RoleVerificationSummary `
            -State 'ContractConflict' `
            -Results @(
                (
                    script:New-RoleVerificationResult `
                        -Role 'CRM Showcase Insurance Reader' `
                        -State 'Ready'
                ),
                (
                    script:New-RoleVerificationResult `
                        -Role 'CRM Showcase Insurance Data Steward' `
                        -State 'ContractConflict' `
                        -Details @(
                            "Role 'CRM Showcase Insurance Data Steward' reviewed-solution membership expected 'crmshow_Foundation'; actual reviewed membership was 'crmshow_Foundation, crmshow_DataModel'."
                        )
                )
            )

        $result = Invoke-InsuranceAuthoringPreflight `
            -EnvironmentUrl 'https://unit.crm.dynamics.com' `
            -Contract $script:contract `
            -Manifest $script:manifest

        $result.State | Should -Be 'ContractConflict'
        $result.RolesReady | Should -BeFalse
        @($result.RoleConflicts) | Should -Be @(
            "Role 'CRM Showcase Insurance Data Steward': Role 'CRM Showcase Insurance Data Steward' reviewed-solution membership expected 'crmshow_Foundation'; actual reviewed membership was 'crmshow_Foundation, crmshow_DataModel'."
        )
        Should -Invoke Invoke-PreflightDataverseRequest -Times 0 -Exactly -ParameterFilter {
            $Path -eq '/WhoAmI'
        }
        Should -Invoke Invoke-PreflightDataverseRequest -Times 0 -Exactly -ParameterFilter {
            $Path -eq '/RetrieveProvisionedLanguages()'
        }
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

    It 'emits classified conflict JSON and exits three on reviewed publisher conflict' {
        $invocation = script:Invoke-PreflightEntryScript -Scenario WrongPublisher

        $invocation.ExitCode | Should -Be 3
        { $invocation.Output | ConvertFrom-Json -ErrorAction Stop } | Should -Not -Throw

        $result = $invocation.Output | ConvertFrom-Json -ErrorAction Stop
        $result.State | Should -Be 'ContractConflict'
        $result.MutationOccurred | Should -BeFalse
        @($result.SolutionConflicts).Count | Should -Be 1
    }

    It 'emits a single safe error line and exits one on hostile az transport failure' {
        $invocation = script:Invoke-PreflightEntryScript -Scenario TransportFailure

        $invocation.ExitCode | Should -Be 1
        script:Assert-SafeDiagnosticLine -Text $invocation.Output -MaxLength 500
        $invocation.Output | Should -Match 'Dataverse preflight transport failed'
        $invocation.Output | Should -Match '/solutions\?\$select=solutionid,uniquename'
        $invocation.Output | Should -Match 'Output:'
        $invocation.Output | Should -Match (
            [regex]::Escape(
                '::warning::preflight transport Permission denied blocked'
            )
        )
        $invocation.Output | Should -Not -Match 'At line:|--method|--url|--resource'
    }
}

Describe 'Preflight entry point safety' {
    It 'does not invoke az when dot-sourced with unit arguments' {
        $text = @'
function az { throw 'az was called' }
. '__SCRIPT__' -EnvironmentUrl 'https://unit.crm.dynamics.com' -ContractPath '__CONTRACT__' -ManifestPath '__MANIFEST__'
'@.Replace('__SCRIPT__', $script:preflightPath.Replace("'", "''")).
            Replace('__CONTRACT__', $script:contractPath.Replace("'", "''")).
            Replace('__MANIFEST__', $script:manifestPath.Replace("'", "''"))

        & ([scriptblock]::Create($text))
    }
}
