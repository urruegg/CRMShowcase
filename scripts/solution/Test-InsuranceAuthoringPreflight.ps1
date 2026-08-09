<#
.SYNOPSIS
    Performs a read-only Dataverse authoring preflight for the insurance demo.
.DESCRIPTION
    Verifies that the current user has a proven schema-authoring role, the
    required solutions are present, the reviewed custom roles exist, and the
    contract languages are provisioned. All Dataverse transport is GET-only and
    delegated to `az rest`.
#>
[CmdletBinding()]
param(
    [string]$EnvironmentUrl,
    [string]$ContractPath
)

. (Join-Path $PSScriptRoot 'ConvertTo-SafeCliDiagnosticLine.ps1')

$ErrorActionPreference = 'Stop'
$script:SupportedAuthoringRoles = @('System Customizer', 'System Administrator')

function Get-InsuranceAuthoringPhaseState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [bool]$SolutionsReady,

        [Parameter(Mandatory)]
        [bool]$SchemaFeasible,

        [Parameter(Mandatory)]
        [bool]$RolesReady
    )

    if (-not $SchemaFeasible) {
        return 'UnsupportedInTenant'
    }
    if (-not $SolutionsReady) {
        return 'Precondition'
    }
    if (-not $RolesReady) {
        return 'ManualPrerequisite'
    }
    return 'Ready'
}

function Get-NormalizedIntegerValues {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [object[]]$Value
    )

    $normalized = foreach ($item in @($Value)) {
        if ($null -eq $item) {
            continue
        }

        $text = [string]$item
        if ([string]::IsNullOrWhiteSpace($text)) {
            continue
        }

        [int]$text
    }

    return @($normalized | Sort-Object -Unique)
}

function Get-NormalizedStringValues {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [object[]]$Value
    )

    $normalized = foreach ($item in @($Value)) {
        if ($null -eq $item) {
            continue
        }

        $text = [string]$item
        if ([string]::IsNullOrWhiteSpace($text)) {
            continue
        }

        $text.Trim()
    }

    return @($normalized | Sort-Object -Unique)
}

function Get-MissingIntegerValues {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object[]]$Required,

        [AllowNull()]
        [object[]]$Actual
    )

    $requiredValues = @(Get-NormalizedIntegerValues -Value $Required)
    $actualValues = @(Get-NormalizedIntegerValues -Value $Actual)

    return @($requiredValues | Where-Object { $_ -notin $actualValues })
}

function Get-MissingStringValues {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object[]]$Required,

        [AllowNull()]
        [object[]]$Actual
    )

    $requiredValues = foreach ($item in @($Required)) {
        if ($null -eq $item) {
            continue
        }

        $text = [string]$item
        if ([string]::IsNullOrWhiteSpace($text)) {
            continue
        }

        $text.Trim()
    }
    $actualValues = @(Get-NormalizedStringValues -Value $Actual)

    return @($requiredValues | Where-Object { $_ -notin $actualValues })
}

function Get-LanguagePreflightAction {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object[]]$Required,

        [AllowNull()]
        [object[]]$Provisioned
    )

    $missing = @(Get-MissingIntegerValues -Required $Required -Actual $Provisioned)
    if ($missing.Count -gt 0) {
        return 'Reconcile'
    }
    return 'None'
}

function Test-DemoSchemaAuthoringCapability {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [string[]]$AssignedRoleNames
    )

    $assigned = @(Get-NormalizedStringValues -Value $AssignedRoleNames)
    return @($script:SupportedAuthoringRoles | Where-Object { $_ -in $assigned }).Count -gt 0
}

function ConvertTo-ODataStringLiteral {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Value
    )

    return $Value.Replace("'", "''")
}

function Get-RequiredContractLanguages {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Contract
    )

    return @(Get-NormalizedIntegerValues -Value @($Contract.languages))
}

function Get-RequiredContractSolutions {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Contract
    )

    return @($Contract.solutions | ForEach-Object { [string]$_ })
}

function Get-RequiredContractRoles {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Contract
    )

    return @($Contract.roles | ForEach-Object { [string]$_.name })
}

function Get-CurrentUserRolesPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$UserId
    )

    return "/systemusers($UserId)/systemuserroles_association?`$select=name"
}

function Get-RequiredSolutionsPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string[]]$SolutionUniqueName
    )

    $filter = @($SolutionUniqueName | ForEach-Object {
            "uniquename eq '$(ConvertTo-ODataStringLiteral -Value $_)'"
        }) -join ' or '

    return "/solutions?`$select=uniquename&`$filter=$filter"
}

function Get-RequiredRolesPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string[]]$RoleName
    )

    $roleNameFilter = @($RoleName | ForEach-Object {
            "name eq '$(ConvertTo-ODataStringLiteral -Value $_)'"
        }) -join ' or '
    $filter = "_parentrootroleid_value eq null and ($roleNameFilter)"

    return "/roles?`$select=roleid,name&`$filter=$filter"
}

function Invoke-PreflightDataverseRequest {
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
        $detail = ConvertTo-SafeCliDiagnosticLine -Value $output
        throw "Dataverse preflight transport failed (GET $Path); az rest exited with code $exitCode. Output: $detail"
    }

    $text = ($output | Out-String).Trim()
    if ([string]::IsNullOrWhiteSpace($text)) {
        return $null
    }

    return $text | ConvertFrom-Json -ErrorAction Stop
}

