<#
.SYNOPSIS
    Performs read-only structural verification of the reviewed Insurance Foundation roles.
.DESCRIPTION
    Uses GET-only `az rest` requests against Dataverse v9.2 with the
    environment URL resource. The verifier proves exact root-role identity,
    solution membership, and declared privilege/depth structure without
    mutating Dataverse. It does not retrieve localized role labels or
    descriptions and is safe to dot-source for testing.
#>
[CmdletBinding()]
param(
    [string]$EnvironmentUrl,
    [string]$ContractPath
)

$ErrorActionPreference = 'Stop'

function ConvertTo-ODataStringLiteral {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Value
    )

    return $Value.Replace("'", "''")
}

function Get-ContractTableSchemaName {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$LogicalName,

        [Parameter(Mandatory)]
        $Contract
    )

    switch ($LogicalName) {
        'account' { return 'Account' }
        'contact' { return 'Contact' }
    }

    $tables = @($Contract.tables | Where-Object logicalName -eq $LogicalName)
    if ($tables.Count -ne 1 -or
        [string]::IsNullOrWhiteSpace([string]$tables[0].schemaName)) {
        throw "Cannot resolve the contract schema name for table '$LogicalName'."
    }

    return [string]$tables[0].schemaName
}

function Get-InsuranceSecurityRolePath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$RoleName
    )

    $escapedName = ConvertTo-ODataStringLiteral -Value $RoleName
    return (
        "/roles?`$select=roleid,name&" +
        "`$filter=_parentrootroleid_value eq null and name eq '$escapedName'"
    )
}

function Get-InsuranceSecurityRoleSolutionMembershipPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$RoleId
    )

    $componentId = ([string]$RoleId).Trim('{}')
    return (
        "/solutioncomponents?`$select=solutioncomponentid&" +
        "`$filter=objectid eq $componentId&" +
        "`$expand=solutionid(`$select=uniquename)"
    )
}

function Get-InsuranceRoleEntityPrivilegesPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$LogicalName
    )

    $escapedLogicalName = ConvertTo-ODataStringLiteral -Value $LogicalName
    return (
        "/EntityDefinitions(LogicalName='$escapedLogicalName')?" +
        "`$select=LogicalName,SchemaName,Privileges"
    )
}

function Get-InsuranceSecurityRolePrivilegesPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$RoleId
    )

    $resolvedRoleId = ([string]$RoleId).Trim('{}')
    return "/RetrieveRolePrivilegesRole(RoleId=$resolvedRoleId)"
}

function Invoke-InsuranceSecurityRoleDataverseRequest {
    [CmdletBinding()]
    param(
        [ValidateSet('GET')]
        [string]$Method = 'GET',

        [Parameter(Mandatory)]
        [string]$EnvironmentUrl,

        [Parameter(Mandatory)]
        [string]$Path
    )

    $baseUrl = $EnvironmentUrl.TrimEnd('/')
    $url = if ($Path -match '^https://') {
        $Path
    }
    else {
        "$baseUrl/api/data/v9.2$Path"
    }

    $arguments = @(
        'rest',
        '--method', 'get',
        '--url', $url,
        '--resource', "$baseUrl/",
        '--only-show-errors'
    )

    $output = & az @arguments 2>&1
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0) {
        $detail = ($output | Out-String).Trim()
        throw "Dataverse security-role verification failed (GET $Path); az rest exited with code $exitCode. $detail"
    }

    $text = ($output | Out-String).Trim()
    if ([string]::IsNullOrWhiteSpace($text)) {
        return $null
    }

    return $text | ConvertFrom-Json -ErrorAction Stop
}

function Test-ContainsExactString {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [object[]]$Value,

        [Parameter(Mandatory)]
        [string]$Expected
    )

    return @($Value | Where-Object {
            [string]$_ -ceq $Expected
        }).Count -gt 0
}

function Get-UniqueExactStrings {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [object[]]$Value
    )

    $unique = [System.Collections.Generic.List[string]]::new()
    foreach ($item in @($Value)) {
        if ($null -eq $item) {
            continue
        }

        $text = [string]$item
        if ([string]::IsNullOrWhiteSpace($text)) {
            continue
        }

        if (-not (Test-ContainsExactString -Value @($unique) -Expected $text)) {
            [void]$unique.Add($text)
        }
    }

    return @($unique)
}

