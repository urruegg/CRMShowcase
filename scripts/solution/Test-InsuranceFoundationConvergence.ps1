<#
.SYNOPSIS
    Performs a read-only full convergence verification of Insurance Foundation.
.DESCRIPTION
    Validates the reviewed contract and repo conventions locally, then performs
    GET-only Dataverse v9.2 reads against the environment resource to verify
    required languages, solution ownership, shared choices, native extensions,
    custom tables, reviewed child metadata, and reviewed security roles before
    package export. Safe to dot-source for testing.
#>
[CmdletBinding()]
param(
    [string]$EnvironmentUrl,
    [string]$ContractPath
)

$ErrorActionPreference = 'Stop'
$script:ConvergenceStatePriority = @{
    Ready              = 0
    ManualPrerequisite = 1
    Precondition       = 2
    UnsupportedInTenant = 3
    ContractConflict   = 4
}

function Get-ConvergenceRepoRoot {
    [CmdletBinding()]
    param()

    return (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
}

function Get-ConvergenceDefaultContractPath {
    [CmdletBinding()]
    param()

    return Join-Path (Get-ConvergenceRepoRoot) 'solution/schema/insurance-foundation.json'
}

function Get-ConvergenceManifestPath {
    [CmdletBinding()]
    param()

    return Join-Path (Get-ConvergenceRepoRoot) 'solution/manifest.json'
}

$script:ConvergenceDependencyEnvironmentUrl = if (
    [string]::IsNullOrWhiteSpace($EnvironmentUrl)
) {
    'https://unit.crm.dynamics.com'
}
else {
    $EnvironmentUrl
}
$script:ConvergenceDependencyContractPath = if (
    [string]::IsNullOrWhiteSpace($ContractPath)
) {
    Get-ConvergenceDefaultContractPath
}
else {
    $ContractPath
}

. (Join-Path $PSScriptRoot 'Publish-InsuranceFoundation.ps1') `
    -EnvironmentUrl $script:ConvergenceDependencyEnvironmentUrl `
    -ContractPath $script:ConvergenceDependencyContractPath
. (Join-Path $PSScriptRoot 'Test-InsuranceSecurityRoles.ps1') `
    -EnvironmentUrl $script:ConvergenceDependencyEnvironmentUrl `
    -ContractPath $script:ConvergenceDependencyContractPath
. (Join-Path $PSScriptRoot 'Get-Manifest.ps1')

function Set-ConvergenceRuntimeContext {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$EnvironmentUrl,

        [string]$ContractPath
    )

    $script:DataverseBaseUrl = $EnvironmentUrl.TrimEnd('/')
    if (-not [string]::IsNullOrWhiteSpace($ContractPath)) {
        $script:ContractFile = $ContractPath
    }
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

function Get-ConvergenceStatePriority {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$State
    )

    if (-not $script:ConvergenceStatePriority.ContainsKey($State)) {
        throw "Unsupported convergence state '$State'."
    }

    return [int]$script:ConvergenceStatePriority[$State]
}

function Get-UniqueConvergenceStrings {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [object[]]$Value
    )

    $items = [System.Collections.Generic.List[string]]::new()
    $seen = @{}
    foreach ($entry in @($Value)) {
        if ($null -eq $entry) {
            continue
        }

        $text = [string]$entry
        if ([string]::IsNullOrWhiteSpace($text)) {
            continue
        }

        if ($seen.ContainsKey($text)) {
            continue
        }

        $seen[$text] = $true
        [void]$items.Add($text)
    }

    return @($items)
}

function Get-UniqueConvergenceDifferenceObjects {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [object[]]$Value
    )

    $items = [System.Collections.Generic.List[object]]::new()
    $seen = @{}
    foreach ($entry in @($Value)) {
        if ($null -eq $entry) {
            continue
        }

        $key = $entry | ConvertTo-Json -Depth 30 -Compress
        if ($seen.ContainsKey($key)) {
            continue
        }

        $seen[$key] = $true
        [void]$items.Add($entry)
    }

    return @($items)
}

function New-ConvergenceResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Component,

        [Parameter(Mandatory)]
        [ValidateSet(
            'Ready',
            'ManualPrerequisite',
            'Precondition',
            'UnsupportedInTenant',
            'ContractConflict'
        )]
        [string]$State,

        [AllowNull()]
        [object[]]$Missing = @(),

        [AllowNull()]
        [object[]]$Unexpected = @(),

        [AllowNull()]
        [object[]]$Differences = @(),

        [AllowNull()]
        [object[]]$Details = @(),

        [AllowNull()]
        [object[]]$Children = @()
    )

    return [pscustomobject][ordered]@{
        Component   = $Component
        State       = $State
        Missing     = @(Get-UniqueConvergenceStrings -Value $Missing)
        Unexpected  = @(Get-UniqueConvergenceStrings -Value $Unexpected)
        Differences = @(Get-UniqueConvergenceDifferenceObjects -Value $Differences)
        Details     = @(Get-UniqueConvergenceStrings -Value $Details)
        Children    = @($Children)
    }
}

function New-ConvergenceSummary {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object[]]$Results
    )

    $resolvedResults = @($Results)
    $blocking = @($resolvedResults | Where-Object {
            [string]$_.State -ne 'Ready'
        })

    $state = 'Ready'
    if ($blocking.Count -gt 0) {
        $state = @(
            $blocking |
                Sort-Object `
                    @{ Expression = { -1 * (Get-ConvergenceStatePriority -State ([string]$_.State)) } }, `
                    @{ Expression = { [string]$_.Component } }
        )[0].State
    }

    return [pscustomobject][ordered]@{
        State              = $state
        BlockingComponents = @($blocking | ForEach-Object { [string]$_.Component })
        MutationOccurred   = $false
        Results            = $resolvedResults
    }
}

function Get-ConvergenceManagedPropertyValue {
    [CmdletBinding()]
    param($Value)

    if ($null -eq $Value) {
        return $null
    }

    if ($Value -is [bool]) {
        return [bool]$Value
    }

    if ($Value -is [System.Collections.IDictionary] -and
        $Value.Contains('Value')) {
        return [bool]$Value['Value']
    }

    if ($Value.PSObject -and
        $Value.PSObject.Properties.Name -contains 'Value') {
        return [bool]$Value.Value
    }

    return [bool]$Value
}

function Get-ConvergenceRequiredLevelValue {
    [CmdletBinding()]
    param($Attribute)

    if ($null -eq $Attribute) {
        return $null
    }

    $requiredLevel = $Attribute.RequiredLevel
    if ($null -eq $requiredLevel) {
        return $null
    }

    if ($requiredLevel -is [System.Collections.IDictionary] -and
        $requiredLevel.Contains('Value')) {
        return [string]$requiredLevel['Value']
    }

    if ($requiredLevel.PSObject -and
        $requiredLevel.PSObject.Properties.Name -contains 'Value') {
        return [string]$requiredLevel.Value
    }

    return [string]$requiredLevel
}

function Get-ConvergenceLocalizedLabel {
    [CmdletBinding()]
    param(
        $LocalizedValue,

        [Parameter(Mandatory)]
        [string]$LanguageCode
    )

    if ($null -eq $LocalizedValue) {
        return $null
    }

    $labels = @($LocalizedValue.LocalizedLabels | Where-Object {
            [int]$_.LanguageCode -eq [int]$LanguageCode
        })
    if ($labels.Count -ne 1) {
        return $null
    }

    return [string]$labels[0].Label
}

function Get-ConvergenceLocalizedMetadataDifferences {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Existing,

        [Parameter(Mandatory)]
        $Metadata
    )

    $differences = [System.Collections.Generic.List[object]]::new()
    foreach ($pair in @(
            @{ ActualProperty = 'DisplayName'; ContractProperty = 'label' },
            @{ ActualProperty = 'Description'; ContractProperty = 'description' }
        )) {
        foreach ($language in @($script:RequiredLanguages)) {
            $expected = [string]$Metadata.($pair.ContractProperty).$language
            $actual = Get-ConvergenceLocalizedLabel `
                -LocalizedValue $Existing.($pair.ActualProperty) `
                -LanguageCode $language
            if ($actual -cne $expected) {
                [void]$differences.Add([pscustomobject][ordered]@{
                        Property = $pair.ActualProperty
                        Language = [string]$language
                        Expected = $expected
                        Actual   = $actual
                    })
            }
        }
    }

    return @($differences)
}

