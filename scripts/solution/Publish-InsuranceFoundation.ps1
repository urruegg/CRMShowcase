<#
.SYNOPSIS
    Reconciles the insurance-foundation contract into a Dataverse DEV environment.
.DESCRIPTION
    Solution-aware, additive metadata authoring for the one-time controlled DEV
    bootstrap. Authentication is acquired at runtime by `az rest`. The script
    never deletes or recreates metadata and is safe to dot-source for testing.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)] [string]$EnvironmentUrl,
    [Parameter(Mandatory)] [string]$ContractPath,
    [ValidateSet('Foundation', 'DataModel', 'All')] [string]$Scope = 'All'
)

$ErrorActionPreference = 'Stop'
$script:DataverseBaseUrl = $EnvironmentUrl.TrimEnd('/')
$script:ContractFile = $ContractPath
$script:RequiredLanguages = @('1033', '1031', '1036', '1040')

function Get-DataverseHeaders {
    [CmdletBinding()]
    param([Parameter(Mandatory)] [string]$SolutionUniqueName)

    return @{
        'Accept'                           = 'application/json'
        'Content-Type'                     = 'application/json; charset=utf-8'
        'OData-MaxVersion'                 = '4.0'
        'OData-Version'                    = '4.0'
        'Prefer'                           = 'return=representation'
        'MSCRM.SolutionUniqueName'         = $SolutionUniqueName
        'MSCRM.SuppressDuplicateDetection' = 'false'
    }
}

function Invoke-DataverseRequest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [ValidateSet('GET', 'POST', 'PATCH', 'PUT')] [string]$Method,
        [Parameter(Mandatory)] [string]$Path,
        [object]$Body,
        [hashtable]$Headers = @{}
    )

    $url = if ($Path -match '^https://') { $Path } else {
        "$($script:DataverseBaseUrl)/api/data/v9.2$Path"
    }
    $arguments = @(
        'rest', '--method', $Method, '--url', $url,
        '--resource', "$($script:DataverseBaseUrl)/", '--only-show-errors'
    )
    $tempFile = $null
    try {
        if ($Headers.Count -gt 0) {
            # az rest accepts multiple NAME=VALUE values after one --headers
            # switch. Keep this as one occurrence so the complete solution
            # authoring context is one atomic CLI option.
            $arguments += '--headers'
            foreach ($headerName in @($Headers.Keys | Sort-Object)) {
                $arguments += "$headerName=$($Headers[$headerName])"
            }
        }
        if ($null -ne $Body) {
            $tempFile = New-TemporaryFile
            $Body | ConvertTo-Json -Depth 100 -Compress |
                Set-Content -LiteralPath $tempFile.FullName -Encoding UTF8
            $arguments += @('--body', "@$($tempFile.FullName)")
        }

        $output = & az @arguments 2>&1
        $exitCode = $LASTEXITCODE
        if ($exitCode -ne 0) {
            $detail = ($output | Out-String).Trim()
            throw "Dataverse request failed ($Method $Path); az rest exited with code $exitCode. $detail"
        }
        if (-not [string]::IsNullOrWhiteSpace(($output | Out-String))) {
            return ($output | Out-String) | ConvertFrom-Json
        }
    }
    finally {
        if ($null -ne $tempFile) {
            Remove-Item -LiteralPath $tempFile.FullName -Force -ErrorAction SilentlyContinue
        }
    }
}

function ConvertTo-ODataKeyString {
    param([Parameter(Mandatory)] [string]$Value)
    return $Value.Replace("'", "''")
}

function ConvertTo-LocalizedLabel {
    param([Parameter(Mandatory)] $Text)
    $labels = foreach ($language in $script:RequiredLanguages) {
        @{
            Label = [string]$Text.$language
            LanguageCode = [int]$language
            IsManaged = $false
        }
    }
    return @{ LocalizedLabels = @($labels) }
}

function ConvertTo-RequiredLevel {
    param([bool]$Required)
    return @{ Value = $(if ($Required) { 'ApplicationRequired' } else { 'None' }) }
}

function New-CompleteLocalizedMetadataUpdateBody {
    param(
        [Parameter(Mandatory)] $Existing,
        [Parameter(Mandatory)] $Metadata,
        [ValidateSet('Entity', 'Attribute', 'OptionSet')] [string]$Kind
    )
    $required = @{
        Entity = @('LogicalName', 'SchemaName', 'OwnershipType',
            'PrimaryNameAttribute')
        Attribute = @('LogicalName', 'SchemaName', 'AttributeType')
        OptionSet = @('Name', 'IsGlobal', 'OptionSetType')
    }[$Kind]
    foreach ($property in $required) {
        if ($Existing.PSObject.Properties.Name -notcontains $property -or
            $null -eq $Existing.$property -or
            [string]::IsNullOrWhiteSpace([string]$Existing.$property)) {
            throw "Cannot safely update $Kind metadata: the complete typed representation is missing '$property'."
        }
    }

    if ($Kind -eq 'OptionSet') {
        $body = [ordered]@{
            '@odata.type' = 'Microsoft.Dynamics.CRM.OptionSetMetadata'
            Name = $Existing.Name
            DisplayName = ConvertTo-LocalizedLabel $Metadata.label
            Description = ConvertTo-LocalizedLabel $Metadata.description
            IsGlobal = [bool]$Existing.IsGlobal
            OptionSetType = $Existing.OptionSetType
        }
        if ($Existing.MetadataId) {
            $body.MetadataId = $Existing.MetadataId
        }
        return $body
    }

    $body = [ordered]@{}
    foreach ($property in $Existing.PSObject.Properties) {
        if ($property.Name -notmatch '^@odata\.(?:context|etag)$' -and
            $property.Name -ne 'Options') {
            $body[$property.Name] = $property.Value
        }
    }
    $body.DisplayName = ConvertTo-LocalizedLabel $Metadata.label
    $body.Description = ConvertTo-LocalizedLabel $Metadata.description
    if ($Kind -eq 'Entity') {
        $body.DisplayCollectionName = ConvertTo-LocalizedLabel $Metadata.label
    }
    return $body
}

function New-AttributeMetadata {
    param(
        [Parameter(Mandatory)] $Column,
        [System.Collections.IDictionary] $GlobalChoiceMetadataIds
    )

    $common = [ordered]@{
        LogicalName = $Column.logicalName
        SchemaName = $Column.schemaName
        DisplayName = ConvertTo-LocalizedLabel $Column.metadata.label
        Description = ConvertTo-LocalizedLabel $Column.metadata.description
        RequiredLevel = ConvertTo-RequiredLevel ([bool]$Column.required)
        IsAuditEnabled = @{ Value = [bool]$Column.auditing }
        IsPrimaryName = ($Column.logicalName -eq 'crmshow_name')
    }
    switch ($Column.type) {
        'Text' {
            $common['@odata.type'] = 'Microsoft.Dynamics.CRM.StringAttributeMetadata'
            $common.MaxLength = [int]$Column.maxLength
            $common.FormatName = @{ Value = 'Text' }
        }
        'DateOnly' {
            $common['@odata.type'] = 'Microsoft.Dynamics.CRM.DateTimeAttributeMetadata'
            $common.Format = 'DateOnly'
            $common.DateTimeBehavior = @{ Value = 'DateOnly' }
        }
        'DateTime' {
            $common['@odata.type'] = 'Microsoft.Dynamics.CRM.DateTimeAttributeMetadata'
            $common.Format = 'DateAndTime'
            $common.DateTimeBehavior = @{ Value = 'TimeZoneIndependent' }
        }
        'GlobalChoice' {
            $common['@odata.type'] = 'Microsoft.Dynamics.CRM.PicklistAttributeMetadata'
            $binding = if ($GlobalChoiceMetadataIds -and
                $GlobalChoiceMetadataIds.Contains($Column.choice)) {
                "/GlobalOptionSetDefinitions($($GlobalChoiceMetadataIds[$Column.choice]))"
            } else {
                "/GlobalOptionSetDefinitions(Name='$($Column.choice)')"
            }
            $common['GlobalOptionSet@odata.bind'] = $binding
        }
        'Lookup' {
            $common['@odata.type'] = 'Microsoft.Dynamics.CRM.LookupAttributeMetadata'
            $common.Targets = @($Column.lookup.targets)
        }
        'Customer' {
            $common['@odata.type'] = 'Microsoft.Dynamics.CRM.LookupAttributeMetadata'
            $common.Targets = @($Column.lookup.targets)
        }
        default { throw "Unsupported attribute type '$($Column.type)' for '$($Column.logicalName)'." }
    }
    return $common
}

