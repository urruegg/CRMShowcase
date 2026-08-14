BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
    $script:contractPath = Join-Path $script:repoRoot 'solution/schema/insurance-foundation.json'
    $script:manifestPath = Join-Path $script:repoRoot 'solution/manifest.json'
    $script:convergencePath = Join-Path $script:repoRoot 'scripts/solution/Test-InsuranceFoundationConvergence.ps1'
    $script:childPowerShellPath = if (Get-Command pwsh -ErrorAction SilentlyContinue) {
        (Get-Command pwsh -ErrorAction Stop).Source
    }
    else {
        (Get-Command powershell -ErrorAction Stop).Source
    }
    . (Join-Path $script:repoRoot 'scripts/solution/Get-Manifest.ps1')
    . $script:convergencePath `
        -EnvironmentUrl 'https://unit.crm.dynamics.com' `
        -ContractPath $script:contractPath
    $script:contract = Get-Content -LiteralPath $script:contractPath -Raw -Encoding UTF8 |
        ConvertFrom-Json -ErrorAction Stop
    $script:manifest = Get-Manifest -Path $script:manifestPath -Validate
    $script:languages = @('1033', '1031', '1036', '1040')

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

    function script:New-FakeGuid {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            [int]$Index
        )

        return ('00000000-0000-0000-0000-{0:d12}' -f $Index)
    }

    function script:Get-ComponentIdMap {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            $Contract
        )

        $index = 1
        $map = @{}

        foreach ($choice in @($Contract.choices)) {
            $map["choice:$($choice.logicalName)"] = script:New-FakeGuid -Index $index
            $index++
        }

        foreach ($extension in @($Contract.nativeExtensions)) {
            $map["extension:$($extension.table)/$($extension.logicalName)"] =
                script:New-FakeGuid -Index $index
            $index++
        }

        foreach ($table in @($Contract.tables)) {
            $map["table:$($table.logicalName)"] = script:New-FakeGuid -Index $index
            $index++
            foreach ($column in @($table.columns)) {
                $map["column:$($table.logicalName)/$($column.logicalName)"] =
                    script:New-FakeGuid -Index $index
                $index++
            }
            foreach ($rule in @($table.businessRules)) {
                $map["ruleview:$($table.logicalName)/$($rule.name)"] =
                    script:New-FakeGuid -Index $index
                $index++
            }
            foreach ($view in @($table.views)) {
                $map["view:$($table.logicalName)/$($view.name)"] =
                    script:New-FakeGuid -Index $index
                $index++
            }
            foreach ($form in @($table.forms)) {
                $map["form:$($table.logicalName)/$($form.name)"] =
                    script:New-FakeGuid -Index $index
                $index++
            }
        }

        foreach ($role in @($Contract.roles)) {
            $map["role:$($role.name)"] = script:New-FakeGuid -Index $index
            $index++
        }

        return $map
    }

    function script:Get-ObjectTypeCodeMap {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            $Contract
        )

        $map = @{}
        $base = 10427
        for ($index = 0; $index -lt @($Contract.tables).Count; $index++) {
            $table = $Contract.tables[$index]
            $map[[string]$table.logicalName] = $base + $index
        }

        return $map
    }

    function script:Get-ColumnAttributeTypeName {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            $Column
        )

        return @{
            Text         = 'String'
            DateOnly     = 'DateTime'
            DateTime     = 'DateTime'
            GlobalChoice = 'Picklist'
            Lookup       = 'Lookup'
            Customer     = 'Customer'
            Whole        = 'Integer'
            Money        = 'Money'
            TwoOptions   = 'Boolean'
        }[[string]$Column.type]
    }

    function script:New-BaseAttributeSnapshot {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            $Column,

            [Parameter(Mandatory)]
            [string]$MetadataId
        )

        $attribute = [ordered]@{
            MetadataId   = $MetadataId
            LogicalName  = [string]$Column.logicalName
            SchemaName   = [string]$Column.schemaName
            AttributeType = script:Get-ColumnAttributeTypeName -Column $Column
            DisplayName  = ConvertTo-LocalizedLabel $Column.metadata.label
            Description  = ConvertTo-LocalizedLabel $Column.metadata.description
            RequiredLevel = (ConvertTo-RequiredLevel ([bool]$Column.required)).Value
            IsAuditEnabled = @{ Value = [bool]$Column.auditing }
        }

        switch ([string]$Column.type) {
            'Text' {
                $attribute.MaxLength = [int]$Column.maxLength
            }
            'DateOnly' {
                $attribute.Format = 'DateOnly'
                $attribute.DateTimeBehavior = @{ Value = 'DateOnly' }
            }
            'DateTime' {
                $attribute.Format = 'DateAndTime'
                $attribute.DateTimeBehavior = @{ Value = 'TimeZoneIndependent' }
            }
            'GlobalChoice' {
                $attribute.GlobalOptionSet = [pscustomobject]@{
                    Name = [string]$Column.choice
                }
            }
            'Lookup' {
                $attribute.Targets = @($Column.lookup.targets)
            }
            'Customer' {
                $attribute.Targets = @($Column.lookup.targets)
            }
            'Whole' {
                $attribute.MinValue = [int]$Column.minValue
                $attribute.MaxValue = [int]$Column.maxValue
            }
            'Money' {
                $attribute.PrecisionSource = 2
            }
            'TwoOptions' {
                $attribute.DefaultValue = $false
            }
        }

        return [pscustomobject]$attribute
    }

    function script:New-TypedAttributeSnapshot {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            $Column,

            [Parameter(Mandatory)]
            [string]$MetadataId
        )

        $attribute = [ordered]@{
            MetadataId    = $MetadataId
            LogicalName   = [string]$Column.logicalName
            SchemaName    = [string]$Column.schemaName
            AttributeType = script:Get-ColumnAttributeTypeName -Column $Column
            DisplayName   = ConvertTo-LocalizedLabel $Column.metadata.label
            Description   = ConvertTo-LocalizedLabel $Column.metadata.description
            RequiredLevel = ConvertTo-RequiredLevel ([bool]$Column.required)
            IsAuditEnabled = @{ Value = [bool]$Column.auditing }
        }

        switch ([string]$Column.type) {
            'Text' {
                $attribute.MaxLength = [int]$Column.maxLength
            }
            'DateOnly' {
                $attribute.Format = 'DateOnly'
                $attribute.DateTimeBehavior = @{ Value = 'DateOnly' }
            }
            'DateTime' {
                $attribute.Format = 'DateAndTime'
                $attribute.DateTimeBehavior = @{ Value = 'TimeZoneIndependent' }
            }
            'GlobalChoice' {
                $attribute.GlobalOptionSet = [pscustomobject]@{
                    Name = [string]$Column.choice
                }
            }
            'Lookup' {
                $attribute.Targets = @($Column.lookup.targets)
            }
            'Customer' {
                $attribute.AttributeType = 'Customer'
                $attribute.Targets = @($Column.lookup.targets)
            }
            'Whole' {
                $attribute.MinValue = [int]$Column.minValue
                $attribute.MaxValue = [int]$Column.maxValue
            }
            'Money' {
                $attribute.PrecisionSource = 2
            }
            'TwoOptions' {
                $attribute.DefaultValue = $false
            }
        }

        return [pscustomobject]$attribute
    }

    function script:New-RelationshipSnapshots {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            $Table
        )

        $relationships = [System.Collections.Generic.List[object]]::new()
        foreach ($relationship in @($Table.relationships)) {
            if ([string]$relationship.authoring -eq 'CreateCustomerRelationships') {
                $column = @($Table.columns | Where-Object {
                        $_.logicalName -eq $relationship.lookupColumn
                    })[0]
                foreach ($expected in @(Get-ExpectedCustomerRelationships `
                            -Table $Table `
                            -Column $column)) {
                    [void]$relationships.Add([pscustomobject]@{
                            SchemaName          = [string]$expected.SchemaName
                            ReferencedEntity    = [string]$expected.ReferencedEntity
                            ReferencingEntity   = [string]$Table.logicalName
                            ReferencingAttribute = [string]$column.logicalName
                            CascadeConfiguration = [pscustomobject](
                                Get-ExpectedOrdinaryRelationshipCascade `
                                    -ReferencedEntity ([string]$expected.ReferencedEntity)
                            )
                        })
                }
                continue
            }

            $target = [string]$relationship.referencedTables[0]
            [void]$relationships.Add([pscustomobject]@{
                    SchemaName          = [string]$relationship.schemaName
                    ReferencedEntity    = $target
                    ReferencingEntity   = [string]$Table.logicalName
                    ReferencingAttribute = [string]$relationship.lookupColumn
                    CascadeConfiguration = [pscustomobject](
                        Get-ExpectedOrdinaryRelationshipCascade `
                            -ReferencedEntity $target
                    )
                })
        }

        return @($relationships)
    }

    function script:New-TableSnapshot {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            $Table,

            [Parameter(Mandatory)]
            [hashtable]$IdMap,

            [Parameter(Mandatory)]
            [int]$ObjectTypeCode
        )

        $attributes = foreach ($column in @($Table.columns)) {
            script:New-BaseAttributeSnapshot `
                -Column $column `
                -MetadataId $IdMap["column:$($Table.logicalName)/$($column.logicalName)"]
        }

        return [pscustomobject][ordered]@{
            MetadataId          = $IdMap["table:$($Table.logicalName)"]
            LogicalName         = [string]$Table.logicalName
            SchemaName          = [string]$Table.schemaName
            OwnershipType       = [string]$Table.ownership
            PrimaryNameAttribute = 'crmshow_name'
            IsAuditEnabled      = @{ Value = [bool]$Table.auditing }
            DisplayName         = ConvertTo-LocalizedLabel $Table.metadata.label
            Description         = ConvertTo-LocalizedLabel $Table.metadata.description
            ObjectTypeCode      = $ObjectTypeCode
            Attributes          = @($attributes)
            ManyToOneRelationships = @(script:New-RelationshipSnapshots -Table $Table)
        }
    }

    function script:New-ChoiceSnapshot {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            $Choice,

            [Parameter(Mandatory)]
            [string]$MetadataId
        )

        $options = [System.Collections.Generic.List[object]]::new()
        for ($index = 0; $index -lt @($Choice.options).Count; $index++) {
            $option = $Choice.options[$index]
            [void]$options.Add([pscustomobject]@{
                    Value       = 100000000 + $index
                    Label       = ConvertTo-LocalizedLabel $option.metadata.label
                    Description = ConvertTo-LocalizedLabel $option.metadata.description
                })
        }

        return [pscustomobject][ordered]@{
            MetadataId   = $MetadataId
            Name         = [string]$Choice.logicalName
            IsGlobal     = $true
            OptionSetType = 'Picklist'
            DisplayName  = ConvertTo-LocalizedLabel $Choice.metadata.label
            Description  = ConvertTo-LocalizedLabel $Choice.metadata.description
            Options      = @($options)
        }
    }

    function script:New-SavedQuerySnapshot {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            $Request,

            [Parameter(Mandatory)]
            $Table,

            [Parameter(Mandatory)]
            [string]$SavedQueryId
        )

        return [pscustomobject][ordered]@{
            savedqueryid     = $SavedQueryId
            name             = [string]$Request.Body.name
            description      = [string]$Request.Body.description
            returnedtypecode = [string]$Table.logicalName
            fetchxml         = [string]$Request.Body.fetchxml
            layoutxml        = [string]$Request.Body.layoutxml
        }
    }

    function script:New-FormSnapshot {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            $Request,

            [Parameter(Mandatory)]
            $Table,

            [Parameter(Mandatory)]
            [string]$FormId
        )

        return [pscustomobject][ordered]@{
            formid         = $FormId
            name           = [string]$Request.Body.name
            description    = [string]$Request.Body.description
            objecttypecode = [string]$Table.logicalName
            type           = 2
            formxml        = [string]$Request.Body.formxml
        }
    }

    function script:New-LocalizedRecordResponse {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            $Text
        )

        return [pscustomobject]@{
            Label = [pscustomobject](ConvertTo-LocalizedLabel $Text)
        }
    }

    function script:Add-LocalizedFieldResponses {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            [hashtable]$Responses,

            [Parameter(Mandatory)]
            [string]$EntityLogicalName,

            [Parameter(Mandatory)]
            [string]$IdProperty,

            [Parameter(Mandatory)]
            [string]$RecordId,

            [Parameter(Mandatory)]
            $LocalizedFields
        )

        foreach ($field in @($LocalizedFields.Keys | Sort-Object)) {
            $Responses[(Get-ConvergenceRetrieveLocLabelsPath `
                    -EntityLogicalName $EntityLogicalName `
                    -IdProperty $IdProperty `
                    -RecordId $RecordId `
                    -AttributeName ([string]$field))] =
                script:New-LocalizedRecordResponse -Text $LocalizedFields[$field]
        }
    }

    function script:Get-SchemaMap {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            $Contract
        )

        $map = @{
            account  = 'Account'
            contact  = 'Contact'
            lead     = 'Lead'
            incident = 'Incident'
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
                        Name        = "prv$verb$schemaName"
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
                    Name        = "prv$verb$schemaName"
                    PrivilegeId = "$($tablePrivilege.table)-$verb"
                    Depth       = 'Global'
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
                        PrivilegeId   = $_.PrivilegeId
                        Depth         = $_.Depth
                    }
                }
        )
    }

    function script:New-SolutionMembershipResponse {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            [string[]]$SolutionUniqueName
        )

        return [pscustomobject]@{
            value = @(
                @(Get-UniqueConvergenceStrings -Value $SolutionUniqueName) |
                    ForEach-Object {
                        [pscustomobject]@{
                            solutionid = [pscustomobject]@{
                                uniquename = [string]$_
                            }
                        }
                    }
            )
        }
    }

    function script:New-SolutionInventoryEntry {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            [string]$ObjectId,

            [Parameter(Mandatory)]
            [int]$ComponentType,

            [string]$SolutionComponentId,

            [string]$RootSolutionComponentId,

            [AllowNull()]
            [int]$RootComponentBehavior
        )

        $resolvedObjectId = ([string]$ObjectId).Trim('{}')
        $resolvedSolutionComponentId = if ([string]::IsNullOrWhiteSpace($SolutionComponentId)) {
            $resolvedObjectId
        }
        else {
            ([string]$SolutionComponentId).Trim('{}')
        }
        $resolvedRootSolutionComponentId = if ([string]::IsNullOrWhiteSpace($RootSolutionComponentId)) {
            $null
        }
        else {
            ([string]$RootSolutionComponentId).Trim('{}')
        }

        return [pscustomobject]@{
            solutioncomponentid          = $resolvedSolutionComponentId
            objectid                     = $resolvedObjectId
            componenttype                = [int]$ComponentType
            rootcomponentbehavior        = $RootComponentBehavior
            rootsolutioncomponentid      = $resolvedRootSolutionComponentId
        }
    }

    function script:New-EntityInventorySnapshot {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            [string]$MetadataId,

            [Parameter(Mandatory)]
            [string]$LogicalName,

            [Parameter(Mandatory)]
            [string]$SchemaName
        )

        return [pscustomobject]@{
            MetadataId  = $MetadataId
            LogicalName = $LogicalName
            SchemaName  = $SchemaName
        }
    }

    function script:New-AttributeInventorySnapshot {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            $Column,

            [Parameter(Mandatory)]
            [string]$MetadataId,

            [string]$AttributeOf
        )

        $attribute = script:New-BaseAttributeSnapshot `
            -Column $Column `
            -MetadataId $MetadataId
        $attribute | Add-Member -NotePropertyName AttributeOf -NotePropertyValue $AttributeOf
        return $attribute
    }

    function script:New-TableUnexpectedChildrenSnapshot {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            [string]$LogicalName,

            [Parameter(Mandatory)]
            [string]$SchemaName,

            [Parameter(Mandatory)]
            [string]$PrimaryIdAttribute,

            [AllowNull()]
            [object[]]$Attributes = @(),

            [AllowNull()]
            [object[]]$ManyToOneRelationships = @(),

            [AllowNull()]
            [object[]]$Keys = @()
        )

        return [pscustomobject]@{
            LogicalName            = $LogicalName
            SchemaName             = $SchemaName
            PrimaryIdAttribute     = $PrimaryIdAttribute
            Attributes             = @($Attributes)
            ManyToOneRelationships = @($ManyToOneRelationships)
            Keys                   = @($Keys)
        }
    }

    function script:New-ReadyConvergenceResponseMap {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            $Contract,

            [Parameter(Mandatory)]
            $Manifest,

            [ValidateSet('Ready', 'MissingLanguage', 'RoleNameCaseConflict')]
            [string]$Scenario = 'Ready'
        )

        $idMap = script:Get-ComponentIdMap -Contract $Contract
        $objectTypeCodes = script:Get-ObjectTypeCodeMap -Contract $Contract
        $schemaMap = script:Get-SchemaMap -Contract $Contract
        $metadataPrivileges = script:Get-MetadataPrivilegeMap -Contract $Contract
        $responses = @{}
        $publisherPrefix = Get-ConvergencePublisherLogicalPrefix -Manifest $Manifest

        $provisionedLanguages = if ($Scenario -eq 'MissingLanguage') {
            @(1033, 1031, 1036)
        }
        else {
            @($Contract.languages | ForEach-Object { [int]$_ })
        }
        $responses[(Get-ConvergenceLanguagesPath)] = [pscustomobject]@{
            RetrieveProvisionedLanguages = @($provisionedLanguages)
        }

        $solutions = @(
            [pscustomobject]@{
                solutionid  = script:New-FakeGuid -Index 9001
                uniquename  = 'crmshow_Foundation'
                publisherid = [pscustomobject]@{
                    uniquename                    = [string]$Manifest.publisher.uniqueName
                    customizationprefix           = [string]$Manifest.publisher.prefix
                    customizationoptionvalueprefix = [int]$Manifest.publisher.customizationOptionValuePrefix
                }
            },
            [pscustomobject]@{
                solutionid  = script:New-FakeGuid -Index 9002
                uniquename  = 'crmshow_DataModel'
                publisherid = [pscustomobject]@{
                    uniquename                    = [string]$Manifest.publisher.uniqueName
                    customizationprefix           = [string]$Manifest.publisher.prefix
                    customizationoptionvalueprefix = [int]$Manifest.publisher.customizationOptionValuePrefix
                }
            }
        )
        $solutionIds = @{
            crmshow_Foundation = [string]$solutions[0].solutionid
            crmshow_DataModel  = [string]$solutions[1].solutionid
        }
        $solutionInventory = @{
            crmshow_Foundation = [System.Collections.Generic.List[object]]::new()
            crmshow_DataModel  = [System.Collections.Generic.List[object]]::new()
        }
        $rootRoles = [System.Collections.Generic.List[object]]::new()
        $responses[(Get-ConvergenceSolutionsPath -SolutionUniqueName @($Contract.solutions))] = [pscustomobject]@{
            value = @($solutions)
        }

        foreach ($choice in @($Contract.choices)) {
            $choiceSnapshot = script:New-ChoiceSnapshot `
                -Choice $choice `
                -MetadataId $idMap["choice:$($choice.logicalName)"]
            $responses[(Get-ConvergenceGlobalChoicePath -ChoiceLogicalName $choice.logicalName)] =
                $choiceSnapshot
            $responses[(Get-ConvergenceGlobalChoiceByMetadataIdPath -MetadataId $choiceSnapshot.MetadataId)] =
                $choiceSnapshot
            $responses[(Get-ConvergenceSolutionMembershipPath -ComponentId $choiceSnapshot.MetadataId)] =
                script:New-SolutionMembershipResponse -SolutionUniqueName ([string]$choice.solution)
            [void]$solutionInventory[[string]$choice.solution].Add(
                (script:New-SolutionInventoryEntry `
                    -ObjectId ([string]$choiceSnapshot.MetadataId) `
                    -ComponentType 9)
            )
        }

        foreach ($extension in @($Contract.nativeExtensions)) {
            $attribute = script:New-TypedAttributeSnapshot `
                -Column $extension `
                -MetadataId $idMap["extension:$($extension.table)/$($extension.logicalName)"]
            $responses[(Get-ConvergenceTypedAttributePath -TableLogicalName $extension.table -Column $extension)] =
                [pscustomobject]@{ value = @($attribute) }
            $responses[(Get-ConvergenceSolutionMembershipPath -ComponentId $attribute.MetadataId)] =
                script:New-SolutionMembershipResponse -SolutionUniqueName ([string]$extension.solution)
        }

        foreach ($tableLogicalName in @('account', 'contact', 'lead', 'incident')) {
            $nativeExtensions = @($Contract.nativeExtensions | Where-Object {
                    [string]$_.table -ceq $tableLogicalName
                })
            $nativeAttributes = foreach ($extension in @($nativeExtensions)) {
                script:New-AttributeInventorySnapshot `
                    -Column $extension `
                    -MetadataId $idMap["extension:$($extension.table)/$($extension.logicalName)"]
            }
            $responses[(Get-ConvergenceTableUnexpectedChildrenPath `
                    -LogicalName $tableLogicalName `
                    -PublisherPrefix $publisherPrefix)] =
                script:New-TableUnexpectedChildrenSnapshot `
                    -LogicalName $tableLogicalName `
                    -SchemaName ([string]$schemaMap[$tableLogicalName]) `
                    -PrimaryIdAttribute ($tableLogicalName + 'id') `
                    -Attributes @($nativeAttributes)
        }

        foreach ($table in @($Contract.tables)) {
            $tableSnapshot = script:New-TableSnapshot `
                -Table $table `
                -IdMap $idMap `
                -ObjectTypeCode $objectTypeCodes[[string]$table.logicalName]
            $responses[(Get-ConvergenceEntityByMetadataIdPath -MetadataId $tableSnapshot.MetadataId)] =
                (script:New-EntityInventorySnapshot `
                    -MetadataId $tableSnapshot.MetadataId `
                    -LogicalName ([string]$table.logicalName) `
                    -SchemaName ([string]$table.schemaName))
            $responses[(Get-ConvergenceTableMetadataPath `
                    -LogicalName $table.logicalName `
                    -RequestedAttributeLogicalNames @($table.columns.logicalName))] =
                [pscustomobject]@{ value = @($tableSnapshot) }
            $responses[(Get-ConvergenceSolutionMembershipPath -ComponentId $tableSnapshot.MetadataId)] =
                script:New-SolutionMembershipResponse -SolutionUniqueName ([string]$table.solution)
            [void]$solutionInventory[[string]$table.solution].Add(
                (script:New-SolutionInventoryEntry `
                    -ObjectId ([string]$tableSnapshot.MetadataId) `
                    -ComponentType 1)
            )

            $inventoryAttributes = foreach ($column in @($table.columns)) {
                script:New-AttributeInventorySnapshot `
                    -Column $column `
                    -MetadataId $idMap["column:$($table.logicalName)/$($column.logicalName)"]
            }
            $inventoryKeys = foreach ($key in @($table.alternateKeys)) {
                [pscustomobject]@{
                    SchemaName    = [string]$key.schemaName
                    KeyAttributes = @($key.columns)
                }
            }
            $responses[(Get-ConvergenceTableUnexpectedChildrenPath `
                    -LogicalName $table.logicalName `
                    -PublisherPrefix $publisherPrefix)] =
                script:New-TableUnexpectedChildrenSnapshot `
                    -LogicalName ([string]$table.logicalName) `
                    -SchemaName ([string]$table.schemaName) `
                    -PrimaryIdAttribute ("$($table.logicalName)id") `
                    -Attributes @($inventoryAttributes) `
                    -ManyToOneRelationships @(script:New-RelationshipSnapshots -Table $table) `
                    -Keys @($inventoryKeys)

            foreach ($column in @($table.columns)) {
                $typedAttribute = script:New-TypedAttributeSnapshot `
                    -Column $column `
                    -MetadataId $idMap["column:$($table.logicalName)/$($column.logicalName)"]
                $responses[(Get-ConvergenceTypedAttributePath -TableLogicalName $table.logicalName -Column $column)] =
                    [pscustomobject]@{ value = @($typedAttribute) }
            }

            foreach ($key in @($table.alternateKeys)) {
                $responses[(Get-ConvergenceKeyPath `
                        -TableLogicalName $table.logicalName `
                        -SchemaName $key.schemaName)] = [pscustomobject]@{
                    value = @([pscustomobject]@{
                            MetadataId   = script:New-FakeGuid -Index 9500
                            SchemaName   = [string]$key.schemaName
                            KeyAttributes = @($key.columns)
                        })
                }
            }

            foreach ($rule in @($table.businessRules)) {
                $ruleRequest = New-InvalidDateViewRequest `
                    -Table $table `
                    -Rule $rule `
                    -ObjectTypeCode $objectTypeCodes[[string]$table.logicalName]
                $savedQuery = script:New-SavedQuerySnapshot `
                    -Request $ruleRequest `
                    -Table $table `
                    -SavedQueryId $idMap["ruleview:$($table.logicalName)/$($rule.name)"]
                $ruleLabel = [string]$rule.metadata.label.'1033'
                $responses[(Get-ConvergenceSavedQueryPath `
                        -TableLogicalName $table.logicalName `
                        -Label $ruleLabel)] = [pscustomobject]@{
                    value = @($savedQuery)
                }
                $responses[(Get-ConvergenceSavedQueryByIdPath -SavedQueryId $savedQuery.savedqueryid)] =
                    $savedQuery
                $responses[(Get-ConvergenceSolutionMembershipPath -ComponentId $savedQuery.savedqueryid)] =
                    script:New-SolutionMembershipResponse -SolutionUniqueName ([string]$table.solution)
                [void]$solutionInventory[[string]$table.solution].Add(
                    (script:New-SolutionInventoryEntry `
                        -ObjectId ([string]$savedQuery.savedqueryid) `
                        -ComponentType 26)
                )
                script:Add-LocalizedFieldResponses `
                    -Responses $responses `
                    -EntityLogicalName 'savedquery' `
                    -IdProperty 'savedqueryid' `
                    -RecordId $savedQuery.savedqueryid `
                    -LocalizedFields $ruleRequest.LocalizedFields
            }

            foreach ($view in @($table.views)) {
                $viewRequest = New-ViewRequest `
                    -Table $table `
                    -View $view `
                    -ObjectTypeCode $objectTypeCodes[[string]$table.logicalName]
                $savedQuery = script:New-SavedQuerySnapshot `
                    -Request $viewRequest `
                    -Table $table `
                    -SavedQueryId $idMap["view:$($table.logicalName)/$($view.name)"]
                $viewLabel = [string]$view.metadata.label.'1033'
                $responses[(Get-ConvergenceSavedQueryPath `
                        -TableLogicalName $table.logicalName `
                        -Label $viewLabel)] = [pscustomobject]@{
                    value = @($savedQuery)
                }
                $responses[(Get-ConvergenceSavedQueryByIdPath -SavedQueryId $savedQuery.savedqueryid)] =
                    $savedQuery
                $responses[(Get-ConvergenceSolutionMembershipPath -ComponentId $savedQuery.savedqueryid)] =
                    script:New-SolutionMembershipResponse -SolutionUniqueName ([string]$table.solution)
                [void]$solutionInventory[[string]$table.solution].Add(
                    (script:New-SolutionInventoryEntry `
                        -ObjectId ([string]$savedQuery.savedqueryid) `
                        -ComponentType 26)
                )
                script:Add-LocalizedFieldResponses `
                    -Responses $responses `
                    -EntityLogicalName 'savedquery' `
                    -IdProperty 'savedqueryid' `
                    -RecordId $savedQuery.savedqueryid `
                    -LocalizedFields $viewRequest.LocalizedFields
            }

            foreach ($form in @($table.forms)) {
                $formRequest = New-FormRequest -Table $table -Form $form
                $systemForm = script:New-FormSnapshot `
                    -Request $formRequest `
                    -Table $table `
                    -FormId $idMap["form:$($table.logicalName)/$($form.name)"]
                $formLabel = [string]$form.metadata.label.'1033'
                $responses[(Get-ConvergenceSystemFormPath `
                        -TableLogicalName $table.logicalName `
                        -Label $formLabel)] = [pscustomobject]@{
                    value = @($systemForm)
                }
                $responses[(Get-ConvergenceSystemFormByIdPath -FormId $systemForm.formid)] =
                    $systemForm
                $responses[(Get-ConvergenceSolutionMembershipPath -ComponentId $systemForm.formid)] =
                    script:New-SolutionMembershipResponse -SolutionUniqueName ([string]$table.solution)
                [void]$solutionInventory[[string]$table.solution].Add(
                    (script:New-SolutionInventoryEntry `
                        -ObjectId ([string]$systemForm.formid) `
                        -ComponentType 60)
                )
                script:Add-LocalizedFieldResponses `
                    -Responses $responses `
                    -EntityLogicalName 'systemform' `
                    -IdProperty 'formid' `
                    -RecordId $systemForm.formid `
                    -LocalizedFields $formRequest.LocalizedFields
            }
        }

        foreach ($logicalName in @($metadataPrivileges.Keys)) {
            $responses[(Get-InsuranceRoleEntityPrivilegesPath -LogicalName $logicalName)] =
                [pscustomobject]@{
                    LogicalName = [string]$logicalName
                    SchemaName  = [string]$schemaMap[$logicalName]
                    Privileges  = @($metadataPrivileges[$logicalName])
                }
        }

        foreach ($role in @($Contract.roles)) {
            $roleId = $idMap["role:$($role.name)"]
            $roleName = if ($Scenario -eq 'RoleNameCaseConflict' -and
                [string]$role.name -eq 'CRM Showcase Insurance Data Steward') {
                ([string]$role.name).ToLowerInvariant()
            }
            else {
                [string]$role.name
            }

            $responses[(Get-InsuranceSecurityRolePath -RoleName $role.name)] =
                [pscustomobject]@{
                    value = @([pscustomobject]@{
                            roleid = $roleId
                            name   = $roleName
                        })
                }
            $responses[(Get-InsuranceSecurityRoleSolutionMembershipPath -RoleId $roleId)] =
                script:New-SolutionMembershipResponse -SolutionUniqueName ([string]$role.solution)
            $responses[(Get-InsuranceSecurityRolePrivilegesPath -RoleId $roleId)] =
                [pscustomobject]@{
                    RolePrivileges = @(
                        script:Get-ActualRolePrivileges -Role $role -Contract $Contract
                    )
                }
            $responses[(Get-ConvergenceRoleByIdPath -RoleId $roleId)] = [pscustomobject]@{
                roleid = $roleId
                name   = $roleName
                _parentrootroleid_value = $null
            }
            [void]$rootRoles.Add([pscustomobject]@{
                    roleid = $roleId
                    name = $roleName
                    _parentrootroleid_value = $null
                })
        }

        foreach ($solutionUniqueName in @($solutionInventory.Keys)) {
            $responses[(Get-ConvergenceSolutionInventoryPath `
                    -SolutionId $solutionIds[$solutionUniqueName] `
                    -ComponentType (Get-ConvergenceReverseInventoryComponentTypes))] =
                [pscustomobject]@{
                    value = @($solutionInventory[$solutionUniqueName])
                }
        }
        $responses[(Get-ConvergenceRootInsuranceRolesPath -RolePrefix 'CRM Showcase Insurance ')] =
            [pscustomobject]@{
                value = @($rootRoles)
            }

        return [pscustomobject]@{
            Responses       = $responses
            IdMap           = $idMap
            ObjectTypeCodes = $objectTypeCodes
            SolutionIds     = $solutionIds
        }
    }

    function script:Register-ConvergenceTransportMock {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            [hashtable]$Responses
        )

        $script:calls = [System.Collections.Generic.List[object]]::new()
        $script:responseMap = $Responses

        Mock Invoke-ConvergenceDataverseRequest {
            param($Method, $EnvironmentUrl, $Path, $Headers)

            [void]$script:calls.Add([pscustomobject]@{
                    Method         = $Method
                    EnvironmentUrl = $EnvironmentUrl
                    Path           = $Path
                })

            if ($Method -cne 'GET') {
                throw "Unexpected mocked method: $Method"
            }

            if ($Path -match "^/EntityDefinitions\(LogicalName='([^']+)'\)/ManyToOneRelationships") {
                $relTable = $matches[1]
                $entityPrefix = "/EntityDefinitions(LogicalName='$relTable')?"
                # Multiple fixture keys can share this entity-name prefix (e.g. the
                # "unexpected children" reverse-inventory query and the metadata-snapshot
                # query both start with "/EntityDefinitions(LogicalName='X')?"). Only the
                # unexpected-children query's $expand includes "Keys(" (see
                # Get-ConvergenceTableUnexpectedChildrenPath), so require that substring
                # too. Without it, resolution depends on Hashtable key enumeration order,
                # which is not stable across processes and causes flaky failures (#96).
                $entityKey = @($script:responseMap.Keys |
                        Where-Object {
                            $_.StartsWith($entityPrefix, [System.StringComparison]::Ordinal) -and
                            $_.Contains('Keys(')
                        }) | Select-Object -First 1
                $relationships = @()
                if ($null -ne $entityKey -and
                    $null -ne $script:responseMap[$entityKey].ManyToOneRelationships) {
                    $relationships = @($script:responseMap[$entityKey].ManyToOneRelationships)
                }
                return [pscustomobject]@{ value = @($relationships) }
            }

            if (-not $script:responseMap.ContainsKey($Path)) {
                throw "Unexpected mocked path: $Path"
            }

            return $script:responseMap[$Path]
        }
    }

    function script:New-ConvergenceAzShim {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            [string]$RootPath,

            [Parameter(Mandatory)]
            [string]$ResponseMapPath
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

    $Value | ConvertTo-Json -Compress -Depth 100
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

if ($env:TEST_INSURANCE_CONVERGENCE_SCENARIO -eq 'TransportFailure') {
    $escape = [char]27
    Write-Error (
        "::warning::convergence transport`r`nSynthetic az transport failure.`t" +
        "$escape[31mblocked$escape[0m"
    ) -ErrorAction Continue
    exit 1
}

if ($env:TEST_INSURANCE_CONVERGENCE_SCENARIO -eq 'RetrieveLocLabelsUnsupported' -and
    $path -like '/RetrieveLocLabels*') {
    Write-Error "The requested resource does not support HTTP method 'GET'."
    exit 1
}

$map = Get-Content -LiteralPath '__MAP__' -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop

if ($path -match "^/EntityDefinitions\(LogicalName='([^']+)'\)/ManyToOneRelationships") {
    $relTable = $matches[1]
    $entityPrefix = "/EntityDefinitions(LogicalName='$relTable')?"
    # See the matching comment in Register-ConvergenceTransportMock (#96): require the
    # unique "Keys(" substring so resolution does not depend on property enumeration
    # order when more than one fixture key shares this entity-name prefix.
    $entityProperty = $map.PSObject.Properties |
        Where-Object {
            $_.Name.StartsWith($entityPrefix, [System.StringComparison]::Ordinal) -and
            $_.Name.Contains('Keys(')
        } |
        Select-Object -First 1
    $relationships = @()
    if ($null -ne $entityProperty -and
        $null -ne $entityProperty.Value.ManyToOneRelationships) {
        $relationships = @($entityProperty.Value.ManyToOneRelationships)
    }
    Write-Json ([pscustomobject]@{ value = @($relationships) })
    exit 0
}

$property = $map.PSObject.Properties[$path]
if ($null -eq $property) {
    Write-Error "Unexpected az rest URL: $url"
    exit 1
}

Write-Json $property.Value
'@.Replace('__MAP__', $ResponseMapPath.Replace("'", "''"))

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

    function script:Invoke-ConvergenceEntryScript {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            [ValidateSet('Ready', 'MissingLanguage', 'RoleNameCaseConflict', 'MissingRoleAndUnexpectedView', 'TransportFailure', 'RetrieveLocLabelsUnsupported')]
            [string]$Scenario
        )

        $fixtureScenario = if ($Scenario -in @('MissingRoleAndUnexpectedView', 'TransportFailure', 'RetrieveLocLabelsUnsupported')) {
            'Ready'
        }
        else {
            $Scenario
        }
        $fixture = script:New-ReadyConvergenceResponseMap `
            -Contract $script:contract `
            -Manifest $script:manifest `
            -Scenario $fixtureScenario

        if ($Scenario -eq 'MissingRoleAndUnexpectedView') {
            $missingRole = @($script:contract.roles | Where-Object {
                    [string]$_.name -ceq 'CRM Showcase Insurance Data Steward'
                })[0]
            $fixture.Responses[(Get-InsuranceSecurityRolePath -RoleName ([string]$missingRole.name))] =
                [pscustomobject]@{
                    value = @()
                }

            $table = @($script:contract.tables | Where-Object {
                    [string]$_.logicalName -ceq 'crmshow_policyprojection'
                })[0]
            $viewId = script:New-FakeGuid -Index 9721
            $inventoryPath = Get-ConvergenceSolutionInventoryPath `
                -SolutionId $fixture.SolutionIds['crmshow_DataModel'] `
                -ComponentType (Get-ConvergenceReverseInventoryComponentTypes)
            $fixture.Responses[$inventoryPath].value = @(
                $fixture.Responses[$inventoryPath].value +
                (script:New-SolutionInventoryEntry `
                    -ObjectId $viewId `
                    -ComponentType 26)
            )
            $fixture.Responses[(Get-ConvergenceSavedQueryByIdPath -SavedQueryId $viewId)] =
                [pscustomobject]@{
                    savedqueryid     = $viewId
                    name             = 'Unexpected Policy Projection View'
                    description      = 'Unexpected custom view.'
                    returnedtypecode = [string]$table.logicalName
                    fetchxml         = '<fetch version="1.0"><entity name="crmshow_policyprojection"><attribute name="crmshow_name" /></entity></fetch>'
                    layoutxml        = '<grid name="resultset" object="10428"><row name="crmshow_policyprojection" id="crmshow_policyprojectionid"><cell name="crmshow_name" width="150" /></row></grid>'
                }
        }

        $testRoot = Join-Path (Get-PSDrive -Name TestDrive).Root ([guid]::NewGuid().Guid)
        $null = New-Item -ItemType Directory -Path $testRoot -Force

        $responseMapPath = Join-Path $testRoot 'responses.json'
        $fixture.Responses | ConvertTo-Json -Depth 100 |
            Set-Content -LiteralPath $responseMapPath -Encoding UTF8

        script:New-ConvergenceAzShim `
            -RootPath $testRoot `
            -ResponseMapPath $responseMapPath

        $previousPath = $env:PATH
        $previousScenario = [Environment]::GetEnvironmentVariable(
            'TEST_INSURANCE_CONVERGENCE_SCENARIO',
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
            $env:TEST_INSURANCE_CONVERGENCE_SCENARIO = $Scenario

            $stdoutPath = Join-Path $testRoot 'stdout.txt'
            $stderrPath = Join-Path $testRoot 'stderr.txt'
            $process = Start-Process `
                -FilePath $script:childPowerShellPath `
                -ArgumentList @(
                    '-NoLogo',
                    '-NoProfile',
                    '-NonInteractive',
                    '-File', $script:convergencePath,
                    '-EnvironmentUrl', 'https://unit.crm.dynamics.com',
                    '-ContractPath', $script:contractPath
                ) `
                -Wait `
                -PassThru `
                -RedirectStandardOutput $stdoutPath `
                -RedirectStandardError $stderrPath
            $stdout = if (Test-Path -LiteralPath $stdoutPath -PathType Leaf) {
                Get-Content -LiteralPath $stdoutPath -Raw -Encoding UTF8
            }
            else {
                ''
            }
            $stderr = if (Test-Path -LiteralPath $stderrPath -PathType Leaf) {
                Get-Content -LiteralPath $stderrPath -Raw -Encoding UTF8
            }
            else {
                ''
            }
            $output = @($stdout, $stderr) | Where-Object {
                -not [string]::IsNullOrWhiteSpace([string]$_)
            }
            $exitCode = $process.ExitCode
        }
        finally {
            $env:PATH = $previousPath
            if ($null -eq $previousScenario) {
                Remove-Item Env:TEST_INSURANCE_CONVERGENCE_SCENARIO -ErrorAction SilentlyContinue
            }
            else {
                $env:TEST_INSURANCE_CONVERGENCE_SCENARIO = $previousScenario
            }
        }

        return [pscustomobject]@{
            ExitCode = $exitCode
            Output   = (@($output | ForEach-Object { $_.ToString() }) -join [Environment]::NewLine).Trim()
        }
    }
}

Describe 'New-ConvergenceSummary' {
    It 'is Ready only when every component is Ready' {
        New-ConvergenceSummary -Results @(
            [pscustomobject]@{ Component='choices'; State='Ready' },
            [pscustomobject]@{ Component='tables'; State='Ready' },
            [pscustomobject]@{ Component='roles'; State='Ready' }
        ) | Select-Object -ExpandProperty State |
            Should -Be 'Ready'
    }

    It 'lets ContractConflict dominate later in result order' {
        $summary = New-ConvergenceSummary -Results @(
            [pscustomobject]@{ Component='roles'; State='ManualPrerequisite' },
            [pscustomobject]@{ Component='tables'; State='ContractConflict' }
        )

        $summary.State | Should -Be 'ContractConflict'
        $summary.BlockingComponents | Should -Be @('roles', 'tables')
    }

    It 'uses deterministic safety precedence when no contract conflict exists' {
        $summary = New-ConvergenceSummary -Results @(
            [pscustomobject]@{ Component='roles'; State='ManualPrerequisite' },
            [pscustomobject]@{ Component='languages'; State='Precondition' },
            [pscustomobject]@{ Component='tables'; State='UnsupportedInTenant' },
            [pscustomobject]@{ Component='choices'; State='Ready' }
        )

        $summary.State | Should -Be 'UnsupportedInTenant'
        $summary.BlockingComponents | Should -Be @('roles', 'languages', 'tables')
    }

    It 'keeps all blocking components and MutationOccurred false' {
        $summary = New-ConvergenceSummary -Results @(
            [pscustomobject]@{ Component='roles'; State='ManualPrerequisite' },
            [pscustomobject]@{ Component='languages'; State='Precondition' }
        )

        $summary.State | Should -Be 'Precondition'
        $summary.BlockingComponents | Should -Be @('roles', 'languages')
        $summary.MutationOccurred | Should -BeFalse
    }
}

Describe 'Test-ConvergenceRetrieveLocLabelsUnsupportedError' {
    It 'returns true for known endpoint-not-supported semantics' {
        $errorRecord = $null
        try {
            throw "Dataverse convergence transport failed (GET /RetrieveLocLabels(EntityMoniker=@p1,AttributeName=@p2,IncludeUnpublished=@p3)?@p1=x&@p2='name'&@p3=true); az rest exited with code 1. The requested resource does not support HTTP method 'GET'."
        }
        catch {
            $errorRecord = $_
        }

        Test-ConvergenceRetrieveLocLabelsUnsupportedError -ErrorRecord $errorRecord |
            Should -BeTrue
    }

    It 'does not mask ordinary bad requests as UnsupportedInTenant' {
        $errorRecord = $null
        try {
            throw "Dataverse convergence transport failed (GET /RetrieveLocLabels(EntityMoniker=@p1,AttributeName=@p2,IncludeUnpublished=@p3)?@p1=x&@p2='name'&@p3=true); az rest exited with code 1. 400 Bad Request. Request message has unresolved parameters."
        }
        catch {
            $errorRecord = $_
        }

        Test-ConvergenceRetrieveLocLabelsUnsupportedError -ErrorRecord $errorRecord |
            Should -BeFalse
    }
}

Describe 'Convergence path builders' {
    It 'escapes apostrophes in solution, choice, key, view and form paths' {
        Get-ConvergenceSolutionsPath -SolutionUniqueName @(
            "crmshow_Foundation",
            "crmshow_O'Reilly"
        ) | Should -Be (
            "/solutions?`$select=solutionid,uniquename&" +
            "`$expand=publisherid(`$select=uniquename,customizationprefix,customizationoptionvalueprefix)&" +
            "`$filter=uniquename eq 'crmshow_Foundation' or uniquename eq 'crmshow_O''Reilly'"
        )

        Get-ConvergenceGlobalChoicePath -ChoiceLogicalName "crmshow_o'reilly" |
            Should -Be (
                "/GlobalOptionSetDefinitions(Name='crmshow_o''reilly')/" +
                'Microsoft.Dynamics.CRM.OptionSetMetadata'
            )

        Get-ConvergenceKeyPath `
            -TableLogicalName "crmshow_o'reilly" `
            -SchemaName "crmshow_Key'Odata" | Should -Be (
                "/EntityDefinitions(LogicalName='crmshow_o''reilly')/Keys?" +
                "`$select=MetadataId,SchemaName,KeyAttributes&" +
                "`$filter=SchemaName eq 'crmshow_Key''Odata'"
            )

        Get-ConvergenceSavedQueryPath `
            -TableLogicalName "crmshow_o'reilly" `
            -Label "O'Reilly View" | Should -Be (
                '/savedqueries?' +
                "`$select=savedqueryid,name,description,returnedtypecode,fetchxml,layoutxml&" +
                "`$filter=name eq 'O''Reilly View' and returnedtypecode eq 'crmshow_o''reilly'"
            )

        Get-ConvergenceSystemFormPath `
            -TableLogicalName "crmshow_o'reilly" `
            -Label "O'Reilly Form" | Should -Be (
                '/systemforms?' +
                "`$select=formid,name,description,objecttypecode,type,formxml&" +
                "`$filter=name eq 'O''Reilly Form' and objecttypecode eq 'crmshow_o''reilly' and type eq 2"
            )
    }

    It 'builds savedquery RetrieveLocLabels paths with @odata.id entity monikers' {
        $expectedEntityMoniker = [System.Uri]::EscapeDataString(
            '{"@odata.id":"savedqueries(11111111-1111-1111-1111-111111111111)"}'
        )
        Get-ConvergenceRetrieveLocLabelsPath `
            -EntityLogicalName 'savedquery' `
            -IdProperty 'savedqueryid' `
            -RecordId '11111111-1111-1111-1111-111111111111' `
            -AttributeName "na'me" | Should -Be (
                '/RetrieveLocLabels(EntityMoniker=@p1,AttributeName=@p2,IncludeUnpublished=@p3)?' +
                "@p1=$expectedEntityMoniker&" +
                "@p2='na''me'&" +
                '@p3=true'
            )
    }

    It 'builds systemform RetrieveLocLabels paths with @odata.id entity monikers' {
        $expectedEntityMoniker = [System.Uri]::EscapeDataString(
            '{"@odata.id":"systemforms(22222222-2222-2222-2222-222222222222)"}'
        )
        Get-ConvergenceRetrieveLocLabelsPath `
            -EntityLogicalName 'systemform' `
            -IdProperty 'formid' `
            -RecordId '{22222222-2222-2222-2222-222222222222}' `
            -AttributeName 'description' | Should -Be (
                '/RetrieveLocLabels(EntityMoniker=@p1,AttributeName=@p2,IncludeUnpublished=@p3)?' +
                "@p1=$expectedEntityMoniker&" +
                "@p2='description'&" +
                '@p3=true'
            )
    }

    It 'builds bounded reverse-inventory paths for reviewed solutions and object IDs' {
        Get-ConvergenceSolutionInventoryPath `
            -SolutionId '{11111111-1111-1111-1111-111111111111}' `
            -ComponentType @(60, 1, 9, 26, 1) | Should -Be (
                "/solutioncomponents?`$select=solutioncomponentid,objectid,componenttype,rootcomponentbehavior,rootsolutioncomponentid&" +
                "`$filter=_solutionid_value eq 11111111-1111-1111-1111-111111111111 and (componenttype eq 1 or componenttype eq 9 or componenttype eq 26 or componenttype eq 60)"
            )

        Get-ConvergenceEntityByMetadataIdPath `
            -MetadataId '{33333333-3333-3333-3333-333333333333}' |
            Should -Be "/EntityDefinitions(33333333-3333-3333-3333-333333333333)?`$select=MetadataId,LogicalName,SchemaName"

        Get-ConvergenceGlobalChoiceByMetadataIdPath `
            -MetadataId '{44444444-4444-4444-4444-444444444444}' | Should -Be (
                "/GlobalOptionSetDefinitions(44444444-4444-4444-4444-444444444444)/" +
                "Microsoft.Dynamics.CRM.OptionSetMetadata?`$select=MetadataId,Name,IsGlobal,OptionSetType"
            )

        Get-ConvergenceSavedQueryByIdPath `
            -SavedQueryId '{55555555-5555-5555-5555-555555555555}' | Should -Be (
                "/savedqueries(55555555-5555-5555-5555-555555555555)?" +
                "`$select=savedqueryid,name,description,returnedtypecode,fetchxml,layoutxml"
            )

        Get-ConvergenceSystemFormByIdPath `
            -FormId '{66666666-6666-6666-6666-666666666666}' | Should -Be (
                "/systemforms(66666666-6666-6666-6666-666666666666)?" +
                "`$select=formid,name,description,objecttypecode,type,formxml"
            )

        Get-ConvergenceRootInsuranceRolesPath -RolePrefix 'CRM Showcase Insurance ' |
            Should -Be (
                "/roles?`$select=roleid,name,_parentrootroleid_value&" +
                "`$filter=startswith(name,'CRM Showcase Insurance ')"
            )
    }

    It 'emits a Microsoft.Dynamics.CRM cast type for every typed attribute' {
        # Regression guard: '?' is a valid PowerShell variable-name character, so
        # an unbraced "$typeName?" swallows both the cast type and the '?', which
        # produced a malformed metadata URL and a Dataverse 500 in CD-DEV.
        $expectedTypes = @{
            Text     = 'StringAttributeMetadata'
            DateOnly = 'DateTimeAttributeMetadata'
            DateTime = 'DateTimeAttributeMetadata'
            Lookup   = 'LookupAttributeMetadata'
            Customer = 'LookupAttributeMetadata'
        }
        $expectedDerived = @{
            Text     = 'MaxLength'
            DateOnly = 'Format,DateTimeBehavior'
            DateTime = 'Format,DateTimeBehavior'
            Lookup   = 'Targets'
            Customer = 'Targets'
        }

        foreach ($type in $expectedTypes.Keys) {
            $column = [pscustomobject]@{ type = $type; logicalName = 'crmshow_probe' }
            Get-ConvergenceTypedAttributePath `
                -TableLogicalName 'crmshow_accountcontactrole' `
                -Column $column | Should -Be (
                    "/EntityDefinitions(LogicalName='crmshow_accountcontactrole')/Attributes/" +
                    "Microsoft.Dynamics.CRM.$($expectedTypes[$type])?" +
                    "`$select=MetadataId,LogicalName,SchemaName,AttributeType," +
                    "DisplayName,Description,RequiredLevel,IsAuditEnabled,$($expectedDerived[$type])&" +
                    "`$filter=LogicalName eq 'crmshow_probe'"
                )
        }
    }
}