function Get-ConvergenceDifferenceDetails {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [object[]]$Differences = @()
    )

    $details = foreach ($difference in @($Differences)) {
        if ($null -eq $difference) {
            continue
        }

        $parts = [System.Collections.Generic.List[string]]::new()
        foreach ($propertyName in @('Property', 'Language', 'Code', 'Expected', 'Actual')) {
            $property = $difference.PSObject.Properties[$propertyName]
            if ($null -eq $property) {
                continue
            }

            $value = $property.Value
            if ($null -eq $value -or [string]::IsNullOrWhiteSpace([string]$value)) {
                continue
            }

            [void]$parts.Add("$propertyName=$value")
        }

        if ($parts.Count -gt 0) {
            $parts -join '; '
        }
    }

    return @(Get-UniqueConvergenceStrings -Value $details)
}

function Add-ConvergenceStringsToList {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $List,

        [AllowNull()]
        [object[]]$Values = @()
    )

    foreach ($value in @(Get-UniqueConvergenceStrings -Value $Values)) {
        [void]$List.Add([string]$value)
    }
}

function Get-ConvergenceErrorMessage {
    [CmdletBinding()]
    param($ErrorRecord)

    if ($ErrorRecord -is [System.Management.Automation.ErrorRecord]) {
        return [string]$ErrorRecord.Exception.Message
    }
    if ($ErrorRecord -is [System.Exception]) {
        return [string]$ErrorRecord.Message
    }

    return [string]$ErrorRecord
}

function Test-ConvergenceTransportError {
    [CmdletBinding()]
    param($ErrorRecord)

    $message = Get-ConvergenceErrorMessage -ErrorRecord $ErrorRecord
    if ([string]::IsNullOrWhiteSpace($message)) {
        return $false
    }

    return $message -like 'Dataverse convergence transport failed*' -or
        $message -like 'Dataverse security-role verification failed*' -or
        $message -like 'Dataverse request failed*'
}

function Test-ConvergenceRetrieveLocLabelsUnsupportedError {
    [CmdletBinding()]
    param($ErrorRecord)

    $message = Get-ConvergenceErrorMessage -ErrorRecord $ErrorRecord
    if ([string]::IsNullOrWhiteSpace($message) -or
        $message -notlike 'Dataverse convergence transport failed (GET /RetrieveLocLabels*') {
        return $false
    }

    return $message -match '(?i)(400|404|BadRequest|Bad Request|Not Found|Resource not found|does not support|not supported|unsupported)'
}

function Get-ConvergenceLanguagesPath {
    [CmdletBinding()]
    param()

    return '/RetrieveProvisionedLanguages()'
}

function Get-ConvergenceSolutionsPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string[]]$SolutionUniqueName
    )

    $filter = @($SolutionUniqueName | ForEach-Object {
            "uniquename eq '$(
                ConvertTo-ODataKeyString ([string]$_)
            )'"
        }) -join ' or '

    return (
        "/solutions?`$select=solutionid,uniquename&" +
        "`$expand=publisherid(`$select=uniquename,customizationprefix,customizationoptionvalueprefix)&" +
        "`$filter=$filter"
    )
}

function Get-ConvergenceSolutionMembershipPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ComponentId
    )

    $resolvedComponentId = ([string]$ComponentId).Trim('{}')
    return (
        "/solutioncomponents?`$select=solutioncomponentid&" +
        "`$filter=objectid eq $resolvedComponentId&" +
        "`$expand=solutionid(`$select=uniquename)"
    )
}

function Get-ConvergenceGlobalChoicePath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ChoiceLogicalName
    )

    $escapedChoiceName = ConvertTo-ODataKeyString $ChoiceLogicalName
    return (
        "/GlobalOptionSetDefinitions(Name='$escapedChoiceName')/" +
        'Microsoft.Dynamics.CRM.OptionSetMetadata'
    )
}

function Get-ConvergencePicklistAttributePath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$TableLogicalName,

        [Parameter(Mandatory)]
        [string]$AttributeLogicalName
    )

    $escapedTableName = ConvertTo-ODataKeyString $TableLogicalName
    $escapedAttributeName = ConvertTo-ODataKeyString $AttributeLogicalName
    return (
        "/EntityDefinitions(LogicalName='$escapedTableName')/Attributes/" +
        'Microsoft.Dynamics.CRM.PicklistAttributeMetadata?' +
        "`$select=MetadataId,LogicalName,SchemaName,AttributeType," +
        'DisplayName,Description,RequiredLevel,IsAuditEnabled&' +
        "`$expand=GlobalOptionSet(`$select=Name)&" +
        "`$filter=LogicalName eq '$escapedAttributeName'"
    )
}

function Get-ConvergenceTypedAttributePath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$TableLogicalName,

        [Parameter(Mandatory)]
        $Column
    )

    if ([string]$Column.type -eq 'GlobalChoice') {
        return Get-ConvergencePicklistAttributePath `
            -TableLogicalName $TableLogicalName `
            -AttributeLogicalName ([string]$Column.logicalName)
    }

    $typeName = @{
        Text     = 'StringAttributeMetadata'
        DateOnly = 'DateTimeAttributeMetadata'
        DateTime = 'DateTimeAttributeMetadata'
        Lookup   = 'LookupAttributeMetadata'
        Customer = 'LookupAttributeMetadata'
    }[[string]$Column.type]
    $derivedProperties = @{
        Text     = 'MaxLength'
        DateOnly = 'Format,DateTimeBehavior'
        DateTime = 'Format,DateTimeBehavior'
        Lookup   = 'Targets'
        Customer = 'Targets'
    }[[string]$Column.type]

    if ([string]::IsNullOrWhiteSpace($typeName)) {
        throw "Unsupported typed metadata query for '$($Column.type)' column '$($Column.logicalName)'."
    }

    $escapedTableName = ConvertTo-ODataKeyString $TableLogicalName
    $escapedAttributeName = ConvertTo-ODataKeyString ([string]$Column.logicalName)
    return (
        "/EntityDefinitions(LogicalName='$escapedTableName')/Attributes/" +
        "Microsoft.Dynamics.CRM.$typeName?" +
        "`$select=MetadataId,LogicalName,SchemaName,AttributeType," +
        "DisplayName,Description,RequiredLevel,IsAuditEnabled,$derivedProperties&" +
        "`$filter=LogicalName eq '$escapedAttributeName'"
    )
}

function Get-ConvergenceTableMetadataPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$LogicalName,

        [string[]]$RequestedAttributeLogicalNames
    )

    $escapedLogicalName = ConvertTo-ODataKeyString $LogicalName
    $requestedAttributeLogicalNames = @(Get-UniqueMetadataStrings `
            -Values $RequestedAttributeLogicalNames)

    $attributeExpand = (
        "Attributes(`$select=MetadataId,LogicalName,SchemaName," +
        'AttributeType,DisplayName,Description'
    )
    if ($requestedAttributeLogicalNames.Count -gt 0) {
        $attributeFilter = @(
            $requestedAttributeLogicalNames | ForEach-Object {
                "LogicalName eq '$(
                    ConvertTo-ODataKeyString ([string]$_)
                )'"
            }
        ) -join ' or '
        $attributeExpand += ";`$filter=$attributeFilter"
    }
    $attributeExpand += ')'

    return (
        '/EntityDefinitions?' +
        "`$select=MetadataId,LogicalName,SchemaName,OwnershipType," +
        'PrimaryNameAttribute,IsAuditEnabled,DisplayName,Description,ObjectTypeCode&' +
        "`$expand=$attributeExpand," +
        "ManyToOneRelationships(`$select=SchemaName,ReferencedEntity,ReferencingEntity,ReferencingAttribute,CascadeConfiguration)&" +
        "`$filter=LogicalName eq '$escapedLogicalName'"
    )
}

function Get-ConvergenceKeyPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$TableLogicalName,

        [Parameter(Mandatory)]
        [string]$SchemaName
    )

    $escapedTableName = ConvertTo-ODataKeyString $TableLogicalName
    $escapedSchemaName = ConvertTo-ODataKeyString $SchemaName
    return (
        "/EntityDefinitions(LogicalName='$escapedTableName')/Keys?" +
        "`$select=MetadataId,SchemaName,KeyAttributes&" +
        "`$filter=SchemaName eq '$escapedSchemaName'"
    )
}

function Get-ConvergenceSavedQueryPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$TableLogicalName,

        [Parameter(Mandatory)]
        [string]$Label
    )

    $escapedLabel = ConvertTo-ODataKeyString $Label
    $escapedTableName = ConvertTo-ODataKeyString $TableLogicalName
    return (
        '/savedqueries?' +
        "`$select=savedqueryid,name,description,returnedtypecode,fetchxml,layoutxml&" +
        "`$filter=name eq '$escapedLabel' and returnedtypecode eq '$escapedTableName'"
    )
}

function Get-ConvergenceSystemFormPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$TableLogicalName,

        [Parameter(Mandatory)]
        [string]$Label
    )

    $escapedLabel = ConvertTo-ODataKeyString $Label
    $escapedTableName = ConvertTo-ODataKeyString $TableLogicalName
    return (
        '/systemforms?' +
        "`$select=formid,name,description,objecttypecode,type,formxml&" +
        "`$filter=name eq '$escapedLabel' and objecttypecode eq '$escapedTableName' and type eq 2"
    )
}

function Get-ConvergenceRetrieveLocLabelsPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$EntityLogicalName,

        [Parameter(Mandatory)]
        [string]$IdProperty,

        [Parameter(Mandatory)]
        [string]$RecordId,

        [Parameter(Mandatory)]
        [string]$AttributeName
    )

    $resolvedRecordId = ([string]$RecordId).Trim('{}')
    $entityMoniker = [ordered]@{
        '@odata.type' = "Microsoft.Dynamics.CRM.$EntityLogicalName"
        "$IdProperty" = $resolvedRecordId
    } | ConvertTo-Json -Compress
    $escapedEntityMoniker = [System.Uri]::EscapeDataString($entityMoniker)
    $escapedAttributeName = ConvertTo-ODataKeyString $AttributeName
    return (
        '/RetrieveLocLabels(EntityMoniker=@p1,AttributeName=@p2,IncludeUnpublished=@p3)?' +
        "@p1=$escapedEntityMoniker&" +
        "@p2='$escapedAttributeName'&" +
        '@p3=true'
    )
}

function Invoke-ConvergenceDataverseRequest {
    [CmdletBinding()]
    param(
        [ValidateSet('GET')]
        [string]$Method = 'GET',

        [Parameter(Mandatory)]
        [string]$EnvironmentUrl,

        [Parameter(Mandatory)]
        [string]$Path,

        [hashtable]$Headers = @{}
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

    if ($Headers.Count -gt 0) {
        $arguments += '--headers'
        foreach ($headerName in @($Headers.Keys | Sort-Object)) {
            $arguments += "$headerName=$($Headers[$headerName])"
        }
    }

    $output = & az @arguments 2>&1
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0) {
        $detail = ($output | Out-String).Trim()
        throw "Dataverse convergence transport failed (GET $Path); az rest exited with code $exitCode. $detail"
    }

    $text = ($output | Out-String).Trim()
    if ([string]::IsNullOrWhiteSpace($text)) {
        return $null
    }

    return $text | ConvertFrom-Json -ErrorAction Stop
}

function Invoke-DataverseRequest {
    [CmdletBinding()]
    param(
        [ValidateSet('GET')]
        [string]$Method = 'GET',

        [Parameter(Mandatory)]
        [string]$Path,

        [AllowNull()]
        [object]$Body,

        [hashtable]$Headers = @{}
    )

    if ($null -ne $Body) {
        throw "Convergence gate is GET-only; body submission is not allowed for '$Method $Path'."
    }

    if ([string]::IsNullOrWhiteSpace($script:DataverseBaseUrl)) {
        throw 'Dataverse base URL was not initialized for convergence verification.'
    }

    return Invoke-ConvergenceDataverseRequest `
        -Method $Method `
        -EnvironmentUrl $script:DataverseBaseUrl `
        -Path $Path `
        -Headers $Headers
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

    return Invoke-ConvergenceDataverseRequest `
        -Method $Method `
        -EnvironmentUrl $EnvironmentUrl `
        -Path $Path
}

function Test-ConvergenceLocalizedRecordFields {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$EnvironmentUrl,

        [Parameter(Mandatory)]
        [string]$EntityLogicalName,

        [Parameter(Mandatory)]
        [string]$IdProperty,

        [Parameter(Mandatory)]
        [string]$RecordId,

        [Parameter(Mandatory)]
        $LocalizedFields,

        [Parameter(Mandatory)]
        [string]$Component
    )

    $differences = [System.Collections.Generic.List[object]]::new()
    $details = [System.Collections.Generic.List[string]]::new()
    $unsupported = [System.Collections.Generic.List[string]]::new()

    foreach ($field in @($LocalizedFields.Keys | Sort-Object)) {
        $response = $null
        try {
            $response = Invoke-ConvergenceDataverseRequest `
                -Method GET `
                -EnvironmentUrl $EnvironmentUrl `
                -Path (Get-ConvergenceRetrieveLocLabelsPath `
                    -EntityLogicalName $EntityLogicalName `
                    -IdProperty $IdProperty `
                    -RecordId $RecordId `
                    -AttributeName ([string]$field))
        }
        catch {
            if (Test-ConvergenceRetrieveLocLabelsUnsupportedError $_) {
                [void]$unsupported.Add(
                    "RetrieveLocLabels GET for '$EntityLogicalName.$field' on '$Component' is unavailable for GET-only localized convergence verification in this tenant. $(
                        Get-ConvergenceErrorMessage -ErrorRecord $_
                    )"
                )
                continue
            }

            if (Test-ConvergenceTransportError $_) {
                throw
            }

            [void]$details.Add((Get-ConvergenceErrorMessage -ErrorRecord $_))
            continue
        }

        if ($null -eq $response -or
            $response.PSObject.Properties.Name -notcontains 'Label' -or
            $null -eq $response.Label) {
            [void]$unsupported.Add(
                "RetrieveLocLabels GET for '$EntityLogicalName.$field' on '$Component' returned no Label payload; GET-only localized convergence verification cannot prove the required translations in this tenant."
            )
            continue
        }

        foreach ($language in @($script:RequiredLanguages)) {
            $expected = [string]$LocalizedFields[$field].$language
            $actual = Get-ConvergenceLocalizedLabel `
                -LocalizedValue $response.Label `
                -LanguageCode $language
            if ($actual -cne $expected) {
                [void]$differences.Add([pscustomobject][ordered]@{
                        Property = [string]$field
                        Language = [string]$language
                        Expected = $expected
                        Actual   = $actual
                    })
            }
        }
    }

    $state = 'Ready'
    if ($differences.Count -gt 0 -or $details.Count -gt 0) {
        $state = 'ContractConflict'
    }
    elseif ($unsupported.Count -gt 0) {
        $state = 'UnsupportedInTenant'
    }

    return [pscustomobject]@{
        State       = $state
        Differences = @($differences)
        Details     = @(
            Get-UniqueConvergenceStrings -Value (
                @($details) + @($unsupported)
            )
        )
    }
}

function Get-PicklistAttributeMetadata {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$TableLogicalName,

        [Parameter(Mandatory)]
        [string]$AttributeLogicalName
    )

    return Get-One (
        Get-ConvergencePicklistAttributePath `
            -TableLogicalName $TableLogicalName `
            -AttributeLogicalName $AttributeLogicalName
    )
}

function Get-TypedAttributeMetadata {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$TableLogicalName,

        [Parameter(Mandatory)]
        $Column
    )

    return Get-One (
        Get-ConvergenceTypedAttributePath `
            -TableLogicalName $TableLogicalName `
            -Column $Column
    )
}

function Assert-ConvergenceSolutionOwnership {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Existing,

        [Parameter(Mandatory)]
        [string]$Expected,

        [Parameter(Mandatory)]
        [string]$Component
    )

    if ($Existing.PSObject.Properties.Name -contains 'formid') {
        if ($Existing.PSObject.Properties.Name -contains 'SolutionUniqueName' -and
            $Existing.SolutionUniqueName -and
            [string]$Existing.SolutionUniqueName -ne $Expected) {
            throw "Structural ownership conflict for '$Component': expected '$Expected', found '$($Existing.SolutionUniqueName)'."
        }

        $componentId = ([string]$Existing.formid).Trim('{}')
        if (-not [string]::IsNullOrWhiteSpace($componentId)) {
            $membership = Invoke-DataverseRequest -Method GET -Path (
                Get-ConvergenceSolutionMembershipPath -ComponentId $componentId
            )
            $solutionNames = @($membership.value | ForEach-Object {
                    if ($_.solutionid) { [string]$_.solutionid.uniquename }
                })
            if ($Expected -notin $solutionNames) {
                throw "Structural ownership conflict for '$Component': component is not in '$Expected'."
            }
        }

        if ($Existing._solutionid_value) {
            $solutionId = ([string]$Existing._solutionid_value).Trim('{}')
            $solution = Get-One (
                "/solutions?`$select=uniquename&`$filter=solutionid eq $solutionId"
            )
            if ($null -eq $solution -or
                [string]$solution.uniquename -ne $Expected) {
                throw "Structural ownership conflict for '$Component': expected '$Expected'."
            }
        }

        return
    }

    Assert-SolutionOwnership $Existing $Expected $Component
}

