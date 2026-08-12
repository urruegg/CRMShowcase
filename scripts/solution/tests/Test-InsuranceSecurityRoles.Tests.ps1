BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
    $script:contractPath = Join-Path $script:repoRoot 'solution/schema/insurance-foundation.json'
    $script:verifierPath = Join-Path $script:repoRoot 'scripts/solution/Test-InsuranceSecurityRoles.ps1'
    $script:childPowerShellPath = if (Get-Command pwsh -ErrorAction SilentlyContinue) {
        (Get-Command pwsh -ErrorAction Stop).Source
    }
    else {
        (Get-Command powershell -ErrorAction Stop).Source
    }
    . $script:verifierPath -EnvironmentUrl 'https://unit.crm.dynamics.com' -ContractPath $script:contractPath
    $script:contract = Get-Content -LiteralPath $script:contractPath -Raw -Encoding UTF8 |
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

    function script:Get-SchemaMap {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            $Contract
        )

        $map = @{
            account = 'Account'
            contact = 'Contact'
        }

        foreach ($table in @($Contract.tables)) {
            $map[[string]$table.logicalName] = [string]$table.schemaName
        }

        return $map
    }

    function script:Get-MetadataPrivilegeMap {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            $Contract
        )

        $schemaMap = script:Get-SchemaMap -Contract $Contract
        $map = @{}

        foreach ($role in @($Contract.roles)) {
            foreach ($tablePrivilege in @($role.tablePrivileges)) {
                $logicalName = [string]$tablePrivilege.table
                if (-not $map.ContainsKey($logicalName)) {
                    $map[$logicalName] = @()
                }

                $schemaName = [string]$schemaMap[$logicalName]
                foreach ($verb in @($tablePrivilege.privileges)) {
                    $map[$logicalName] += [pscustomobject]@{
                        Name = "prv$verb$schemaName"
                        PrivilegeId = "$logicalName-$verb"
                    }
                }
            }
        }

        foreach ($logicalName in @($map.Keys)) {
            $unique = @()
            foreach ($privilege in @($map[$logicalName])) {
                if (@($unique.Name | Where-Object { $_ -ceq $privilege.Name }).Count -gt 0) {
                    continue
                }

                $unique += $privilege
            }

            $map[$logicalName] = @($unique)
        }

        return $map
    }

    function script:Get-ExpectedPrivilegesForRole {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            $Role,

            [Parameter(Mandatory)]
            $Contract
        )

        $schemaMap = script:Get-SchemaMap -Contract $Contract
        $expected = foreach ($tablePrivilege in @($Role.tablePrivileges)) {
            $schemaName = [string]$schemaMap[[string]$tablePrivilege.table]
            foreach ($verb in @($tablePrivilege.privileges)) {
                [pscustomobject]@{
                    Name = "prv$verb$schemaName"
                    PrivilegeId = "$($tablePrivilege.table)-$verb"
                    Depth = 'Global'
                }
            }
        }

        return @($expected)
    }

    function script:Get-ActualRolePrivileges {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            $Role,

            [Parameter(Mandatory)]
            $Contract
        )

        return @(
            script:Get-ExpectedPrivilegesForRole -Role $Role -Contract $Contract |
                ForEach-Object {
                    [pscustomobject]@{
                        PrivilegeName = $_.Name
                        PrivilegeId = $_.PrivilegeId
                        Depth = $_.Depth
                    }
                }
        )
    }

    function script:New-SecurityRolesEntryContract {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            [string]$RootPath
        )

        $contract = [ordered]@{
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

        $path = Join-Path $RootPath 'insurance-security-roles-entry-contract.json'
        Set-Content -LiteralPath $path `
            -Value ($contract | ConvertTo-Json -Depth 20) `
            -Encoding UTF8
        return $path
    }

    function script:New-SecurityRolesAzShim {
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
if ($env:TEST_INSURANCE_SECURITY_ROLES_SCENARIO -eq 'TransportFailure') {
    Write-Error (
        "::warning::security roles transport`r`nPermission denied`t" +
        "$escape[31mblocked$escape[0m"
    ) -ErrorAction Continue
    exit 9
}

$readerRoleId = '11111111-1111-1111-1111-111111111111'
$stewardRoleId = '22222222-2222-2222-2222-222222222222'

switch ($path) {
    "/roles?`$select=roleid,name,_parentrootroleid_value&`$filter=name eq 'CRM Showcase Insurance Reader'" {
        # Self-referencing root shape (parentrootroleid == roleid), which the
        # previous `eq null` predicate failed to detect.
        Write-Json ([pscustomobject]@{
                value = @([pscustomobject]@{
                        roleid = $readerRoleId
                        name = 'CRM Showcase Insurance Reader'
                        _parentrootroleid_value = $readerRoleId
                    })
            })
        exit 0
    }
    "/roles?`$select=roleid,name,_parentrootroleid_value&`$filter=name eq 'CRM Showcase Insurance Data Steward'" {
        $roles = @()
        if ($env:TEST_INSURANCE_SECURITY_ROLES_SCENARIO -ne 'MissingRole') {
            $resolvedRoleName = if ($env:TEST_INSURANCE_SECURITY_ROLES_SCENARIO -eq 'LowerCaseRoleName') {
                'crm showcase insurance data steward'
            }
            else {
                'CRM Showcase Insurance Data Steward'
            }
            $roles += [pscustomobject]@{
                roleid = $stewardRoleId
                name = $resolvedRoleName
                _parentrootroleid_value = $null
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

    function script:Invoke-SecurityRolesEntryScript {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            [ValidateSet('Ready', 'MissingRole', 'LowerCaseRoleName', 'TransportFailure')]
            [string]$Scenario
        )

        $testRoot = Join-Path (Get-PSDrive -Name TestDrive).Root ([guid]::NewGuid().Guid)
        $null = New-Item -ItemType Directory -Path $testRoot -Force

        $contractPath = script:New-SecurityRolesEntryContract -RootPath $testRoot
        script:New-SecurityRolesAzShim -RootPath $testRoot

        $previousPath = $env:PATH
        $previousScenario = [Environment]::GetEnvironmentVariable(
            'TEST_INSURANCE_SECURITY_ROLES_SCENARIO',
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
            $env:TEST_INSURANCE_SECURITY_ROLES_SCENARIO = $Scenario

            $previousErrorActionPreference = $ErrorActionPreference
            $ErrorActionPreference = 'Continue'
            try {
                $output = & $script:childPowerShellPath `
                    -NoLogo `
                    -NoProfile `
                    -NonInteractive `
                    -File $script:verifierPath `
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
                Remove-Item Env:TEST_INSURANCE_SECURITY_ROLES_SCENARIO `
                    -ErrorAction SilentlyContinue
            }
            else {
                $env:TEST_INSURANCE_SECURITY_ROLES_SCENARIO = $previousScenario
            }
        }

        return [pscustomobject]@{
            ExitCode = $exitCode
            Output = (@($output | ForEach-Object { $_.ToString() }) -join [Environment]::NewLine).Trim()
        }
    }
}

Describe 'Invoke-InsuranceSecurityRoleDataverseRequest' {
    AfterEach {
        Remove-Item Function:\az -ErrorAction SilentlyContinue
    }

    It 'rejects non-GET methods' {
        {
            Invoke-InsuranceSecurityRoleDataverseRequest `
                -Method POST `
                -EnvironmentUrl 'https://unit.crm.dynamics.com' `
                -Path '/roles'
        } | Should -Throw
    }

    It 'uses az rest GET against Dataverse v9.2 and parses JSON' {
        $script:azArguments = @()
        function global:az {
            $script:azArguments = @($args)
            $global:LASTEXITCODE = 0
            '{"value":[{"roleid":"11111111-1111-1111-1111-111111111111","name":"Reader"}]}'
        }

        $result = Invoke-InsuranceSecurityRoleDataverseRequest `
            -Method GET `
            -EnvironmentUrl 'https://unit.crm.dynamics.com' `
            -Path '/roles'

        $result.value[0].roleid | Should -Be '11111111-1111-1111-1111-111111111111'
        $script:azArguments | Should -Be @(
            'rest',
            '--method', 'get',
            '--url', 'https://unit.crm.dynamics.com/api/data/v9.2/roles',
            '--resource', 'https://unit.crm.dynamics.com/',
            '--only-show-errors'
        )
    }

    It 'sanitizes hostile az output on nonzero exit' {
        $escape = [char]27
        function global:az {
            Write-Error (
                "::warning::security roles transport`r`nPermission denied`t" +
                "$escape[31mblocked$escape[0m"
            ) -ErrorAction Continue
            $global:LASTEXITCODE = 9
        }

        $message = $null
        try {
            Invoke-InsuranceSecurityRoleDataverseRequest `
                -Method GET `
                -EnvironmentUrl 'https://unit.crm.dynamics.com' `
                -Path '/roles'
            throw 'Expected transport failure.'
        }
        catch {
            $message = $_.Exception.Message
        }

        script:Assert-SafeDiagnosticLine -Text $message -MaxLength 400
        $message | Should -Match (
            [regex]::Escape(
                "Dataverse security-role verification failed (GET /roles); az rest exited with code 9."
            )
        )
        $message | Should -Match 'Output:'
        $message | Should -Match (
            [regex]::Escape(
                '::warning::security roles transport Permission denied blocked'
            )
        )
        $message | Should -Not -Match 'At line:|--method|--url|--resource'
    }
}

Describe 'Compare-InsuranceRolePrivileges' {
    It 'reports Ready when exact privileges and depth match' {
        $result = Compare-InsuranceRolePrivileges `
            -RoleName 'Reader' `
            -Expected @([pscustomobject]@{
                    Name = 'prvReadAccount'
                    Depth = 'Global'
                }) `
            -Actual @([pscustomobject]@{
                    Name = 'prvReadAccount'
                    Depth = 'Global'
                })

        $result.State | Should -Be 'Ready'
        @($result.Missing) | Should -Be @()
        @($result.Unexpected) | Should -Be @()
        @($result.WrongDepth) | Should -Be @()
    }

    It 'reports missing expected privileges' {
        $result = Compare-InsuranceRolePrivileges `
            -RoleName 'Reader' `
            -Expected @(
                [pscustomobject]@{ Name = 'prvReadAccount'; Depth = 'Global' },
                [pscustomobject]@{ Name = 'prvReadContact'; Depth = 'Global' }
            ) `
            -Actual @([pscustomobject]@{
                    Name = 'prvReadAccount'
                    Depth = 'Global'
                })

        $result.State | Should -Be 'ContractConflict'
        @($result.Missing) | Should -Be @('prvReadContact')
    }

    It 'fails closed for an unexpected privilege' {
        $result = Compare-InsuranceRolePrivileges `
            -RoleName 'Reader' `
            -Expected @([pscustomobject]@{
                    Name = 'prvReadAccount'
                    Depth = 'Global'
                }) `
            -Actual @(
                [pscustomobject]@{ Name = 'prvReadAccount'; Depth = 'Global' },
                [pscustomobject]@{ Name = 'prvDeleteAccount'; Depth = 'Global' }
            )

        $result.State | Should -Be 'ContractConflict'
        @($result.Unexpected) | Should -Be @('prvDeleteAccount')
    }

    It 'ignores platform-managed SharePoint baseline privileges' {
        $result = Compare-InsuranceRolePrivileges `
            -RoleName 'Reader' `
            -Expected @([pscustomobject]@{
                    Name = 'prvReadAccount'
                    Depth = 'Global'
                }) `
            -Actual @(
                [pscustomobject]@{ Name = 'prvReadAccount'; Depth = 'Global' },
                [pscustomobject]@{ Name = 'prvReadSharePointDocument'; Depth = 'Global' },
                [pscustomobject]@{ Name = 'prvReadSharePointData'; Depth = 'Global' },
                [pscustomobject]@{ Name = 'prvWriteSharePointData'; Depth = 'Global' },
                [pscustomobject]@{ Name = 'prvCreateSharePointData'; Depth = 'Global' }
            )

        $result.State | Should -Be 'Ready'
        @($result.Unexpected) | Should -Be @()
        @($result.WrongDepth) | Should -Be @()
    }

    It 'reports wrong depth per privilege entry' {
        $result = Compare-InsuranceRolePrivileges `
            -RoleName 'Reader' `
            -Expected @([pscustomobject]@{
                    Name = 'prvReadAccount'
                    Depth = 'Global'
                }) `
            -Actual @([pscustomobject]@{
                    Name = 'prvReadAccount'
                    Depth = 'Local'
                })

        $result.State | Should -Be 'ContractConflict'
        @($result.WrongDepth).Count | Should -Be 1
        $result.WrongDepth[0].Name | Should -Be 'prvReadAccount'
        $result.WrongDepth[0].ExpectedDepth | Should -Be 'Global'
        $result.WrongDepth[0].ActualDepth | Should -Be 'Local'
    }

    It 'treats duplicate actual privilege names as a conflict' {
        $result = Compare-InsuranceRolePrivileges `
            -RoleName 'Reader' `
            -Expected @([pscustomobject]@{
                    Name = 'prvReadAccount'
                    Depth = 'Global'
                }) `
            -Actual @(
                [pscustomobject]@{ Name = 'prvReadAccount'; Depth = 'Global' },
                [pscustomobject]@{ Name = 'prvReadAccount'; Depth = 'Global' }
            )

        $result.State | Should -Be 'ContractConflict'
        @($result.DuplicateActual) | Should -Be @('prvReadAccount')
    }

    It 'treats duplicate expected privilege names as a conflict' {
        $result = Compare-InsuranceRolePrivileges `
            -RoleName 'Reader' `
            -Expected @(
                [pscustomobject]@{ Name = 'prvReadAccount'; Depth = 'Global' },
                [pscustomobject]@{ Name = 'prvReadAccount'; Depth = 'Global' }
            ) `
            -Actual @([pscustomobject]@{
                    Name = 'prvReadAccount'
                    Depth = 'Global'
                })

        $result.State | Should -Be 'ContractConflict'
        @($result.DuplicateExpected) | Should -Be @('prvReadAccount')
    }
}

Describe 'OData query helpers' {
    It 'escapes root role names and queries by name for client-side root selection' {
        Get-InsuranceSecurityRolePath -RoleName "Reader's Role" |
            Should -Be (
                "/roles?`$select=roleid,name,_parentrootroleid_value&" +
                "`$filter=name eq 'Reader''s Role'"
            )
    }

    It 'escapes logical names for entity privilege metadata lookup' {
        Get-InsuranceRoleEntityPrivilegesPath -LogicalName "crmshow_o'reilly" |
            Should -Be (
                "/EntityDefinitions(LogicalName='crmshow_o''reilly')?" +
                "`$select=LogicalName,SchemaName,Privileges"
            )
    }
}

Describe 'Test-InsuranceSecurityRole' {
    BeforeEach {
        $script:calls = [System.Collections.Generic.List[object]]::new()
        $script:role = script:Clone-Object -InputObject $script:contract.roles[1]
        $script:roleId = '22222222-2222-2222-2222-222222222222'
        $script:schemaMap = script:Get-SchemaMap -Contract $script:contract
        $script:metadataPrivileges = script:Get-MetadataPrivilegeMap -Contract $script:contract
        $script:actualPrivileges = script:Get-ActualRolePrivileges `
            -Role $script:role `
            -Contract $script:contract
        $script:rootRoleItems = @([pscustomobject]@{
                roleid = $script:roleId
                name = $script:role.name
            })
        $script:solutionNames = @($script:role.solution)

        Mock Invoke-InsuranceSecurityRoleDataverseRequest {
            param($EnvironmentUrl, $Method, $Path)

            [void]$script:calls.Add([pscustomobject]@{
                    EnvironmentUrl = $EnvironmentUrl
                    Method = $Method
                    Path = $Path
                })

            if ($Method -eq 'GET' -and $Path -like '/roles?*') {
                return [pscustomobject]@{ value = @($script:rootRoleItems) }
            }
            if ($Method -eq 'GET' -and $Path -like '/solutioncomponents?*') {
                return [pscustomobject]@{
                    value = @($script:solutionNames | ForEach-Object {
                            [pscustomobject]@{
                                solutionid = [pscustomobject]@{
                                    uniquename = $_
                                }
                            }
                        })
                }
            }
            if ($Method -eq 'GET' -and
                $Path.StartsWith("/EntityDefinitions(LogicalName='", [System.StringComparison]::Ordinal)) {
                $logicalName = [regex]::Match(
                    $Path,
                    "^/EntityDefinitions\(LogicalName='((?:[^']|'')*)'\)"
                ).Groups[1].Value.Replace("''", "'")
                return [pscustomobject]@{
                    LogicalName = $logicalName
                    SchemaName = [string]$script:schemaMap[$logicalName]
                    Privileges = @($script:metadataPrivileges[$logicalName])
                }
            }
            if ($Method -eq 'GET' -and
                $Path -eq "/RetrieveRolePrivilegesRole(RoleId=$($script:roleId))") {
                return [pscustomobject]@{
                    RolePrivileges = @($script:actualPrivileges)
                }
            }

            throw "Unexpected mocked verifier path: $Path"
        }
    }

    It 'returns Ready for exact ownership and privilege matches with GET-only transport' {
        $result = Test-InsuranceSecurityRole `
            -EnvironmentUrl 'https://unit.crm.dynamics.com' `
            -Role $script:role `
            -Contract $script:contract

        $result.Role | Should -Be $script:role.name
        $result.State | Should -Be 'Ready'
        @($result.Missing) | Should -Be @()
        @($result.Unexpected) | Should -Be @()
        @($result.WrongDepth) | Should -Be @()
        @($result.DuplicateExpected) | Should -Be @()
        @($result.DuplicateActual) | Should -Be @()

        $expectedGetCalls = @($script:role.tablePrivileges).Count + 3
        Should -Invoke Invoke-InsuranceSecurityRoleDataverseRequest -Times $expectedGetCalls -Exactly `
            -ParameterFilter { $Method -eq 'GET' }
        Should -Invoke Invoke-InsuranceSecurityRoleDataverseRequest -Times 0 -Exactly `
            -ParameterFilter { $Method -ne 'GET' }
        @($script:calls.Path | Where-Object {
                $_ -match '(?i)(SetLocLabels|AddPrivilegesRole|ReplacePrivilegesRole|/roles$)'
            }) | Should -BeNullOrEmpty
    }

    It 'returns ManualPrerequisite when the root role is missing' {
        $script:rootRoleItems = @()

        $result = Test-InsuranceSecurityRole `
            -EnvironmentUrl 'https://unit.crm.dynamics.com' `
            -Role $script:role `
            -Contract $script:contract

        $result.State | Should -Be 'ManualPrerequisite'
        @($result.Details) | Should -Contain (
            "Root security role '$($script:role.name)' was not found."
        )
        @($script:calls.Path) | Should -Be @(
            Get-InsuranceSecurityRolePath -RoleName $script:role.name
        )
    }

    It 'returns ContractConflict when multiple root roles match the same name' {
        $script:rootRoleItems = @(
            [pscustomobject]@{ roleid = '1'; name = $script:role.name },
            [pscustomobject]@{ roleid = '2'; name = $script:role.name }
        )

        $result = Test-InsuranceSecurityRole `
            -EnvironmentUrl 'https://unit.crm.dynamics.com' `
            -Role $script:role `
            -Contract $script:contract

        $result.State | Should -Be 'ContractConflict'
        @($result.Details) | Should -Contain (
            "Expected exactly one root security role named '$($script:role.name)', found 2."
        )
    }

    It 'detects a self-referencing root role (parentrootroleid == roleid)' {
        $script:rootRoleItems = @([pscustomobject]@{
                roleid = $script:roleId
                name = $script:role.name
                _parentrootroleid_value = $script:roleId
            })

        $result = Test-InsuranceSecurityRole `
            -EnvironmentUrl 'https://unit.crm.dynamics.com' `
            -Role $script:role `
            -Contract $script:contract

        $result.State | Should -Be 'Ready'
    }

    It 'ignores inherited business-unit role copies and resolves the root' {
        $script:rootRoleItems = @(
            [pscustomobject]@{
                roleid = '88888888-8888-8888-8888-888888888888'
                name = $script:role.name
                _parentrootroleid_value = $script:roleId
            },
            [pscustomobject]@{
                roleid = $script:roleId
                name = $script:role.name
                _parentrootroleid_value = $null
            }
        )

        $result = Test-InsuranceSecurityRole `
            -EnvironmentUrl 'https://unit.crm.dynamics.com' `
            -Role $script:role `
            -Contract $script:contract

        $result.State | Should -Be 'Ready'
    }

    It 'returns ContractConflict when the root-role query resolves only a case-insensitive name match' {
        $resolvedRoleName = $script:role.name.ToLowerInvariant()
        $script:rootRoleItems = @([pscustomobject]@{
                roleid = $script:roleId
                name = $resolvedRoleName
            })

        $result = Test-InsuranceSecurityRole `
            -EnvironmentUrl 'https://unit.crm.dynamics.com' `
            -Role $script:role `
            -Contract $script:contract

        $result.State | Should -Be 'ContractConflict'
        @($result.Details) | Should -Contain (
            "Root security role query for contract name '$($script:role.name)' returned name '$resolvedRoleName'; exact case-sensitive identity match is required."
        )
        @($script:calls.Path) | Should -Be @(
            Get-InsuranceSecurityRolePath -RoleName $script:role.name
        )
    }

    It 'returns ContractConflict when the expected reviewed solution membership is missing' {
        $script:solutionNames = @('crmshow_DataModel')

        $result = Test-InsuranceSecurityRole `
            -EnvironmentUrl 'https://unit.crm.dynamics.com' `
            -Role $script:role `
            -Contract $script:contract

        $result.State | Should -Be 'ContractConflict'
        @($result.Details) | Should -Contain (
            "Role '$($script:role.name)' reviewed-solution membership expected '$($script:role.solution)'; actual reviewed membership was 'crmshow_DataModel'."
        )
    }

    It 'returns ContractConflict when the role is in an extra reviewed solution' {
        $script:solutionNames = @('crmshow_Foundation', 'crmshow_DataModel')

        $result = Test-InsuranceSecurityRole `
            -EnvironmentUrl 'https://unit.crm.dynamics.com' `
            -Role $script:role `
            -Contract $script:contract

        $result.State | Should -Be 'ContractConflict'
        @($result.Details) | Should -Contain (
            "Role '$($script:role.name)' reviewed-solution membership expected '$($script:role.solution)'; actual reviewed membership was 'crmshow_Foundation, crmshow_DataModel'."
        )
    }

    It 'resolves exact privilege metadata with case-sensitive schema names' {
        $result = Test-InsuranceSecurityRole `
            -EnvironmentUrl 'https://unit.crm.dynamics.com' `
            -Role $script:role `
            -Contract $script:contract

        $result.State | Should -Be 'Ready'
        Should -Invoke Invoke-InsuranceSecurityRoleDataverseRequest -Times 1 -Exactly -ParameterFilter {
            $Path -eq (
                "/EntityDefinitions(LogicalName='crmshow_policyprojection')?" +
                "`$select=LogicalName,SchemaName,Privileges"
            )
        }
    }

    It 'fails closed when Dataverse returns a schema name with different casing' {
        $script:schemaMap['crmshow_policyprojection'] = 'crmshow_policyprojection'

        $result = Test-InsuranceSecurityRole `
            -EnvironmentUrl 'https://unit.crm.dynamics.com' `
            -Role $script:role `
            -Contract $script:contract

        $result.State | Should -Be 'ContractConflict'
        @($result.Details) | Should -Contain (
            "Dataverse metadata for table 'crmshow_policyprojection' did not return contract schema name 'crmshow_PolicyProjection'."
        )
    }

    It 'fails closed when the contract requests an unsupported depth' {
        $role = script:Clone-Object -InputObject $script:role
        $role.tablePrivileges[0].depth = 'BusinessUnit'

        $result = Test-InsuranceSecurityRole `
            -EnvironmentUrl 'https://unit.crm.dynamics.com' `
            -Role $role `
            -Contract $script:contract

        $result.State | Should -Be 'ContractConflict'
        @($result.Details) | Should -Contain (
            "Unsupported contract privilege depth 'BusinessUnit' for role '$($role.name)' table 'account'."
        )
    }

    It 'fails closed when deniedPrivileges overlap requested verbs before transport' {
        $role = script:Clone-Object -InputObject $script:role
        $role.deniedPrivileges = @('Read')

        $result = Test-InsuranceSecurityRole `
            -EnvironmentUrl 'https://unit.crm.dynamics.com' `
            -Role $role `
            -Contract $script:contract

        $result.State | Should -Be 'ContractConflict'
        @($result.Details) | Should -Contain (
            "Role '$($role.name)' deniedPrivileges overlap requested privilege verbs: Read."
        )
        Should -Invoke Invoke-InsuranceSecurityRoleDataverseRequest -Times 0 -Exactly
    }
}

Describe 'Invoke-InsuranceSecurityRoleVerification' {
    It 'returns one result per contract role, overall Ready, and MutationOccurred false' {
        Mock Test-InsuranceSecurityRole {
            param($EnvironmentUrl, $Role, $Contract)

            [pscustomobject]@{
                Role = [string]$Role.name
                State = 'Ready'
                Missing = @()
                Unexpected = @()
                WrongDepth = @()
                DuplicateExpected = @()
                DuplicateActual = @()
                Details = @()
            }
        }

        $result = Invoke-InsuranceSecurityRoleVerification `
            -EnvironmentUrl 'https://unit.crm.dynamics.com' `
            -Contract $script:contract

        $result.State | Should -Be 'Ready'
        $result.MutationOccurred | Should -BeFalse
        @($result.Results.Role) | Should -Be @($script:contract.roles.name)
        Should -Invoke Test-InsuranceSecurityRole -Times @($script:contract.roles).Count -Exactly
    }

    It 'prefers ManualPrerequisite overall when any contract role is missing' {
        Mock Test-InsuranceSecurityRole {
            param($EnvironmentUrl, $Role, $Contract)

            if ($Role.name -eq 'CRM Showcase Insurance Reader') {
                return [pscustomobject]@{
                    Role = [string]$Role.name
                    State = 'Ready'
                    Missing = @()
                    Unexpected = @()
                    WrongDepth = @()
                    DuplicateExpected = @()
                    DuplicateActual = @()
                    Details = @()
                }
            }

            return [pscustomobject]@{
                Role = [string]$Role.name
                State = 'ManualPrerequisite'
                Missing = @()
                Unexpected = @()
                WrongDepth = @()
                DuplicateExpected = @()
                DuplicateActual = @()
                Details = @('missing')
            }
        }

        $result = Invoke-InsuranceSecurityRoleVerification `
            -EnvironmentUrl 'https://unit.crm.dynamics.com' `
            -Contract $script:contract

        $result.State | Should -Be 'ManualPrerequisite'
    }

    It 'returns ContractConflict overall when no role is missing but one conflicts' {
        Mock Test-InsuranceSecurityRole {
            param($EnvironmentUrl, $Role, $Contract)

            $state = if ($Role.name -eq 'CRM Showcase Insurance Reader') {
                'ContractConflict'
            }
            else {
                'Ready'
            }

            return [pscustomobject]@{
                Role = [string]$Role.name
                State = $state
                Missing = @()
                Unexpected = @()
                WrongDepth = @()
                DuplicateExpected = @()
                DuplicateActual = @()
                Details = @()
            }
        }

        $result = Invoke-InsuranceSecurityRoleVerification `
            -EnvironmentUrl 'https://unit.crm.dynamics.com' `
            -Contract $script:contract

        $result.State | Should -Be 'ContractConflict'
    }
}

Describe 'Security-role verifier direct entry point' {
    It 'emits ready JSON and exits zero when verification is Ready' {
        $invocation = script:Invoke-SecurityRolesEntryScript -Scenario Ready

        $invocation.ExitCode | Should -Be 0
        { $invocation.Output | ConvertFrom-Json -ErrorAction Stop } |
            Should -Not -Throw

        $result = $invocation.Output | ConvertFrom-Json -ErrorAction Stop
        $result.State | Should -Be 'Ready'
        $result.MutationOccurred | Should -BeFalse
        @($result.Results).Count | Should -Be 2
    }

    It 'emits classified non-ready JSON and exits two when a root role is missing' {
        $invocation = script:Invoke-SecurityRolesEntryScript -Scenario MissingRole

        $invocation.ExitCode | Should -Be 2
        { $invocation.Output | ConvertFrom-Json -ErrorAction Stop } |
            Should -Not -Throw

        $result = $invocation.Output | ConvertFrom-Json -ErrorAction Stop
        $result.State | Should -Be 'ManualPrerequisite'
        $result.MutationOccurred | Should -BeFalse
        @($result.Results | Where-Object State -eq 'ManualPrerequisite').Count |
            Should -Be 1
    }

    It 'emits classified non-ready JSON and exits two when the root-role query returns lower-case name only' {
        $invocation = script:Invoke-SecurityRolesEntryScript -Scenario LowerCaseRoleName

        $invocation.ExitCode | Should -Be 2
        { $invocation.Output | ConvertFrom-Json -ErrorAction Stop } |
            Should -Not -Throw

        $result = $invocation.Output | ConvertFrom-Json -ErrorAction Stop
        $result.State | Should -Be 'ContractConflict'
        @($result.Results | Where-Object {
                $_.Role -eq 'CRM Showcase Insurance Data Steward' -and
                $_.State -eq 'ContractConflict'
            }).Count | Should -Be 1
        @($result.Results | Where-Object {
                $_.Role -eq 'CRM Showcase Insurance Data Steward' -and
                @($_.Details) -contains (
                    "Root security role query for contract name 'CRM Showcase Insurance Data Steward' returned name 'crm showcase insurance data steward'; exact case-sensitive identity match is required."
                )
            }).Count | Should -Be 1
    }

    It 'emits a single safe error line and exits one on hostile az transport failure' {
        $invocation = script:Invoke-SecurityRolesEntryScript -Scenario TransportFailure

        $invocation.ExitCode | Should -Be 1
        script:Assert-SafeDiagnosticLine -Text $invocation.Output -MaxLength 450
        $invocation.Output | Should -Match 'Dataverse security-role verification failed'
        $invocation.Output | Should -Match '/roles\?\$select=roleid,name'
        $invocation.Output | Should -Match 'Output:'
        $invocation.Output | Should -Match (
            [regex]::Escape(
                '::warning::security roles transport Permission denied blocked'
            )
        )
        $invocation.Output | Should -Not -Match 'At line:|--method|--url|--resource'
    }
}

Describe 'Security-role verifier entry point safety' {
    It 'does not invoke az when dot-sourced with unit arguments' {
        $text = @'
function az { throw 'az was called' }
. '__SCRIPT__' -EnvironmentUrl 'https://unit.crm.dynamics.com' -ContractPath '__CONTRACT__'
'@.Replace('__SCRIPT__', $script:verifierPath.Replace("'", "''")).
            Replace('__CONTRACT__', $script:contractPath.Replace("'", "''"))

        & ([scriptblock]::Create($text))
    }
}