Describe 'Convergence fixture paths' {
    It 'registers savedquery and systemform localized-label paths with @odata.id monikers' {
        $fixture = script:New-ReadyConvergenceResponseMap `
            -Contract $script:contract `
            -Manifest $script:manifest `
            -Scenario Ready

        $table = $script:contract.tables[0]
        $view = $table.views[0]
        $form = $table.forms[0]

        $viewId = [string]$fixture.IdMap["view:$($table.logicalName)/$($view.name)"]
        $formId = [string]$fixture.IdMap["form:$($table.logicalName)/$($form.name)"]
        $expectedViewEntityMoniker = [System.Uri]::EscapeDataString(
            '{"@odata.id":"savedqueries(' + $viewId + ')"}'
        )
        $expectedFormEntityMoniker = [System.Uri]::EscapeDataString(
            '{"@odata.id":"systemforms(' + $formId + ')"}'
        )
        $expectedViewPath = (
            '/RetrieveLocLabels(EntityMoniker=@p1,AttributeName=@p2,IncludeUnpublished=@p3)?' +
            "@p1=$expectedViewEntityMoniker&" +
            "@p2='name'&" +
            '@p3=true'
        )
        $expectedFormPath = (
            '/RetrieveLocLabels(EntityMoniker=@p1,AttributeName=@p2,IncludeUnpublished=@p3)?' +
            "@p1=$expectedFormEntityMoniker&" +
            "@p2='name'&" +
            '@p3=true'
        )

        $fixture.Responses.ContainsKey($expectedViewPath) | Should -BeTrue
        $fixture.Responses.ContainsKey($expectedFormPath) | Should -BeTrue
    }
}

Describe 'Component-level convergence checks' {
    It 'classifies a missing language as Precondition' {
        script:Register-ConvergenceTransportMock -Responses @{
            (Get-ConvergenceLanguagesPath) = [pscustomobject]@{
                RetrieveProvisionedLanguages = @(1033, 1031, 1036)
            }
        }

        $result = Test-InsuranceFoundationLanguages `
            -EnvironmentUrl 'https://unit.crm.dynamics.com' `
            -Contract $script:contract

        $result.State | Should -Be 'Precondition'
        @($result.Missing) | Should -Be @('1040')
    }

    It 'classifies a missing solution as Precondition' {
        script:Register-ConvergenceTransportMock -Responses @{
            (Get-ConvergenceSolutionsPath -SolutionUniqueName @($script:contract.solutions)) =
                [pscustomobject]@{
                    value = @([pscustomobject]@{
                            solutionid = script:New-FakeGuid -Index 1
                            uniquename = 'crmshow_Foundation'
                            publisherid = [pscustomobject]@{
                                uniquename                    = [string]$script:manifest.publisher.uniqueName
                                customizationprefix           = [string]$script:manifest.publisher.prefix
                                customizationoptionvalueprefix = [int]$script:manifest.publisher.customizationOptionValuePrefix
                            }
                        })
                }
        }

        $result = Test-InsuranceFoundationSolutions `
            -EnvironmentUrl 'https://unit.crm.dynamics.com' `
            -Contract $script:contract `
            -Manifest $script:manifest

        $result.State | Should -Be 'Precondition'
        @($result.Missing) | Should -Be @('crmshow_DataModel')
    }

    It 'classifies a choice option mismatch as ContractConflict' {
        $choice = script:Clone-Object -InputObject $script:contract.choices[0]
        $choiceSnapshot = script:New-ChoiceSnapshot `
            -Choice $choice `
            -MetadataId (script:New-FakeGuid -Index 2)
        $choiceSnapshot.Options[0].Label = ConvertTo-LocalizedLabel ([pscustomobject]@{
                '1033' = 'Wrong'
                '1031' = 'Falsch'
                '1036' = 'Faux'
                '1040' = 'Errato'
            })

        script:Register-ConvergenceTransportMock -Responses @{
            (Get-ConvergenceGlobalChoicePath -ChoiceLogicalName $choice.logicalName) = $choiceSnapshot
            (Get-ConvergenceSolutionMembershipPath -ComponentId $choiceSnapshot.MetadataId) =
                script:New-SolutionMembershipResponse -SolutionUniqueName ([string]$choice.solution)
        }

        $result = Test-InsuranceFoundationChoice `
            -EnvironmentUrl 'https://unit.crm.dynamics.com' `
            -Choice $choice

        $result.State | Should -Be 'ContractConflict'
        @($result.Differences | Where-Object {
                $_.Property -eq 'Label' -and $_.Code -eq 'Household'
            }).Count | Should -Be 4
    }

    It 'classifies a column mismatch as ContractConflict' {
        $table = script:Clone-Object -InputObject $script:contract.tables[0]
        $snapshot = [pscustomobject]@{
            Attributes = @(
                script:New-TypedAttributeSnapshot `
                    -Column $table.columns[0] `
                    -MetadataId (script:New-FakeGuid -Index 3)
            )
        }
        $snapshot.Attributes[0].RequiredLevel = @{ Value = 'None' }

        $result = Test-InsuranceFoundationTableColumn `
            -Table $table `
            -Column $table.columns[0] `
            -Snapshot $snapshot

        $result.State | Should -Be 'ContractConflict'
        @($result.Differences | Where-Object {
                $_.Property -eq 'RequiredLevel'
            }).Count | Should -Be 1
    }

    It 'classifies a relationship cascade mismatch as ContractConflict' {
        $table = script:Clone-Object -InputObject $script:contract.tables[1]
        $relationship = @($table.relationships | Where-Object {
                $_.authoring -ne 'CreateCustomerRelationships'
            })[0]
        $snapshot = [pscustomobject]@{
            Attributes = @(
                script:New-TypedAttributeSnapshot `
                    -Column (@($table.columns | Where-Object {
                            $_.logicalName -eq $relationship.lookupColumn
                        })[0]) `
                    -MetadataId (script:New-FakeGuid -Index 4)
            )
            ManyToOneRelationships = @([pscustomobject]@{
                    SchemaName          = [string]$relationship.schemaName
                    ReferencedEntity    = [string]$relationship.referencedTables[0]
                    ReferencingEntity   = [string]$table.logicalName
                    ReferencingAttribute = [string]$relationship.lookupColumn
                    CascadeConfiguration = [pscustomobject]@{
                        Assign   = 'NoCascade'
                        Delete   = 'Cascade'
                        Merge    = 'Cascade'
                        Reparent = 'NoCascade'
                        Share    = 'NoCascade'
                        Unshare  = 'NoCascade'
                    }
                })
        }

        $result = Test-InsuranceFoundationOrdinaryRelationship `
            -Table $table `
            -Relationship $relationship `
            -Snapshot $snapshot

        $result.State | Should -Be 'ContractConflict'
        @($result.Details) -join ' ' | Should -Match 'cascade conflict'
    }

    It 'classifies a key mismatch as ContractConflict' {
        $table = script:Clone-Object -InputObject $script:contract.tables[0]
        $key = $table.alternateKeys[0]

        script:Register-ConvergenceTransportMock -Responses @{
            (Get-ConvergenceKeyPath -TableLogicalName $table.logicalName -SchemaName $key.schemaName) =
                [pscustomobject]@{
                    value = @([pscustomobject]@{
                            MetadataId   = script:New-FakeGuid -Index 5
                            SchemaName   = [string]$key.schemaName
                            KeyAttributes = @('crmshow_accountid')
                        })
                }
        }

        $result = Test-InsuranceFoundationAlternateKey `
            -EnvironmentUrl 'https://unit.crm.dynamics.com' `
            -Table $table `
            -Key $key

        $result.State | Should -Be 'ContractConflict'
        @($result.Differences | Where-Object {
                $_.Property -eq 'KeyAttributes'
            }).Count | Should -Be 1
    }

    It 'accepts server-normalized view XML with exact four-language localized labels' {
        $table = script:Clone-Object -InputObject $script:contract.tables[0]
        $view = $table.views[0]
        $request = New-ViewRequest -Table $table -View $view -ObjectTypeCode 10427
        $storedFetchXml = $request.Body.fetchxml.Replace(
            '<fetch ',
            '<fetch savedqueryid="fd79983c-bf93-f111-8075-000d3a30c0f4" '
        )
        $savedQuery = script:New-SavedQuerySnapshot `
            -Request $request `
            -Table $table `
            -SavedQueryId (script:New-FakeGuid -Index 6)
        $savedQuery.fetchxml = $storedFetchXml

        $responses = @{
            (Get-ConvergenceSavedQueryPath `
                -TableLogicalName $table.logicalName `
                -Label ([string]$view.metadata.label.'1033')) = [pscustomobject]@{
                value = @($savedQuery)
            }
            (Get-ConvergenceSolutionMembershipPath -ComponentId $savedQuery.savedqueryid) =
                script:New-SolutionMembershipResponse -SolutionUniqueName ([string]$table.solution)
        }
        script:Add-LocalizedFieldResponses `
            -Responses $responses `
            -EntityLogicalName 'savedquery' `
            -IdProperty 'savedqueryid' `
            -RecordId $savedQuery.savedqueryid `
            -LocalizedFields $request.LocalizedFields
        script:Register-ConvergenceTransportMock -Responses $responses

        $result = Test-InsuranceFoundationView `
            -EnvironmentUrl 'https://unit.crm.dynamics.com' `
            -Table $table `
            -View $view `
            -ObjectTypeCode 10427

        $result.State | Should -Be 'Ready'
        Should -Invoke Invoke-ConvergenceDataverseRequest -Times 2 -Exactly -ParameterFilter {
            $Method -eq 'GET' -and $Path -like '/RetrieveLocLabels*'
        }
    }

    It 'classifies a view localized-field conflict when translations are missing or wrong' {
        $table = script:Clone-Object -InputObject $script:contract.tables[0]
        $view = $table.views[0]
        $request = New-ViewRequest -Table $table -View $view -ObjectTypeCode 10427
        $savedQuery = script:New-SavedQuerySnapshot `
            -Request $request `
            -Table $table `
            -SavedQueryId (script:New-FakeGuid -Index 16)

        $nameResponse = script:New-LocalizedRecordResponse -Text $request.LocalizedFields.name
        $nameResponse.Label.LocalizedLabels = @($nameResponse.Label.LocalizedLabels | Where-Object {
                [int]$_.LanguageCode -ne 1040
            })
        $descriptionResponse = script:New-LocalizedRecordResponse -Text $request.LocalizedFields.description
        @($descriptionResponse.Label.LocalizedLabels | Where-Object {
                [int]$_.LanguageCode -eq 1031
            })[0].Label = 'Wrong localized description'

        script:Register-ConvergenceTransportMock -Responses @{
            (Get-ConvergenceSavedQueryPath `
                -TableLogicalName $table.logicalName `
                -Label ([string]$view.metadata.label.'1033')) = [pscustomobject]@{
                value = @($savedQuery)
            }
            (Get-ConvergenceSolutionMembershipPath -ComponentId $savedQuery.savedqueryid) =
                script:New-SolutionMembershipResponse -SolutionUniqueName ([string]$table.solution)
            (Get-ConvergenceRetrieveLocLabelsPath `
                -EntityLogicalName 'savedquery' `
                -IdProperty 'savedqueryid' `
                -RecordId $savedQuery.savedqueryid `
                -AttributeName 'name') = $nameResponse
            (Get-ConvergenceRetrieveLocLabelsPath `
                -EntityLogicalName 'savedquery' `
                -IdProperty 'savedqueryid' `
                -RecordId $savedQuery.savedqueryid `
                -AttributeName 'description') = $descriptionResponse
        }

        $result = Test-InsuranceFoundationView `
            -EnvironmentUrl 'https://unit.crm.dynamics.com' `
            -Table $table `
            -View $view `
            -ObjectTypeCode 10427

        $result.State | Should -Be 'ContractConflict'
        @($result.Differences | Where-Object {
                $_.Property -eq 'name' -and
                $_.Language -eq '1040' -and
                $null -eq $_.Actual
            }).Count | Should -Be 1
        @($result.Differences | Where-Object {
                $_.Property -eq 'description' -and
                $_.Language -eq '1031' -and
                $_.Actual -eq 'Wrong localized description'
            }).Count | Should -Be 1
    }

    It 'rethrows ordinary RetrieveLocLabels bad requests for views' {
        $table = script:Clone-Object -InputObject $script:contract.tables[0]
        $view = $table.views[0]
        $request = New-ViewRequest -Table $table -View $view -ObjectTypeCode 10427
        $savedQuery = script:New-SavedQuerySnapshot `
            -Request $request `
            -Table $table `
            -SavedQueryId (script:New-FakeGuid -Index 18)
        $savedQueryPath = Get-ConvergenceSavedQueryPath `
            -TableLogicalName $table.logicalName `
            -Label ([string]$view.metadata.label.'1033')
        $solutionMembershipPath = Get-ConvergenceSolutionMembershipPath `
            -ComponentId $savedQuery.savedqueryid
        $solutionMembership = script:New-SolutionMembershipResponse `
            -SolutionUniqueName ([string]$table.solution)

        Mock Invoke-ConvergenceDataverseRequest {
            param($Method, $EnvironmentUrl, $Path, $Headers)

            if ($Method -cne 'GET') {
                throw "Unexpected mocked method: $Method"
            }
            if ($Path -eq $savedQueryPath) {
                return [pscustomobject]@{
                    value = @($savedQuery)
                }
            }
            if ($Path -eq $solutionMembershipPath) {
                return $solutionMembership
            }
            if ($Path -like '/RetrieveLocLabels*') {
                throw "Dataverse convergence transport failed (GET $Path); az rest exited with code 1. 400 Bad Request. Request message has unresolved parameters."
            }

            throw "Unexpected mocked path: $Path"
        }

        {
            Test-InsuranceFoundationView `
                -EnvironmentUrl 'https://unit.crm.dynamics.com' `
                -Table $table `
                -View $view `
                -ObjectTypeCode 10427
        } | Should -Throw '*400 Bad Request*'
    }

    It 'accepts platform-normalized form ids with exact four-language localized labels' {
        $table = script:Clone-Object -InputObject $script:contract.tables[0]
        $form = $table.forms[0]
        $request = New-FormRequest -Table $table -Form $form
        $systemForm = [pscustomobject]@{
            formid         = script:New-FakeGuid -Index 7
            name           = [string]$request.Body.name
            description    = [string]$request.Body.description
            objecttypecode = [string]$table.logicalName
            type           = 2
            formxml        = ([string]$request.Body.formxml).
                Replace(
                    '<tab name="general">',
                    '<tab name="general" id="{11111111-1111-1111-1111-111111111111}">'
                ).
                Replace(
                    '<section name="general">',
                    '<section name="general" id="{22222222-2222-2222-2222-222222222222}">'
                )
        }

        $responses = @{
            (Get-ConvergenceSystemFormPath `
                -TableLogicalName $table.logicalName `
                -Label ([string]$form.metadata.label.'1033')) = [pscustomobject]@{
                value = @($systemForm)
            }
            (Get-ConvergenceSolutionMembershipPath -ComponentId $systemForm.formid) =
                script:New-SolutionMembershipResponse -SolutionUniqueName ([string]$table.solution)
        }
        script:Add-LocalizedFieldResponses `
            -Responses $responses `
            -EntityLogicalName 'systemform' `
            -IdProperty 'formid' `
            -RecordId $systemForm.formid `
            -LocalizedFields $request.LocalizedFields
        script:Register-ConvergenceTransportMock -Responses $responses

        $result = Test-InsuranceFoundationForm `
            -EnvironmentUrl 'https://unit.crm.dynamics.com' `
            -Table $table `
            -Form $form

        $result.State | Should -Be 'Ready'
        Should -Invoke Invoke-ConvergenceDataverseRequest -Times 2 -Exactly -ParameterFilter {
            $Method -eq 'GET' -and $Path -like '/RetrieveLocLabels*'
        }
    }

    It 'classifies a form localized-field conflict when translations are missing or wrong' {
        $table = script:Clone-Object -InputObject $script:contract.tables[0]
        $form = $table.forms[0]
        $request = New-FormRequest -Table $table -Form $form
        $systemForm = script:New-FormSnapshot `
            -Request $request `
            -Table $table `
            -FormId (script:New-FakeGuid -Index 17)

        $nameResponse = script:New-LocalizedRecordResponse -Text $request.LocalizedFields.name
        @($nameResponse.Label.LocalizedLabels | Where-Object {
                [int]$_.LanguageCode -eq 1036
            })[0].Label = 'Wrong localized form name'
        $descriptionResponse = script:New-LocalizedRecordResponse -Text $request.LocalizedFields.description
        $descriptionResponse.Label.LocalizedLabels = @(
            $descriptionResponse.Label.LocalizedLabels | Where-Object {
                [int]$_.LanguageCode -ne 1040
            }
        )

        script:Register-ConvergenceTransportMock -Responses @{
            (Get-ConvergenceSystemFormPath `
                -TableLogicalName $table.logicalName `
                -Label ([string]$form.metadata.label.'1033')) = [pscustomobject]@{
                value = @($systemForm)
            }
            (Get-ConvergenceSolutionMembershipPath -ComponentId $systemForm.formid) =
                script:New-SolutionMembershipResponse -SolutionUniqueName ([string]$table.solution)
            (Get-ConvergenceRetrieveLocLabelsPath `
                -EntityLogicalName 'systemform' `
                -IdProperty 'formid' `
                -RecordId $systemForm.formid `
                -AttributeName 'name') = $nameResponse
            (Get-ConvergenceRetrieveLocLabelsPath `
                -EntityLogicalName 'systemform' `
                -IdProperty 'formid' `
                -RecordId $systemForm.formid `
                -AttributeName 'description') = $descriptionResponse
        }

        $result = Test-InsuranceFoundationForm `
            -EnvironmentUrl 'https://unit.crm.dynamics.com' `
            -Table $table `
            -Form $form

        $result.State | Should -Be 'ContractConflict'
        @($result.Differences | Where-Object {
                $_.Property -eq 'name' -and
                $_.Language -eq '1036' -and
                $_.Actual -eq 'Wrong localized form name'
            }).Count | Should -Be 1
        @($result.Differences | Where-Object {
                $_.Property -eq 'description' -and
                $_.Language -eq '1040' -and
                $null -eq $_.Actual
            }).Count | Should -Be 1
    }

    It 'does not classify a view owned by a different solution as a contract conflict (issue #92)' {
        $table = script:Clone-Object -InputObject $script:contract.tables[0]
        $view = $table.views[0]
        $request = New-ViewRequest -Table $table -View $view -ObjectTypeCode 10427
        $savedQuery = script:New-SavedQuerySnapshot `
            -Request $request `
            -Table $table `
            -SavedQueryId (script:New-FakeGuid -Index 26)

        $responses = @{
            (Get-ConvergenceSavedQueryPath `
                -TableLogicalName $table.logicalName `
                -Label ([string]$view.metadata.label.'1033')) = [pscustomobject]@{
                value = @($savedQuery)
            }
            (Get-ConvergenceSolutionMembershipPath -ComponentId $savedQuery.savedqueryid) =
                script:New-SolutionMembershipResponse -SolutionUniqueName 'Active'
        }
        script:Add-LocalizedFieldResponses `
            -Responses $responses `
            -EntityLogicalName 'savedquery' `
            -IdProperty 'savedqueryid' `
            -RecordId $savedQuery.savedqueryid `
            -LocalizedFields $request.LocalizedFields
        script:Register-ConvergenceTransportMock -Responses $responses

        $result = Test-InsuranceFoundationView `
            -EnvironmentUrl 'https://unit.crm.dynamics.com' `
            -Table $table `
            -View $view `
            -ObjectTypeCode 10427

        $result.State | Should -Be 'Ready'
    }

    It 'does not classify a form owned by a different solution as a contract conflict (issue #92)' {
        $table = script:Clone-Object -InputObject $script:contract.tables[0]
        $form = $table.forms[0]
        $request = New-FormRequest -Table $table -Form $form
        $systemForm = script:New-FormSnapshot `
            -Request $request `
            -Table $table `
            -FormId (script:New-FakeGuid -Index 27)

        $responses = @{
            (Get-ConvergenceSystemFormPath `
                -TableLogicalName $table.logicalName `
                -Label ([string]$form.metadata.label.'1033')) = [pscustomobject]@{
                value = @($systemForm)
            }
            (Get-ConvergenceSolutionMembershipPath -ComponentId $systemForm.formid) =
                script:New-SolutionMembershipResponse -SolutionUniqueName 'Active'
        }
        script:Add-LocalizedFieldResponses `
            -Responses $responses `
            -EntityLogicalName 'systemform' `
            -IdProperty 'formid' `
            -RecordId $systemForm.formid `
            -LocalizedFields $request.LocalizedFields
        script:Register-ConvergenceTransportMock -Responses $responses

        $result = Test-InsuranceFoundationForm `
            -EnvironmentUrl 'https://unit.crm.dynamics.com' `
            -Table $table `
            -Form $form

        $result.State | Should -Be 'Ready'
    }

    It 'classifies a role prerequisite through the reused role verifier result' {
        Mock Invoke-InsuranceSecurityRoleVerification {
            [pscustomobject]@{
                State            = 'ManualPrerequisite'
                MutationOccurred = $false
                Results          = @(
                    [pscustomobject]@{
                        Role             = 'CRM Showcase Insurance Reader'
                        State            = 'Ready'
                        Missing          = @()
                        Unexpected       = @()
                        WrongDepth       = @()
                        DuplicateExpected = @()
                        DuplicateActual  = @()
                        Details          = @()
                    },
                    [pscustomobject]@{
                        Role             = 'CRM Showcase Insurance Data Steward'
                        State            = 'ManualPrerequisite'
                        Missing          = @()
                        Unexpected       = @()
                        WrongDepth       = @()
                        DuplicateExpected = @()
                        DuplicateActual  = @()
                        Details          = @('Root security role missing.')
                    }
                )
            }
        }

        $result = Test-InsuranceFoundationRoles `
            -EnvironmentUrl 'https://unit.crm.dynamics.com' `
            -Contract $script:contract

        $result.State | Should -Be 'ManualPrerequisite'
        @($result.Children | Where-Object {
                $_.State -eq 'ManualPrerequisite'
            }).Count | Should -Be 1
    }
}