function Test-InsuranceFoundationManifestAlignment {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Contract,

        [Parameter(Mandatory)]
        $Manifest
    )

    $missingSolutions = @()
    $manifestSolutions = @($Manifest.solutions | ForEach-Object {
            [string]$_.uniqueName
        })
    foreach ($solutionUniqueName in @($Contract.solutions)) {
        if ([string]$solutionUniqueName -notin $manifestSolutions) {
            $missingSolutions += [string]$solutionUniqueName
        }
    }

    $details = [System.Collections.Generic.List[string]]::new()
    if ($missingSolutions.Count -gt 0) {
        [void]$details.Add(
            "Contract solutions are absent from solution/manifest.json: $($missingSolutions -join ', ')."
        )
    }

    if ($null -eq $Manifest.publisher -or
        [string]::IsNullOrWhiteSpace([string]$Manifest.publisher.uniqueName) -or
        [string]::IsNullOrWhiteSpace([string]$Manifest.publisher.prefix)) {
        [void]$details.Add(
            'solution/manifest.json must declare publisher.uniqueName and publisher.prefix.'
        )
    }

    if ($details.Count -eq 0) {
        return New-ConvergenceResult -Component 'manifest' -State 'Ready'
    }

    return New-ConvergenceResult `
        -Component 'manifest' `
        -State 'ContractConflict' `
        -Missing $missingSolutions `
        -Details @($details)
}

function Test-InsuranceFoundationLanguages {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$EnvironmentUrl,

        [Parameter(Mandatory)]
        $Contract
    )

    Set-ConvergenceRuntimeContext -EnvironmentUrl $EnvironmentUrl

    $response = Invoke-ConvergenceDataverseRequest `
        -Method GET `
        -EnvironmentUrl $EnvironmentUrl `
        -Path (Get-ConvergenceLanguagesPath)
    if ($null -eq $response -or
        $response.PSObject.Properties.Name -notcontains 'RetrieveProvisionedLanguages') {
        return New-ConvergenceResult `
            -Component 'languages' `
            -State 'Precondition' `
            -Details @('RetrieveProvisionedLanguages returned no language collection.')
    }

    $provisioned = @($response.RetrieveProvisionedLanguages | ForEach-Object {
            [string]$_
        })
    $missing = @($Contract.languages | Where-Object {
            [string]$_ -notin $provisioned
        })
    if ($missing.Count -gt 0) {
        return New-ConvergenceResult `
            -Component 'languages' `
            -State 'Precondition' `
            -Missing $missing `
            -Details @(
                "Required Dataverse languages are not yet provisioned: $($missing -join ', ')."
            )
    }

    return New-ConvergenceResult -Component 'languages' -State 'Ready'
}

function Test-InsuranceFoundationSolutions {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$EnvironmentUrl,

        [Parameter(Mandatory)]
        $Contract,

        [Parameter(Mandatory)]
        $Manifest
    )

    Set-ConvergenceRuntimeContext -EnvironmentUrl $EnvironmentUrl

    $response = Invoke-ConvergenceDataverseRequest `
        -Method GET `
        -EnvironmentUrl $EnvironmentUrl `
        -Path (Get-ConvergenceSolutionsPath -SolutionUniqueName @($Contract.solutions))
    $solutions = @($response.value)
    $missing = @()
    $differences = [System.Collections.Generic.List[object]]::new()
    foreach ($expectedSolution in @($Contract.solutions)) {
        $matches = @($solutions | Where-Object {
                [string]$_.uniquename -ceq [string]$expectedSolution
            })
        if ($matches.Count -eq 0) {
            $missing += [string]$expectedSolution
            continue
        }
        if ($matches.Count -gt 1) {
            [void]$differences.Add([pscustomobject]@{
                    Property = 'DuplicateSolution'
                    Expected = [string]$expectedSolution
                    Actual   = $matches.Count
                })
            continue
        }

        $solution = $matches[0]
        $publisher = $solution.publisherid
        if ($null -eq $publisher) {
            [void]$differences.Add([pscustomobject]@{
                    Property = 'Publisher'
                    Expected = [string]$Manifest.publisher.uniqueName
                    Actual   = $null
                })
            continue
        }

        if ([string]$publisher.uniquename -cne [string]$Manifest.publisher.uniqueName) {
            [void]$differences.Add([pscustomobject]@{
                    Property = "$expectedSolution.PublisherUniqueName"
                    Expected = [string]$Manifest.publisher.uniqueName
                    Actual   = [string]$publisher.uniquename
                })
        }
        if ([string]$publisher.customizationprefix -cne [string]$Manifest.publisher.prefix) {
            [void]$differences.Add([pscustomobject]@{
                    Property = "$expectedSolution.CustomizationPrefix"
                    Expected = [string]$Manifest.publisher.prefix
                    Actual   = [string]$publisher.customizationprefix
                })
        }
        if ($publisher.PSObject.Properties.Name -contains 'customizationoptionvalueprefix') {
            $actualOptionValuePrefix = [int]$publisher.customizationoptionvalueprefix
            $expectedOptionValuePrefix = [int]$Manifest.publisher.customizationOptionValuePrefix
            if ($actualOptionValuePrefix -ne $expectedOptionValuePrefix) {
                [void]$differences.Add([pscustomobject]@{
                        Property = "$expectedSolution.CustomizationOptionValuePrefix"
                        Expected = $expectedOptionValuePrefix
                        Actual   = $actualOptionValuePrefix
                    })
            }
        }
    }

    if ($differences.Count -gt 0) {
        return New-ConvergenceResult `
            -Component 'solutions' `
            -State 'ContractConflict' `
            -Missing $missing `
            -Differences @($differences) `
            -Details (Get-ConvergenceDifferenceDetails -Differences @($differences))
    }

    if ($missing.Count -gt 0) {
        return New-ConvergenceResult `
            -Component 'solutions' `
            -State 'Precondition' `
            -Missing $missing `
            -Details @(
                "Required solutions are missing from the environment: $($missing -join ', ')."
            )
    }

    return New-ConvergenceResult -Component 'solutions' -State 'Ready'
}

function Compare-InsuranceFoundationChoiceOptions {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Choice,

        [AllowNull()]
        [object[]]$ActualOptions = @()
    )

    $expectedOptions = @{}
    $expectedValue = 100000000
    foreach ($option in @($Choice.options)) {
        $expectedOptions[[string]$expectedValue] = [pscustomobject]@{
            Code     = [string]$option.code
            Metadata = $option.metadata
        }
        $expectedValue++
    }

    $actualByValue = @{}
    $duplicates = [System.Collections.Generic.List[object]]::new()
    foreach ($actualOption in @($ActualOptions)) {
        if ($null -eq $actualOption) {
            continue
        }

        $value = [string]$actualOption.Value
        if ([string]::IsNullOrWhiteSpace($value)) {
            [void]$duplicates.Add([pscustomobject]@{
                    Property = 'OptionValue'
                    Expected = 'Non-empty'
                    Actual   = $null
                })
            continue
        }

        if ($actualByValue.ContainsKey($value)) {
            [void]$duplicates.Add([pscustomobject]@{
                    Property = 'DuplicateOptionValue'
                    Expected = $value
                    Actual   = $value
                })
            continue
        }

        $actualByValue[$value] = $actualOption
    }

    $missing = [System.Collections.Generic.List[string]]::new()
    $unexpected = [System.Collections.Generic.List[string]]::new()
    $differences = [System.Collections.Generic.List[object]]::new()

    foreach ($value in @($expectedOptions.Keys | Sort-Object)) {
        if (-not $actualByValue.ContainsKey($value)) {
            [void]$missing.Add("$($expectedOptions[$value].Code)($value)")
            continue
        }

        $actualOption = $actualByValue[$value]
        foreach ($pair in @(
                @{ Property = 'Label'; Contract = 'label' },
                @{ Property = 'Description'; Contract = 'description' }
            )) {
            foreach ($language in @($script:RequiredLanguages)) {
                $expectedText = [string]$expectedOptions[$value].Metadata.($pair.Contract).$language
                $actualText = Get-ConvergenceLocalizedLabel `
                    -LocalizedValue $actualOption.($pair.Property) `
                    -LanguageCode $language
                if ($actualText -cne $expectedText) {
                    [void]$differences.Add([pscustomobject][ordered]@{
                            Property = $pair.Property
                            Language = [string]$language
                            Code     = [string]$expectedOptions[$value].Code
                            Expected = $expectedText
                            Actual   = $actualText
                        })
                }
            }
        }
    }

    foreach ($value in @($actualByValue.Keys | Sort-Object)) {
        if (-not $expectedOptions.ContainsKey($value)) {
            [void]$unexpected.Add([string]$value)
        }
    }

    foreach ($duplicate in @($duplicates)) {
        [void]$differences.Add($duplicate)
    }

    return [pscustomobject]@{
        Missing     = @($missing)
        Unexpected  = @($unexpected)
        Differences = @($differences)
    }
}

