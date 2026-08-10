<#
.SYNOPSIS
    Performs a read-only Dataverse authoring preflight for the insurance demo.
.DESCRIPTION
    Verifies reviewed solution ownership, the current user's proven
    schema-authoring role, the required custom-role structure, and the contract
    languages. All Dataverse transport is GET-only and delegated to `az rest`.
#>
[CmdletBinding()]
param(
    [string]$EnvironmentUrl,
    [string]$ContractPath,
    [string]$ManifestPath = 'solution/manifest.json'
)

. (Join-Path $PSScriptRoot 'ConvertTo-SafeCliDiagnosticLine.ps1')
. (Join-Path $PSScriptRoot 'Get-Manifest.ps1')
. (Join-Path $PSScriptRoot 'Test-InsuranceSecurityRoles.ps1') `
    -EnvironmentUrl $EnvironmentUrl `
    -ContractPath $ContractPath

$ErrorActionPreference = 'Stop'
$script:SupportedAuthoringRoles = @('System Customizer', 'System Administrator')
$script:InsuranceAuthoringPreflightDefaultManifestPath = 'solution/manifest.json'

function Get-InsuranceAuthoringPreflightRepoRoot {
    [CmdletBinding()]
    param()

    return (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
}

function Resolve-InsuranceAuthoringPreflightPath {
    [CmdletBinding()]
    param(
        [AllowEmptyString()]
        [string]$Path = $script:InsuranceAuthoringPreflightDefaultManifestPath
    )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        return $Path
    }
    if ([System.IO.Path]::IsPathRooted($Path)) {
        return $Path
    }

    return Join-Path (Get-InsuranceAuthoringPreflightRepoRoot) $Path
}

function Get-InsuranceAuthoringPhaseState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [bool]$HasContractConflict,

        [Parameter(Mandatory)]
        [bool]$SchemaFeasible,

        [Parameter(Mandatory)]
        [bool]$SolutionsReady,

        [Parameter(Mandatory)]
        [bool]$RolesReady
    )

    if ($HasContractConflict) {
        return 'ContractConflict'
    }
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

    return (
        "/solutions?`$select=solutionid,uniquename&" +
        "`$expand=publisherid(`$select=uniquename,customizationprefix,customizationoptionvalueprefix)&" +
        "`$filter=$filter"
    )
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

function Get-RequiredManifestPublisher {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Manifest
    )

    if ($null -eq $Manifest.publisher -or
        [string]::IsNullOrWhiteSpace([string]$Manifest.publisher.uniqueName) -or
        [string]::IsNullOrWhiteSpace([string]$Manifest.publisher.prefix) -or
        $null -eq $Manifest.publisher.customizationOptionValuePrefix -or
        [string]::IsNullOrWhiteSpace(
            [string]$Manifest.publisher.customizationOptionValuePrefix
        )) {
        throw (
            'solution/manifest.json must declare publisher.uniqueName, ' +
            'publisher.prefix, and publisher.customizationOptionValuePrefix.'
        )
    }

    return [pscustomobject]@{
        UniqueName                     = [string]$Manifest.publisher.uniqueName
        Prefix                         = [string]$Manifest.publisher.prefix
        CustomizationOptionValuePrefix = [int]$Manifest.publisher.customizationOptionValuePrefix
    }
}