Describe 'Table classification propagation' {
    It 'lets ContractConflict dominate blocking child classifications when direct checks are exact' {
        $fixture = script:New-ReadyConvergenceResponseMap `
            -Contract $script:contract `
            -Manifest $script:manifest `
            -Scenario Ready
        $table = script:Clone-Object -InputObject $script:contract.tables[0]
        $tableSnapshot = @(
            $fixture.Responses[(Get-ConvergenceTableMetadataPath `
                    -LogicalName $table.logicalName `
                    -RequestedAttributeLogicalNames @($table.columns.logicalName))].value
        )[0]

        Mock Get-TableMetadataSnapshot { $tableSnapshot }
        Mock Assert-ConvergenceSolutionOwnership {}
        Mock Test-LocalizedMetadataChanged { $false }
        Mock Test-InsuranceFoundationTableColumn {
            param($Table, $Column, $Snapshot)

            New-ConvergenceResult `
                -Component "$($Table.logicalName)/column/$($Column.logicalName)" `
                -State 'Ready'
        }
        Mock Test-InsuranceFoundationOrdinaryRelationship {
            param($Table, $Relationship, $Snapshot)

            $state = if ([string]$Relationship.schemaName -eq
                [string]$table.relationships[1].schemaName) {
                'UnsupportedInTenant'
            }
            else {
                'Ready'
            }

            New-ConvergenceResult `
                -Component "$($Table.logicalName)/relationship/$($Relationship.schemaName)" `
                -State $state `
                -Details @(
                    if ($state -eq 'UnsupportedInTenant') {
                        'Synthetic unsupported relationship child.'
                    }
                )
        }
        Mock Test-InsuranceFoundationCustomerRelationship {
            param($Table, $Column, $Snapshot)

            New-ConvergenceResult `
                -Component "$($Table.logicalName)/relationship/$($Column.logicalName)" `
                -State 'Ready'
        }
        Mock Test-InsuranceFoundationAlternateKey {
            param($EnvironmentUrl, $Table, $Key)

            New-ConvergenceResult `
                -Component "$($Table.logicalName)/key/$($Key.schemaName)" `
                -State 'ContractConflict' `
                -Details @('Synthetic later key conflict.')
        }
        Mock Test-InsuranceFoundationView {
            param($EnvironmentUrl, $Table, $View, $ObjectTypeCode)

            New-ConvergenceResult `
                -Component "$($Table.logicalName)/view/$($View.name)" `
                -State 'Ready'
        }
        Mock Test-InsuranceFoundationForm {
            param($EnvironmentUrl, $Table, $Form)

            New-ConvergenceResult `
                -Component "$($Table.logicalName)/form/$($Form.name)" `
                -State 'Ready'
        }

        $result = Test-InsuranceFoundationTable `
            -EnvironmentUrl 'https://unit.crm.dynamics.com' `
            -Table $table

        $result.State | Should -Be 'ContractConflict'
        @($result.Children | Where-Object {
                $_.State -ne 'Ready'
            } | ForEach-Object {
                [string]$_.Component
            }) | Should -Be @(
                "$($table.logicalName)/relationship/$([string]$table.relationships[1].schemaName)",
                "$($table.logicalName)/key/$([string]$table.alternateKeys[0].schemaName)"
            )
    }
}

Describe 'Unexpected metadata reverse inventory' {
    It 'classifies an unexpected Foundation global choice as ContractConflict' {
        $fixture = script:New-ReadyConvergenceResponseMap `
            -Contract $script:contract `
            -Manifest $script:manifest `
            -Scenario Ready
        $choiceId = script:New-FakeGuid -Index 9701
        $inventoryPath = Get-ConvergenceSolutionInventoryPath `
            -SolutionId $fixture.SolutionIds['crmshow_Foundation'] `
            -ComponentType (Get-ConvergenceReverseInventoryComponentTypes)
        $fixture.Responses[$inventoryPath].value = @(
            $fixture.Responses[$inventoryPath].value +
            [pscustomobject]@{
                objectid      = $choiceId
                componenttype = 9
            }
        )
        $fixture.Responses[(Get-ConvergenceGlobalChoiceByMetadataIdPath -MetadataId $choiceId)] =
            [pscustomobject]@{
                MetadataId   = $choiceId
                Name         = 'crmshow_unexpectedchoice'
                IsGlobal     = $true
                OptionSetType = 'Picklist'
            }
        script:Register-ConvergenceTransportMock -Responses $fixture.Responses

        $result = Test-InsuranceFoundationUnexpectedMetadata `
            -EnvironmentUrl 'https://unit.crm.dynamics.com' `
            -Contract $script:contract `
            -Manifest $script:manifest

        $result.State | Should -Be 'ContractConflict'
        @($result.Unexpected) | Should -Contain 'crmshow_Foundation/choice/crmshow_unexpectedchoice'
    }

    It 'classifies an unexpected DataModel table as ContractConflict' {
        $fixture = script:New-ReadyConvergenceResponseMap `
            -Contract $script:contract `
            -Manifest $script:manifest `
            -Scenario Ready
        $tableId = script:New-FakeGuid -Index 9702
        $inventoryPath = Get-ConvergenceSolutionInventoryPath `
            -SolutionId $fixture.SolutionIds['crmshow_DataModel'] `
            -ComponentType (Get-ConvergenceReverseInventoryComponentTypes)
        $fixture.Responses[$inventoryPath].value = @(
            $fixture.Responses[$inventoryPath].value +
            [pscustomobject]@{
                objectid      = $tableId
                componenttype = 1
            }
        )
        $fixture.Responses[(Get-ConvergenceEntityByMetadataIdPath -MetadataId $tableId)] =
            (script:New-EntityInventorySnapshot `
                -MetadataId $tableId `
                -LogicalName 'crmshow_unexpectedtable' `
                -SchemaName 'crmshow_UnexpectedTable')
        script:Register-ConvergenceTransportMock -Responses $fixture.Responses

        $result = Test-InsuranceFoundationUnexpectedMetadata `
            -EnvironmentUrl 'https://unit.crm.dynamics.com' `
            -Contract $script:contract `
            -Manifest $script:manifest

        $result.State | Should -Be 'ContractConflict'
        @($result.Unexpected) | Should -Contain 'crmshow_DataModel/table/crmshow_unexpectedtable'
    }

    It 'resolves ManyToOneRelationships direct navigation to the unexpected-children fixture, not an ambiguous metadata-query fixture sharing the same entity prefix (#96)' {
        # Get-ConvergenceTableMetadataPath and Get-ConvergenceTableUnexpectedChildrenPath
        # both register a fixture key starting with "/EntityDefinitions(LogicalName='X')?"
        # for every contract table (see New-ReadyConvergenceResponseMap above). Only the
        # unexpected-children key is authoritative for ManyToOneRelationships direct
        # navigation. Diverge the two fixtures' relationships to prove resolution always
        # picks the correct one, regardless of Hashtable key enumeration order.
        $fixture = script:New-ReadyConvergenceResponseMap `
            -Contract $script:contract `
            -Manifest $script:manifest `
            -Scenario Ready
        $table = $script:contract.tables[2]
        $metadataPath = Get-ConvergenceTableMetadataPath `
            -LogicalName $table.logicalName `
            -RequestedAttributeLogicalNames @($table.columns.logicalName)
        $childrenPath = Get-ConvergenceTableUnexpectedChildrenPath `
            -LogicalName $table.logicalName `
            -PublisherPrefix (Get-ConvergencePublisherLogicalPrefix -Manifest $script:manifest)

        # Decoy: inject a relationship visible only via the non-authoritative
        # metadata-query fixture. A buggy (order-dependent) resolver could surface it.
        $fixture.Responses[$metadataPath].value[0].ManyToOneRelationships = @(
            $fixture.Responses[$metadataPath].value[0].ManyToOneRelationships +
            [pscustomobject]@{
                SchemaName           = 'crmshow_DecoyFromMetadataFixture'
                ReferencedEntity     = 'account'
                ReferencingEntity    = [string]$table.logicalName
                ReferencingAttribute = 'crmshow_decoyfrommetadatafixtureid'
            }
        )
        script:Register-ConvergenceTransportMock -Responses $fixture.Responses

        $result = Invoke-ConvergenceDataverseRequest -Method GET `
            -EnvironmentUrl 'https://unit.crm.dynamics.com' `
            -Path (Get-ConvergenceTableRelationshipsPath -LogicalName $table.logicalName)

        @($result.value.SchemaName) | Should -Not -Contain 'crmshow_DecoyFromMetadataFixture'
        @($result.value.SchemaName) |
            Should -Be @($fixture.Responses[$childrenPath].ManyToOneRelationships.SchemaName)
    }

    It 'classifies an unexpected custom column as ContractConflict' {
        $fixture = script:New-ReadyConvergenceResponseMap `
            -Contract $script:contract `
            -Manifest $script:manifest `
            -Scenario Ready
        $table = $script:contract.tables[1]
        $path = Get-ConvergenceTableUnexpectedChildrenPath `
            -LogicalName $table.logicalName `
            -PublisherPrefix (Get-ConvergencePublisherLogicalPrefix -Manifest $script:manifest)
        $fixture.Responses[$path].Attributes = @(
            $fixture.Responses[$path].Attributes +
            [pscustomobject]@{
                LogicalName  = 'crmshow_unexpectedcolumn'
                SchemaName   = 'crmshow_UnexpectedColumn'
                AttributeType = 'String'
                AttributeOf  = $null
            }
        )
        script:Register-ConvergenceTransportMock -Responses $fixture.Responses

        $result = Test-InsuranceFoundationUnexpectedMetadata `
            -EnvironmentUrl 'https://unit.crm.dynamics.com' `
            -Contract $script:contract `
            -Manifest $script:manifest

        $result.State | Should -Be 'ContractConflict'
        @($result.Unexpected) | Should -Contain "$($table.logicalName)/column/crmshow_unexpectedcolumn"
    }

    It 'classifies an unexpected custom relationship as ContractConflict' {
        $fixture = script:New-ReadyConvergenceResponseMap `
            -Contract $script:contract `
            -Manifest $script:manifest `
            -Scenario Ready
        $table = $script:contract.tables[2]
        $path = Get-ConvergenceTableUnexpectedChildrenPath `
            -LogicalName $table.logicalName `
            -PublisherPrefix (Get-ConvergencePublisherLogicalPrefix -Manifest $script:manifest)
        $fixture.Responses[$path].ManyToOneRelationships = @(
            $fixture.Responses[$path].ManyToOneRelationships +
            [pscustomobject]@{
                SchemaName           = 'crmshow_UnexpectedRelationship'
                ReferencedEntity     = 'account'
                ReferencingEntity    = [string]$table.logicalName
                ReferencingAttribute = 'crmshow_unexpectedrelationshipid'
            }
        )
        script:Register-ConvergenceTransportMock -Responses $fixture.Responses

        $result = Test-InsuranceFoundationUnexpectedMetadata `
            -EnvironmentUrl 'https://unit.crm.dynamics.com' `
            -Contract $script:contract `
            -Manifest $script:manifest

        $result.State | Should -Be 'ContractConflict'
        @($result.Unexpected) | Should -Contain "$($table.logicalName)/relationship/crmshow_UnexpectedRelationship"
    }

    It 'classifies an unexpected custom alternate key as ContractConflict' {
        $fixture = script:New-ReadyConvergenceResponseMap `
            -Contract $script:contract `
            -Manifest $script:manifest `
            -Scenario Ready
        $table = $script:contract.tables[0]
        $path = Get-ConvergenceTableUnexpectedChildrenPath `
            -LogicalName $table.logicalName `
            -PublisherPrefix (Get-ConvergencePublisherLogicalPrefix -Manifest $script:manifest)
        $fixture.Responses[$path].Keys = @(
            $fixture.Responses[$path].Keys +
            [pscustomobject]@{
                SchemaName    = 'crmshow_UnexpectedKey'
                KeyAttributes = @('crmshow_name')
            }
        )
        script:Register-ConvergenceTransportMock -Responses $fixture.Responses

        $result = Test-InsuranceFoundationUnexpectedMetadata `
            -EnvironmentUrl 'https://unit.crm.dynamics.com' `
            -Contract $script:contract `
            -Manifest $script:manifest

        $result.State | Should -Be 'ContractConflict'
        @($result.Unexpected) | Should -Contain "$($table.logicalName)/key/crmshow_UnexpectedKey"
    }

    It 'classifies an unexpected solution-owned view as ContractConflict' {
        $fixture = script:New-ReadyConvergenceResponseMap `
            -Contract $script:contract `
            -Manifest $script:manifest `
            -Scenario Ready
        $viewId = script:New-FakeGuid -Index 9703
        $inventoryPath = Get-ConvergenceSolutionInventoryPath `
            -SolutionId $fixture.SolutionIds['crmshow_DataModel'] `
            -ComponentType (Get-ConvergenceReverseInventoryComponentTypes)
        $fixture.Responses[$inventoryPath].value = @(
            $fixture.Responses[$inventoryPath].value +
            (script:New-SolutionInventoryEntry `
                -ObjectId $viewId `
                -ComponentType 26)
        )
        $fixture.Responses[(Get-ConvergenceSavedQueryByIdPath -SavedQueryId $viewId)] =
            [pscustomobject]@{
                savedqueryid     = $viewId
                name             = 'Unexpected Policy Projection View'
                description      = 'Unexpected custom view.'
                returnedtypecode = 'crmshow_policyprojection'
                fetchxml         = '<fetch version="1.0"><entity name="crmshow_policyprojection"><attribute name="crmshow_name" /></entity></fetch>'
                layoutxml        = '<grid name="resultset" object="10428"><row name="crmshow_policyprojection" id="crmshow_policyprojectionid"><cell name="crmshow_name" width="150" /></row></grid>'
            }
        script:Register-ConvergenceTransportMock -Responses $fixture.Responses

        $result = Test-InsuranceFoundationUnexpectedMetadata `
            -EnvironmentUrl 'https://unit.crm.dynamics.com' `
            -Contract $script:contract `
            -Manifest $script:manifest

        $result.State | Should -Be 'ContractConflict'
        @($result.Unexpected) | Should -Contain 'crmshow_DataModel/view/crmshow_policyprojection/Unexpected Policy Projection View'
    }

    It 'classifies an unexpected solution-owned form as ContractConflict' {
        $fixture = script:New-ReadyConvergenceResponseMap `
            -Contract $script:contract `
            -Manifest $script:manifest `
            -Scenario Ready
        $formId = script:New-FakeGuid -Index 9704
        $inventoryPath = Get-ConvergenceSolutionInventoryPath `
            -SolutionId $fixture.SolutionIds['crmshow_DataModel'] `
            -ComponentType (Get-ConvergenceReverseInventoryComponentTypes)
        $fixture.Responses[$inventoryPath].value = @(
            $fixture.Responses[$inventoryPath].value +
            (script:New-SolutionInventoryEntry `
                -ObjectId $formId `
                -ComponentType 60)
        )
        $fixture.Responses[(Get-ConvergenceSystemFormByIdPath -FormId $formId)] =
            [pscustomobject]@{
                formid         = $formId
                name           = 'Unexpected Policy Projection Form'
                description    = 'Unexpected custom form.'
                objecttypecode = 'crmshow_policyprojection'
                type           = 2
                formxml        = '<form><tabs><tab name="general"><columns><column width="100%"><sections><section name="general"><rows><row><cell><control id="crmshow_name" classid="{4273EDBD-AC1D-40d3-9FB2-095C621B552D}" datafieldname="crmshow_name" /></cell></row></rows></section></sections></column></columns></tab></tabs></form>'
            }
        script:Register-ConvergenceTransportMock -Responses $fixture.Responses

        $result = Test-InsuranceFoundationUnexpectedMetadata `
            -EnvironmentUrl 'https://unit.crm.dynamics.com' `
            -Contract $script:contract `
            -Manifest $script:manifest

        $result.State | Should -Be 'ContractConflict'
        @($result.Unexpected) | Should -Contain 'crmshow_DataModel/form/crmshow_policyprojection/Unexpected Policy Projection Form'
    }

    It 'ignores transitive generated Information and default-active components included through the table root' {
        $fixture = script:New-ReadyConvergenceResponseMap `
            -Contract $script:contract `
            -Manifest $script:manifest `
            -Scenario Ready
        $table = @($script:contract.tables | Where-Object {
                [string]$_.logicalName -ceq 'crmshow_policyprojection'
            })[0]
        $inventoryPath = Get-ConvergenceSolutionInventoryPath `
            -SolutionId $fixture.SolutionIds['crmshow_DataModel'] `
            -ComponentType (Get-ConvergenceReverseInventoryComponentTypes)
        $tableRootEntry = @($fixture.Responses[$inventoryPath].value | Where-Object {
                [int]$_.componenttype -eq 1 -and
                [string]$_.objectid -ceq [string]$fixture.IdMap["table:$($table.logicalName)"]
            })[0]
        $tableRootSolutionComponentId = if ($null -eq $tableRootEntry.solutioncomponentid) {
            [string]$tableRootEntry.objectid
        }
        else {
            [string]$tableRootEntry.solutioncomponentid
        }
        $viewId = script:New-FakeGuid -Index 9709
        $formId = script:New-FakeGuid -Index 9710
        $fixture.Responses[$inventoryPath].value = @(
            $fixture.Responses[$inventoryPath].value +
            (script:New-SolutionInventoryEntry `
                -ObjectId $viewId `
                -ComponentType 26 `
                -RootSolutionComponentId $tableRootSolutionComponentId `
                -RootComponentBehavior 0) +
            (script:New-SolutionInventoryEntry `
                -ObjectId $formId `
                -ComponentType 60 `
                -RootSolutionComponentId $tableRootSolutionComponentId `
                -RootComponentBehavior 0)
        )
        $fixture.Responses[(Get-ConvergenceSavedQueryByIdPath -SavedQueryId $viewId)] =
            [pscustomobject]@{
                savedqueryid     = $viewId
                name             = 'Active Policy Projections'
                description      = 'Platform-generated default active view.'
                returnedtypecode = [string]$table.logicalName
                fetchxml         = '<fetch version="1.0"><entity name="crmshow_policyprojection"><attribute name="crmshow_name" /></entity></fetch>'
                layoutxml        = '<grid name="resultset" object="10428"><row name="crmshow_policyprojection" id="crmshow_policyprojectionid"><cell name="crmshow_name" width="150" /></row></grid>'
            }
        $fixture.Responses[(Get-ConvergenceSystemFormByIdPath -FormId $formId)] =
            [pscustomobject]@{
                formid         = $formId
                name           = 'Information'
                description    = 'Platform-generated default main form.'
                objecttypecode = [string]$table.logicalName
                type           = 2
                formxml        = '<form><tabs><tab name="general"><columns><column width="100%"><sections><section name="general"><rows><row><cell><control id="crmshow_name" classid="{4273EDBD-AC1D-40d3-9FB2-095C621B552D}" datafieldname="crmshow_name" /></cell></row></rows></section></sections></column></columns></tab></tabs></form>'
            }
        script:Register-ConvergenceTransportMock -Responses $fixture.Responses

        $result = Test-InsuranceFoundationUnexpectedMetadata `
            -EnvironmentUrl 'https://unit.crm.dynamics.com' `
            -Contract $script:contract `
            -Manifest $script:manifest

        $result.State | Should -Be 'Ready'
        @($result.Unexpected) | Should -Be @()
    }

    It 'still flags explicitly owned Information and default-active components' {
        $fixture = script:New-ReadyConvergenceResponseMap `
            -Contract $script:contract `
            -Manifest $script:manifest `
            -Scenario Ready
        $viewId = script:New-FakeGuid -Index 9711
        $formId = script:New-FakeGuid -Index 9712
        $inventoryPath = Get-ConvergenceSolutionInventoryPath `
            -SolutionId $fixture.SolutionIds['crmshow_DataModel'] `
            -ComponentType (Get-ConvergenceReverseInventoryComponentTypes)
        $fixture.Responses[$inventoryPath].value = @(
            $fixture.Responses[$inventoryPath].value +
            (script:New-SolutionInventoryEntry `
                -ObjectId $viewId `
                -ComponentType 26) +
            (script:New-SolutionInventoryEntry `
                -ObjectId $formId `
                -ComponentType 60)
        )
        $fixture.Responses[(Get-ConvergenceSavedQueryByIdPath -SavedQueryId $viewId)] =
            [pscustomobject]@{
                savedqueryid     = $viewId
                name             = 'Active Policy Projections'
                description      = 'Explicit extra custom view.'
                returnedtypecode = 'crmshow_policyprojection'
                fetchxml         = '<fetch version="1.0"><entity name="crmshow_policyprojection"><attribute name="crmshow_name" /></entity></fetch>'
                layoutxml        = '<grid name="resultset" object="10428"><row name="crmshow_policyprojection" id="crmshow_policyprojectionid"><cell name="crmshow_name" width="150" /></row></grid>'
            }
        $fixture.Responses[(Get-ConvergenceSystemFormByIdPath -FormId $formId)] =
            [pscustomobject]@{
                formid         = $formId
                name           = 'Information'
                description    = 'Explicit extra custom form.'
                objecttypecode = 'crmshow_policyprojection'
                type           = 2
                formxml        = '<form><tabs><tab name="general"><columns><column width="100%"><sections><section name="general"><rows><row><cell><control id="crmshow_name" classid="{4273EDBD-AC1D-40d3-9FB2-095C621B552D}" datafieldname="crmshow_name" /></cell></row></rows></section></sections></column></columns></tab></tabs></form>'
            }
        script:Register-ConvergenceTransportMock -Responses $fixture.Responses

        $result = Test-InsuranceFoundationUnexpectedMetadata `
            -EnvironmentUrl 'https://unit.crm.dynamics.com' `
            -Contract $script:contract `
            -Manifest $script:manifest

        $result.State | Should -Be 'ContractConflict'
        @($result.Unexpected) | Should -Contain 'crmshow_DataModel/view/crmshow_policyprojection/Active Policy Projections'
        @($result.Unexpected) | Should -Contain 'crmshow_DataModel/form/crmshow_policyprojection/Information'
    }

    It 'accepts a declared CRM Showcase Insurance Reader root role when reviewed membership matches exactly' {
        $fixture = script:New-ReadyConvergenceResponseMap `
            -Contract $script:contract `
            -Manifest $script:manifest `
            -Scenario Ready
        $readerRoleId = [string]$fixture.IdMap['role:CRM Showcase Insurance Reader']
        $fixture.Responses[(Get-ConvergenceSolutionMembershipPath -ComponentId $readerRoleId)] =
            script:New-SolutionMembershipResponse -SolutionUniqueName 'crmshow_Foundation'
        script:Register-ConvergenceTransportMock -Responses $fixture.Responses

        $result = Test-InsuranceFoundationUnexpectedMetadata `
            -EnvironmentUrl 'https://unit.crm.dynamics.com' `
            -Contract $script:contract `
            -Manifest $script:manifest

        $result.State | Should -Be 'Ready'
        @($result.Unexpected) | Should -Be @()
        @($result.Details | Where-Object {
                $_ -match 'CRM Showcase Insurance Reader'
            }) | Should -Be @()
    }

    It 'ignores declared CRM Showcase Insurance Reader memberships outside reviewed solutions' {
        $fixture = script:New-ReadyConvergenceResponseMap `
            -Contract $script:contract `
            -Manifest $script:manifest `
            -Scenario Ready
        $readerRoleId = [string]$fixture.IdMap['role:CRM Showcase Insurance Reader']
        $fixture.Responses[(Get-ConvergenceSolutionMembershipPath -ComponentId $readerRoleId)] =
            script:New-SolutionMembershipResponse -SolutionUniqueName @(
                'crmshow_Foundation',
                'crmshow_Unreviewed'
            )
        script:Register-ConvergenceTransportMock -Responses $fixture.Responses

        $result = Test-InsuranceFoundationUnexpectedMetadata `
            -EnvironmentUrl 'https://unit.crm.dynamics.com' `
            -Contract $script:contract `
            -Manifest $script:manifest

        $result.State | Should -Be 'Ready'
        @($result.Unexpected) | Should -Be @()
    }

    It 'classifies a declared CRM Showcase Insurance Reader root role in Foundation and DataModel as ContractConflict' {
        $fixture = script:New-ReadyConvergenceResponseMap `
            -Contract $script:contract `
            -Manifest $script:manifest `
            -Scenario Ready
        $readerRoleId = [string]$fixture.IdMap['role:CRM Showcase Insurance Reader']
        $fixture.Responses[(Get-ConvergenceSolutionMembershipPath -ComponentId $readerRoleId)] =
            script:New-SolutionMembershipResponse -SolutionUniqueName @(
                'crmshow_Foundation',
                'crmshow_DataModel'
            )
        script:Register-ConvergenceTransportMock -Responses $fixture.Responses

        $result = Test-InsuranceFoundationUnexpectedMetadata `
            -EnvironmentUrl 'https://unit.crm.dynamics.com' `
            -Contract $script:contract `
            -Manifest $script:manifest

        $result.State | Should -Be 'ContractConflict'
        @($result.Unexpected) | Should -Contain 'crmshow_DataModel/role/CRM Showcase Insurance Reader'
        @($result.Details) -join ' ' | Should -Match 'unexpected reviewed solution membership ''crmshow_DataModel'''
    }

    It 'classifies a declared CRM Showcase Insurance Reader root role only in DataModel as ContractConflict' {
        $fixture = script:New-ReadyConvergenceResponseMap `
            -Contract $script:contract `
            -Manifest $script:manifest `
            -Scenario Ready
        $readerRoleId = [string]$fixture.IdMap['role:CRM Showcase Insurance Reader']
        $fixture.Responses[(Get-ConvergenceSolutionMembershipPath -ComponentId $readerRoleId)] =
            script:New-SolutionMembershipResponse -SolutionUniqueName 'crmshow_DataModel'
        script:Register-ConvergenceTransportMock -Responses $fixture.Responses

        $result = Test-InsuranceFoundationUnexpectedMetadata `
            -EnvironmentUrl 'https://unit.crm.dynamics.com' `
            -Contract $script:contract `
            -Manifest $script:manifest

        $result.State | Should -Be 'ContractConflict'
        @($result.Unexpected) | Should -Contain 'crmshow_DataModel/role/CRM Showcase Insurance Reader'
        @($result.Details) -join ' ' | Should -Match 'missing reviewed solution membership ''crmshow_Foundation'''
        @($result.Details) -join ' ' | Should -Match 'actual reviewed solution membership: crmshow_DataModel'
    }

    It 'classifies an additional CRM Showcase Insurance Foundation root role as ContractConflict' {
        $fixture = script:New-ReadyConvergenceResponseMap `
            -Contract $script:contract `
            -Manifest $script:manifest `
            -Scenario Ready
        $roleId = script:New-FakeGuid -Index 9705
        $rolesPath = Get-ConvergenceRootInsuranceRolesPath -RolePrefix 'CRM Showcase Insurance '
        $fixture.Responses[$rolesPath].value = @(
            $fixture.Responses[$rolesPath].value +
            [pscustomobject]@{
                roleid = $roleId
                name = 'CRM Showcase Insurance Escalation'
                _parentrootroleid_value = $null
            }
        )
        $fixture.Responses[(Get-ConvergenceRoleByIdPath -RoleId $roleId)] = [pscustomobject]@{
            roleid = $roleId
            name = 'CRM Showcase Insurance Escalation'
            _parentrootroleid_value = $null
        }
        $fixture.Responses[(Get-ConvergenceSolutionMembershipPath -ComponentId $roleId)] =
            script:New-SolutionMembershipResponse -SolutionUniqueName 'crmshow_Foundation'
        script:Register-ConvergenceTransportMock -Responses $fixture.Responses

        $result = Test-InsuranceFoundationUnexpectedMetadata `
            -EnvironmentUrl 'https://unit.crm.dynamics.com' `
            -Contract $script:contract `
            -Manifest $script:manifest

        $result.State | Should -Be 'ContractConflict'
        @($result.Unexpected) | Should -Contain 'crmshow_Foundation/role/CRM Showcase Insurance Escalation'
    }

    It 'classifies an additional CRM Showcase Insurance DataModel root role as ContractConflict' {
        $fixture = script:New-ReadyConvergenceResponseMap `
            -Contract $script:contract `
            -Manifest $script:manifest `
            -Scenario Ready
        $roleId = script:New-FakeGuid -Index 9713
        $rolesPath = Get-ConvergenceRootInsuranceRolesPath -RolePrefix 'CRM Showcase Insurance '
        $fixture.Responses[$rolesPath].value = @(
            $fixture.Responses[$rolesPath].value +
            [pscustomobject]@{
                roleid = $roleId
                name = 'CRM Showcase Insurance DataModel Reviewer'
                _parentrootroleid_value = $null
            }
        )
        $fixture.Responses[(Get-ConvergenceRoleByIdPath -RoleId $roleId)] = [pscustomobject]@{
            roleid = $roleId
            name = 'CRM Showcase Insurance DataModel Reviewer'
            _parentrootroleid_value = $null
        }
        $fixture.Responses[(Get-ConvergenceSolutionMembershipPath -ComponentId $roleId)] =
            script:New-SolutionMembershipResponse -SolutionUniqueName 'crmshow_DataModel'
        script:Register-ConvergenceTransportMock -Responses $fixture.Responses

        $result = Test-InsuranceFoundationUnexpectedMetadata `
            -EnvironmentUrl 'https://unit.crm.dynamics.com' `
            -Contract $script:contract `
            -Manifest $script:manifest

        $result.State | Should -Be 'ContractConflict'
        @($result.Unexpected) | Should -Contain 'crmshow_DataModel/role/CRM Showcase Insurance DataModel Reviewer'
    }

    It 'ignores inherited business-unit role copies that are not the root role' {
        $fixture = script:New-ReadyConvergenceResponseMap `
            -Contract $script:contract `
            -Manifest $script:manifest `
            -Scenario Ready
        $inheritedRoleId = script:New-FakeGuid -Index 9720
        $rootPointerId = script:New-FakeGuid -Index 9721
        $rolesPath = Get-ConvergenceRootInsuranceRolesPath -RolePrefix 'CRM Showcase Insurance '
        $fixture.Responses[$rolesPath].value = @(
            $fixture.Responses[$rolesPath].value +
            [pscustomobject]@{
                roleid = $inheritedRoleId
                name = 'CRM Showcase Insurance Reader'
                _parentrootroleid_value = $rootPointerId
            }
        )
        # No membership or by-id response is registered for the inherited copy:
        # it must be skipped before any further lookup.
        script:Register-ConvergenceTransportMock -Responses $fixture.Responses

        $result = Test-InsuranceFoundationUnexpectedMetadata `
            -EnvironmentUrl 'https://unit.crm.dynamics.com' `
            -Contract $script:contract `
            -Manifest $script:manifest

        $result.State | Should -Be 'Ready'
        @($result.Unexpected) | Should -Not -Contain 'crmshow_Foundation/role/CRM Showcase Insurance Reader'
    }

    It 'ignores system-generated table children and unrelated roles or views outside reviewed solutions' {
        $fixture = script:New-ReadyConvergenceResponseMap `
            -Contract $script:contract `
            -Manifest $script:manifest `
            -Scenario Ready
        $publisherPrefix = Get-ConvergencePublisherLogicalPrefix -Manifest $script:manifest
        $table = $script:contract.tables[2]
        $tablePath = Get-ConvergenceTableUnexpectedChildrenPath `
            -LogicalName $table.logicalName `
            -PublisherPrefix $publisherPrefix
        $fixture.Responses[$tablePath].Attributes = @(
            $fixture.Responses[$tablePath].Attributes +
            [pscustomobject]@{
                LogicalName  = "$($table.logicalName)id"
                SchemaName   = "$($table.schemaName)Id"
                AttributeType = 'Uniqueidentifier'
                AttributeOf  = $null
            } +
            [pscustomobject]@{
                LogicalName  = 'crmshow_partyidname'
                SchemaName   = 'crmshow_PartyIdName'
                AttributeType = 'String'
                AttributeOf  = 'crmshow_partyid'
            }
        )

        $rolesPath = Get-ConvergenceRootInsuranceRolesPath -RolePrefix 'CRM Showcase Insurance '
        $fixture.Responses[$rolesPath].value = @(
            $fixture.Responses[$rolesPath].value +
            [pscustomobject]@{
                roleid = script:New-FakeGuid -Index 9706
                name = 'System Administrator'
                _parentrootroleid_value = $null
            } +
            [pscustomobject]@{
                roleid = script:New-FakeGuid -Index 9714
                name = 'CRM Showcase Insurance Archive'
                _parentrootroleid_value = $null
            }
        )
        $fixture.Responses[(Get-ConvergenceSolutionMembershipPath -ComponentId (script:New-FakeGuid -Index 9714))] =
            script:New-SolutionMembershipResponse -SolutionUniqueName 'crmshow_Unreviewed'

        $viewId = script:New-FakeGuid -Index 9707
        $formId = script:New-FakeGuid -Index 9708
        $inventoryPath = Get-ConvergenceSolutionInventoryPath `
            -SolutionId $fixture.SolutionIds['crmshow_DataModel'] `
            -ComponentType (Get-ConvergenceReverseInventoryComponentTypes)
        $fixture.Responses[$inventoryPath].value = @(
            $fixture.Responses[$inventoryPath].value +
            (script:New-SolutionInventoryEntry `
                -ObjectId $viewId `
                -ComponentType 26) +
            (script:New-SolutionInventoryEntry `
                -ObjectId $formId `
                -ComponentType 60)
        )
        $fixture.Responses[(Get-ConvergenceSavedQueryByIdPath -SavedQueryId $viewId)] =
            [pscustomobject]@{
                savedqueryid     = $viewId
                name             = 'Open Opportunities'
                description      = 'Platform opportunity view.'
                returnedtypecode = 'opportunity'
                fetchxml         = '<fetch version="1.0"><entity name="opportunity"><attribute name="name" /></entity></fetch>'
                layoutxml        = '<grid name="resultset" object="3"><row name="opportunity" id="opportunityid"><cell name="name" width="150" /></row></grid>'
            }
        $fixture.Responses[(Get-ConvergenceSystemFormByIdPath -FormId $formId)] =
            [pscustomobject]@{
                formid         = $formId
                name           = 'Opportunity Main'
                description    = 'Platform opportunity form.'
                objecttypecode = 'opportunity'
                type           = 2
                formxml        = '<form><tabs><tab name="general"><columns><column width="100%"><sections><section name="general"><rows><row><cell><control id="name" classid="{4273EDBD-AC1D-40d3-9FB2-095C621B552D}" datafieldname="name" /></cell></row></rows></section></sections></column></columns></tab></tabs></form>'
            }
        script:Register-ConvergenceTransportMock -Responses $fixture.Responses

        $result = Test-InsuranceFoundationUnexpectedMetadata `
            -EnvironmentUrl 'https://unit.crm.dynamics.com' `
            -Contract $script:contract `
            -Manifest $script:manifest

        $result.State | Should -Be 'Ready'
        @($result.Unexpected) | Should -Be @()
    }
}

Describe 'Invoke-InsuranceFoundationConvergence' {
    BeforeEach {
        Mock Invoke-PlannedRequest {}
        Mock Invoke-ChoiceReconciliation {}
        Mock Invoke-TableReconciliation {}
        Mock Invoke-RoleReconciliation {}
    }

    It 'returns a representative exact Ready result with GET-only transport and no mutation' {
        $fixture = script:New-ReadyConvergenceResponseMap `
            -Contract $script:contract `
            -Manifest $script:manifest `
            -Scenario Ready
        script:Register-ConvergenceTransportMock -Responses $fixture.Responses

        $result = Invoke-InsuranceFoundationConvergence `
            -EnvironmentUrl 'https://unit.crm.dynamics.com' `
            -ContractPath $script:contractPath

        $result.State | Should -Be 'Ready'
        $result.MutationOccurred | Should -BeFalse
        @($result.BlockingComponents) | Should -Be @()
        @($result.Results.Component) | Should -Contain 'languages'
        @($result.Results.Component) | Should -Contain 'crmshow_accounttype'
        @($result.Results.Component) | Should -Contain 'account/crmshow_accounttype'
        @($result.Results.Component) | Should -Contain 'crmshow_policyprojection'
        @($result.Results.Component) | Should -Contain 'roles'
        @($result.Results.Component) | Should -Contain 'unexpectedMetadata'
        @($result.Results.Component) | Should -Be (
            @('languages', 'solutions') +
            @($script:contract.choices | ForEach-Object {
                    [string]$_.logicalName
                }) +
            @($script:contract.nativeExtensions | ForEach-Object {
                    "$($_.table)/$($_.logicalName)"
                }) +
            @($script:contract.tables | ForEach-Object {
                    [string]$_.logicalName
                }) +
            @('roles', 'unexpectedMetadata')
        )

        $policyProjection = @($result.Results | Where-Object {
                $_.Component -eq 'crmshow_policyprojection'
            })[0]
        @($policyProjection.Children.Component) | Should -Contain (
            'crmshow_policyprojection/view/crmshow_policyprojectionadminview'
        )
        @($policyProjection.Children.Component) | Should -Contain (
            'crmshow_policyprojection/form/crmshow_policyprojectionadminform'
        )

        Should -Invoke Invoke-ConvergenceDataverseRequest -Times 0 -Exactly -ParameterFilter {
            $Method -ne 'GET'
        }
        Should -Invoke Invoke-PlannedRequest -Times 0 -Exactly
        Should -Invoke Invoke-ChoiceReconciliation -Times 0 -Exactly
        Should -Invoke Invoke-TableReconciliation -Times 0 -Exactly
        Should -Invoke Invoke-RoleReconciliation -Times 0 -Exactly
    }

    It 'validates the contract before any online reads' {
        Mock Test-InsuranceFoundationContract {
            throw 'Synthetic contract failure.'
        }
        Mock Invoke-ConvergenceDataverseRequest {}

        $result = Invoke-InsuranceFoundationConvergence `
            -EnvironmentUrl 'https://unit.crm.dynamics.com' `
            -ContractPath $script:contractPath

        $result.State | Should -Be 'ContractConflict'
        @($result.Results.Component) | Should -Be @('contract')
        Should -Invoke Invoke-ConvergenceDataverseRequest -Times 0 -Exactly
    }

    It 'rethrows transport failures' {
        Mock Invoke-ConvergenceDataverseRequest {
            throw 'Dataverse convergence transport failed (GET /RetrieveProvisionedLanguages()); az rest exited with code 1.'
        }

        {
            Invoke-InsuranceFoundationConvergence `
                -EnvironmentUrl 'https://unit.crm.dynamics.com' `
                -ContractPath $script:contractPath
        } | Should -Throw '*transport failed*'
    }
}

Describe 'Convergence direct entry point' {
    It 'emits ready JSON and exits zero when convergence is Ready' {
        $invocation = script:Invoke-ConvergenceEntryScript -Scenario Ready

        $invocation.ExitCode | Should -Be 0
        { $invocation.Output | ConvertFrom-Json -ErrorAction Stop } |
            Should -Not -Throw

        $result = $invocation.Output | ConvertFrom-Json -ErrorAction Stop
        $result.State | Should -Be 'Ready'
        $result.MutationOccurred | Should -BeFalse
    }

    It 'emits classified precondition JSON and exits two when a required language is missing' {
        $invocation = script:Invoke-ConvergenceEntryScript -Scenario MissingLanguage

        $invocation.ExitCode | Should -Be 2
        { $invocation.Output | ConvertFrom-Json -ErrorAction Stop } |
            Should -Not -Throw

        $result = $invocation.Output | ConvertFrom-Json -ErrorAction Stop
        $result.State | Should -Be 'Precondition'
        @($result.Results | Where-Object {
                $_.Component -eq 'languages' -and $_.State -eq 'Precondition'
            }).Count | Should -Be 1
    }

    It 'emits classified contract-conflict JSON and exits three on exact role-name mismatch' {
        $invocation = script:Invoke-ConvergenceEntryScript -Scenario RoleNameCaseConflict

        $invocation.ExitCode | Should -Be 3
        { $invocation.Output | ConvertFrom-Json -ErrorAction Stop } |
            Should -Not -Throw

        $result = $invocation.Output | ConvertFrom-Json -ErrorAction Stop
        $result.State | Should -Be 'ContractConflict'
        @($result.Results | Where-Object {
                $_.Component -eq 'roles' -and $_.State -eq 'ContractConflict'
            }).Count | Should -Be 1
    }

    It 'emits contract-conflict JSON and exits three when drift coexists with a manual prerequisite' {
        $invocation = script:Invoke-ConvergenceEntryScript -Scenario MissingRoleAndUnexpectedView

        $invocation.ExitCode | Should -Be 3
        { $invocation.Output | ConvertFrom-Json -ErrorAction Stop } |
            Should -Not -Throw

        $result = $invocation.Output | ConvertFrom-Json -ErrorAction Stop
        $result.State | Should -Be 'ContractConflict'
        @($result.Results | Where-Object {
                $_.Component -eq 'roles' -and $_.State -eq 'ManualPrerequisite'
            }).Count | Should -Be 1
        @($result.Results | Where-Object {
                $_.Component -eq 'unexpectedMetadata' -and
                $_.State -eq 'ContractConflict'
            }).Count | Should -Be 1
    }

    It 'emits classified unsupported JSON and exits two when GET-only localization is unavailable' {
        $invocation = script:Invoke-ConvergenceEntryScript -Scenario RetrieveLocLabelsUnsupported

        $invocation.ExitCode | Should -Be 2
        { $invocation.Output | ConvertFrom-Json -ErrorAction Stop } |
            Should -Not -Throw

        $result = $invocation.Output | ConvertFrom-Json -ErrorAction Stop
        $result.State | Should -Be 'UnsupportedInTenant'
        @($result.Results | Where-Object {
                $_.Component -eq 'crmshow_accountcontactrole' -and
                $_.State -eq 'UnsupportedInTenant'
            }).Count | Should -Be 1
    }

    It 'emits error output and exits one when az returns a non-classified transport failure' {
        $invocation = script:Invoke-ConvergenceEntryScript -Scenario TransportFailure

        $invocation.ExitCode | Should -Be 1
        script:Assert-SafeDiagnosticLine -Text $invocation.Output -MaxLength 450
        $invocation.Output | Should -Match 'Dataverse convergence transport failed'
        $invocation.Output | Should -Match '/RetrieveProvisionedLanguages\(\)'
        $invocation.Output | Should -Match 'Output:'
        $invocation.Output | Should -Match (
            [regex]::Escape(
                '::warning::convergence transport Synthetic az transport failure. blocked'
            )
        )
        $invocation.Output | Should -Not -Match 'At line:|--method|--url|--resource'
        { $invocation.Output | ConvertFrom-Json -ErrorAction Stop } |
            Should -Throw
    }
}

Describe 'Convergence entry point safety' {
    It 'does not invoke az when dot-sourced with unit arguments' {
        $text = @'
function az { throw 'az was called' }
. '__SCRIPT__' -EnvironmentUrl 'https://unit.crm.dynamics.com' -ContractPath '__CONTRACT__'
'@.Replace('__SCRIPT__', $script:convergencePath.Replace("'", "''")).
            Replace('__CONTRACT__', $script:contractPath.Replace("'", "''"))

        & ([scriptblock]::Create($text))
    }
}