function Get-DuplicateInsuranceRolePrivilegeNames {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [object[]]$Privileges
    )

    $seen = [System.Collections.Generic.List[string]]::new()
    $duplicates = [System.Collections.Generic.List[string]]::new()
    foreach ($privilege in @($Privileges)) {
        if ($null -eq $privilege) {
            continue
        }

        $name = [string]$privilege.Name
        if ([string]::IsNullOrWhiteSpace($name)) {
            continue
        }

        if (Test-ContainsExactString -Value @($seen) -Expected $name) {
            if (-not (Test-ContainsExactString -Value @($duplicates) -Expected $name)) {
                [void]$duplicates.Add($name)
            }
            continue
        }

        [void]$seen.Add($name)
    }

    return @($duplicates)
}

function New-InsuranceSecurityRoleResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Role,

        [Parameter(Mandatory)]
        [ValidateSet('Ready', 'ManualPrerequisite', 'ContractConflict')]
        [string]$State,

        [AllowNull()]
        [object[]]$Missing = @(),

        [AllowNull()]
        [object[]]$Unexpected = @(),

        [AllowNull()]
        [object[]]$WrongDepth = @(),

        [AllowNull()]
        [object[]]$DuplicateExpected = @(),

        [AllowNull()]
        [object[]]$DuplicateActual = @(),

        [AllowNull()]
        [object[]]$Details = @()
    )

    return [pscustomobject][ordered]@{
        Role = $Role
        State = $State
        Missing = @(Get-UniqueExactStrings -Value $Missing)
        Unexpected = @(Get-UniqueExactStrings -Value $Unexpected)
        WrongDepth = @($WrongDepth)
        DuplicateExpected = @(Get-UniqueExactStrings -Value $DuplicateExpected)
        DuplicateActual = @(Get-UniqueExactStrings -Value $DuplicateActual)
        Details = @($Details | Where-Object {
                -not [string]::IsNullOrWhiteSpace([string]$_)
            })
    }
}

function Get-InsuranceRoleRequestedPrivilegeVerbs {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Role
    )

    $verbs = foreach ($tablePrivilege in @($Role.tablePrivileges)) {
        foreach ($verb in @($tablePrivilege.privileges)) {
            [string]$verb
        }
    }

    return @(Get-UniqueExactStrings -Value $verbs)
}

function Get-OverlappingInsuranceRolePrivilegeVerbs {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Role
    )

    $requestedVerbs = @(Get-InsuranceRoleRequestedPrivilegeVerbs -Role $Role)
    $overlap = foreach ($denied in @($Role.deniedPrivileges)) {
        $verb = [string]$denied
        if (Test-ContainsExactString -Value $requestedVerbs -Expected $verb) {
            $verb
        }
    }

    return @(Get-UniqueExactStrings -Value $overlap)
}

function Get-InsuranceDataversePrivilegeDepth {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ContractDepth
    )

    switch ($ContractDepth) {
        'Organization' { return 'Global' }
        default { return $null }
    }
}

function Normalize-InsuranceRolePrivilegeCollection {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [object[]]$Privileges
    )

    $normalized = foreach ($privilege in @($Privileges)) {
        if ($null -eq $privilege) {
            continue
        }

        $name = $null
        foreach ($propertyName in @('Name', 'PrivilegeName')) {
            $property = $privilege.PSObject.Properties[$propertyName]
            if ($null -ne $property) {
                $name = [string]$property.Value
                break
            }
        }

        $privilegeId = $null
        foreach ($propertyName in @('PrivilegeId', 'privilegeid')) {
            $property = $privilege.PSObject.Properties[$propertyName]
            if ($null -ne $property) {
                $privilegeId = [string]$property.Value
                break
            }
        }

        $depth = $null
        $depthProperty = $privilege.PSObject.Properties['Depth']
        if ($null -ne $depthProperty) {
            $depth = [string]$depthProperty.Value
        }

        [pscustomobject]@{
            Name = if ($null -eq $name) { '' } else { $name.Trim() }
            PrivilegeId = if ($null -eq $privilegeId) { '' } else { $privilegeId.Trim() }
            Depth = if ($null -eq $depth) { '' } else { $depth.Trim() }
        }
    }

    return @($normalized)
}