function Get-InsuranceAuthoringSolutionConflictDetails {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$SolutionUniqueName,

        [AllowNull()]
        $Solution,

        [Parameter(Mandatory)]
        $ExpectedPublisher
    )

    $details = [System.Collections.Generic.List[string]]::new()
    $publisher = $null
    if ($null -ne $Solution) {
        $publisher = $Solution.publisherid
    }

    if ($null -eq $publisher) {
        [void]$details.Add('Expanded publisher metadata was not returned.')
    }
    else {
        if ([string]$publisher.uniquename -cne [string]$ExpectedPublisher.UniqueName) {
            [void]$details.Add(
                "publisher.uniquename expected '$([string]$ExpectedPublisher.UniqueName)' but was '$([string]$publisher.uniquename)'."
            )
        }
        if ([string]$publisher.customizationprefix -cne [string]$ExpectedPublisher.Prefix) {
            [void]$details.Add(
                "publisher.customizationprefix expected '$([string]$ExpectedPublisher.Prefix)' but was '$([string]$publisher.customizationprefix)'."
            )
        }
        if ($publisher.PSObject.Properties.Name -notcontains 'customizationoptionvalueprefix') {
            [void]$details.Add(
                'publisher.customizationoptionvalueprefix was not returned.'
            )
        }
        else {
            $actualOptionValuePrefix = [int]$publisher.customizationoptionvalueprefix
            $expectedOptionValuePrefix = [int]$ExpectedPublisher.CustomizationOptionValuePrefix
            if ($actualOptionValuePrefix -ne $expectedOptionValuePrefix) {
                [void]$details.Add(
                    "publisher.customizationoptionvalueprefix expected '$expectedOptionValuePrefix' but was '$actualOptionValuePrefix'."
                )
            }
        }
    }

    if ($details.Count -eq 0) {
        return @()
    }

    return @(
        "Solution '$SolutionUniqueName' publisher metadata does not match solution/manifest.json: $($details.ToArray() -join ' ')"
    )
}