function Get-TableCreateRequest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] $Table,
        [System.Collections.IDictionary] $GlobalChoiceMetadataIds
    )

    $attributes = foreach ($column in $Table.columns) {
        if ($column.type -notin @('Lookup', 'Customer')) {
            New-AttributeMetadata -Column $column `
                -GlobalChoiceMetadataIds $GlobalChoiceMetadataIds
        }
    }
    $relationships = foreach ($relationship in @($Table.relationships | Where-Object {
        $_.authoring -eq 'InitialTableCreate'
    })) {
        New-OrdinaryRelationshipMetadata -Table $Table -Relationship $relationship
    }
    return [pscustomobject]@{
        Method = 'POST'
        Path = '/EntityDefinitions'
        Solution = $Table.solution
        Body = [ordered]@{
            '@odata.type' = 'Microsoft.Dynamics.CRM.EntityMetadata'
            LogicalName = $Table.logicalName
            SchemaName = $Table.schemaName
            DisplayName = ConvertTo-LocalizedLabel $Table.metadata.label
            DisplayCollectionName = ConvertTo-LocalizedLabel $Table.metadata.label
            Description = ConvertTo-LocalizedLabel $Table.metadata.description
            OwnershipType = $Table.ownership
            IsAuditEnabled = @{ Value = [bool]$Table.auditing }
            IsActivity = [bool]$Table.isActivity
            HasActivities = $false
            HasNotes = $false
            PrimaryNameAttribute = 'crmshow_name'
            Attributes = @($attributes)
            OneToManyRelationships = @($relationships)
        }
    }
}

function New-OrdinaryRelationshipMetadata {
    param(
        [Parameter(Mandatory)] $Table,
        [Parameter(Mandatory)] $Relationship
    )

    $columns = @($Table.columns | Where-Object {
        $_.logicalName -eq $Relationship.lookupColumn -and $_.type -eq 'Lookup'
    })
    if ($columns.Count -ne 1) {
        throw "Relationship '$($Relationship.schemaName)' must resolve one ordinary lookup column."
    }
    $column = $columns[0]
    $target = [string]$Relationship.referencedTables[0]
    return [ordered]@{
        '@odata.type' = 'Microsoft.Dynamics.CRM.OneToManyRelationshipMetadata'
        SchemaName = $Relationship.schemaName
        ReferencedAttribute = "${target}id"
        ReferencedEntity = $target
        ReferencingEntity = $Table.logicalName
        AssociatedMenuConfiguration = @{
            Behavior = 'UseLabel'
            Group = 'Details'
            Label = ConvertTo-LocalizedLabel $Relationship.metadata.label
            Order = 10000
        }
        CascadeConfiguration = @{
            Assign = 'NoCascade'
            Delete = 'Restrict'
            Merge = if ($target -in @('account', 'contact')) {
                'Cascade'
            } else {
                'NoCascade'
            }
            Reparent = 'NoCascade'
            Share = 'NoCascade'
            Unshare = 'NoCascade'
        }
        Lookup = [ordered]@{
            '@odata.type' = 'Microsoft.Dynamics.CRM.LookupAttributeMetadata'
            LogicalName = $column.logicalName
            SchemaName = $column.schemaName
            AttributeType = 'Lookup'
            AttributeTypeName = @{ Value = 'LookupType' }
            DisplayName = ConvertTo-LocalizedLabel $column.metadata.label
            Description = ConvertTo-LocalizedLabel $column.metadata.description
            RequiredLevel = ConvertTo-RequiredLevel ([bool]$column.required)
            IsAuditEnabled = @{ Value = [bool]$column.auditing }
        }
    }
}

function Get-OrdinaryRelationshipRequest {
    param(
        [Parameter(Mandatory)] $Table,
        [Parameter(Mandatory)] $Relationship
    )

    return [pscustomobject]@{
        Method = 'POST'
        Path = '/RelationshipDefinitions'
        Solution = $Table.solution
        Body = New-OrdinaryRelationshipMetadata -Table $Table `
            -Relationship $Relationship
    }
}

function Get-CustomerRelationshipRequest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] $Table,
        [Parameter(Mandatory)] $Column
    )

    $relationship = $Table.relationships | Where-Object {
        $_.lookupColumn -eq $Column.logicalName -and
        $_.authoring -eq 'CreateCustomerRelationships'
    }
    if (@($relationship).Count -ne 1) {
        throw "Customer column '$($Column.logicalName)' must have one relationship contract."
    }
    $oneToMany = foreach ($target in $Column.lookup.targets) {
        @{
            SchemaName = "$($relationship.schemaName)_$target"
            ReferencedEntity = $target
            ReferencingEntity = $Table.logicalName
            RelationshipType = 'OneToManyRelationship'
            AssociatedMenuConfiguration = @{
                Behavior = 'UseLabel'
                Group = 'Details'
                Label = ConvertTo-LocalizedLabel $relationship.metadata.label
                Order = 10000
            }
        }
    }
    return [pscustomobject]@{
        Method = 'POST'
        Path = '/CreateCustomerRelationships'
        Solution = $Table.solution
        Body = @{
            Lookup = @{
                SchemaName = $Column.schemaName
                DisplayName = ConvertTo-LocalizedLabel $Column.metadata.label
                Description = ConvertTo-LocalizedLabel $Column.metadata.description
                RequiredLevel = ConvertTo-RequiredLevel ([bool]$Column.required)
                IsAuditEnabled = @{ Value = [bool]$Column.auditing }
                Targets = @($Column.lookup.targets)
            }
            OneToManyRelationships = @($oneToMany)
            SolutionUniqueName = $Table.solution
        }
    }
}

function Get-AlternateKeyRequest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string]$TableLogicalName,
        [Parameter(Mandatory)] [string[]]$Columns,
        $Key,
        [string]$SchemaName,
        $Metadata
    )

    if ($Key) {
        $Columns = @($Key.columns)
        $SchemaName = $Key.schemaName
        $Metadata = $Key.metadata
    }
    if ([string]::IsNullOrWhiteSpace($SchemaName)) {
        $SchemaName = ($TableLogicalName + '_' + ($Columns -join '_') + '_key')
    }
    return [pscustomobject]@{
        Method = 'POST'
        Path = "/EntityDefinitions(LogicalName='$TableLogicalName')/Keys"
        Solution = 'crmshow_DataModel'
        SolutionComponentType = 14
        Body = @{
            SchemaName = $SchemaName
            DisplayName = if ($Metadata) {
                ConvertTo-LocalizedLabel $Metadata.label
            } else {
                ConvertTo-LocalizedLabel ([pscustomobject]@{
                    '1033' = $SchemaName; '1031' = $SchemaName
                    '1036' = $SchemaName; '1040' = $SchemaName
                })
            }
            KeyAttributes = @($Columns)
        }
    }
}

function New-ChoiceRequest {
    param([Parameter(Mandatory)] $Choice)
    $optionIndex = 0
    $options = foreach ($option in $Choice.options) {
        @{
            Label = ConvertTo-LocalizedLabel $option.metadata.label
            Description = ConvertTo-LocalizedLabel $option.metadata.description
            # The publisher's option-value prefix is 10000. Contract order fixes
            # deterministic values without leaking environment-assigned IDs.
            Value = 100000000 + $optionIndex
        }
        $optionIndex++
    }
    return [pscustomobject]@{
        Method = 'POST'; Path = '/GlobalOptionSetDefinitions'; Solution = $Choice.solution
        Body = @{
            '@odata.type' = 'Microsoft.Dynamics.CRM.OptionSetMetadata'
            Name = $Choice.logicalName
            DisplayName = ConvertTo-LocalizedLabel $Choice.metadata.label
            Description = ConvertTo-LocalizedLabel $Choice.metadata.description
            IsGlobal = $true
            Options = @($options)
        }
    }
}

function New-NativeAttributeRequest {
    param(
        [Parameter(Mandatory)] $Extension,
        [System.Collections.IDictionary] $GlobalChoiceMetadataIds
    )
    return [pscustomobject]@{
        Method = 'POST'
        Path = "/EntityDefinitions(LogicalName='$($Extension.table)')/Attributes"
        Solution = $Extension.solution
        Body = New-AttributeMetadata -Column $Extension `
            -GlobalChoiceMetadataIds $GlobalChoiceMetadataIds
    }
}

function ConvertTo-FetchXml {
    param($Table, $View)
    $attributes = @($View.columns | ForEach-Object { "<attribute name=`"$_`" />" }) -join ''
    $filter = if ($View.purpose -eq 'InvalidDateReporting') {
        $from = if ($Table.logicalName -eq 'crmshow_policyprojection') {
            'crmshow_effectivefrom'
        } else { 'crmshow_validfrom' }
        $to = if ($Table.logicalName -eq 'crmshow_policyprojection') {
            'crmshow_effectiveto'
        } else { 'crmshow_validto' }
        "<filter type=`"and`"><condition attribute=`"$to`" operator=`"not-null`" />" +
        "<condition attribute=`"$to`" operator=`"lt`" valueof=`"$from`" /></filter>"
    } elseif ($View.purpose -eq 'OverlapReporting') {
        $groupColumns = if ($Table.logicalName -eq 'crmshow_accountcontactrole') {
            @('crmshow_accountid', 'crmshow_contactid', 'crmshow_roletype')
        } else {
            @('crmshow_policyid', 'crmshow_partyid', 'crmshow_roletype')
        }
        $primaryId = "$($Table.logicalName)id"
        $sameGroup = @($groupColumns[1..($groupColumns.Count - 1)] | ForEach-Object {
            "<condition attribute=`"$_`" operator=`"eq`" valueof=`"a.$_`" />"
        }) -join ''
        "<link-entity name=`"$($Table.logicalName)`" from=`"$($groupColumns[0])`" to=`"$($groupColumns[0])`" alias=`"b`">" +
        "<filter type=`"and`">$sameGroup" +
        "<condition attribute=`"$primaryId`" operator=`"gt`" valueof=`"a.$primaryId`" />" +
        "<filter type=`"or`"><condition attribute=`"crmshow_validto`" operator=`"null`" />" +
        "<condition attribute=`"crmshow_validto`" operator=`"ge`" valueof=`"a.crmshow_validfrom`" /></filter>" +
        "<filter type=`"or`"><condition entityname=`"a`" attribute=`"crmshow_validto`" operator=`"null`" />" +
        "<condition attribute=`"crmshow_validfrom`" operator=`"le`" valueof=`"a.crmshow_validto`" /></filter>" +
        '</filter></link-entity>'
    } else { '' }
    $distinct = if ($View.purpose -eq 'OverlapReporting') { ' distinct="true"' } else { '' }
    return "<fetch version=`"1.0`"$distinct><entity name=`"$($Table.logicalName)`" alias=`"a`">$attributes$filter</entity></fetch>"
}

function ConvertTo-LayoutXml {
    param($Table, $View, [Parameter(Mandatory)] [int]$ObjectTypeCode)
    $cells = @($View.columns | ForEach-Object {
        "<cell name=`"$_`" width=`"150`" />"
    }) -join ''
    return "<grid name=`"resultset`" object=`"$ObjectTypeCode`" jump=`"crmshow_name`" select=`"1`" preview=`"0`"><row name=`"$($Table.logicalName)`" id=`"$($Table.logicalName)id`">$cells</row></grid>"
}

function New-ViewRequest {
    param($Table, $View, [Parameter(Mandatory)] [int]$ObjectTypeCode)
    return [pscustomobject]@{
        Method = 'POST'; Path = '/savedqueries'; Solution = $Table.solution
        EntityLogicalName = 'savedquery'; IdProperty = 'savedqueryid'
        LocalizedFields = @{
            name = $View.metadata.label
            description = $View.metadata.description
        }
        Body = @{
            name = [string]$View.metadata.label.'1033'
            description = [string]$View.metadata.description.'1033'
            returnedtypecode = $Table.logicalName
            querytype = 0
            fetchxml = ConvertTo-FetchXml $Table $View
            layoutxml = ConvertTo-LayoutXml $Table $View $ObjectTypeCode
            isdefault = $false
            iscustomizable = @{ Value = $true }
        }
    }
}

function New-FormRequest {
    param($Table, $Form)
    $rows = @($Form.columns | ForEach-Object {
        "<row><cell><control id=`"$_`" classid=`"{4273EDBD-AC1D-40d3-9FB2-095C621B552D}`" datafieldname=`"$_`" /></cell></row>"
    }) -join ''
    $formLabels = @($script:RequiredLanguages | ForEach-Object {
        "<label description=`"$([System.Security.SecurityElement]::Escape([string]$Form.metadata.label.$_))`" languagecode=`"$_`" />"
    }) -join ''
    return [pscustomobject]@{
        Method = 'POST'; Path = '/systemforms'; Solution = $Table.solution
        EntityLogicalName = 'systemform'; IdProperty = 'formid'
        LocalizedFields = @{
            name = $Form.metadata.label
            description = $Form.metadata.description
        }
        Body = @{
            name = [string]$Form.metadata.label.'1033'
            description = [string]$Form.metadata.description.'1033'
            objecttypecode = $Table.logicalName
            type = 2
            formactivationstate = 1
            formxml = "<form><tabs><tab name=`"general`"><labels>$formLabels</labels><columns><column width=`"100%`"><sections><section name=`"general`"><labels>$formLabels</labels><rows>$rows</rows></section></sections></column></columns></tab></tabs></form>"
            iscustomizable = @{ Value = $true }
        }
    }
}