function Compare-InsuranceRolePrivileges {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$RoleName,

        [AllowNull()]
        [object[]]$Expected = @(),

        [AllowNull()]
        [object[]]$Actual = @()
    )

    $expectedItems = @(Normalize-InsuranceRolePrivilegeCollection -Privileges $Expected)
    $actualItems = @(Normalize-InsuranceRolePrivilegeCollection -Privileges $Actual)

    $duplicateExpected = @(Get-DuplicateInsuranceRolePrivilegeNames -Privileges $expectedItems)
    $duplicateActual = @(Get-DuplicateInsuranceRolePrivilegeNames -Privileges $actualItems)

    $missing = foreach ($name in @(Get-UniqueExactStrings -Value @($expectedItems.Name))) {
        if (-not (Test-ContainsExactString -Value @($actualItems.Name) -Expected $name)) {
            $name
        }
    }

    $unexpected = foreach ($name in @(Get-UniqueExactStrings -Value @($actualItems.Name))) {
        if (-not (Test-ContainsExactString -Value @($expectedItems.Name) -Expected $name)) {
            $name
        }
    }

    $wrongDepth = foreach ($name in @(Get-UniqueExactStrings -Value @($expectedItems.Name))) {
        $expectedMatches = @($expectedItems | Where-Object {
                [string]$_.Name -ceq $name
            })
        $actualMatches = @($actualItems | Where-Object {
                [string]$_.Name -ceq $name
            })

        if ($expectedMatches.Count -ne 1 -or $actualMatches.Count -ne 1) {
            continue
        }

        if ([string]$actualMatches[0].Depth -cne [string]$expectedMatches[0].Depth) {
            [pscustomobject]@{
                Name = [string]$expectedMatches[0].Name
                ExpectedDepth = [string]$expectedMatches[0].Depth
                ActualDepth = [string]$actualMatches[0].Depth
            }
        }
    }

    $state = if (@($missing).Count -eq 0 -and
        @($unexpected).Count -eq 0 -and
        @($wrongDepth).Count -eq 0 -and
        $duplicateExpected.Count -eq 0 -and
        $duplicateActual.Count -eq 0) {
        'Ready'
    }
    else {
        'ContractConflict'
    }

    return New-InsuranceSecurityRoleResult `
        -Role $RoleName `
        -State $state `
        -Missing $missing `
        -Unexpected $unexpected `
        -WrongDepth $wrongDepth `
        -DuplicateExpected $duplicateExpected `
        -DuplicateActual $duplicateActual
}

function Resolve-InsuranceRoleExpectedPrivileges {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$EnvironmentUrl,

        [Parameter(Mandatory)]
        $Role,

        [Parameter(Mandatory)]
        $Contract
    )

    $expected = [System.Collections.Generic.List[object]]::new()
    foreach ($tablePrivilege in @($Role.tablePrivileges)) {
        $logicalName = [string]$tablePrivilege.table
        $requestedDepth = [string]$tablePrivilege.depth
        $depth = Get-InsuranceDataversePrivilegeDepth -ContractDepth $requestedDepth
        if ([string]::IsNullOrWhiteSpace($depth)) {
            return [pscustomobject]@{
                State = 'ContractConflict'
                Details = @(
                    "Unsupported contract privilege depth '$requestedDepth' for role '$($Role.name)' table '$logicalName'."
                )
                Expected = @()
            }
        }

        try {
            $schemaName = Get-ContractTableSchemaName -LogicalName $logicalName -Contract $Contract
        }
        catch {
            return [pscustomobject]@{
                State = 'ContractConflict'
                Details = @($_.Exception.Message)
                Expected = @()
            }
        }

        $entityMetadata = Invoke-InsuranceSecurityRoleDataverseRequest `
            -Method GET `
            -EnvironmentUrl $EnvironmentUrl `
            -Path (Get-InsuranceRoleEntityPrivilegesPath -LogicalName $logicalName)
        if ($null -eq $entityMetadata -or
            [string]$entityMetadata.SchemaName -cne $schemaName) {
            return [pscustomobject]@{
                State = 'ContractConflict'
                Details = @(
                    "Dataverse metadata for table '$logicalName' did not return contract schema name '$schemaName'."
                )
                Expected = @()
            }
        }

        foreach ($verb in @($tablePrivilege.privileges)) {
            $exactName = "prv$verb$schemaName"
            $matches = @($entityMetadata.Privileges | Where-Object {
                    [string]$_.Name -ceq $exactName
                })
            if ($matches.Count -ne 1 -or
                [string]::IsNullOrWhiteSpace([string]$matches[0].PrivilegeId)) {
                return [pscustomobject]@{
                    State = 'ContractConflict'
                    Details = @(
                        "Required Dataverse privilege '$exactName' was not found in metadata for '$logicalName'."
                    )
                    Expected = @()
                }
            }

            [void]$expected.Add([pscustomobject]@{
                    Name = [string]$matches[0].Name
                    PrivilegeId = [string]$matches[0].PrivilegeId
                    Depth = $depth
                })
        }
    }

    return [pscustomobject]@{
        State = 'Ready'
        Details = @()
        Expected = @($expected)
    }
}