function Test-InsuranceFoundationChoice {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$EnvironmentUrl,

        [Parameter(Mandatory)]
        $Choice
    )

    Set-ConvergenceRuntimeContext -EnvironmentUrl $EnvironmentUrl

    $component = [string]$Choice.logicalName
    try {
        $actual = Get-GlobalOptionSet -Name $Choice.logicalName
    }
    catch {
        if (Test-ConvergenceTransportError $_) {
            throw
        }
        return New-ConvergenceResult `
            -Component $component `
            -State 'ContractConflict' `
            -Details @($_.Exception.Message)
    }
    if ($null -eq $actual) {
        return New-ConvergenceResult `
            -Component $component `
            -State 'ContractConflict' `
            -Missing @($Choice.logicalName) `
            -Details @("Global choice '$($Choice.logicalName)' was not found.")
    }

    $differences = [System.Collections.Generic.List[object]]::new()
    $details = [System.Collections.Generic.List[string]]::new()
    try {
        Assert-ConvergenceSolutionOwnership `
            -Existing $actual `
            -Expected ([string]$Choice.solution) `
            -Component $component
    }
    catch {
        [void]$details.Add($_.Exception.Message)
    }

    if ([string]$actual.Name -cne [string]$Choice.logicalName) {
        [void]$differences.Add([pscustomobject]@{
                Property = 'Name'
                Expected = [string]$Choice.logicalName
                Actual   = [string]$actual.Name
            })
    }
    if (-not [bool]$actual.IsGlobal) {
        [void]$differences.Add([pscustomobject]@{
                Property = 'IsGlobal'
                Expected = $true
                Actual   = [bool]$actual.IsGlobal
            })
    }
    if ($actual.PSObject.Properties.Name -contains 'OptionSetType' -and
        [string]$actual.OptionSetType -ne 'Picklist') {
        [void]$differences.Add([pscustomobject]@{
                Property = 'OptionSetType'
                Expected = 'Picklist'
                Actual   = [string]$actual.OptionSetType
            })
    }

    if (Test-LocalizedMetadataChanged -Existing $actual -Metadata $Choice.metadata) {
        foreach ($difference in @(Get-ConvergenceLocalizedMetadataDifferences `
                    -Existing $actual `
                    -Metadata $Choice.metadata)) {
            [void]$differences.Add($difference)
        }
    }

    $optionComparison = Compare-InsuranceFoundationChoiceOptions `
        -Choice $Choice `
        -ActualOptions @($actual.Options)
    foreach ($difference in @($optionComparison.Differences)) {
        [void]$differences.Add($difference)
    }

    Add-ConvergenceStringsToList `
        -List $details `
        -Values @(Get-ConvergenceDifferenceDetails -Differences @($differences))
    if ($optionComparison.Unexpected.Count -gt 0) {
        [void]$details.Add(
            "Unexpected option values exist for '$($Choice.logicalName)': $(@($optionComparison.Unexpected) -join ', ')."
        )
    }

    if ($differences.Count -eq 0 -and
        $optionComparison.Missing.Count -eq 0 -and
        $optionComparison.Unexpected.Count -eq 0 -and
        $details.Count -eq 0) {
        return New-ConvergenceResult -Component $component -State 'Ready'
    }

    return New-ConvergenceResult `
        -Component $component `
        -State 'ContractConflict' `
        -Missing @($optionComparison.Missing) `
        -Unexpected @($optionComparison.Unexpected) `
        -Differences @($differences) `
        -Details @($details)
}