function New-InvalidDateViewRequest {
    param($Table, $Rule, [Parameter(Mandatory)] [int]$ObjectTypeCode)
    $from = if ($Table.logicalName -eq 'crmshow_policyprojection') {
        'crmshow_effectivefrom'
    } else { 'crmshow_validfrom' }
    $to = if ($Table.logicalName -eq 'crmshow_policyprojection') {
        'crmshow_effectiveto'
    } else { 'crmshow_validto' }
    $view = [pscustomobject]@{
        name = "$($Rule.name)report"
        purpose = 'InvalidDateReporting'
        columns = @('crmshow_name', $from, $to)
        metadata = $Rule.metadata
    }
    return New-ViewRequest $Table $view $ObjectTypeCode
}

function Assert-InsuranceFoundationIntegrity {
    param([Parameter(Mandatory)] $Contract)
    $contract = $Contract
    if ((@($contract.languages) -join ',') -ne ($script:RequiredLanguages -join ',')) {
        throw 'Contract languages must be exactly 1033, 1031, 1036 and 1040.'
    }
    $choiceNames = @($contract.choices | ForEach-Object { $_.logicalName })
    if (@($choiceNames | Select-Object -Unique).Count -ne $choiceNames.Count) {
        throw 'Contract contains duplicate global choice logical names.'
    }
    $choiceReferences = @(
        foreach ($extension in @($contract.nativeExtensions)) {
            if ($extension.choice) { $extension.choice }
        }
        foreach ($table in @($contract.tables)) {
            foreach ($column in @($table.columns)) {
                if ($column.choice) { $column.choice }
            }
        }
    )
    foreach ($reference in $choiceReferences) {
        if ($reference -notin $choiceNames) { throw "Unresolved global choice '$reference'." }
    }
    $tableNames = @($contract.tables | ForEach-Object { $_.logicalName })
    if (@($tableNames | Select-Object -Unique).Count -ne $tableNames.Count) {
        throw 'Contract contains duplicate table logical names.'
    }
    foreach ($table in $contract.tables) {
        $columnNames = @($table.columns.logicalName)
        if (@($columnNames | Select-Object -Unique).Count -ne $columnNames.Count) {
            throw "Table '$($table.logicalName)' contains duplicate column logical names."
        }
        foreach ($keyColumn in @($table.alternateKeys.columns)) {
            if ($keyColumn -notin $columnNames) {
                throw "Key column '$keyColumn' is absent from '$($table.logicalName)'."
            }
        }
        foreach ($relationship in $table.relationships) {
            if ($relationship.referencingTable -ne $table.logicalName -or
                $relationship.lookupColumn -notin $columnNames) {
                throw "Relationship '$($relationship.name)' is referentially invalid."
            }
            foreach ($target in $relationship.referencedTables) {
                if ($target -notin @('account', 'contact') -and $target -notin $tableNames) {
                    throw "Relationship target '$target' is undeclared."
                }
            }
        }
    }
    foreach ($role in $contract.roles) {
        foreach ($denied in $role.deniedPrivileges) {
            if (@($role.tablePrivileges.privileges) -contains $denied) {
                throw "Role '$($role.name)' grants forbidden privilege '$denied'."
            }
        }
    }
}

function Test-InsuranceFoundationContract {
    [CmdletBinding()]
    param([Parameter(Mandatory)] [string]$Path)

    $resolved = (Resolve-Path -LiteralPath $Path).Path
    $schemaPath = Join-Path (Split-Path $resolved -Parent) 'insurance-foundation.schema.json'
    if (-not (Test-Path -LiteralPath $schemaPath)) {
        throw "Contract schema not found at '$schemaPath'."
    }
    $json = Get-Content -LiteralPath $resolved -Raw -Encoding UTF8
    try {
        if (Get-Command Test-Json -ErrorAction SilentlyContinue) {
            if (-not (Test-Json -Json $json -SchemaFile $schemaPath -ErrorAction Stop)) {
                throw 'JSON Schema validation returned false.'
            }
        } else {
            $validator = @'
import json, sys
from jsonschema import Draft202012Validator
with open(sys.argv[1], encoding='utf-8-sig') as source:
    instance = json.load(source)
with open(sys.argv[2], encoding='utf-8-sig') as source:
    schema = json.load(source)
Draft202012Validator.check_schema(schema)
errors = list(Draft202012Validator(schema).iter_errors(instance))
sys.exit(1 if errors else 0)
'@
            & python -c $validator $resolved $schemaPath
            if ($LASTEXITCODE -ne 0) {
                throw 'Draft 2020-12 JSON Schema validation returned false.'
            }
        }
    } catch {
        throw "Insurance foundation contract failed JSON Schema validation: $($_.Exception.Message)"
    }
    $contract = $json | ConvertFrom-Json
    Assert-InsuranceFoundationIntegrity $contract
    return $contract
}