function Get-ResponseValues {
    [CmdletBinding()]
    param(
        [AllowNull()]
        $Response,

        [Parameter(Mandatory)]
        [string]$PropertyName
    )

    if ($null -eq $Response) {
        return @()
    }

    $values = foreach ($item in @($Response.value)) {
        if ($null -eq $item) {
            continue
        }

        $property = $item.PSObject.Properties[$PropertyName]
        if ($null -eq $property) {
            continue
        }

        $property.Value
    }

    return @($values)
}

function Invoke-InsuranceAuthoringPreflight {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$EnvironmentUrl,

        [Parameter(Mandatory)]
        $Contract
    )

    $requiredSolutions = @(Get-RequiredContractSolutions -Contract $Contract)
    $requiredLanguages = @(Get-RequiredContractLanguages -Contract $Contract)
    $requiredRoles = @(Get-RequiredContractRoles -Contract $Contract)

    $whoAmI = Invoke-PreflightDataverseRequest -Method GET `
        -EnvironmentUrl $EnvironmentUrl `
        -Path '/WhoAmI'
    $userId = [string]$whoAmI.UserId
    if ([string]::IsNullOrWhiteSpace($userId)) {
        throw 'WhoAmI returned no UserId.'
    }

    $assignedRolesResponse = Invoke-PreflightDataverseRequest -Method GET `
        -EnvironmentUrl $EnvironmentUrl `
        -Path (Get-CurrentUserRolesPath -UserId $userId)
    $assignedRoleNames = @(Get-NormalizedStringValues -Value (
            Get-ResponseValues -Response $assignedRolesResponse -PropertyName 'name'
        ))

    $languagesResponse = Invoke-PreflightDataverseRequest -Method GET `
        -EnvironmentUrl $EnvironmentUrl `
        -Path '/RetrieveProvisionedLanguages()'
    if ($null -eq $languagesResponse -or
        $languagesResponse.PSObject.Properties.Name -notcontains 'RetrieveProvisionedLanguages') {
        throw 'RetrieveProvisionedLanguages returned no language collection.'
    }
    $provisionedLanguages = @(Get-NormalizedIntegerValues -Value @(
            $languagesResponse.RetrieveProvisionedLanguages
        ))

    $solutionsResponse = Invoke-PreflightDataverseRequest -Method GET `
        -EnvironmentUrl $EnvironmentUrl `
        -Path (Get-RequiredSolutionsPath -SolutionUniqueName $requiredSolutions)
    $availableSolutions = @(Get-NormalizedStringValues -Value (
            Get-ResponseValues -Response $solutionsResponse -PropertyName 'uniquename'
        ))
    $missingSolutions = @(Get-MissingStringValues `
            -Required $requiredSolutions `
            -Actual $availableSolutions)
    $solutionsReady = $missingSolutions.Count -eq 0

    $rolesResponse = Invoke-PreflightDataverseRequest -Method GET `
        -EnvironmentUrl $EnvironmentUrl `
        -Path (Get-RequiredRolesPath -RoleName $requiredRoles)
    $availableRoles = @(Get-NormalizedStringValues -Value (
            Get-ResponseValues -Response $rolesResponse -PropertyName 'name'
        ))
    $missingRoles = @(Get-MissingStringValues `
            -Required $requiredRoles `
            -Actual $availableRoles)
    $rolesReady = $missingRoles.Count -eq 0

    $missingLanguages = @(Get-MissingIntegerValues `
            -Required $requiredLanguages `
            -Actual $provisionedLanguages)
    $languageAction = Get-LanguagePreflightAction `
        -Required $requiredLanguages `
        -Provisioned $provisionedLanguages
    $languagesReady = $missingLanguages.Count -eq 0

    $schemaFeasible = Test-DemoSchemaAuthoringCapability `
        -AssignedRoleNames $assignedRoleNames
    $state = Get-InsuranceAuthoringPhaseState `
        -SolutionsReady $solutionsReady `
        -SchemaFeasible $schemaFeasible `
        -RolesReady $rolesReady

    return [pscustomobject][ordered]@{
        State                 = $state
        UserId                = $userId
        SchemaFeasible        = $schemaFeasible
        SolutionsReady        = $solutionsReady
        MissingSolutions      = @($missingSolutions)
        LanguagesReady        = $languagesReady
        LanguageAction        = $languageAction
        MissingLanguageLcid   = @($missingLanguages)
        RolesReady            = $rolesReady
        AssignedRoleNames     = @($assignedRoleNames)
        MissingRoles          = @($missingRoles)
        MutationOccurred      = $false
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
        $result = Invoke-InsuranceAuthoringPreflight `
            -EnvironmentUrl $EnvironmentUrl `
            -Contract $contract
        $result | ConvertTo-Json -Depth 10

        if ($result.State -eq 'Ready') {
            exit 0
        }

        exit 2
    }
    catch {
        Write-SafeCliErrorLine -ErrorRecord $_
        exit 1
    }
}