function Test-InsuranceFoundationNativeExtension {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$EnvironmentUrl,

        [Parameter(Mandatory)]
        $Extension
    )

    Set-ConvergenceRuntimeContext -EnvironmentUrl $EnvironmentUrl

    $component = "$($Extension.table)/$($Extension.logicalName)"
    try {
        $actual = Get-TypedAttributeMetadata `
            -TableLogicalName $Extension.table `
            -Column $Extension
    }
    catch {
        if (Test-ConvergenceTransportError $_) {
            throw
        }
        return New-ConvergenceResult `
            -Component $component `
            -State 'ContractConflict' `
            -Details @($_.Exception.Message)
    }
    if ($null -eq $actual) {
        return New-ConvergenceResult `
            -Component $component `
            -State 'ContractConflict' `
            -Missing @($Extension.logicalName) `
            -Details @("Native extension '$component' was not found.")
    }

    $differences = [System.Collections.Generic.List[object]]::new()
    $details = [System.Collections.Generic.List[string]]::new()
    try {
        Assert-ConvergenceSolutionOwnership `
            -Existing $actual `
            -Expected ([string]$Extension.solution) `
            -Component $component
    }
    catch {
        [void]$details.Add($_.Exception.Message)
    }

    if ([string]$actual.LogicalName -cne [string]$Extension.logicalName) {
        [void]$differences.Add([pscustomobject]@{
                Property = 'LogicalName'
                Expected = [string]$Extension.logicalName
                Actual   = [string]$actual.LogicalName
            })
    }
    if ([string]$actual.SchemaName -cne [string]$Extension.schemaName) {
        [void]$differences.Add([pscustomobject]@{
                Property = 'SchemaName'
                Expected = [string]$Extension.schemaName
                Actual   = [string]$actual.SchemaName
            })
    }

    try {
        Test-AttributeCompatibility `
            -Existing $actual `
            -Column $Extension `
            -Owner $Extension.table
    }
    catch {
        [void]$details.Add($_.Exception.Message)
    }

    $expectedRequiredLevel = (ConvertTo-RequiredLevel ([bool]$Extension.required)).Value
    $actualRequiredLevel = Get-ConvergenceRequiredLevelValue -Attribute $actual
    if ($actualRequiredLevel -cne $expectedRequiredLevel) {
        [void]$differences.Add([pscustomobject]@{
                Property = 'RequiredLevel'
                Expected = $expectedRequiredLevel
                Actual   = $actualRequiredLevel
            })
    }

    $expectedAudit = [bool]$Extension.auditing
    $actualAudit = Get-ConvergenceManagedPropertyValue -Value $actual.IsAuditEnabled
    if ($actualAudit -ne $expectedAudit) {
        [void]$differences.Add([pscustomobject]@{
                Property = 'IsAuditEnabled'
                Expected = $expectedAudit
                Actual   = $actualAudit
            })
    }

    if (Test-LocalizedMetadataChanged -Existing $actual -Metadata $Extension.metadata) {
        foreach ($difference in @(Get-ConvergenceLocalizedMetadataDifferences `
                    -Existing $actual `
                    -Metadata $Extension.metadata)) {
            [void]$differences.Add($difference)
        }
    }

    Add-ConvergenceStringsToList `
        -List $details `
        -Values @(Get-ConvergenceDifferenceDetails -Differences @($differences))
    if ($differences.Count -eq 0 -and $details.Count -eq 0) {
        return New-ConvergenceResult -Component $component -State 'Ready'
    }

    return New-ConvergenceResult `
        -Component $component `
        -State 'ContractConflict' `
        -Differences @($differences) `
        -Details @($details)
}

function Get-ConvergenceSnapshotAttribute {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Snapshot,

        [Parameter(Mandatory)]
        [string]$LogicalName
    )

    return @($Snapshot.Attributes | Where-Object {
            [string]$_.LogicalName -ceq $LogicalName
        })
}

function Test-InsuranceFoundationTableColumn {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Table,

        [Parameter(Mandatory)]
        $Column,

        [Parameter(Mandatory)]
        $Snapshot
    )

    $component = "$($Table.logicalName)/column/$($Column.logicalName)"
    $matches = @(Get-ConvergenceSnapshotAttribute -Snapshot $Snapshot -LogicalName $Column.logicalName)
    if ($matches.Count -eq 0) {
        return New-ConvergenceResult `
            -Component $component `
            -State 'ContractConflict' `
            -Missing @($Column.logicalName) `
            -Details @("Column '$($Column.logicalName)' is missing from '$($Table.logicalName)'.")
    }
    if ($matches.Count -gt 1) {
        return New-ConvergenceResult `
            -Component $component `
            -State 'ContractConflict' `
            -Details @("Duplicate physical attributes found for '$($Table.logicalName)/$($Column.logicalName)'.")
    }

    $actual = $matches[0]
    $differences = [System.Collections.Generic.List[object]]::new()
    $details = [System.Collections.Generic.List[string]]::new()

    if ([string]$actual.SchemaName -cne [string]$Column.schemaName) {
        [void]$differences.Add([pscustomobject]@{
                Property = 'SchemaName'
                Expected = [string]$Column.schemaName
                Actual   = [string]$actual.SchemaName
            })
    }

    try {
        Test-AttributeCompatibility `
            -Existing $actual `
            -Column $Column `
            -Owner $Table.logicalName
    }
    catch {
        [void]$details.Add($_.Exception.Message)
    }

    $expectedRequiredLevel = (ConvertTo-RequiredLevel ([bool]$Column.required)).Value
    $actualRequiredLevel = Get-ConvergenceRequiredLevelValue -Attribute $actual
    if ($actualRequiredLevel -cne $expectedRequiredLevel) {
        [void]$differences.Add([pscustomobject]@{
                Property = 'RequiredLevel'
                Expected = $expectedRequiredLevel
                Actual   = $actualRequiredLevel
            })
    }

    $expectedAudit = [bool]$Column.auditing
    $actualAudit = Get-ConvergenceManagedPropertyValue -Value $actual.IsAuditEnabled
    if ($actualAudit -ne $expectedAudit) {
        [void]$differences.Add([pscustomobject]@{
                Property = 'IsAuditEnabled'
                Expected = $expectedAudit
                Actual   = $actualAudit
            })
    }

    if (Test-LocalizedMetadataChanged -Existing $actual -Metadata $Column.metadata) {
        foreach ($difference in @(Get-ConvergenceLocalizedMetadataDifferences `
                    -Existing $actual `
                    -Metadata $Column.metadata)) {
            [void]$differences.Add($difference)
        }
    }

    Add-ConvergenceStringsToList `
        -List $details `
        -Values @(Get-ConvergenceDifferenceDetails -Differences @($differences))
    if ($differences.Count -eq 0 -and $details.Count -eq 0) {
        return New-ConvergenceResult -Component $component -State 'Ready'
    }

    return New-ConvergenceResult `
        -Component $component `
        -State 'ContractConflict' `
        -Differences @($differences) `
        -Details @($details)
}

function Test-InsuranceFoundationOrdinaryRelationship {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Table,

        [Parameter(Mandatory)]
        $Relationship,

        [Parameter(Mandatory)]
        $Snapshot
    )

    $component = "$($Table.logicalName)/relationship/$($Relationship.schemaName)"
    try {
        if (-not (Test-OrdinaryRelationshipVisibility `
                    -Table $Table `
                    -Relationship $Relationship `
                    -Snapshot $Snapshot)) {
            return New-ConvergenceResult `
                -Component $component `
                -State 'ContractConflict' `
                -Details @("Relationship '$($Relationship.schemaName)' is missing or incomplete.")
        }
    }
    catch {
        return New-ConvergenceResult `
            -Component $component `
            -State 'ContractConflict' `
            -Details @($_.Exception.Message)
    }

    return New-ConvergenceResult -Component $component -State 'Ready'
}

function Test-InsuranceFoundationCustomerRelationship {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Table,

        [Parameter(Mandatory)]
        $Column,

        [Parameter(Mandatory)]
        $Snapshot
    )

    $component = "$($Table.logicalName)/relationship/$($Column.logicalName)"
    try {
        if (-not (Test-CustomerRelationshipVisibility `
                    -Table $Table `
                    -Column $Column `
                    -Snapshot $Snapshot)) {
            return New-ConvergenceResult `
                -Component $component `
                -State 'ContractConflict' `
                -Details @("Customer relationship '$($Column.logicalName)' is missing or incomplete.")
        }
    }
    catch {
        return New-ConvergenceResult `
            -Component $component `
            -State 'ContractConflict' `
            -Details @($_.Exception.Message)
    }

    return New-ConvergenceResult -Component $component -State 'Ready'
}

function Test-InsuranceFoundationAlternateKey {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$EnvironmentUrl,

        [Parameter(Mandatory)]
        $Table,

        [Parameter(Mandatory)]
        $Key
    )

    Set-ConvergenceRuntimeContext -EnvironmentUrl $EnvironmentUrl

    $component = "$($Table.logicalName)/key/$($Key.schemaName)"
    try {
        $actual = Get-One (
            Get-ConvergenceKeyPath `
                -TableLogicalName $Table.logicalName `
                -SchemaName $Key.schemaName
        )
    }
    catch {
        if (Test-ConvergenceTransportError $_) {
            throw
        }
        return New-ConvergenceResult `
            -Component $component `
            -State 'ContractConflict' `
            -Details @($_.Exception.Message)
    }
    if ($null -eq $actual) {
        return New-ConvergenceResult `
            -Component $component `
            -State 'ContractConflict' `
            -Missing @($Key.schemaName) `
            -Details @("Alternate key '$($Key.schemaName)' was not found.")
    }

    $differences = [System.Collections.Generic.List[object]]::new()
    if ([string]$actual.SchemaName -cne [string]$Key.schemaName) {
        [void]$differences.Add([pscustomobject]@{
                Property = 'SchemaName'
                Expected = [string]$Key.schemaName
                Actual   = [string]$actual.SchemaName
            })
    }

    $actualColumns = @($actual.KeyAttributes | Sort-Object)
    $expectedColumns = @($Key.columns | Sort-Object)
    if (($actualColumns -join ',') -cne ($expectedColumns -join ',')) {
        [void]$differences.Add([pscustomobject]@{
                Property = 'KeyAttributes'
                Expected = ($expectedColumns -join ',')
                Actual   = ($actualColumns -join ',')
            })
    }

    if ($differences.Count -eq 0) {
        return New-ConvergenceResult -Component $component -State 'Ready'
    }

    return New-ConvergenceResult `
        -Component $component `
        -State 'ContractConflict' `
        -Differences @($differences) `
        -Details (Get-ConvergenceDifferenceDetails -Differences @($differences))
}