function Invoke-PlannedRequest {
    param([Parameter(Mandatory)] $Request)
    $headers = Get-DataverseHeaders -SolutionUniqueName $Request.Solution
    Invoke-DataverseRequest -Method $Request.Method -Path $Request.Path `
        -Body $Request.Body -Headers $headers
}

function Set-RecordLocalizedFields {
    param(
        [Parameter(Mandatory)] $Request,
        $CreatedRecord
    )
    if (-not $Request.LocalizedFields -or -not $CreatedRecord) { return }
    $id = $CreatedRecord.($Request.IdProperty)
    if (-not $id) { return }
    foreach ($field in $Request.LocalizedFields.Keys) {
        $labels = foreach ($language in $script:RequiredLanguages) {
            @{
                Label = [string]$Request.LocalizedFields[$field].$language
                LanguageCode = [int]$language
            }
        }
        $localizeRequest = [pscustomobject]@{
            Method = 'POST'; Path = '/SetLocLabels'; Solution = $Request.Solution
            Body = @{
                EntityMoniker = @{
                    '@odata.type' = "Microsoft.Dynamics.CRM.$($Request.EntityLogicalName)"
                    "$($Request.IdProperty)" = $id
                }
                AttributeName = $field
                Labels = @($labels)
            }
        }
        Invoke-PlannedRequest $localizeRequest | Out-Null
    }
}

function Get-One {
    param([Parameter(Mandatory)] [string]$Path)
    $response = Invoke-DataverseRequest -Method GET -Path $Path
    if ($null -eq $response) { return $null }
    $items = @($response.value)
    if ($items.Count -gt 1) { throw "Metadata resolution was ambiguous for '$Path'." }
    if ($items.Count -eq 1) { return $items[0] }
    return $null
}

function Get-GlobalOptionSet {
    param([Parameter(Mandatory)] [string]$Name)
    $escaped = ConvertTo-ODataKeyString $Name
    $path = (
        "/GlobalOptionSetDefinitions(Name='$escaped')/" +
        'Microsoft.Dynamics.CRM.OptionSetMetadata'
    )
    try {
        $response = Invoke-DataverseRequest -Method GET -Path $path
    } catch {
        if ($_.Exception.Message -match '(?i)(404|not found)') { return $null }
        throw
    }
    if ($null -eq $response) { return $null }
    if ($response.PSObject.Properties.Name -contains 'value') {
        throw "Global option-set alternate-key lookup returned a collection for '$Name'."
    }
    return $response
}

function Get-GlobalChoiceMetadataIds {
    param([Parameter(Mandatory)] [object[]]$Columns)
    $metadataIds = @{}
    foreach ($column in @($Columns | Where-Object type -eq 'GlobalChoice')) {
        if ($metadataIds.Contains($column.choice)) { continue }
        $choice = Get-GlobalOptionSet $column.choice
        $metadataId = [guid]::Empty
        if ($null -eq $choice -or
            -not [guid]::TryParse([string]$choice.MetadataId, [ref]$metadataId)) {
            throw "Cannot bind '$($column.logicalName)' to global choice '$($column.choice)': a valid metadata ID was not returned."
        }
        $metadataIds[$column.choice] = $metadataId.ToString()
    }
    return $metadataIds
}

function Get-CompleteMetadata {
    param(
        [Parameter(Mandatory)] [string]$Path,
        [ValidateSet('Entity', 'Attribute', 'OptionSet')] [string]$Kind
    )
    $metadata = Invoke-DataverseRequest -Method GET -Path $Path
    if ($null -eq $metadata -or $metadata.PSObject.Properties.Name -contains 'value') {
        throw "Cannot safely update $Kind metadata: a complete typed representation was not returned by '$Path'."
    }
    # Validation is shared with the body builder and deliberately occurs before PUT.
    New-CompleteLocalizedMetadataUpdateBody $metadata ([pscustomobject]@{
        label = [pscustomobject]@{ '1033'='probe'; '1031'='probe'; '1036'='probe'; '1040'='probe' }
        description = [pscustomobject]@{ '1033'='probe'; '1031'='probe'; '1036'='probe'; '1040'='probe' }
    }) $Kind | Out-Null
    return $metadata
}

function Get-MergeLabelHeaders {
    param([Parameter(Mandatory)] [string]$Solution)
    $headers = Get-DataverseHeaders $Solution
    $headers['MSCRM.MergeLabels'] = 'true'
    return $headers
}

function Assert-SolutionOwnership {
    param(
        $Existing,
        [string]$Expected,
        [string]$Component,
        [Nullable[int]]$RepairComponentType
    )
    if ($Existing.PSObject.Properties.Name -contains 'SolutionUniqueName' -and
        $Existing.SolutionUniqueName -and $Existing.SolutionUniqueName -ne $Expected) {
        throw "Structural ownership conflict for '$Component': expected '$Expected', found '$($Existing.SolutionUniqueName)'."
    }
    $componentId = if ($Existing.MetadataId) {
        ([string]$Existing.MetadataId).Trim('{}')
    } elseif ($Existing.savedqueryid) {
        ([string]$Existing.savedqueryid).Trim('{}')
    }
    if ($componentId -and
        $Existing.PSObject.Properties.Name -notcontains 'SolutionUniqueName') {
        $membership = Invoke-DataverseRequest -Method GET -Path (
            "/solutioncomponents?`$select=solutioncomponentid&" +
            "`$filter=objectid eq $componentId&" +
            "`$expand=solutionid(`$select=uniquename)"
        )
        $solutionNames = @($membership.value | ForEach-Object {
            if ($_.solutionid) { $_.solutionid.uniquename }
        })
        if ($Expected -notin $solutionNames) {
            if ($null -eq $RepairComponentType) {
                throw "Structural ownership conflict for '$Component': component is not in '$Expected'."
            }
            Invoke-DataverseRequest -Method POST -Path '/AddSolutionComponent' -Body @{
                ComponentId = $componentId
                ComponentType = [int]$RepairComponentType
                SolutionUniqueName = $Expected
                AddRequiredComponents = $false
                DoNotIncludeSubcomponents = $true
            } -Headers (Get-DataverseHeaders $Expected) | Out-Null
            $membership = Invoke-DataverseRequest -Method GET -Path (
                "/solutioncomponents?`$select=solutioncomponentid&" +
                "`$filter=objectid eq $componentId&" +
                "`$expand=solutionid(`$select=uniquename)"
            )
            $solutionNames = @($membership.value | ForEach-Object {
                if ($_.solutionid) { $_.solutionid.uniquename }
            })
            if ($Expected -notin $solutionNames) {
                throw "Structural ownership conflict for '$Component': repair did not add the component to '$Expected'."
            }
        }
    }
    if ($Existing._solutionid_value) {
        $solutionId = ([string]$Existing._solutionid_value).Trim('{}')
        $solution = Get-One "/solutions?`$select=uniquename&`$filter=solutionid eq $solutionId"
        if ($null -eq $solution -or $solution.uniquename -ne $Expected) {
            throw "Structural ownership conflict for '$Component': expected '$Expected'."
        }
    }
}

function Test-LocalizedMetadataChanged {
    param($Existing, $Metadata)
    foreach ($pair in @(
        @{ Property = 'DisplayName'; Contract = 'label' },
        @{ Property = 'Description'; Contract = 'description' }
    )) {
        $actualProperty = $Existing.($pair.Property)
        if (-not $actualProperty) { return $true }
        foreach ($language in $script:RequiredLanguages) {
            $actualLabel = @($actualProperty.LocalizedLabels | Where-Object {
                [int]$_.LanguageCode -eq [int]$language
            })
            if ($actualLabel.Count -ne 1 -or
                [string]$actualLabel[0].Label -ne
                [string]$Metadata.($pair.Contract).$language) {
                return $true
            }
        }
    }
    return $false
}

function Invoke-ChoiceReconciliation {
    param($Choice)
    $existing = Get-GlobalOptionSet $Choice.logicalName
    if ($null -eq $existing) {
        Invoke-PlannedRequest (New-ChoiceRequest $Choice) | Out-Null
        Write-Output "$($Choice.logicalName): Created"
        return
    }
    Assert-SolutionOwnership $existing $Choice.solution $Choice.logicalName
    if ($existing.Name -ne $Choice.logicalName -or -not [bool]$existing.IsGlobal -or
        ($existing.'@odata.type' -and $existing.'@odata.type' -notmatch 'OptionSetMetadata')) {
        throw "Structural choice conflict for '$($Choice.logicalName)'."
    }
    $desired = New-ChoiceRequest $Choice
    $metadataChanged = Test-LocalizedMetadataChanged $existing $Choice.metadata
    $actualOptions = @($existing.Options)
    if ($actualOptions.Count -gt @($Choice.options).Count) {
        throw "Structural option conflict for '$($Choice.logicalName)': unexpected options exist."
    }
    for ($index = 0; $index -lt $actualOptions.Count; $index++) {
        $expectedValue = 100000000 + $index
        if ($actualOptions[$index].Value -ne $null -and
            [int]$actualOptions[$index].Value -ne $expectedValue) {
            throw "Structural option-value conflict for '$($Choice.logicalName)'."
        }
    }
    if ($actualOptions.Count -lt @($Choice.options).Count) {
        if (-not $existing.MetadataId) {
            throw "Cannot reconcile missing options for '$($Choice.logicalName)' without its metadata ID."
        }
        if ($metadataChanged) {
            $complete = Get-CompleteMetadata `
                ("/GlobalOptionSetDefinitions($($existing.MetadataId))/" +
                    'Microsoft.Dynamics.CRM.OptionSetMetadata') OptionSet
            Invoke-DataverseRequest -Method PUT `
                -Path "/GlobalOptionSetDefinitions($($existing.MetadataId))" `
                -Body (New-CompleteLocalizedMetadataUpdateBody $complete $Choice.metadata OptionSet) `
                -Headers (Get-MergeLabelHeaders $Choice.solution) | Out-Null
        }
        for ($index = $actualOptions.Count; $index -lt @($Choice.options).Count; $index++) {
            $option = $Choice.options[$index]
            Invoke-PlannedRequest ([pscustomobject]@{
                Method = 'POST'
                Path = '/InsertOptionValue'
                Solution = $Choice.solution
                Body = @{
                    OptionSetName = $Choice.logicalName
                    Label = ConvertTo-LocalizedLabel $option.metadata.label
                    Description = ConvertTo-LocalizedLabel $option.metadata.description
                    Value = 100000000 + $index
                    SolutionUniqueName = $Choice.solution
                }
            }) | Out-Null
        }
        Write-Output "$($Choice.logicalName): Updated"
        return
    }
    $changedOptions = [System.Collections.Generic.List[int]]::new()
    if ($actualOptions.Count -gt 0) {
        for ($index = 0; $index -lt $actualOptions.Count; $index++) {
            foreach ($property in 'Label', 'Description') {
                foreach ($language in $script:RequiredLanguages) {
                    $actualLabel = @(
                        $actualOptions[$index].$property.LocalizedLabels | Where-Object {
                            [int]$_.LanguageCode -eq [int]$language
                        }
                    )
                    $expectedLabel = [string]$Choice.options[$index].metadata.$(
                        $property.ToLowerInvariant()
                    ).$language
                    if ($actualLabel.Count -ne 1 -or
                        [string]$actualLabel[0].Label -ne $expectedLabel) {
                        if (-not $changedOptions.Contains($index)) {
                            $changedOptions.Add($index)
                        }
                        break
                    }
                }
            }
        }
    }
    if ($metadataChanged) {
        if (-not $existing.MetadataId) {
            throw "Cannot update localized metadata for '$($Choice.logicalName)' without its metadata ID."
        }
        $complete = Get-CompleteMetadata `
            ("/GlobalOptionSetDefinitions($($existing.MetadataId))/" +
                'Microsoft.Dynamics.CRM.OptionSetMetadata') OptionSet
        Invoke-DataverseRequest -Method PUT `
            -Path "/GlobalOptionSetDefinitions($($existing.MetadataId))" `
            -Body (New-CompleteLocalizedMetadataUpdateBody $complete $Choice.metadata OptionSet) `
            -Headers (Get-MergeLabelHeaders $Choice.solution) | Out-Null
    }
    foreach ($index in $changedOptions) {
        $option = $Choice.options[$index]
        Invoke-PlannedRequest ([pscustomobject]@{
            Method = 'POST'; Path = '/UpdateOptionValue'; Solution = $Choice.solution
            Body = @{
                OptionSetName = $Choice.logicalName
                Value = 100000000 + $index
                Label = ConvertTo-LocalizedLabel $option.metadata.label
                Description = ConvertTo-LocalizedLabel $option.metadata.description
                MergeLabels = $true
                SolutionUniqueName = $Choice.solution
            }
        }) | Out-Null
    }
    if ($metadataChanged -or $changedOptions.Count -gt 0) {
        Write-Output "$($Choice.logicalName): Updated"
        return
    }
    Write-Output "$($Choice.logicalName): Unchanged"
}