function Get-InsuranceRoleConflictDetails {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Comparison
    )

    $details = [System.Collections.Generic.List[string]]::new()
    if (@($Comparison.DuplicateExpected).Count -gt 0) {
        [void]$details.Add(
            "Expected privileges resolved with duplicate names: $(@($Comparison.DuplicateExpected) -join ', ')."
        )
    }
    if (@($Comparison.DuplicateActual).Count -gt 0) {
        [void]$details.Add(
            "Actual role '$($Comparison.Role)' contains duplicate privilege names: $(@($Comparison.DuplicateActual) -join ', ')."
        )
    }
    if (@($Comparison.Missing).Count -gt 0) {
        [void]$details.Add(
            "Missing privileges: $(@($Comparison.Missing) -join ', ')."
        )
    }
    if (@($Comparison.Unexpected).Count -gt 0) {
        [void]$details.Add(
            "Unexpected privileges: $(@($Comparison.Unexpected) -join ', ')."
        )
    }
    foreach ($entry in @($Comparison.WrongDepth)) {
        [void]$details.Add(
            "Privilege '$($entry.Name)' depth mismatch: expected '$($entry.ExpectedDepth)', actual '$($entry.ActualDepth)'."
        )
    }

    return @($details)
}

function Test-InsuranceSecurityRole {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$EnvironmentUrl,

        [Parameter(Mandatory)]
        $Role,

        [Parameter(Mandatory)]
        $Contract
    )

    $roleName = [string]$Role.name
    $overlap = @(Get-OverlappingInsuranceRolePrivilegeVerbs -Role $Role)
    if ($overlap.Count -gt 0) {
        return New-InsuranceSecurityRoleResult `
            -Role $roleName `
            -State 'ContractConflict' `
            -Details @(
                "Role '$roleName' deniedPrivileges overlap requested privilege verbs: $($overlap -join ', ')."
            )
    }

    $roleResponse = Invoke-InsuranceSecurityRoleDataverseRequest `
        -Method GET `
        -EnvironmentUrl $EnvironmentUrl `
        -Path (Get-InsuranceSecurityRolePath -RoleName $roleName)
    $matches = @()
    if ($null -ne $roleResponse) {
        $matches = @($roleResponse.value)
    }

    if ($matches.Count -eq 0) {
        return New-InsuranceSecurityRoleResult `
            -Role $roleName `
            -State 'ManualPrerequisite' `
            -Details @("Root security role '$roleName' was not found.")
    }

    if ($matches.Count -gt 1) {
        return New-InsuranceSecurityRoleResult `
            -Role $roleName `
            -State 'ContractConflict' `
            -Details @(
                "Expected exactly one root security role named '$roleName', found $($matches.Count)."
            )
    }

    $resolvedRoleName = [string]$matches[0].name
    if (-not ($resolvedRoleName -ceq $roleName)) {
        $resolvedRoleNameDetail = if ([string]::IsNullOrWhiteSpace($resolvedRoleName)) {
            '<empty>'
        }
        else {
            $resolvedRoleName
        }

        return New-InsuranceSecurityRoleResult `
            -Role $roleName `
            -State 'ContractConflict' `
            -Details @(
                "Root security role query for contract name '$roleName' returned name '$resolvedRoleNameDetail'; exact case-sensitive identity match is required."
            )
    }

    $roleId = [string]$matches[0].roleid
    $membershipResponse = Invoke-InsuranceSecurityRoleDataverseRequest `
        -Method GET `
        -EnvironmentUrl $EnvironmentUrl `
        -Path (Get-InsuranceSecurityRoleSolutionMembershipPath -RoleId $roleId)
    $solutionNames = foreach ($entry in @($membershipResponse.value)) {
        if ($null -ne $entry -and $entry.solutionid) {
            [string]$entry.solutionid.uniquename
        }
    }
    if (-not (Test-ContainsExactString -Value $solutionNames -Expected ([string]$Role.solution))) {
        return New-InsuranceSecurityRoleResult `
            -Role $roleName `
            -State 'ContractConflict' `
            -Details @(
                "Role '$roleName' is not a member of solution '$([string]$Role.solution)'."
            )
    }

    $expectedResolution = Resolve-InsuranceRoleExpectedPrivileges `
        -EnvironmentUrl $EnvironmentUrl `
        -Role $Role `
        -Contract $Contract
    if ($expectedResolution.State -ne 'Ready') {
        return New-InsuranceSecurityRoleResult `
            -Role $roleName `
            -State 'ContractConflict' `
            -Details $expectedResolution.Details
    }

    $actualResponse = Invoke-InsuranceSecurityRoleDataverseRequest `
        -Method GET `
        -EnvironmentUrl $EnvironmentUrl `
        -Path (Get-InsuranceSecurityRolePrivilegesPath -RoleId $roleId)
    $actual = @()
    if ($null -ne $actualResponse -and
        $actualResponse.PSObject.Properties.Name -contains 'RolePrivileges') {
        $actual = @(Normalize-InsuranceRolePrivilegeCollection -Privileges @(
                $actualResponse.RolePrivileges
            ))
    }

    $comparison = Compare-InsuranceRolePrivileges `
        -RoleName $roleName `
        -Expected $expectedResolution.Expected `
        -Actual $actual
    if ($comparison.State -eq 'Ready') {
        return $comparison
    }

    return New-InsuranceSecurityRoleResult `
        -Role $comparison.Role `
        -State $comparison.State `
        -Missing $comparison.Missing `
        -Unexpected $comparison.Unexpected `
        -WrongDepth $comparison.WrongDepth `
        -DuplicateExpected $comparison.DuplicateExpected `
        -DuplicateActual $comparison.DuplicateActual `
        -Details (Get-InsuranceRoleConflictDetails -Comparison $comparison)
}

function Get-InsuranceSecurityRolesOverallState {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [object[]]$Results = @()
    )

    if (@($Results | Where-Object State -eq 'ManualPrerequisite').Count -gt 0) {
        return 'ManualPrerequisite'
    }
    if (@($Results | Where-Object State -ne 'Ready').Count -gt 0) {
        return 'ContractConflict'
    }

    return 'Ready'
}

function Invoke-InsuranceSecurityRoleVerification {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$EnvironmentUrl,

        [Parameter(Mandatory)]
        $Contract
    )

    $results = foreach ($role in @($Contract.roles)) {
        Test-InsuranceSecurityRole `
            -EnvironmentUrl $EnvironmentUrl `
            -Role $role `
            -Contract $Contract
    }

    return [pscustomobject][ordered]@{
        State = Get-InsuranceSecurityRolesOverallState -Results @($results)
        MutationOccurred = $false
        Results = @($results)
    }
}

if ($MyInvocation.InvocationName -ne '.') {
    try {
        if ([string]::IsNullOrWhiteSpace($EnvironmentUrl)) {
            throw 'EnvironmentUrl is required.'
        }
        if ([string]::IsNullOrWhiteSpace($ContractPath)) {
            throw 'ContractPath is required.'
        }
        if (-not (Test-Path -LiteralPath $ContractPath -PathType Leaf)) {
            throw "ContractPath was not found: $ContractPath"
        }

        $contract = Get-Content -LiteralPath $ContractPath -Raw -Encoding UTF8 |
            ConvertFrom-Json -ErrorAction Stop
        $result = Invoke-InsuranceSecurityRoleVerification `
            -EnvironmentUrl $EnvironmentUrl `
            -Contract $contract
        $result | ConvertTo-Json -Depth 20

        if ($result.State -eq 'Ready') {
            exit 0
        }

        exit 2
    }
    catch {
        Write-Error $_
        exit 1
    }
}