function Test-InsuranceFoundationView {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$EnvironmentUrl,

        [Parameter(Mandatory)]
        $Table,

        [Parameter(Mandatory)]
        $View,

        [Parameter(Mandatory)]
        [int]$ObjectTypeCode
    )

    Set-ConvergenceRuntimeContext -EnvironmentUrl $EnvironmentUrl

    $component = "$($Table.logicalName)/view/$($View.name)"
    $expectedRequest = New-ViewRequest -Table $Table -View $View -ObjectTypeCode $ObjectTypeCode
    $expectedName = [string]$View.metadata.label.'1033'
    try {
        $actual = Get-One (
            Get-ConvergenceSavedQueryPath `
                -TableLogicalName $Table.logicalName `
                -Label $expectedName
        )
    }
    catch {
        if (Test-ConvergenceTransportError $_) {
            throw
        }
        return New-ConvergenceResult `
            -Component $component `
            -State 'ContractConflict' `
            -Details @($_.Exception.Message)
    }
    if ($null -eq $actual) {
        return New-ConvergenceResult `
            -Component $component `
            -State 'ContractConflict' `
            -Missing @($View.name) `
            -Details @("View '$($View.name)' was not found.")
    }

    $differences = [System.Collections.Generic.List[object]]::new()
    $details = [System.Collections.Generic.List[string]]::new()
    $unsupportedDetails = [System.Collections.Generic.List[string]]::new()
    try {
        Assert-ConvergenceSolutionOwnership `
            -Existing $actual `
            -Expected ([string]$Table.solution) `
            -Component $component
    }
    catch {
        [void]$details.Add($_.Exception.Message)
    }

    $localizedFields = Test-ConvergenceLocalizedRecordFields `
        -EnvironmentUrl $EnvironmentUrl `
        -EntityLogicalName 'savedquery' `
        -IdProperty 'savedqueryid' `
        -RecordId ([string]$actual.savedqueryid) `
        -LocalizedFields $expectedRequest.LocalizedFields `
        -Component $component
    switch ([string]$localizedFields.State) {
        'ContractConflict' {
            foreach ($difference in @($localizedFields.Differences)) {
                [void]$differences.Add($difference)
            }
            Add-ConvergenceStringsToList `
                -List $details `
                -Values @($localizedFields.Details)
        }
        'UnsupportedInTenant' {
            Add-ConvergenceStringsToList `
                -List $unsupportedDetails `
                -Values @($localizedFields.Details)
        }
    }

    try {
        if ($actual.returnedtypecode -and
            [string]$actual.returnedtypecode -ne [string]$Table.logicalName) {
            throw "Structural view target conflict for '$($View.name)'."
        }
        Assert-XmlCompatible `
            -Existing $actual `
            -Request $expectedRequest `
            -Property 'fetchxml' `
            -Component $View.name
        Assert-XmlCompatible `
            -Existing $actual `
            -Request $expectedRequest `
            -Property 'layoutxml' `
            -Component $View.name
    }
    catch {
        [void]$details.Add($_.Exception.Message)
    }

    Add-ConvergenceStringsToList `
        -List $details `
        -Values @(Get-ConvergenceDifferenceDetails -Differences @($differences))
    $allDetails = [System.Collections.Generic.List[string]]::new()
    Add-ConvergenceStringsToList -List $allDetails -Values @($details)
    Add-ConvergenceStringsToList -List $allDetails -Values @($unsupportedDetails)
    if ($differences.Count -eq 0 -and
        $details.Count -eq 0 -and
        $unsupportedDetails.Count -eq 0) {
        return New-ConvergenceResult -Component $component -State 'Ready'
    }

    return New-ConvergenceResult `
        -Component $component `
        -State $(if ($differences.Count -eq 0 -and
                $details.Count -eq 0 -and
                $unsupportedDetails.Count -gt 0) {
                'UnsupportedInTenant'
            }
            else {
                'ContractConflict'
            }) `
        -Differences @($differences) `
        -Details @($allDetails)
}

function Test-InsuranceFoundationForm {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$EnvironmentUrl,

        [Parameter(Mandatory)]
        $Table,

        [Parameter(Mandatory)]
        $Form
    )

    Set-ConvergenceRuntimeContext -EnvironmentUrl $EnvironmentUrl

    $component = "$($Table.logicalName)/form/$($Form.name)"
    $expectedRequest = New-FormRequest -Table $Table -Form $Form
    $expectedName = [string]$Form.metadata.label.'1033'
    try {
        $actual = Get-One (
            Get-ConvergenceSystemFormPath `
                -TableLogicalName $Table.logicalName `
                -Label $expectedName
        )
    }
    catch {
        if (Test-ConvergenceTransportError $_) {
            throw
        }
        return New-ConvergenceResult `
            -Component $component `
            -State 'ContractConflict' `
            -Details @($_.Exception.Message)
    }
    if ($null -eq $actual) {
        return New-ConvergenceResult `
            -Component $component `
            -State 'ContractConflict' `
            -Missing @($Form.name) `
            -Details @("Form '$($Form.name)' was not found.")
    }

    $differences = [System.Collections.Generic.List[object]]::new()
    $details = [System.Collections.Generic.List[string]]::new()
    $unsupportedDetails = [System.Collections.Generic.List[string]]::new()
    try {
        Assert-ConvergenceSolutionOwnership `
            -Existing $actual `
            -Expected ([string]$Table.solution) `
            -Component $component
    }
    catch {
        [void]$details.Add($_.Exception.Message)
    }

    $localizedFields = Test-ConvergenceLocalizedRecordFields `
        -EnvironmentUrl $EnvironmentUrl `
        -EntityLogicalName 'systemform' `
        -IdProperty 'formid' `
        -RecordId ([string]$actual.formid) `
        -LocalizedFields $expectedRequest.LocalizedFields `
        -Component $component
    switch ([string]$localizedFields.State) {
        'ContractConflict' {
            foreach ($difference in @($localizedFields.Differences)) {
                [void]$differences.Add($difference)
            }
            Add-ConvergenceStringsToList `
                -List $details `
                -Values @($localizedFields.Details)
        }
        'UnsupportedInTenant' {
            Add-ConvergenceStringsToList `
                -List $unsupportedDetails `
                -Values @($localizedFields.Details)
        }
    }

    try {
        if (($actual.objecttypecode -and
                [string]$actual.objecttypecode -ne [string]$Table.logicalName) -or
            ($actual.type -ne $null -and [int]$actual.type -ne 2)) {
            throw "Structural form target conflict for '$($Form.name)'."
        }
        Assert-XmlCompatible `
            -Existing $actual `
            -Request $expectedRequest `
            -Property 'formxml' `
            -Component $Form.name
    }
    catch {
        [void]$details.Add($_.Exception.Message)
    }

    Add-ConvergenceStringsToList `
        -List $details `
        -Values @(Get-ConvergenceDifferenceDetails -Differences @($differences))
    $allDetails = [System.Collections.Generic.List[string]]::new()
    Add-ConvergenceStringsToList -List $allDetails -Values @($details)
    Add-ConvergenceStringsToList -List $allDetails -Values @($unsupportedDetails)
    if ($differences.Count -eq 0 -and
        $details.Count -eq 0 -and
        $unsupportedDetails.Count -eq 0) {
        return New-ConvergenceResult -Component $component -State 'Ready'
    }

    return New-ConvergenceResult `
        -Component $component `
        -State $(if ($differences.Count -eq 0 -and
                $details.Count -eq 0 -and
                $unsupportedDetails.Count -gt 0) {
                'UnsupportedInTenant'
            }
            else {
                'ContractConflict'
            }) `
        -Differences @($differences) `
        -Details @($allDetails)
}