function Test-AttributeCompatibility {
    param($Existing, $Column, [string]$Owner)
    $expectedType = @{
        Text = 'String'; DateOnly = 'DateTime'; DateTime = 'DateTime'
        GlobalChoice = 'Picklist'; Lookup = 'Lookup'; Customer = 'Customer'
    }[$Column.type]
    $actualType = [string]$Existing.AttributeType
    if ($actualType -and $actualType -ne $expectedType) {
        throw "Structural type conflict for '$Owner/$($Column.logicalName)': expected $expectedType, found $actualType."
    }
    if ($Column.type -in @('Lookup', 'Customer')) {
        if ($null -eq $Existing.Targets) {
            throw "Incomplete typed lookup metadata for '$Owner/$($Column.logicalName)'."
        }
        if ((@($Existing.Targets | Sort-Object) -join ',') -ne
            (@($Column.lookup.targets | Sort-Object) -join ',')) {
            throw "Structural target conflict for '$Owner/$($Column.logicalName)'."
        }
    }
    if ($Column.type -eq 'Text') {
        if ($null -eq $Existing.MaxLength) {
            throw "Incomplete typed string metadata for '$Owner/$($Column.logicalName)'."
        }
        if ([int]$Existing.MaxLength -lt [int]$Column.maxLength) {
            throw "Structural length conflict for '$Owner/$($Column.logicalName)'."
        }
    }
    if ($Column.type -eq 'GlobalChoice') {
        if (-not $Existing.GlobalOptionSet -or
            [string]::IsNullOrWhiteSpace([string]$Existing.GlobalOptionSet.Name)) {
            throw "Incomplete typed choice metadata for '$Owner/$($Column.logicalName)'."
        }
        if ($Existing.GlobalOptionSet.Name -ne $Column.choice) {
            throw "Structural choice-binding conflict for '$Owner/$($Column.logicalName)'."
        }
    }
    if ($Column.type -in @('DateOnly', 'DateTime')) {
        $expectedBehavior = if ($Column.type -eq 'DateOnly') {
            'DateOnly'
        } else { 'TimeZoneIndependent' }
        $expectedFormat = if ($Column.type -eq 'DateOnly') {
            'DateOnly'
        } else { 'DateAndTime' }
        $actualBehavior = if ($Existing.DateTimeBehavior.Value) {
            [string]$Existing.DateTimeBehavior.Value
        } else { [string]$Existing.DateTimeBehavior }
        if ($actualBehavior -ne $expectedBehavior -or
            [string]$Existing.Format -ne $expectedFormat) {
            throw "Structural date metadata conflict for '$Owner/$($Column.logicalName)': expected $expectedBehavior/$expectedFormat, found $actualBehavior/$($Existing.Format)."
        }
    }
}

function Get-PicklistAttributeMetadata {
    param(
        [Parameter(Mandatory)] [string]$TableLogicalName,
        [Parameter(Mandatory)] [string]$AttributeLogicalName
    )
    $escapedTableName = ConvertTo-ODataKeyString $TableLogicalName
    $escapedAttributeName = ConvertTo-ODataKeyString $AttributeLogicalName
    return Get-One (
        "/EntityDefinitions(LogicalName='$escapedTableName')/Attributes/" +
        "Microsoft.Dynamics.CRM.PicklistAttributeMetadata?" +
        "`$select=MetadataId,LogicalName,SchemaName,AttributeType,DisplayName,Description&" +
        "`$expand=GlobalOptionSet(`$select=Name)&" +
        "`$filter=LogicalName eq '$escapedAttributeName'"
    )
}

function Get-TypedAttributeMetadata {
    param(
        [Parameter(Mandatory)] [string]$TableLogicalName,
        [Parameter(Mandatory)] $Column
    )
    if ($Column.type -eq 'GlobalChoice') {
        return Get-PicklistAttributeMetadata $TableLogicalName $Column.logicalName
    }
    $type = @{
        Text = 'StringAttributeMetadata'
        DateOnly = 'DateTimeAttributeMetadata'
        DateTime = 'DateTimeAttributeMetadata'
        Lookup = 'LookupAttributeMetadata'
    }[$Column.type]
    $derivedProperties = @{
        Text = 'MaxLength'
        DateOnly = 'Format,DateTimeBehavior'
        DateTime = 'Format,DateTimeBehavior'
        Lookup = 'Targets'
    }[$Column.type]
    if (-not $type) {
        throw "Unsupported typed metadata query for '$($Column.type)' column '$($Column.logicalName)'."
    }
    $escapedTableName = ConvertTo-ODataKeyString $TableLogicalName
    $escapedAttributeName = ConvertTo-ODataKeyString $Column.logicalName
    return Get-One (
        "/EntityDefinitions(LogicalName='$escapedTableName')/Attributes/" +
        "Microsoft.Dynamics.CRM.${type}?" +
        "`$select=MetadataId,LogicalName,SchemaName,AttributeType," +
        "DisplayName,Description,$derivedProperties&" +
        "`$filter=LogicalName eq '$escapedAttributeName'"
    )
}

function Invoke-NativeExtensionReconciliation {
    param($Extension)
    $existing = Get-PicklistAttributeMetadata $Extension.table `
        $Extension.logicalName
    if ($null -eq $existing) {
        $choiceMetadataIds = Get-GlobalChoiceMetadataIds @($Extension)
        Invoke-PlannedRequest (
            New-NativeAttributeRequest $Extension $choiceMetadataIds
        ) | Out-Null
        Write-Output "$($Extension.table)/$($Extension.logicalName): Created"
        return
    }
    Assert-SolutionOwnership $existing $Extension.solution "$($Extension.table)/$($Extension.logicalName)"
    Test-AttributeCompatibility $existing $Extension $Extension.table
    if (Test-LocalizedMetadataChanged $existing $Extension.metadata) {
        if (-not $existing.MetadataId) {
            throw "Cannot update localized metadata for '$($Extension.logicalName)' without its metadata ID."
        }
        $typeName = switch ([string]$existing.AttributeType) {
            'String' { 'StringAttributeMetadata' }
            'DateTime' { 'DateTimeAttributeMetadata' }
            'Picklist' { 'PicklistAttributeMetadata' }
            default { throw "Cannot safely update attribute metadata for '$($Extension.logicalName)': unsupported typed endpoint." }
        }
        $path = "/EntityDefinitions(LogicalName='$($Extension.table)')/Attributes($($existing.MetadataId))/Microsoft.Dynamics.CRM.$typeName"
        $complete = Get-CompleteMetadata $path Attribute
        Invoke-DataverseRequest -Method PUT -Path $path `
            -Body (New-CompleteLocalizedMetadataUpdateBody $complete $Extension.metadata Attribute) `
            -Headers (Get-MergeLabelHeaders $Extension.solution) | Out-Null
        Write-Output "$($Extension.table)/$($Extension.logicalName): Updated"
    } else {
        Write-Output "$($Extension.table)/$($Extension.logicalName): Unchanged"
    }
}

function Invoke-ChildRequestIfMissing {
    param(
        [string]$QueryPath,
        $Request,
        [string]$Component,
        [scriptblock]$AssertCompatible
    )
    $existing = Get-One $QueryPath
    if ($null -eq $existing) {
        $created = Invoke-PlannedRequest $Request
        Set-RecordLocalizedFields -Request $Request -CreatedRecord $created
        Write-Output "$Component`: Created"
    } else {
        Assert-SolutionOwnership $existing $Request.Solution $Component `
            -RepairComponentType $Request.SolutionComponentType
        if ($AssertCompatible) { & $AssertCompatible $existing }
        if ($Request.LocalizedFields) {
            # savedquery/systemform localization cannot be expanded reliably
            # through the Web API. SetLocLabels is idempotent, so converge all
            # four required languages on every reconciliation.
            Set-RecordLocalizedFields -Request $Request -CreatedRecord $existing
            Write-Output "$Component`: Updated"
        } else {
            Write-Output "$Component`: Unchanged"
        }
    }
}