function Test-InsuranceAuthoringPreflightSolutions {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$EnvironmentUrl,

        [Parameter(Mandatory)]
        $Contract,

        [Parameter(Mandatory)]
        $Manifest
    )

    $requiredSolutions = @(Get-RequiredContractSolutions -Contract $Contract)
    $expectedPublisher = Get-RequiredManifestPublisher -Manifest $Manifest
    $response = Invoke-PreflightDataverseRequest -Method GET `
        -EnvironmentUrl $EnvironmentUrl `
        -Path (Get-RequiredSolutionsPath -SolutionUniqueName $requiredSolutions)

    $solutions = @()
    if ($null -ne $response -and
        $response.PSObject.Properties.Name -contains 'value') {
        $solutions = @($response.value)
    }

    $missingSolutions = [System.Collections.Generic.List[string]]::new()
    $solutionConflicts = [System.Collections.Generic.List[string]]::new()
    foreach ($expectedSolutionUniqueName in $requiredSolutions) {
        $matches = @($solutions | Where-Object {
                [string]$_.uniquename -ceq [string]$expectedSolutionUniqueName
            })

        if ($matches.Count -eq 0) {
            [void]$missingSolutions.Add([string]$expectedSolutionUniqueName)
            continue
        }
        if ($matches.Count -gt 1) {
            [void]$solutionConflicts.Add(
                "Solution '$expectedSolutionUniqueName' returned $($matches.Count) records; expected exactly one reviewed solution."
            )
            continue
        }

        foreach ($detail in @(Get-InsuranceAuthoringSolutionConflictDetails `
                    -SolutionUniqueName $expectedSolutionUniqueName `
                    -Solution $matches[0] `
                    -ExpectedPublisher $expectedPublisher)) {
            [void]$solutionConflicts.Add([string]$detail)
        }
    }

    $state = if ($solutionConflicts.Count -gt 0) {
        'ContractConflict'
    }
    elseif ($missingSolutions.Count -gt 0) {
        'Precondition'
    }
    else {
        'Ready'
    }

    return [pscustomobject][ordered]@{
        State             = $state
        MissingSolutions  = @($missingSolutions.ToArray())
        SolutionConflicts = @($solutionConflicts.ToArray())
    }
}

function Get-InsuranceAuthoringMissingRoles {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [object[]]$RoleResults = @()
    )

    $missingRoles = foreach ($result in @($RoleResults)) {
        if ([string]$result.State -ne 'ManualPrerequisite') {
            continue
        }
        if ([string]::IsNullOrWhiteSpace([string]$result.Role)) {
            continue
        }

        [string]$result.Role
    }

    return @(Get-NormalizedStringValues -Value $missingRoles)
}

function Get-InsuranceAuthoringRoleConflictDetails {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [object[]]$RoleResults = @()
    )

    $details = [System.Collections.Generic.List[string]]::new()
    foreach ($result in @($RoleResults)) {
        if ([string]$result.State -ne 'ContractConflict') {
            continue
        }

        $roleName = [string]$result.Role
        $resultDetails = @($result.Details | Where-Object {
                -not [string]::IsNullOrWhiteSpace([string]$_)
            })
        if ($resultDetails.Count -eq 0) {
            [void]$details.Add(
                "Role '$roleName' conflicts with the reviewed security-role contract."
            )
            continue
        }

        foreach ($detail in $resultDetails) {
            [void]$details.Add("Role '$roleName': $detail")
        }
    }

    return @($details.ToArray())
}

function Invoke-InsuranceAuthoringPreflight {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$EnvironmentUrl,

        [Parameter(Mandatory)]
        $Contract,

        [Parameter(Mandatory)]
        $Manifest
    )

    $requiredLanguages = @(Get-RequiredContractLanguages -Contract $Contract)
    $solutionAssessment = Test-InsuranceAuthoringPreflightSolutions `
        -EnvironmentUrl $EnvironmentUrl `
        -Contract $Contract `
        -Manifest $Manifest

    $roleVerification = Invoke-InsuranceSecurityRoleVerification `
        -EnvironmentUrl $EnvironmentUrl `
        -Contract $Contract
    $roleResults = @()
    if ($null -ne $roleVerification -and
        $roleVerification.PSObject.Properties.Name -contains 'Results') {
        $roleResults = @($roleVerification.Results)
    }

    $missingRoles = @(Get-InsuranceAuthoringMissingRoles -RoleResults $roleResults)
    $roleConflicts = @(Get-InsuranceAuthoringRoleConflictDetails -RoleResults $roleResults)
    $missingSolutions = @($solutionAssessment.MissingSolutions)
    $solutionConflicts = @($solutionAssessment.SolutionConflicts)
    $solutionsReady = $missingSolutions.Count -eq 0
    $rolesReady = $missingRoles.Count -eq 0 -and $roleConflicts.Count -eq 0
    $hasContractConflict = $solutionConflicts.Count -gt 0 -or $roleConflicts.Count -gt 0

    if ($hasContractConflict) {
        return [pscustomobject][ordered]@{
            State               = 'ContractConflict'
            UserId              = $null
            SchemaFeasible      = $null
            SolutionsReady      = $solutionsReady
            MissingSolutions    = @($missingSolutions)
            SolutionConflicts   = @($solutionConflicts)
            LanguagesReady      = $null
            LanguageAction      = 'Skipped'
            MissingLanguageLcid = @()
            RolesReady          = $rolesReady
            AssignedRoleNames   = @()
            MissingRoles        = @($missingRoles)
            RoleConflicts       = @($roleConflicts)
            MutationOccurred    = $false
        }
    }

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
        -HasContractConflict $false `
        -SchemaFeasible $schemaFeasible `
        -SolutionsReady $solutionsReady `
        -RolesReady $rolesReady

    return [pscustomobject][ordered]@{
        State               = $state
        UserId              = $userId
        SchemaFeasible      = $schemaFeasible
        SolutionsReady      = $solutionsReady
        MissingSolutions    = @($missingSolutions)
        SolutionConflicts   = @($solutionConflicts)
        LanguagesReady      = $languagesReady
        LanguageAction      = $languageAction
        MissingLanguageLcid = @($missingLanguages)
        RolesReady          = $rolesReady
        AssignedRoleNames   = @($assignedRoleNames)
        MissingRoles        = @($missingRoles)
        RoleConflicts       = @($roleConflicts)
        MutationOccurred    = $false
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

        $resolvedManifestPath = Resolve-InsuranceAuthoringPreflightPath `
            -Path $ManifestPath
        if ([string]::IsNullOrWhiteSpace($resolvedManifestPath)) {
            throw 'ManifestPath is required.'
        }

        $contract = Get-Content -LiteralPath $ContractPath -Raw -Encoding UTF8 |
            ConvertFrom-Json -ErrorAction Stop
        $manifest = Get-Manifest -Path $resolvedManifestPath -Validate
        $result = Invoke-InsuranceAuthoringPreflight `
            -EnvironmentUrl $EnvironmentUrl `
            -Contract $contract `
            -Manifest $manifest
        $result | ConvertTo-Json -Depth 20

        if ($result.State -eq 'Ready') {
            exit 0
        }
        if ($result.State -eq 'ContractConflict') {
            exit 3
        }

        exit 2
    }
    catch {
        Write-SafeCliErrorLine -ErrorRecord $_
        exit 1
    }
}