function Test-InsuranceFoundationTable {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$EnvironmentUrl,

        [Parameter(Mandatory)]
        $Table
    )

    Set-ConvergenceRuntimeContext -EnvironmentUrl $EnvironmentUrl

    $requestedAttributeLogicalNames = @(
        Get-TableContractAttributeLogicalNames -Table $Table
    )
    try {
        $snapshot = Get-TableMetadataSnapshot `
            -LogicalName $Table.logicalName `
            -RequestedAttributeLogicalNames $requestedAttributeLogicalNames
    }
    catch {
        if (Test-ConvergenceTransportError $_) {
            throw
        }
        return New-ConvergenceResult `
            -Component ([string]$Table.logicalName) `
            -State 'ContractConflict' `
            -Details @($_.Exception.Message)
    }
    if ($null -eq $snapshot) {
        return New-ConvergenceResult `
            -Component ([string]$Table.logicalName) `
            -State 'ContractConflict' `
            -Missing @($Table.logicalName) `
            -Details @("Custom table '$($Table.logicalName)' was not found.")
    }

    $differences = [System.Collections.Generic.List[object]]::new()
    $details = [System.Collections.Generic.List[string]]::new()
    try {
        Assert-ConvergenceSolutionOwnership `
            -Existing $snapshot `
            -Expected ([string]$Table.solution) `
            -Component ([string]$Table.logicalName)
    }
    catch {
        [void]$details.Add($_.Exception.Message)
    }

    if ([string]$snapshot.SchemaName -cne [string]$Table.schemaName) {
        [void]$differences.Add([pscustomobject]@{
                Property = 'SchemaName'
                Expected = [string]$Table.schemaName
                Actual   = [string]$snapshot.SchemaName
            })
    }
    if ([string]$snapshot.OwnershipType -cne [string]$Table.ownership) {
        [void]$differences.Add([pscustomobject]@{
                Property = 'OwnershipType'
                Expected = [string]$Table.ownership
                Actual   = [string]$snapshot.OwnershipType
            })
    }
    if ([string]$snapshot.PrimaryNameAttribute -cne 'crmshow_name') {
        [void]$differences.Add([pscustomobject]@{
                Property = 'PrimaryNameAttribute'
                Expected = 'crmshow_name'
                Actual   = [string]$snapshot.PrimaryNameAttribute
            })
    }

    $expectedAudit = [bool]$Table.auditing
    $actualAudit = Get-ConvergenceManagedPropertyValue -Value $snapshot.IsAuditEnabled
    if ($actualAudit -ne $expectedAudit) {
        [void]$differences.Add([pscustomobject]@{
                Property = 'IsAuditEnabled'
                Expected = $expectedAudit
                Actual   = $actualAudit
            })
    }

    if (Test-LocalizedMetadataChanged -Existing $snapshot -Metadata $Table.metadata) {
        foreach ($difference in @(Get-ConvergenceLocalizedMetadataDifferences `
                    -Existing $snapshot `
                    -Metadata $Table.metadata)) {
            [void]$differences.Add($difference)
        }
    }

    $objectTypeCode = if ($snapshot.ObjectTypeCode) {
        [int]$snapshot.ObjectTypeCode
    }
    else {
        Resolve-TableObjectTypeCode -TableLogicalName $Table.logicalName
    }

    $children = [System.Collections.Generic.List[object]]::new()
    foreach ($column in @($Table.columns)) {
        [void]$children.Add(
            (Test-InsuranceFoundationTableColumn `
                -Table $Table `
                -Column $column `
                -Snapshot $snapshot)
        )
    }
    foreach ($relationship in @($Table.relationships | Where-Object {
                $_.authoring -ne 'CreateCustomerRelationships'
            })) {
        [void]$children.Add(
            (Test-InsuranceFoundationOrdinaryRelationship `
                -Table $Table `
                -Relationship $relationship `
                -Snapshot $snapshot)
        )
    }
    foreach ($customerColumn in @($Table.columns | Where-Object {
                $_.type -eq 'Customer'
            })) {
        [void]$children.Add(
            (Test-InsuranceFoundationCustomerRelationship `
                -Table $Table `
                -Column $customerColumn `
                -Snapshot $snapshot)
        )
    }
    foreach ($key in @($Table.alternateKeys)) {
        [void]$children.Add(
            (Test-InsuranceFoundationAlternateKey `
                -EnvironmentUrl $EnvironmentUrl `
                -Table $Table `
                -Key $key)
        )
    }
    foreach ($rule in @($Table.businessRules)) {
        $reportView = [pscustomobject]@{
            name     = "$($rule.name)report"
            purpose  = 'InvalidDateReporting'
            columns  = @(
                if ($Table.logicalName -eq 'crmshow_policyprojection') {
                    'crmshow_name'
                    'crmshow_effectivefrom'
                    'crmshow_effectiveto'
                }
                else {
                    'crmshow_name'
                    'crmshow_validfrom'
                    'crmshow_validto'
                }
            )
            metadata = $rule.metadata
        }
        [void]$children.Add(
            (Test-InsuranceFoundationView `
                -EnvironmentUrl $EnvironmentUrl `
                -Table $Table `
                -View $reportView `
                -ObjectTypeCode $objectTypeCode)
        )
    }
    foreach ($view in @($Table.views)) {
        [void]$children.Add(
            (Test-InsuranceFoundationView `
                -EnvironmentUrl $EnvironmentUrl `
                -Table $Table `
                -View $view `
                -ObjectTypeCode $objectTypeCode)
        )
    }
    foreach ($form in @($Table.forms)) {
        [void]$children.Add(
            (Test-InsuranceFoundationForm `
                -EnvironmentUrl $EnvironmentUrl `
                -Table $Table `
                -Form $form)
        )
    }

    $blockingChildren = @($children | Where-Object {
            [string]$_.State -ne 'Ready'
        })
    if ($blockingChildren.Count -gt 0) {
        [void]$details.Add(
            "Blocking child components: $(@($blockingChildren.Component) -join ', ')."
        )
    }

    Add-ConvergenceStringsToList `
        -List $details `
        -Values @(Get-ConvergenceDifferenceDetails -Differences @($differences))
    if ($differences.Count -eq 0 -and $details.Count -eq 0 -and $blockingChildren.Count -eq 0) {
        return New-ConvergenceResult `
            -Component ([string]$Table.logicalName) `
            -State 'Ready' `
            -Children @($children)
    }

    return New-ConvergenceResult `
        -Component ([string]$Table.logicalName) `
        -State 'ContractConflict' `
        -Differences @($differences) `
        -Details @($details) `
        -Children @($children)
}

function Test-InsuranceFoundationRoles {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$EnvironmentUrl,

        [Parameter(Mandatory)]
        $Contract
    )

    Set-ConvergenceRuntimeContext -EnvironmentUrl $EnvironmentUrl

    $verification = Invoke-InsuranceSecurityRoleVerification `
        -EnvironmentUrl $EnvironmentUrl `
        -Contract $Contract
    $details = [System.Collections.Generic.List[string]]::new()
    foreach ($result in @($verification.Results | Where-Object {
                [string]$_.State -ne 'Ready'
            })) {
        foreach ($detail in @($result.Details)) {
            [void]$details.Add($detail)
        }
    }

    return New-ConvergenceResult `
        -Component 'roles' `
        -State ([string]$verification.State) `
        -Details @($details) `
        -Children @($verification.Results)
}

function Invoke-InsuranceFoundationConvergence {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$EnvironmentUrl,

        [Parameter(Mandatory)]
        [string]$ContractPath
    )

    Set-ConvergenceRuntimeContext `
        -EnvironmentUrl $EnvironmentUrl `
        -ContractPath $ContractPath

    $contract = $null
    try {
        $contract = Test-InsuranceFoundationContract -Path $ContractPath
    }
    catch {
        return New-ConvergenceSummary -Results @(
            (New-ConvergenceResult `
                -Component 'contract' `
                -State 'ContractConflict' `
                -Details @($_.Exception.Message))
        )
    }

    $manifest = $null
    try {
        $manifest = Get-Manifest -Path (Get-ConvergenceManifestPath) -Validate
    }
    catch {
        return New-ConvergenceSummary -Results @(
            (New-ConvergenceResult `
                -Component 'manifest' `
                -State 'ContractConflict' `
                -Details @($_.Exception.Message))
        )
    }

    $manifestAlignment = Test-InsuranceFoundationManifestAlignment `
        -Contract $contract `
        -Manifest $manifest
    if ([string]$manifestAlignment.State -ne 'Ready') {
        return New-ConvergenceSummary -Results @($manifestAlignment)
    }

    $results = [System.Collections.Generic.List[object]]::new()
    [void]$results.Add(
        (Test-InsuranceFoundationLanguages `
            -EnvironmentUrl $EnvironmentUrl `
            -Contract $contract)
    )
    [void]$results.Add(
        (Test-InsuranceFoundationSolutions `
            -EnvironmentUrl $EnvironmentUrl `
            -Contract $contract `
            -Manifest $manifest)
    )
    foreach ($choice in @($contract.choices)) {
        [void]$results.Add(
            (Test-InsuranceFoundationChoice `
                -EnvironmentUrl $EnvironmentUrl `
                -Choice $choice)
        )
    }
    foreach ($extension in @($contract.nativeExtensions)) {
        [void]$results.Add(
            (Test-InsuranceFoundationNativeExtension `
                -EnvironmentUrl $EnvironmentUrl `
                -Extension $extension)
        )
    }
    foreach ($table in @($contract.tables)) {
        [void]$results.Add(
            (Test-InsuranceFoundationTable `
                -EnvironmentUrl $EnvironmentUrl `
                -Table $table)
        )
    }
    [void]$results.Add(
        (Test-InsuranceFoundationRoles `
            -EnvironmentUrl $EnvironmentUrl `
            -Contract $contract)
    )

    return New-ConvergenceSummary -Results @($results)
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

        $result = Invoke-InsuranceFoundationConvergence `
            -EnvironmentUrl $EnvironmentUrl `
            -ContractPath $ContractPath
        $result | ConvertTo-Json -Depth 50

        switch ([string]$result.State) {
            'Ready' { exit 0 }
            'ManualPrerequisite' { exit 2 }
            'Precondition' { exit 2 }
            'UnsupportedInTenant' { exit 2 }
            'ContractConflict' { exit 3 }
            default { exit 1 }
        }
    }
    catch {
        Write-Error $_
        exit 1
    }
}