function Get-XmlStructuralSignature {
    param([Parameter(Mandatory)] [string]$Xml, [Parameter(Mandatory)] [string]$Component)
    try {
        [xml]$document = $Xml
    } catch {
        throw "Structural XML conflict for '$Component': existing or desired XML is invalid."
    }
    function Get-NodeSignature($Node) {
        if ($Node.NodeType -eq [System.Xml.XmlNodeType]::Text) {
            if ([string]::IsNullOrWhiteSpace($Node.Value)) { return '' }
            return '#text:' + $Node.Value
        }
        if ($Node.NodeType -ne [System.Xml.XmlNodeType]::Element) { return '' }
        $attributes = @($Node.Attributes | Sort-Object Name | ForEach-Object {
            "$($_.Name)=$($_.Value)"
        }) -join ';'
        $children = @($Node.ChildNodes | ForEach-Object {
            Get-NodeSignature $_
        } | Where-Object { $_ }) -join ''
        return "<$($Node.Name)|$attributes>$children</$($Node.Name)>"
    }
    return Get-NodeSignature $document.DocumentElement
}

function Assert-XmlCompatible {
    param($Existing, $Request, [string]$Property, [string]$Component)
    if ($Existing.PSObject.Properties.Name -notcontains $Property -or
        [string]::IsNullOrWhiteSpace([string]$Existing.$Property)) {
        throw "Structural XML conflict for '$Component': '$Property' was not retrieved."
    }
    $actual = Get-XmlStructuralSignature ([string]$Existing.$Property) $Component
    $wanted = Get-XmlStructuralSignature ([string]$Request.Body.$Property) $Component
    if ($actual -ne $wanted) {
        throw "Structural XML conflict for '$Component': existing $Property is stale."
    }
}

function Invoke-TableChildren {
    param($Table, [Parameter(Mandatory)] [int]$ObjectTypeCode)
    foreach ($key in $Table.alternateKeys) {
        $expectedKeyColumns = @($key.columns)
        Invoke-ChildRequestIfMissing `
            -QueryPath "/EntityDefinitions(LogicalName='$($Table.logicalName)')/Keys?`$select=MetadataId,SchemaName,KeyAttributes&`$filter=SchemaName eq '$($key.schemaName)'" `
            -Request (Get-AlternateKeyRequest -TableLogicalName $Table.logicalName `
                -Columns @($key.columns) -Key $key) `
            -Component "$($Table.logicalName)/$($key.name)" `
            -AssertCompatible {
                param($actual)
                if ((@($actual.KeyAttributes) -join ',') -ne ($expectedKeyColumns -join ',')) {
                    throw "Structural key conflict for '$($Table.logicalName)/$($key.name)'."
                }
            }
    }
    foreach ($rule in $Table.businessRules) {
        Write-Output "$($Table.logicalName)/$($rule.name): Deferred: OR-001/#9"
        $ruleLabel = ([string]$rule.metadata.label.'1033').Replace("'", "''")
        Invoke-ChildRequestIfMissing `
            -QueryPath "/savedqueries?`$select=savedqueryid,name,description,returnedtypecode,fetchxml,layoutxml&`$filter=name eq '$ruleLabel' and returnedtypecode eq '$($Table.logicalName)'" `
            -Request ($ruleRequest = New-InvalidDateViewRequest $Table $rule $ObjectTypeCode) `
            -Component "$($Table.logicalName)/$($rule.name)report" `
            -AssertCompatible {
                param($actual)
                if ($actual.returnedtypecode -and $actual.returnedtypecode -ne $Table.logicalName) {
                    throw "Structural view target conflict for '$($rule.name)report'."
                }
                Assert-XmlCompatible $actual $ruleRequest fetchxml "$($rule.name)report"
                Assert-XmlCompatible $actual $ruleRequest layoutxml "$($rule.name)report"
            }
    }
    foreach ($view in $Table.views) {
        $viewLabel = ([string]$view.metadata.label.'1033').Replace("'", "''")
        Invoke-ChildRequestIfMissing `
            -QueryPath "/savedqueries?`$select=savedqueryid,name,description,returnedtypecode,fetchxml,layoutxml&`$filter=name eq '$viewLabel' and returnedtypecode eq '$($Table.logicalName)'" `
            -Request ($viewRequest = New-ViewRequest $Table $view $ObjectTypeCode) `
            -Component "$($Table.logicalName)/$($view.name)" `
            -AssertCompatible {
                param($actual)
                if ($actual.returnedtypecode -and $actual.returnedtypecode -ne $Table.logicalName) {
                    throw "Structural view target conflict for '$($view.name)'."
                }
                Assert-XmlCompatible $actual $viewRequest fetchxml $view.name
                Assert-XmlCompatible $actual $viewRequest layoutxml $view.name
            }
    }
    foreach ($form in $Table.forms) {
        $formLabel = ([string]$form.metadata.label.'1033').Replace("'", "''")
        Invoke-ChildRequestIfMissing `
            -QueryPath "/systemforms?`$select=formid,name,description,objecttypecode,type,formxml,_solutionid_value&`$filter=name eq '$formLabel' and objecttypecode eq '$($Table.logicalName)' and type eq 2" `
            -Request ($formRequest = New-FormRequest $Table $form) `
            -Component "$($Table.logicalName)/$($form.name)" `
            -AssertCompatible {
                param($actual)
                if (($actual.objecttypecode -and $actual.objecttypecode -ne $Table.logicalName) -or
                    ($actual.type -ne $null -and [int]$actual.type -ne 2)) {
                    throw "Structural form target conflict for '$($form.name)'."
                }
                Assert-XmlCompatible $actual $formRequest formxml $form.name
            }
    }
}

function Resolve-TableObjectTypeCode {
    param([Parameter(Mandatory)] [string]$TableLogicalName)
    $response = Invoke-DataverseRequest -Method GET -Path (
        "/EntityDefinitions(LogicalName='$TableLogicalName')?`$select=LogicalName,ObjectTypeCode"
    )
    $metadata = if ($response.ObjectTypeCode) { $response } else { @($response.value)[0] }
    if ($null -eq $metadata -or $null -eq $metadata.ObjectTypeCode) {
        throw "ObjectTypeCode could not be resolved for '$TableLogicalName'."
    }
    return [int]$metadata.ObjectTypeCode
}

function Invoke-ExistingCustomerRelationshipReconciliation {
    param(
        [Parameter(Mandatory)] $Table,
        [Parameter(Mandatory)] $Column,
        [object[]]$ExistingAttributes = @()
    )

    $escapedLogicalName = ConvertTo-ODataKeyString $Table.logicalName
    $attributeResponse = Invoke-DataverseRequest -Method GET -Path (
        "/EntityDefinitions(LogicalName='$escapedLogicalName')/Attributes/" +
        "Microsoft.Dynamics.CRM.LookupAttributeMetadata?" +
        "`$select=MetadataId,LogicalName,SchemaName,AttributeType,Targets"
    )
    $relationshipResponse = Invoke-DataverseRequest -Method GET -Path (
        "/EntityDefinitions(LogicalName='$escapedLogicalName')/ManyToOneRelationships?" +
        "`$select=MetadataId,SchemaName,ReferencedEntity,ReferencingEntity,ReferencingAttribute"
    )

    $relationshipContract = @($Table.relationships | Where-Object {
        $_.lookupColumn -eq $Column.logicalName -and
        $_.authoring -eq 'CreateCustomerRelationships'
    })
    if ($relationshipContract.Count -ne 1) {
        throw "Customer column '$($Column.logicalName)' must have one relationship contract."
    }
    $relationshipContract = $relationshipContract[0]
    $expectedRelationships = @(
        foreach ($target in $Column.lookup.targets) {
            [pscustomobject]@{
                SchemaName = "$($relationshipContract.schemaName)_$target"
                ReferencedEntity = [string]$target
            }
        }
    )

    $attributeCandidates = @($attributeResponse.value | Where-Object {
        $_.LogicalName -eq $Column.logicalName -or
        $_.SchemaName -eq $Column.schemaName
    })
    $untypedCandidates = @($ExistingAttributes | Where-Object {
        $_.LogicalName -eq $Column.logicalName -or
        $_.SchemaName -eq $Column.schemaName
    })
    if ($untypedCandidates.Count -gt 0 -and $attributeCandidates.Count -eq 0) {
        throw "Structural Customer lookup conflict for '$($Table.logicalName)/$($Column.logicalName)': a conflicting non-lookup or partial attribute exists; automatic recovery requires the column to be wholly absent."
    }
    $relationshipCandidates = @($relationshipResponse.value | Where-Object {
        $_.ReferencingAttribute -eq $Column.logicalName -or
        $_.SchemaName -eq $relationshipContract.schemaName -or
        $_.SchemaName -in @($expectedRelationships.SchemaName)
    })

    if ($attributeCandidates.Count -eq 0 -and
        $relationshipCandidates.Count -eq 0) {
        Invoke-PlannedRequest (Get-CustomerRelationshipRequest $Table $Column) |
            Out-Null
        Write-Output "$($Table.logicalName)/$($Column.logicalName): Created"
        return
    }

    if ($attributeCandidates.Count -ne 1) {
        throw "Structural Customer lookup conflict for '$($Table.logicalName)/$($Column.logicalName)': expected one typed lookup attribute, found $($attributeCandidates.Count); automatic recovery requires no partial metadata."
    }
    $attribute = $attributeCandidates[0]
    if ($attribute.LogicalName -ne $Column.logicalName -or
        $attribute.SchemaName -ne $Column.schemaName) {
        throw "Structural Customer lookup conflict for '$($Table.logicalName)/$($Column.logicalName)': expected logical/schema names '$($Column.logicalName)'/'$($Column.schemaName)', found '$($attribute.LogicalName)'/'$($attribute.SchemaName)'."
    }
    Test-AttributeCompatibility $attribute $Column $Table.logicalName

    if ($relationshipCandidates.Count -ne $expectedRelationships.Count) {
        throw "Structural Customer relationship conflict for '$($Table.logicalName)/$($Column.logicalName)': expected $($expectedRelationships.Count) complete relationships, found $($relationshipCandidates.Count); automatic recovery cannot continue from partial metadata."
    }
    foreach ($expected in $expectedRelationships) {
        $matches = @($relationshipCandidates | Where-Object {
            $_.SchemaName -eq $expected.SchemaName
        })
        if ($matches.Count -ne 1) {
            throw "Structural Customer relationship conflict for '$($Table.logicalName)/$($Column.logicalName)': relationship '$($expected.SchemaName)' is missing or ambiguous."
        }
        $actual = $matches[0]
        if ($actual.ReferencedEntity -ne $expected.ReferencedEntity -or
            $actual.ReferencingEntity -ne $Table.logicalName -or
            $actual.ReferencingAttribute -ne $Column.logicalName) {
            throw "Structural Customer relationship conflict for '$($Table.logicalName)/$($Column.logicalName)': relationship '$($expected.SchemaName)' has conflicting target or schema metadata."
        }
    }
}

function Publish-TableMetadata {
    param([Parameter(Mandatory)] $Table)
    $escapedLogicalName = [System.Security.SecurityElement]::Escape(
        [string]$Table.logicalName
    )
    Invoke-PlannedRequest ([pscustomobject]@{
        Method = 'POST'
        Path = '/PublishXml'
        Solution = $Table.solution
        Body = @{
            ParameterXml = (
                '<importexportxml><entities><entity>' +
                $escapedLogicalName +
                '</entity></entities></importexportxml>'
            )
        }
    }) | Out-Null
}

function Invoke-TableReconciliation {
    param($Table)
    $existing = Get-One "/EntityDefinitions?`$select=MetadataId,LogicalName,SchemaName,OwnershipType,PrimaryNameAttribute,IsAuditEnabled,DisplayName,Description&`$expand=Attributes(`$select=MetadataId,LogicalName,SchemaName,AttributeType,DisplayName,Description),ManyToOneRelationships(`$select=SchemaName,ReferencedEntity,ReferencingEntity,ReferencingAttribute,CascadeConfiguration)&`$filter=LogicalName eq '$($Table.logicalName)'"
    if ($null -eq $existing) {
        $choiceMetadataIds = Get-GlobalChoiceMetadataIds @($Table.columns)
        Invoke-PlannedRequest (
            Get-TableCreateRequest $Table $choiceMetadataIds
        ) | Out-Null
        Write-Output "$($Table.logicalName): Created"
        Publish-TableMetadata $Table

        # Dataverse requires the global action for a polymorphic Customer lookup.
        foreach ($customer in @($Table.columns | Where-Object type -eq 'Customer')) {
            Invoke-PlannedRequest (Get-CustomerRelationshipRequest $Table $customer) | Out-Null
            Write-Output "$($Table.logicalName)/$($customer.logicalName): Created"
        }
    } else {
        Assert-SolutionOwnership $existing $Table.solution $Table.logicalName
        if ([string]$existing.OwnershipType -and [string]$existing.OwnershipType -ne $Table.ownership) {
            throw "Structural ownership conflict for '$($Table.logicalName)'."
        }
        Publish-TableMetadata $Table
        $createdOrdinaryLookups = @{}
        foreach ($customer in @($Table.columns | Where-Object type -eq 'Customer')) {
            Invoke-ExistingCustomerRelationshipReconciliation $Table $customer `
                -ExistingAttributes @($existing.Attributes)
        }
        foreach ($relationship in @($Table.relationships | Where-Object {
            $_.authoring -ne 'CreateCustomerRelationships'
        })) {
            $expected = [pscustomobject]@{
                SchemaName = $relationship.schemaName
                ReferencedEntity = [string]$relationship.referencedTables[0]
            }
            $attributeCandidates = @($existing.Attributes | Where-Object {
                $_.LogicalName -eq $relationship.lookupColumn
            })
            foreach ($wanted in @($expected)) {
                $actualRelationship = @($existing.ManyToOneRelationships |
                    Where-Object SchemaName -eq $wanted.SchemaName)
                if ($actualRelationship.Count -eq 0 -and
                    $attributeCandidates.Count -eq 0) {
                    Invoke-PlannedRequest (
                        Get-OrdinaryRelationshipRequest $Table $relationship
                    ) | Out-Null
                    $createdOrdinaryLookups[$relationship.lookupColumn] = $true
                    Write-Output "$($Table.logicalName)/$($relationship.lookupColumn): Created"
                    continue
                }
                if ($actualRelationship.Count -ne 1 -or
                    $attributeCandidates.Count -ne 1) {
                    throw "Structural relationship conflict for '$($wanted.SchemaName)': relationship and lookup metadata must both be wholly present or wholly absent."
                }
                $actualRelationship = $actualRelationship[0]
                if ([string]::IsNullOrWhiteSpace(
                        [string]$actualRelationship.ReferencedEntity
                    ) -or
                    [string]$actualRelationship.ReferencedEntity -ne
                        $wanted.ReferencedEntity -or
                    [string]::IsNullOrWhiteSpace(
                        [string]$actualRelationship.ReferencingEntity
                    ) -or
                    [string]$actualRelationship.ReferencingEntity -ne
                        $Table.logicalName -or
                    [string]::IsNullOrWhiteSpace(
                        [string]$actualRelationship.ReferencingAttribute
                    ) -or
                    [string]$actualRelationship.ReferencingAttribute -ne
                        $relationship.lookupColumn) {
                    throw "Structural relationship target conflict for '$($wanted.SchemaName)'."
                }
                $expectedCascade = @{
                    Assign='NoCascade'; Delete='Restrict'
                    Merge=$(if ($wanted.ReferencedEntity -in @('account', 'contact')) {
                        'Cascade'
                    } else {
                        'NoCascade'
                    })
                    Reparent='NoCascade'; Share='NoCascade'; Unshare='NoCascade'
                }
                foreach ($action in @($expectedCascade.Keys | Sort-Object)) {
                    if ([string]$actualRelationship.CascadeConfiguration.$action -ne
                        [string]$expectedCascade[$action]) {
                        throw "Structural relationship cascade conflict for '$($wanted.SchemaName)': '$action' must be '$($expectedCascade[$action])'."
                    }
                }
            }
        }
        if (Test-LocalizedMetadataChanged $existing $Table.metadata) {
            if (-not $existing.MetadataId) {
                throw "Cannot update localized metadata for '$($Table.logicalName)' without its metadata ID."
            }
            $path = "/EntityDefinitions($($existing.MetadataId))"
            $complete = Get-CompleteMetadata $path Entity
            Invoke-DataverseRequest -Method PUT -Path $path `
                -Body (New-CompleteLocalizedMetadataUpdateBody $complete $Table.metadata Entity) `
                -Headers (Get-MergeLabelHeaders $Table.solution) | Out-Null
        }
        foreach ($column in $Table.columns) {
            if ($column.type -eq 'Customer') { continue }
            if ($createdOrdinaryLookups.ContainsKey($column.logicalName)) { continue }
            $base = @($existing.Attributes |
                Where-Object LogicalName -eq $column.logicalName)
            if ($base.Count -gt 1) {
                throw "Duplicate physical attributes found for '$($Table.logicalName)/$($column.logicalName)'."
            }
            $needsTypedMetadata = $column.type -eq 'GlobalChoice' -or
                ($base.Count -eq 1 -and (
                    ($column.type -eq 'Text' -and $null -eq $base[0].MaxLength) -or
                    ($column.type -in @('DateOnly', 'DateTime') -and
                        ($null -eq $base[0].Format -or
                            $null -eq $base[0].DateTimeBehavior)) -or
                    ($column.type -eq 'Lookup' -and $null -eq $base[0].Targets)
                ))
            if ($needsTypedMetadata) {
                $typed = Get-TypedAttributeMetadata $Table.logicalName $column
                $actual = @($typed)
                if ($actual.Count -eq 1 -and $null -eq $actual[0]) {
                    $actual = @()
                }
                if ($base.Count -eq 1 -and $actual.Count -eq 0) {
                    throw "Structural type conflict for '$($Table.logicalName)/$($column.logicalName)': base metadata exists but typed metadata is unavailable."
                }
                if ($base.Count -eq 1 -and $actual.Count -eq 1) {
                    foreach ($property in 'MetadataId', 'LogicalName', 'SchemaName',
                        'AttributeType') {
                        if ($null -eq $base[0].$property -or
                            $null -eq $actual[0].$property -or
                            [string]$base[0].$property -ne
                            [string]$actual[0].$property) {
                            throw "Structural metadata conflict for '$($Table.logicalName)/$($column.logicalName)': base and typed '$property' values differ or are incomplete."
                        }
                    }
                }
            } else {
                $actual = $base
            }
            if ($actual.Count -eq 0) {
                if ($column.type -in @('Lookup', 'Customer')) {
                    throw "Structural conflict: lookup '$($column.logicalName)' is missing from existing table '$($Table.logicalName)'; it will not be created or recreated."
                }
                $request = [pscustomobject]@{
                    Method = 'POST'
                    Path = "/EntityDefinitions(LogicalName='$($Table.logicalName)')/Attributes"
                    Solution = $Table.solution
                    Body = New-AttributeMetadata $column `
                        -GlobalChoiceMetadataIds (
                            Get-GlobalChoiceMetadataIds @($column)
                        )
                }
                Invoke-PlannedRequest $request | Out-Null
                Write-Output "$($Table.logicalName)/$($column.logicalName): Created"
            } elseif ($actual.Count -eq 1) {
                Test-AttributeCompatibility $actual[0] $column $Table.logicalName
                if (Test-LocalizedMetadataChanged $actual[0] $column.metadata) {
                    if (-not $actual[0].MetadataId) {
                        throw "Cannot update localized metadata for '$($Table.logicalName)/$($column.logicalName)' without its metadata ID."
                    }
                    $typeName = switch ([string]$actual[0].AttributeType) {
                        'String' { 'StringAttributeMetadata' }
                        'DateTime' { 'DateTimeAttributeMetadata' }
                        'Picklist' { 'PicklistAttributeMetadata' }
                        default { throw "Cannot safely update attribute metadata for '$($column.logicalName)': unsupported typed endpoint." }
                    }
                    $path = "/EntityDefinitions(LogicalName='$($Table.logicalName)')/Attributes($($actual[0].MetadataId))/Microsoft.Dynamics.CRM.$typeName"
                    $complete = Get-CompleteMetadata $path Attribute
                    Invoke-DataverseRequest -Method PUT -Path $path `
                        -Body (New-CompleteLocalizedMetadataUpdateBody $complete $column.metadata Attribute) `
                        -Headers (Get-MergeLabelHeaders $Table.solution) | Out-Null
                }
            } else {
                throw "Duplicate physical attributes found for '$($Table.logicalName)/$($column.logicalName)'."
            }
        }
        Write-Output "$($Table.logicalName): Unchanged"
        Publish-TableMetadata $Table
    }
    $objectTypeCode = Resolve-TableObjectTypeCode $Table.logicalName
    Invoke-TableChildren $Table $objectTypeCode
}

function Get-ContractTableSchemaName {
    param(
        [Parameter(Mandatory)] [string]$LogicalName,
        [Parameter(Mandatory)] $Contract
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

function Invoke-RoleReconciliation {
    param(
        [Parameter(Mandatory)] $Role,
        [Parameter(Mandatory)] $Contract
    )
    foreach ($forbidden in $Role.deniedPrivileges) {
        if (@($Role.tablePrivileges.privileges) -contains $forbidden) {
            throw "Role '$($Role.name)' attempts forbidden privilege '$forbidden'."
        }
    }
    $escapedName = $Role.name.Replace("'", "''")
    $existing = Get-One "/roles?`$select=roleid,name,description,_businessunitid_value,_solutionid_value&`$filter=name eq '$escapedName' and _parentrootroleid_value eq null"
    if ($null -eq $existing) {
        $businessUnit = Get-One "/businessunits?`$select=businessunitid&`$filter=parentbusinessunitid eq null"
        if ($null -eq $businessUnit -or -not $businessUnit.businessunitid) {
            throw 'The root business unit could not be resolved.'
        }
        $businessUnitId = $businessUnit.businessunitid
        $request = [pscustomobject]@{
            Method = 'POST'; Path = '/roles'; Solution = $Role.solution
            EntityLogicalName = 'role'; IdProperty = 'roleid'
            LocalizedFields = @{
                name = $Role.metadata.label
                description = $Role.metadata.description
            }
            Body = @{
                name = $Role.name
                description = [string]$Role.metadata.description.'1033'
                'businessunitid@odata.bind' = "/businessunits($businessUnitId)"
            }
        }
        $existing = Invoke-PlannedRequest $request
        Set-RecordLocalizedFields -Request $request -CreatedRecord $existing
        if ($null -eq $existing -or -not $existing.roleid) {
            throw "Created role '$($Role.name)' did not return its role ID."
        }
        Write-Output "$($Role.name): Created"
    } else {
        Assert-SolutionOwnership $existing $Role.solution $Role.name
        $request = [pscustomobject]@{
            Solution = $Role.solution
            EntityLogicalName = 'role'
            IdProperty = 'roleid'
            LocalizedFields = @{
                name = $Role.metadata.label
                description = $Role.metadata.description
            }
        }
        # Role localized labels are not exposed as a complete language set by
        # the record query. Idempotently repair every language on each run.
        Set-RecordLocalizedFields -Request $request -CreatedRecord $existing
        Write-Output "$($Role.name): Updated"
    }

    $wanted = foreach ($tablePrivilege in $Role.tablePrivileges) {
        $logicalName = [string]$tablePrivilege.table
        $escapedLogicalName = ConvertTo-ODataKeyString $logicalName
        $schemaName = Get-ContractTableSchemaName $logicalName $Contract
        $entityMetadata = Invoke-DataverseRequest -Method GET -Path (
            "/EntityDefinitions(LogicalName='$escapedLogicalName')?`$select=LogicalName,SchemaName,Privileges"
        )
        if ($null -eq $entityMetadata -or
            [string]$entityMetadata.SchemaName -cne $schemaName) {
            throw "Dataverse metadata for table '$logicalName' did not return contract schema name '$schemaName'."
        }
        foreach ($verb in $tablePrivilege.privileges) {
            $exactName = "prv$verb$schemaName"
            $matches = @($entityMetadata.Privileges | Where-Object {
                [string]$_.Name -ceq $exactName
            })
            if ($matches.Count -ne 1 -or -not $matches[0].PrivilegeId) {
                throw "Required Dataverse privilege '$exactName' was not found in metadata for '$logicalName'."
            }
            [pscustomobject]@{
                Name = [string]$matches[0].Name
                PrivilegeId = [string]$matches[0].PrivilegeId
                Depth = 'Global'
            }
        }
    }
    $roleId = $existing.roleid
    $currentResponse = Invoke-DataverseRequest -Method GET -Path (
        "/RetrieveRolePrivilegesRole(RoleId=$roleId)"
    )
    $current = @()
    if ($null -ne $currentResponse.RolePrivileges) {
        $current = @(foreach ($rolePrivilege in @($currentResponse.RolePrivileges)) {
            [pscustomobject]@{
                name = $rolePrivilege.PrivilegeName
                privilegeid = $rolePrivilege.PrivilegeId
                Depth = [string]$rolePrivilege.Depth
            }
        })
    }
    $forbiddenVerbs = @($Role.deniedPrivileges)
    foreach ($entry in $current) {
        if ($forbiddenVerbs | Where-Object { $entry.name -like "prv$_*" }) {
            throw "Existing role '$($Role.name)' contains forbidden privilege '$($entry.name)'."
        }
    }
    $currentWanted = @($current | Where-Object name -in @($wanted.Name))
    $requiresReplacement = @($current | Where-Object name -notin @($wanted.Name)).Count -gt 0 -or
        @($currentWanted | Where-Object Depth -ne 'Global').Count -gt 0
    $toResolve = if ($requiresReplacement) {
        @($wanted)
    } else {
        @($wanted | Where-Object Name -notin @($current.name))
    }
    if ($toResolve.Count -gt 0) {
        $resolved = foreach ($item in $toResolve) {
            @{ PrivilegeId = $item.PrivilegeId; Depth = $item.Depth }
        }
        $request = [pscustomobject]@{
            Method = 'POST'
            Path = if ($requiresReplacement) {
                "/roles($roleId)/Microsoft.Dynamics.CRM.ReplacePrivilegesRole"
            } else {
                "/roles($roleId)/Microsoft.Dynamics.CRM.AddPrivilegesRole"
            }
            Solution = $Role.solution
            Body = @{ Privileges = @($resolved) }
        }
        Invoke-PlannedRequest $request | Out-Null
    }
}

function Invoke-InsuranceFoundationReconciliation {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)] $Contract,
        [ValidateSet('Foundation', 'DataModel', 'All')] [string]$Scope = 'All'
    )

    # This must remain the first operation: malformed or unresolved contracts
    # cannot cause even a metadata read, much less a mutation.
    Assert-InsuranceFoundationIntegrity $Contract

    if ($Scope -in @('Foundation', 'All')) {
        foreach ($choice in $Contract.choices) {
            if ($PSCmdlet.ShouldProcess($choice.logicalName, 'Reconcile global choice')) {
                Invoke-ChoiceReconciliation $choice
            }
        }
    }
    if ($Scope -in @('DataModel', 'All')) {
        foreach ($extension in $Contract.nativeExtensions) {
            if ($PSCmdlet.ShouldProcess("$($extension.table)/$($extension.logicalName)", 'Reconcile native extension')) {
                Invoke-NativeExtensionReconciliation $extension
            }
        }
        foreach ($table in $Contract.tables) {
            if ($PSCmdlet.ShouldProcess($table.logicalName, 'Reconcile custom table')) {
                Invoke-TableReconciliation $table
            }
        }
    }
    if ($Scope -in @('Foundation', 'All')) {
        foreach ($role in $Contract.roles) {
            if ($PSCmdlet.ShouldProcess($role.name, 'Reconcile security role')) {
                Invoke-RoleReconciliation $role $Contract
            }
        }
    }
    if ($PSCmdlet.ShouldProcess($script:DataverseBaseUrl, 'Publish all customizations')) {
        $solution = if ($Scope -eq 'Foundation') { 'crmshow_Foundation' } else { 'crmshow_DataModel' }
        Invoke-DataverseRequest -Method POST -Path '/PublishAllXml' -Body @{} `
            -Headers (Get-DataverseHeaders $solution) | Out-Null
        Write-Output 'Customizations: Published'
    }
}

if ($MyInvocation.InvocationName -ne '.') {
    try {
        $contract = Test-InsuranceFoundationContract -Path $ContractPath
        Invoke-InsuranceFoundationReconciliation -Contract $contract -Scope $Scope
    } catch {
        Write-Error $_
        exit 1
    }
}
