BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
    $script:contractPath = Join-Path $script:repoRoot 'solution/schema/insurance-foundation.json'
    $script:publisherPath = Join-Path $script:repoRoot 'scripts/solution/Publish-InsuranceFoundation.ps1'
    . $script:publisherPath -EnvironmentUrl 'https://unit.crm.dynamics.com' -ContractPath $script:contractPath
    $script:contract = Get-Content $script:contractPath -Raw | ConvertFrom-Json

    function Get-ContractTableByLogicalName {
        param([Parameter(Mandatory)] [string]$LogicalName)
        return @($script:contract.tables | Where-Object logicalName -eq $LogicalName)[0]
    }

    function Get-ColumnAttributeTypeName {
        param([Parameter(Mandatory)] $Column)
        return @{
            Text = 'String'; Lookup = 'Lookup'; Customer = 'Customer'
            GlobalChoice = 'Picklist'; DateOnly = 'DateTime'
            DateTime = 'DateTime'
        }[$Column.type]
    }

    function New-TableAttributeSnapshot {
        param([Parameter(Mandatory)] $Column)

        $attribute = [ordered]@{
            MetadataId = "attribute-$($Column.logicalName)"
            LogicalName = $Column.logicalName
            SchemaName = $Column.schemaName
            AttributeType = Get-ColumnAttributeTypeName $Column
            DisplayName = ConvertTo-LocalizedLabel $Column.metadata.label
            Description = ConvertTo-LocalizedLabel $Column.metadata.description
        }
        switch ($Column.type) {
            'Text' {
                $attribute.MaxLength = $Column.maxLength
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
                    Name = $Column.choice
                }
            }
            'Lookup' {
                $attribute.Targets = @($Column.lookup.targets)
            }
            'Customer' {
                $attribute.Targets = @($Column.lookup.targets)
            }
        }
        return [pscustomobject]$attribute
    }

    function New-TableRelationshipSnapshots {
        param(
            [Parameter(Mandatory)] $Table,
            [Parameter(Mandatory)] $Relationship
        )

        $targets = if ($Relationship.authoring -eq 'CreateCustomerRelationships') {
            @($Relationship.referencedTables)
        } else {
            @([string]$Relationship.referencedTables[0])
        }
        $relationships = foreach ($target in $targets) {
            [pscustomobject]@{
                SchemaName = if (
                    $Relationship.authoring -eq 'CreateCustomerRelationships'
                ) {
                    "$($Relationship.schemaName)_$target"
                } else {
                    $Relationship.schemaName
                }
                ReferencedEntity = [string]$target
                ReferencingEntity = $Table.logicalName
                ReferencingAttribute = $Relationship.lookupColumn
                CascadeConfiguration = [pscustomobject]@{
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
            }
        }
        return @($relationships)
    }

    function New-TableMetadataSnapshot {
        param(
            [Parameter(Mandatory)] $Table,
            [switch]$IncludeCustomerRelationships,
            [string[]]$OmitColumns = @(),
            [string[]]$OmitRelationshipSchemas = @()
        )

        $attributes = foreach ($column in @($Table.columns)) {
            if ($column.logicalName -in $OmitColumns) { continue }
            if ($column.type -eq 'Customer' -and
                -not $IncludeCustomerRelationships) {
                continue
            }
            New-TableAttributeSnapshot $column
        }
        $relationships = foreach ($relationship in @($Table.relationships)) {
            if ($relationship.schemaName -in $OmitRelationshipSchemas) {
                continue
            }
            if ($relationship.authoring -eq 'CreateCustomerRelationships' -and
                -not $IncludeCustomerRelationships) {
                continue
            }
            New-TableRelationshipSnapshots $Table $relationship
        }
        return [pscustomobject]@{
            MetadataId = "table-$($Table.logicalName)"
            LogicalName = $Table.logicalName
            SchemaName = $Table.schemaName
            OwnershipType = $Table.ownership
            PrimaryNameAttribute = 'crmshow_name'
            ObjectTypeCode = 10427
            SolutionUniqueName = $Table.solution
            DisplayName = ConvertTo-LocalizedLabel $Table.metadata.label
            Description = ConvertTo-LocalizedLabel $Table.metadata.description
            Attributes = @($attributes)
            ManyToOneRelationships = @($relationships)
        }
    }

    function New-TableTypedAttributeCollectionResponse {
        param(
            [Parameter(Mandatory)] $Table,
            [Parameter(Mandatory)] [string]$TypeName,
            [switch]$IncludeCustomerRelationships,
            [string]$AttributeLogicalName,
            [string[]]$OmitColumns = @(),
            [string[]]$OmitRelationshipSchemas = @()
        )

        $snapshot = New-TableMetadataSnapshot -Table $Table `
            -IncludeCustomerRelationships:$IncludeCustomerRelationships `
            -OmitColumns $OmitColumns `
            -OmitRelationshipSchemas $OmitRelationshipSchemas
        $attributes = switch ($TypeName) {
            'StringAttributeMetadata' {
                @($snapshot.Attributes | Where-Object AttributeType -eq 'String')
            }
            'DateTimeAttributeMetadata' {
                @($snapshot.Attributes | Where-Object AttributeType -eq 'DateTime')
            }
            'LookupAttributeMetadata' {
                @($snapshot.Attributes | Where-Object {
                    $_.AttributeType -in @('Lookup', 'Customer')
                })
            }
            'PicklistAttributeMetadata' {
                @($snapshot.Attributes | Where-Object AttributeType -eq 'Picklist')
            }
            default {
                throw "Unsupported typed attribute test collection '$TypeName'."
            }
        }
        if (-not [string]::IsNullOrWhiteSpace($AttributeLogicalName)) {
            $attributes = @($attributes | Where-Object {
                $_.LogicalName -eq $AttributeLogicalName
            })
        }
        return [pscustomobject]@{
            value = @($attributes)
        }
    }
}

Describe 'Insurance Foundation request builders' {
    It 'uses the owning solution and duplicate-detection headers' {
        $headers = Get-DataverseHeaders -SolutionUniqueName 'crmshow_DataModel'
        $headers.'MSCRM.SolutionUniqueName' | Should -Be 'crmshow_DataModel'
        $headers.'MSCRM.SuppressDuplicateDetection' | Should -Be 'false'
    }

    It 'builds all four localized labels, descriptions, and choice options' {
        $request = New-ChoiceRequest $script:contract.choices[0]
        @($request.Body.DisplayName.LocalizedLabels.LanguageCode) |
            Should -Be @(1033, 1031, 1036, 1040)
        @($request.Body.Description.LocalizedLabels.LanguageCode) |
            Should -Be @(1033, 1031, 1036, 1040)
        @($request.Body.Options.Value) |
            Should -Be @(100000000, 100000001, 100000002)
        foreach ($option in $request.Body.Options) {
            @($option.Label.LocalizedLabels.LanguageCode) |
                Should -Be @(1033, 1031, 1036, 1040)
            @($option.Description.LocalizedLabels.LanguageCode) |
                Should -Be @(1033, 1031, 1036, 1040)
        }
    }

    It 'binds choice columns by metadata ID when one is resolved' {
        $metadataId = '11111111-1111-1111-1111-111111111111'
        $extension = $script:contract.nativeExtensions[0]
        $native = New-NativeAttributeRequest $extension @{
            $extension.choice = $metadataId
        }
        $native.Body.'GlobalOptionSet@odata.bind' |
            Should -Be "/GlobalOptionSetDefinitions($metadataId)"

        $table = $script:contract.tables[0]
        $choiceColumn = $table.columns | Where-Object type -eq 'GlobalChoice' |
            Select-Object -First 1
        $request = Get-TableCreateRequest $table @{
            $choiceColumn.choice = $metadataId
        }
        ($request.Body.Attributes | Where-Object {
            $_.LogicalName -eq $choiceColumn.logicalName
        }).'GlobalOptionSet@odata.bind' |
            Should -Be "/GlobalOptionSetDefinitions($metadataId)"
    }

    It 'accepts a complete typed-endpoint response without an odata type annotation' {
        $existing = [pscustomobject][ordered]@{
            MetadataId = 'attribute-id'; LogicalName = 'crmshow_name'
            SchemaName = 'crmshow_Name'; AttributeType = 'String'
            MaxLength = 200; IsPrimaryName = $true
            RequiredLevel = @{ Value = 'ApplicationRequired' }
            IsAuditEnabled = @{ Value = $true }; FormatName = @{ Value = 'Text' }
            DisplayName = @{ marker = 'old' }; Description = @{ marker = 'old' }
        }
        $body = New-CompleteLocalizedMetadataUpdateBody $existing `
            $script:contract.tables[0].columns[0].metadata Attribute
        $body.LogicalName | Should -Be 'crmshow_name'
        $body.SchemaName | Should -Be 'crmshow_Name'
        $body.AttributeType | Should -Be 'String'
        $body.MaxLength | Should -Be 200
        $body.IsPrimaryName | Should -BeTrue
        $body.Contains('@odata.type') | Should -BeFalse
        @($body.DisplayName.LocalizedLabels.LanguageCode) |
            Should -Be @(1033, 1031, 1036, 1040)

        $annotated = $existing | ConvertTo-Json -Depth 20 | ConvertFrom-Json
        $annotated | Add-Member NoteProperty '@odata.type' `
            'Microsoft.Dynamics.CRM.StringAttributeMetadata'
        $annotatedBody = New-CompleteLocalizedMetadataUpdateBody $annotated `
            $script:contract.tables[0].columns[0].metadata Attribute
        $annotatedBody.'@odata.type' |
            Should -Be 'Microsoft.Dynamics.CRM.StringAttributeMetadata'

        {
            New-CompleteLocalizedMetadataUpdateBody ([pscustomobject]@{
                '@odata.type'='Microsoft.Dynamics.CRM.StringAttributeMetadata'
            }) $script:contract.tables[0].columns[0].metadata Attribute
        } | Should -Throw '*complete typed representation*LogicalName*'
    }

    It 'compares every required localized label and description' {
        $metadata = $script:contract.tables[0].metadata
        $existing = [pscustomobject]@{
            DisplayName = ConvertTo-LocalizedLabel $metadata.label
            Description = ConvertTo-LocalizedLabel $metadata.description
        }
        Test-LocalizedMetadataChanged $existing $metadata | Should -BeFalse

        foreach ($property in 'DisplayName', 'Description') {
            foreach ($language in 1033, 1031, 1036, 1040) {
                $changed = $existing | ConvertTo-Json -Depth 20 | ConvertFrom-Json
                ($changed.$property.LocalizedLabels |
                    Where-Object LanguageCode -eq $language).Label = 'Incorrect'
                Test-LocalizedMetadataChanged $changed $metadata | Should -BeTrue

                $missing = $existing | ConvertTo-Json -Depth 20 | ConvertFrom-Json
                $missing.$property.LocalizedLabels = @(
                    $missing.$property.LocalizedLabels |
                        Where-Object LanguageCode -ne $language
                )
                Test-LocalizedMetadataChanged $missing $metadata | Should -BeTrue
            }
        }
    }

    It 'deep inserts every ordinary lookup relationship in the initial table create' {
        $table = $script:contract.tables[0]
        $request = Get-TableCreateRequest -Table $table
        @($request.Body.Attributes |
            Where-Object { $_.'@odata.type' -eq 'Microsoft.Dynamics.CRM.LookupAttributeMetadata' }) |
            Should -BeNullOrEmpty
        @($request.Body.OneToManyRelationships.ReferencingAttribute) |
            Should -BeNullOrEmpty
        @($request.Body.OneToManyRelationships.Lookup.LogicalName) |
            Should -Be @('crmshow_accountid', 'crmshow_contactid')
        @($request.Body.OneToManyRelationships.Lookup.Targets) |
            Should -BeNullOrEmpty
        @($request.Body.OneToManyRelationships.CascadeConfiguration.Merge) |
            Should -Be @('Cascade', 'Cascade')

        $customTarget = New-OrdinaryRelationshipMetadata `
            $script:contract.tables[2] $script:contract.tables[2].relationships[0]
        $customTarget.CascadeConfiguration.Merge | Should -Be 'NoCascade'
    }

    It 'marks only crmshow_name as primary name on every custom table create' {
        foreach ($table in $script:contract.tables) {
            $attributes = @(Get-TableCreateRequest $table).Body.Attributes
            @($attributes | Where-Object IsPrimaryName).LogicalName |
                Should -Be @('crmshow_name')
            @($attributes | Where-Object {
                $_.LogicalName -ne 'crmshow_name' -and $_.IsPrimaryName
            }) | Should -BeNullOrEmpty
        }
    }

    It 'creates UTC contract dates as time-zone-independent metadata' {
        $dateTime = New-AttributeMetadata ($script:contract.tables[1].columns |
            Where-Object type -eq 'DateTime' | Select-Object -First 1)
        $dateTime.DateTimeBehavior.Value | Should -Be 'TimeZoneIndependent'
        $dateTime.Format | Should -Be 'DateAndTime'
    }

    It 'uses the typed global-option-set alternate key without expand or filter' {
        $script:choicePath = $null
        Mock Invoke-DataverseRequest {
            param($Method, $Path)
            $script:choicePath = $Path
            return [pscustomobject]@{
                Name = "crmshow_broker's_choice"
                Options = @([pscustomobject]@{ Value = 100000000 })
            }
        }
        $result = Get-GlobalOptionSet "crmshow_broker's_choice"
        @($result.Options).Count | Should -Be 1
        $script:choicePath | Should -BeExactly `
            ("/GlobalOptionSetDefinitions(Name='crmshow_broker''s_choice')/" +
                'Microsoft.Dynamics.CRM.OptionSetMetadata')
        $script:choicePath | Should -Not -Match '\$(?:expand|filter)'

        $source = Get-Content $script:publisherPath -Raw
        $source | Should -Not -Match '\$expand=Options'
    }

    It 'returns null when the typed global-option-set lookup returns 404' {
        Mock Invoke-DataverseRequest {
            param($Method, $Path)
            throw '404 Not Found'
        }

        Get-GlobalOptionSet 'crmshow_missing' | Should -BeNullOrEmpty
    }

    It 'queries choice attributes only through typed metadata collections' {
        $script:picklistPath = $null
        Mock Invoke-DataverseRequest {
            param($Method, $Path)
            $script:picklistPath = $Path
            return [pscustomobject]@{ value = @() }
        }

        Get-PicklistAttributeMetadata 'account' 'crmshow_accounttype' |
            Should -BeNullOrEmpty
        $script:picklistPath | Should -BeExactly (
            "/EntityDefinitions(LogicalName='account')/Attributes/" +
            "Microsoft.Dynamics.CRM.PicklistAttributeMetadata?" +
            "`$select=MetadataId,LogicalName,SchemaName,AttributeType,DisplayName,Description&" +
            "`$expand=GlobalOptionSet(`$select=Name)&" +
            "`$filter=LogicalName eq 'crmshow_accounttype'"
        )

        $source = Get-Content $script:publisherPath -Raw
        $source | Should -Not -Match '/Attributes\?[^\r\n]*\$expand=GlobalOptionSet'
        $source | Should -Not -Match '\$expand=Attributes\([^\r\n]*\$expand=GlobalOptionSet'
    }

    It 'derives initial table-create readiness attributes from the actual create request' {
        $table = $script:contract.tables[2]
        $request = Get-TableCreateRequest -Table $table

        @((Get-RequestSubmittedAttributeLogicalNames `
                -Request $request -Table $table) | Sort-Object) |
            Should -Be @(
                'crmshow_name',
                'crmshow_policyid',
                'crmshow_roletype',
                'crmshow_sourceid',
                'crmshow_sourcesystem',
                'crmshow_validfrom',
                'crmshow_validto'
            )
        @((Get-RequestSubmittedRelationshipSchemas -Request $request) |
                Sort-Object) |
            Should -Be @('crmshow_PolicyProjection_PartyRoles')
    }

    It 'limits typed table metadata fetches to requested contract attributes' {
        $table = $script:contract.tables[1]
        $requestedAttributeLogicalNames = @(
            'crmshow_name',
            'crmshow_policynumber',
            'crmshow_status'
        )
        $snapshot = New-TableMetadataSnapshot -Table $table
        $requestedAttributes = @($snapshot.Attributes | Where-Object {
            $_.LogicalName -in $requestedAttributeLogicalNames
        })
        $script:entityDefinitionPath = $null
        $script:typedAttributeRequests = [System.Collections.Generic.List[string]]::new()

        Mock Invoke-DataverseRequest {
            param($Method, $Path)
            if ($Method -ne 'GET') {
                throw "Unsupported mocked endpoint: $Method $Path"
            }
            if ($Path -like '/EntityDefinitions?*' -and
                $Path -match '\$expand=Attributes') {
                $script:entityDefinitionPath = $Path
                return [pscustomobject]@{
                    value = @([pscustomobject]@{
                        MetadataId = $snapshot.MetadataId
                        LogicalName = $snapshot.LogicalName
                        SchemaName = $snapshot.SchemaName
                        OwnershipType = $snapshot.OwnershipType
                        PrimaryNameAttribute = $snapshot.PrimaryNameAttribute
                        ObjectTypeCode = $snapshot.ObjectTypeCode
                        DisplayName = $snapshot.DisplayName
                        Description = $snapshot.Description
                        Attributes = @(
                            $requestedAttributes +
                            @([pscustomobject]@{
                                MetadataId = 'attribute-createdon'
                                LogicalName = 'createdon'
                                SchemaName = 'CreatedOn'
                                AttributeType = 'DateTime'
                                DisplayName = @{ marker = 'unrelated' }
                                Description = @{ marker = 'unrelated' }
                            })
                        )
                        ManyToOneRelationships = @(
                            $snapshot.ManyToOneRelationships
                        )
                    })
                }
            }
            if ($Path -match (
                "^/EntityDefinitions\(LogicalName='((?:[^']|'')*)'\)" +
                '/Attributes/Microsoft\.Dynamics\.CRM\.' +
                '(StringAttributeMetadata|DateTimeAttributeMetadata|' +
                'LookupAttributeMetadata|PicklistAttributeMetadata)\?'
            )) {
                $script:typedAttributeRequests.Add($Path) | Out-Null
                $logicalName = $Matches[1].Replace("''", "'")
                $typeName = $Matches[2]
                $attributeLogicalName = [regex]::Match(
                    $Path,
                    "LogicalName eq '((?:[^']|'')*)'"
                ).Groups[1].Value.Replace("''", "'")
                return New-TableTypedAttributeCollectionResponse `
                    -Table $table -TypeName $typeName `
                    -AttributeLogicalName $attributeLogicalName
            }
            throw "Unsupported mocked endpoint: $Method $Path"
        }

        $result = Get-TableMetadataSnapshot `
            -LogicalName $table.logicalName `
            -RequestedAttributeLogicalNames $requestedAttributeLogicalNames

        @($result.Attributes.LogicalName | Sort-Object) |
            Should -Be @($requestedAttributeLogicalNames | Sort-Object)
        $expectedAttributeFilter = [regex]::Escape(
            "LogicalName eq 'crmshow_name' or " +
            "LogicalName eq 'crmshow_policynumber' or " +
            "LogicalName eq 'crmshow_status'"
        )
        $script:entityDefinitionPath | Should -Match $expectedAttributeFilter
        $script:typedAttributeRequests.Count | Should -Be 3
        @($script:typedAttributeRequests | Where-Object {
            $_ -match "LogicalName eq 'createdon'"
        }) | Should -BeNullOrEmpty
        (@($result.Attributes | Where-Object {
            $_.LogicalName -eq 'crmshow_status'
        })[0].GlobalOptionSet.Name) | Should -Be 'crmshow_policystatus'
    }

    It 'queries table existence without expanding attributes or typed endpoints' {
        $script:paths = [System.Collections.Generic.List[string]]::new()

        Mock Invoke-DataverseRequest {
            param($Method, $Path)
            if ($Method -ne 'GET') {
                throw "Unsupported mocked endpoint: $Method $Path"
            }
            $script:paths.Add($Path) | Out-Null
            return [pscustomobject]@{
                value = @([pscustomobject]@{
                    MetadataId = 'existing-table'
                    LogicalName = 'crmshow_policyprojection'
                    SchemaName = 'crmshow_PolicyProjection'
                })
            }
        }

        $result = Get-TableExistenceSnapshot -LogicalName 'crmshow_policyprojection'

        $result.MetadataId | Should -Be 'existing-table'
        @($script:paths) | Should -Be @(
            "/EntityDefinitions?" +
            "`$select=MetadataId,LogicalName,SchemaName&" +
            "`$filter=LogicalName eq 'crmshow_policyprojection'"
        )
        $script:paths[0] | Should -Not -Match '\$expand=Attributes'
        $script:paths[0] |
            Should -Not -Match '/Attributes/Microsoft\.Dynamics\.CRM\.'
    }

    It 'builds the documented Customer relationship action' {
        $table = $script:contract.tables[2]
        $column = $table.columns | Where-Object logicalName -eq 'crmshow_partyid'
        $request = Get-CustomerRelationshipRequest -Table $table -Column $column
        $request.Method | Should -Be 'POST'
        $request.Path | Should -Be '/CreateCustomerRelationships'
        $request.Body.Lookup.SchemaName | Should -Be 'crmshow_PartyId'
        $request.Body.SolutionUniqueName | Should -Be 'crmshow_DataModel'
        @($request.Body.OneToManyRelationships.ReferencedEntity) |
            Should -Be @('account', 'contact')
    }

    It 'targets alternate keys through the table logical name' {
        $request = Get-AlternateKeyRequest -TableLogicalName 'crmshow_policyprojection' `
            -Columns @('crmshow_externalsystem', 'crmshow_externalid') `
            -Key $script:contract.tables[1].alternateKeys[0]
        $request.Path | Should -Be "/EntityDefinitions(LogicalName='crmshow_policyprojection')/Keys"
        @($request.Body.KeyAttributes) |
            Should -Be @('crmshow_externalsystem', 'crmshow_externalid')
    }

    It 'carries four-language metadata for forms, views, and deferred-rule reports' {
        $table = $script:contract.tables[0]
        foreach ($request in @(
            (New-InvalidDateViewRequest $table $table.businessRules[0] 10042),
            (New-FormRequest $table $table.forms[0]),
            (New-ViewRequest $table $table.views[0] 10042)
        )) {
            @($request.LocalizedFields.name.PSObject.Properties.Name) |
                Should -Be @('1033', '1031', '1036', '1040')
            @($request.LocalizedFields.description.PSObject.Properties.Name) |
                Should -Be @('1033', '1031', '1036', '1040')
        }
    }

    It 'builds overlap views as distinct self-joins with open-ended intervals' {
        foreach ($table in @($script:contract.tables | Where-Object {
            @($_.views.purpose) -contains 'OverlapReporting'
        })) {
            $view = $table.views | Where-Object purpose -eq 'OverlapReporting'
            $fetch = (New-ViewRequest $table $view 10042).Body.fetchxml
            $fetch | Should -Match 'distinct="true"'
            $fetch | Should -Match "<link-entity name=`"$($table.logicalName)`""
            ([regex]::Matches($fetch, 'operator="null"')).Count | Should -Be 2
            $fetch | Should -Match 'valueof="b\.crmshow_validfrom"'
            $fetch | Should -Match 'valueof="b\.crmshow_validto"'
            $fetch | Should -Not -Match 'valueof="a\.'
            [xml]$document = $fetch
            $document.fetch.entity.'link-entity'.filter |
                Should -BeNullOrEmpty
        }
    }

    It 'uses the resolved custom object type code in layout XML' {
        $request = New-ViewRequest $script:contract.tables[0] `
            $script:contract.tables[0].views[0] 10427

        $request.Body.layoutxml | Should -Match 'object="10427"'
        $request.Body.layoutxml | Should -Match '<grid[^>]+icon="1"'
        $request.Body.layoutxml | Should -Not -Match 'object="1"'
    }
}

Describe 'Dataverse metadata convergence waits' {
    BeforeEach {
        $script:sleepCalls = [System.Collections.Generic.List[int]]::new()
        Mock Start-Sleep {
            param([int]$Seconds)
            $script:sleepCalls.Add($Seconds) | Out-Null
        }
    }

    It 'returns the first non-null result on the third attempt and sleeps only between failures' {
        $script:attempts = 0
        $expected = [pscustomobject]@{ marker = 'ready' }

        $result = Wait-DataverseCondition -Component 'crmshow_table' -Condition {
            $script:attempts++
            if ($script:attempts -eq 3) { return $expected }
            return $null
        }

        $result.marker | Should -Be 'ready'
        $script:attempts | Should -Be 3
        @($script:sleepCalls) | Should -Be @(5, 5)
    }

    It 'throws a classified timeout that includes the exact component and timeout' {
        $script:clock = [System.Collections.Generic.Queue[datetime]]::new()
        foreach ($value in @(
            [datetime]'2026-08-09T12:00:00Z',
            [datetime]'2026-08-09T12:00:00Z',
            [datetime]'2026-08-09T12:03:00Z'
        )) {
            $script:clock.Enqueue($value)
        }
        Mock Get-Date { $script:clock.Dequeue() }

        {
            Wait-DataverseCondition -Component `
                'crmshow_policyprojection/crmshow_accountid' `
                -TimeoutSeconds 180 -Condition { $null }
        } | Should -Throw (
            '*EventualConsistencyTimeout*' +
            'crmshow_policyprojection/crmshow_accountid*180*'
        )
    }

    It 'treats a late non-null condition result as a timeout' {
        $script:clock = [System.Collections.Generic.Queue[datetime]]::new()
        foreach ($value in @(
            [datetime]'2026-08-09T12:00:00Z',
            [datetime]'2026-08-09T12:00:11Z'
        )) {
            $script:clock.Enqueue($value)
        }
        Mock Get-Date { $script:clock.Dequeue() }

        {
            Wait-DataverseCondition -Component 'crmshow_table' `
                -TimeoutSeconds 10 -Condition {
                    [pscustomobject]@{ marker = 'late' }
                }
        } | Should -Throw '*EventualConsistencyTimeout*crmshow_table*10*'
    }

    It 'bounds each sleep to the remaining deadline' {
        $start = [datetime]'2026-08-09T12:00:00Z'
        $script:clock = [System.Collections.Generic.Queue[datetime]]::new()
        foreach ($value in @(
            $start,
            $start,
            $start.AddSeconds(5),
            $start.AddSeconds(10),
            $start.AddSeconds(12)
        )) {
            $script:clock.Enqueue($value)
        }
        Mock Get-Date { $script:clock.Dequeue() }

        {
            Wait-DataverseCondition -Component 'crmshow_lookup' `
                -TimeoutSeconds 12 -PollIntervalSeconds 5 `
                -Condition { $null }
        } | Should -Throw '*EventualConsistencyTimeout*crmshow_lookup*12*'
        @($script:sleepCalls) | Should -Be @(5, 5, 2)
    }
}

Describe 'az rest transport' {
    AfterEach {
        Remove-Item Function:\az -ErrorAction SilentlyContinue
    }

    It 'serializes exactly one headers option and cleans its body file on success' {
        $script:azArguments = @()
        $script:bodyFile = $null
        function global:az {
            $script:azArguments = @($args)
            $bodyIndex = [array]::IndexOf($script:azArguments, '--body')
            $script:bodyFile = ([string]$script:azArguments[$bodyIndex + 1]).TrimStart('@')
            Test-Path -LiteralPath $script:bodyFile | Should -BeTrue
            $global:LASTEXITCODE = 0
            '{}'
        }

        Invoke-DataverseRequest -Method POST -Path '/PublishAllXml' -Body @{ marker = 'private' } `
            -Headers (Get-DataverseHeaders 'crmshow_DataModel') | Out-Null

        @($script:azArguments | Where-Object { $_ -eq '--headers' }).Count | Should -Be 1
        $script:azArguments | Should -Contain 'Content-Type=application/json; charset=utf-8'
        $script:azArguments | Should -Contain 'MSCRM.SolutionUniqueName=crmshow_DataModel'
        $script:azArguments | Should -Contain 'MSCRM.SuppressDuplicateDetection=false'
        $resource = [array]::IndexOf($script:azArguments, '--resource')
        $script:azArguments[$resource + 1] | Should -Be 'https://unit.crm.dynamics.com/'
        Test-Path -LiteralPath $script:bodyFile | Should -BeFalse
    }

    It 'cleans its body file when az rest fails' {
        $script:bodyFile = $null
        function global:az {
            $arguments = @($args)
            $bodyIndex = [array]::IndexOf($arguments, '--body')
            $script:bodyFile = ([string]$arguments[$bodyIndex + 1]).TrimStart('@')
            $global:LASTEXITCODE = 17
        }
        {
            Invoke-DataverseRequest -Method POST -Path '/PublishAllXml' -Body @{ marker = 'private' } `
                -Headers (Get-DataverseHeaders 'crmshow_DataModel')
        } | Should -Throw '*exited with code 17*'
        Test-Path -LiteralPath $script:bodyFile | Should -BeFalse
    }

    It 'treats a Dataverse Not Found error emitted by az on stderr as absent metadata' {
        function global:az {
            Write-Error 'ERROR: {"error":{"code":"0x80060888","message":"Not Found"}}' `
                -ErrorAction Continue
            $global:LASTEXITCODE = 3
        }

        Get-GlobalOptionSet 'crmshow_accounttype' | Should -BeNullOrEmpty
    }

    It 'does not hide a non-404 Dataverse error emitted by az on stderr' {
        function global:az {
            Write-Error 'ERROR: {"error":{"code":"0x80040265","message":"Permission denied"}}' `
                -ErrorAction Continue
            $global:LASTEXITCODE = 4
        }

        {
            Get-GlobalOptionSet 'crmshow_accounttype'
        } | Should -Throw '*exited with code 4*Permission denied*'
    }
}

Describe 'Insurance Foundation scope contract' {
    It 'defaults both scope declarations to Demo and accepts all five supported scopes' {
        $tokens = $null
        $errors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseFile(
            $script:publisherPath,
            [ref]$tokens,
            [ref]$errors
        )

        @($errors) | Should -BeNullOrEmpty
        $expected = @('Foundation', 'DataModel', 'Demo', 'SecurityRoles', 'All')

        $scriptScope = @($ast.ParamBlock.Parameters | Where-Object {
            $_.Name.VariablePath.UserPath -eq 'Scope'
        })[0]
        $scriptScope | Should -Not -BeNullOrEmpty
        $scriptValidateSet = @($scriptScope.Attributes | Where-Object {
            $_.TypeName.FullName -eq 'ValidateSet'
        })[0]
        $scriptValidateSet | Should -Not -BeNullOrEmpty
        @($scriptValidateSet.PositionalArguments | ForEach-Object {
            $_.Extent.Text.Trim("'")
        }) | Should -Be $expected
        $scriptScope.DefaultValue.Extent.Text.Trim("'") | Should -Be 'Demo'

        $reconciliation = $ast.Find({
            param($node)
            $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
            $node.Name -eq 'Invoke-InsuranceFoundationReconciliation'
        }, $true)
        $reconciliation | Should -Not -BeNullOrEmpty
        $functionScope = @($reconciliation.Body.ParamBlock.Parameters | Where-Object {
            $_.Name.VariablePath.UserPath -eq 'Scope'
        })[0]
        $functionScope | Should -Not -BeNullOrEmpty
        $functionValidateSet = @($functionScope.Attributes | Where-Object {
            $_.TypeName.FullName -eq 'ValidateSet'
        })[0]
        $functionValidateSet | Should -Not -BeNullOrEmpty
        @($functionValidateSet.PositionalArguments | ForEach-Object {
            $_.Extent.Text.Trim("'")
        }) | Should -Be $expected
        $functionScope.DefaultValue.Extent.Text.Trim("'") | Should -Be 'Demo'
    }
}

Describe 'Insurance Foundation reconciliation' {
    BeforeEach {
        $script:calls = [System.Collections.Generic.List[object]]::new()
        $script:choicesExist = $false
        $script:createdChoices = [System.Collections.Generic.HashSet[string]]::new()
        $script:createdTables = [System.Collections.Generic.HashSet[string]]::new()
        $script:tablesWithCustomerRelationships = `
            [System.Collections.Generic.HashSet[string]]::new()
        Mock Wait-TableMetadataSnapshot {
            param($Table, $Component, $Ready, $RequestedAttributeLogicalNames)
            if (-not $script:createdTables.Contains($Table.logicalName)) {
                $snapshot = Get-TableMetadataSnapshot `
                    -LogicalName $Table.logicalName `
                    -RequestedAttributeLogicalNames `
                        $RequestedAttributeLogicalNames
                if ($Ready -and -not (& $Ready $snapshot)) {
                    return $null
                }
                return $snapshot
            }
            $includeCustomerRelationships = @(
                $Table.columns | Where-Object type -eq 'Customer'
            ).Count -eq 0 -or
                $script:tablesWithCustomerRelationships.Contains(
                    $Table.logicalName
                )
            $snapshot = New-TableMetadataSnapshot -Table $Table `
                -IncludeCustomerRelationships:$includeCustomerRelationships
            $script:calls.Add([pscustomobject]@{
                Sequence = $script:calls.Count + 1
                Method = 'SNAPSHOT'
                Path = $Component
                Body = $snapshot
                Headers = $null
            })
            if ($Ready -and -not (& $Ready $snapshot)) {
                return $null
            }
            return $snapshot
        }
        Mock Invoke-DataverseRequest {
            param($Method, $Path, $Body, $Headers)
            $script:calls.Add([pscustomobject]@{
                Sequence = $script:calls.Count + 1
                Method = $Method; Path = $Path; Body = $Body; Headers = $Headers
            })
            if ($Method -eq 'GET' -and $Path -match 'ObjectTypeCode') {
                return [pscustomobject]@{ LogicalName = 'resolved'; ObjectTypeCode = 10427 }
            }
            if ($Method -eq 'GET' -and $Path -like '/businessunits*') {
                return [pscustomobject]@{ value = @([pscustomobject]@{
                    businessunitid = 'root-business-unit'
                }) }
            }
            if ($Method -eq 'GET' -and
                $Path -match '^/EntityDefinitions\(LogicalName=''([^'']+)''\)\?\$select=LogicalName,SchemaName,Privileges') {
                $logicalName = $Matches[1]
                $schemaName = switch ($logicalName) {
                    'account' { 'Account' }
                    'contact' { 'Contact' }
                    default {
                        [string]($script:contract.tables |
                            Where-Object logicalName -eq $logicalName).schemaName
                    }
                }
                return [pscustomobject]@{
                    LogicalName = $logicalName
                    SchemaName = $schemaName
                    Privileges = @('Create','Read','Write','Append','AppendTo' |
                        ForEach-Object {
                            [pscustomobject]@{
                                Name = "prv$_$schemaName"
                                PrivilegeId = "$logicalName-$_"
                                PrivilegeType = $_
                            }
                        })
                }
            }
            if ($Method -eq 'GET' -and $Path -like '/EntityDefinitions?*' -and
                $Path -match '\$expand=Attributes') {
                $logicalName = [regex]::Match(
                    $Path,
                    "LogicalName eq '((?:[^']|'')*)'"
                ).Groups[1].Value.Replace("''", "'")
                $table = Get-ContractTableByLogicalName $logicalName
                if ($null -eq $table -or
                    -not $script:createdTables.Contains($logicalName)) {
                    return [pscustomobject]@{ value = @() }
                }
                $includeCustomerRelationships = @(
                    $table.columns | Where-Object type -eq 'Customer'
                ).Count -eq 0 -or
                    $script:tablesWithCustomerRelationships.Contains(
                        $logicalName
                    )
                return [pscustomobject]@{
                    value = @(
                        New-TableMetadataSnapshot -Table $table `
                            -IncludeCustomerRelationships:$includeCustomerRelationships
                    )
                }
            }
            if ($Method -eq 'GET' -and $Path -match (
                "^/EntityDefinitions\(LogicalName='((?:[^']|'')*)'\)" +
                '/Attributes/Microsoft\.Dynamics\.CRM\.' +
                '(StringAttributeMetadata|DateTimeAttributeMetadata|' +
                'LookupAttributeMetadata|PicklistAttributeMetadata)\?'
            )) {
                $logicalName = $Matches[1].Replace("''", "'")
                $typeName = $Matches[2]
                $attributeLogicalName = [regex]::Match(
                    $Path,
                    "LogicalName eq '((?:[^']|'')*)'"
                ).Groups[1].Value.Replace("''", "'")
                $table = Get-ContractTableByLogicalName $logicalName
                if ($null -eq $table -or
                    -not $script:createdTables.Contains($logicalName)) {
                    return [pscustomobject]@{ value = @() }
                }
                $includeCustomerRelationships = @(
                    $table.columns | Where-Object type -eq 'Customer'
                ).Count -eq 0 -or
                    $script:tablesWithCustomerRelationships.Contains(
                        $logicalName
                    )
                return New-TableTypedAttributeCollectionResponse `
                    -Table $table -TypeName $typeName `
                    -IncludeCustomerRelationships:$includeCustomerRelationships `
                    -AttributeLogicalName $attributeLogicalName
            }
            if ($Method -eq 'GET' -and
                $Path -like "/GlobalOptionSetDefinitions(Name='*") {
                $name = [regex]::Match(
                    $Path, "Name='([^']+)'"
                ).Groups[1].Value
                if ($script:choicesExist -or $script:createdChoices.Contains($name)) {
                    $choice = $script:contract.choices |
                        Where-Object logicalName -eq $name
                    $desired = (New-ChoiceRequest $choice).Body
                    $choiceIndex = [array]::IndexOf(
                        @($script:contract.choices.logicalName), $name
                    ) + 1
                    return [pscustomobject]@{
                        Name = $choice.logicalName
                        '@odata.type' = 'Microsoft.Dynamics.CRM.OptionSetMetadata'
                        MetadataId = '00000000-0000-0000-0000-{0:D12}' -f $choiceIndex
                        IsGlobal = $true
                        OptionSetType = 'Picklist'
                        SolutionUniqueName = $choice.solution
                        DisplayName = $desired.DisplayName
                        Description = $desired.Description
                        Options = $desired.Options
                    }
                }
                throw '404 Not Found'
            }
            if ($Method -eq 'GET' -and $Path -match '^/(?:EntityDefinitions|savedqueries|systemforms|roles|solutions|solutioncomponents)(?:\?|.*\?.*)$') {
                return [pscustomobject]@{ value = @() }
            }
            if ($Method -eq 'GET' -and $Path -match '^/RetrieveRolePrivilegesRole') {
                return [pscustomobject]@{ RolePrivileges = @() }
            }
            if ($Method -eq 'GET') { throw "Unsupported mocked endpoint: $Method $Path" }
            if ($Method -eq 'POST' -and $Path -eq '/GlobalOptionSetDefinitions') {
                $script:createdChoices.Add([string]$Body.Name) | Out-Null
            }
            if ($Method -eq 'POST' -and $Path -eq '/EntityDefinitions') {
                $script:createdTables.Add([string]$Body.LogicalName) | Out-Null
            }
            if ($Method -eq 'POST' -and $Path -eq '/CreateCustomerRelationships') {
                $tableLogicalName = [string]$Body.OneToManyRelationships[0].ReferencingEntity
                if (-not [string]::IsNullOrWhiteSpace($tableLogicalName)) {
                    $script:tablesWithCustomerRelationships.Add(
                        $tableLogicalName
                    ) | Out-Null
                }
            }
            if ($Path -eq '/savedqueries') {
                return [pscustomobject]@{ savedqueryid = 'new-view' }
            }
            if ($Path -eq '/systemforms') {
                return [pscustomobject]@{ formid = 'new-form' }
            }
            if ($Path -eq '/roles') {
                return [pscustomobject]@{ roleid = 'new-role' }
            }
            return [pscustomobject]@{}
        }
    }

    It 'schedules all contract components without DELETE and headers every mutation' {
        Invoke-InsuranceFoundationReconciliation -Contract $script:contract -Scope All -Confirm:$false

        @($script:calls | Where-Object Method -eq 'DELETE') | Should -BeNullOrEmpty
        foreach ($call in @($script:calls | Where-Object Method -in @('POST', 'PATCH', 'PUT'))) {
            $call.Headers.'MSCRM.SolutionUniqueName' |
                Should -BeIn @('crmshow_Foundation', 'crmshow_DataModel')
            $call.Headers.'MSCRM.SuppressDuplicateDetection' | Should -Be 'false'
        }

        $created = @($script:calls | Where-Object Method -eq 'POST')
        @($created | Where-Object Path -eq '/GlobalOptionSetDefinitions').Count | Should -Be 5
        @($created | Where-Object Path -eq '/EntityDefinitions').Count | Should -Be 3
        @($created | Where-Object Path -eq '/PublishXml').Count | Should -Be 6
        foreach ($publish in @($created | Where-Object Path -eq '/PublishXml')) {
            $publish.Body.ParameterXml |
                Should -Match '^<importexportxml><entities><entity>crmshow_[a-z]+</entity></entities></importexportxml>$'
        }
        @($created | Where-Object Path -match "EntityDefinitions\(LogicalName='(?:account|contact)'\)/Attributes").Count |
            Should -Be 2
        @($created | Where-Object Path -match '/Keys$').Count | Should -Be 3
        @($created | Where-Object Path -eq '/workflows').Count | Should -Be 0
        @($created | Where-Object Path -eq '/systemforms').Count | Should -Be 3
        @($created | Where-Object Path -eq '/savedqueries').Count | Should -Be 8
        @($created | Where-Object Path -eq '/roles').Count | Should -Be 2
        $roleActions = @($created | Where-Object Path -match 'AddPrivilegesRole$')
        $roleActions.Count | Should -Be 2
        @($roleActions[0].Body.Privileges).Count | Should -Be 5
        @($roleActions[1].Body.Privileges).Count | Should -Be 17
        @($roleActions.Body.Privileges.Depth | Select-Object -Unique) |
            Should -Be @('Global')
        @($created | Where-Object Path -eq '/savedqueries').Body.layoutxml |
            Should -Match 'object="10427"'
        $tableExistenceReads = @($script:calls | Where-Object {
            $_.Method -eq 'GET' -and
            $_.Path -like '/EntityDefinitions?*' -and
            $_.Path -match '\$select=MetadataId,LogicalName,SchemaName&' -and
            $_.Path -notmatch '\$expand=Attributes'
        })
        $tableExistenceReads.Count | Should -Be 3
        @($tableExistenceReads | Where-Object {
            $_.Path -match "LogicalName eq 'crmshow_accountcontactrole'"
        }).Count | Should -Be 1
        @($tableExistenceReads | Where-Object {
            $_.Path -match "LogicalName eq 'crmshow_policyprojection'"
        }).Count | Should -Be 1
        @($tableExistenceReads | Where-Object {
            $_.Path -match "LogicalName eq 'crmshow_policypartyrole'"
        }).Count | Should -Be 1
        $tableMetadataReads = @($script:calls | Where-Object {
            $_.Method -eq 'GET' -and
            $_.Path -like '/EntityDefinitions?*' -and
            $_.Path -match '\$expand=Attributes'
        })
        $tableMetadataReads.Count | Should -Be 0
        @($script:calls | Where-Object {
            $_.Method -eq 'GET' -and
            $_.Path -match (
                '/Attributes/Microsoft\.Dynamics\.CRM\.' +
                '(StringAttributeMetadata|DateTimeAttributeMetadata|' +
                'LookupAttributeMetadata|PicklistAttributeMetadata)\?'
            )
        }).Count | Should -BeGreaterThan 0
        $choiceBindings = @(
            $created |
                Where-Object Path -match '/Attributes$' |
                ForEach-Object { $_.Body.'GlobalOptionSet@odata.bind' }
            $created |
                Where-Object Path -eq '/EntityDefinitions' |
                ForEach-Object {
                    $_.Body.Attributes |
                        Where-Object { $_.'GlobalOptionSet@odata.bind' } |
                        ForEach-Object { $_.'GlobalOptionSet@odata.bind' }
                }
        )
        $choiceBindings.Count | Should -BeGreaterThan 0
        $choiceBindings | Should -Not -Match 'Name='
        $choiceBindings | Should -Match (
            '^/GlobalOptionSetDefinitions\(' +
            '[0-9a-f]{8}(?:-[0-9a-f]{4}){3}-[0-9a-f]{12}\)$'
        )
    }

    It 'keeps Foundation scope choice-only and publishes under the foundation header' {
        Invoke-InsuranceFoundationReconciliation -Contract $script:contract `
            -Scope Foundation -Confirm:$false | Out-Null

        @($script:calls | Where-Object {
            $_.Method -eq 'POST' -and $_.Path -eq '/GlobalOptionSetDefinitions'
        }).Count | Should -Be 5
        @($script:calls | Where-Object {
            $_.Method -ne 'GET' -and $_.Path -like '/EntityDefinitions*'
        }) | Should -BeNullOrEmpty
        @($script:calls | Where-Object {
            $_.Method -ne 'GET' -and
            ($_.Path -eq '/roles' -or $_.Path -match 'PrivilegesRole$')
        }) | Should -BeNullOrEmpty
        @($script:calls | Where-Object {
            $_.Method -ne 'GET' -and $_.Path -eq '/PublishAllXml'
        }).Headers.'MSCRM.SolutionUniqueName' | Should -Be 'crmshow_Foundation'
    }

    It 'keeps DataModel scope free of choice and role authoring and publishes under the data-model header' {
        $script:choicesExist = $true
        Invoke-InsuranceFoundationReconciliation -Contract $script:contract `
            -Scope DataModel -Confirm:$false | Out-Null

        @($script:calls | Where-Object {
            $_.Method -ne 'GET' -and $_.Path -like '/GlobalOptionSetDefinitions*'
        }) | Should -BeNullOrEmpty
        @($script:calls | Where-Object {
            $_.Method -ne 'GET' -and
            ($_.Path -eq '/roles' -or $_.Path -match 'PrivilegesRole$')
        }) | Should -BeNullOrEmpty
        @($script:calls | Where-Object {
            $_.Method -eq 'POST' -and $_.Path -eq '/EntityDefinitions'
        }).Count | Should -Be 3
        @($script:calls | Where-Object {
            $_.Method -ne 'GET' -and $_.Path -eq '/PublishAllXml'
        }).Headers.'MSCRM.SolutionUniqueName' | Should -Be 'crmshow_DataModel'
    }

    It 'keeps Demo scope demo-safe while publishing under the data-model header' {
        Invoke-InsuranceFoundationReconciliation -Contract $script:contract `
            -Scope Demo -Confirm:$false | Out-Null

        @($script:calls | Where-Object {
            $_.Method -eq 'POST' -and $_.Path -eq '/GlobalOptionSetDefinitions'
        }).Count | Should -Be 5
        @($script:calls | Where-Object {
            $_.Method -eq 'POST' -and $_.Path -eq '/EntityDefinitions'
        }).Count | Should -Be 3
        @($script:calls | Where-Object {
            $_.Method -ne 'GET' -and
            ($_.Path -eq '/roles' -or $_.Path -match 'PrivilegesRole$')
        }) | Should -BeNullOrEmpty
        @($script:calls | Where-Object {
            $_.Method -ne 'GET' -and $_.Path -eq '/PublishAllXml'
        }).Headers.'MSCRM.SolutionUniqueName' | Should -Be 'crmshow_DataModel'
    }

    It 'keeps SecurityRoles scope free of choice and data-model authoring and publishes under the foundation header' {
        Invoke-InsuranceFoundationReconciliation -Contract $script:contract `
            -Scope SecurityRoles -Confirm:$false | Out-Null

        @($script:calls | Where-Object {
            $_.Method -ne 'GET' -and $_.Path -like '/GlobalOptionSetDefinitions*'
        }) | Should -BeNullOrEmpty
        @($script:calls | Where-Object {
            $_.Method -ne 'GET' -and $_.Path -like '/EntityDefinitions*'
        }) | Should -BeNullOrEmpty
        @($script:calls | Where-Object {
            $_.Method -ne 'GET' -and
            ($_.Path -eq '/roles' -or $_.Path -match 'PrivilegesRole$')
        }).Count | Should -BeGreaterThan 0
        @($script:calls | Where-Object {
            $_.Method -ne 'GET' -and $_.Path -eq '/PublishAllXml'
        }).Headers.'MSCRM.SolutionUniqueName' | Should -Be 'crmshow_Foundation'
    }

    It 'keeps All as the explicit privileged scope and publishes under the data-model header' {
        Invoke-InsuranceFoundationReconciliation -Contract $script:contract `
            -Scope All -Confirm:$false | Out-Null

        @($script:calls | Where-Object {
            $_.Method -ne 'GET' -and
            ($_.Path -eq '/roles' -or $_.Path -match 'PrivilegesRole$')
        }).Count | Should -BeGreaterThan 0
        @($script:calls | Where-Object {
            $_.Method -ne 'GET' -and $_.Path -eq '/PublishAllXml'
        }).Headers.'MSCRM.SolutionUniqueName' | Should -Be 'crmshow_DataModel'
    }

    It 'queries saved queries only through supported Web API properties' {
        Invoke-InsuranceFoundationReconciliation -Contract $script:contract -Scope All -Confirm:$false

        $savedQueryReads = @($script:calls | Where-Object {
            $_.Method -eq 'GET' -and $_.Path -match '^/savedqueries\?'
        })
        $savedQueryReads.Count | Should -BeGreaterThan 0
        @($savedQueryReads.Path | Where-Object { $_ -match '_solutionid_value' }) |
            Should -BeNullOrEmpty
    }

    It 'queries system forms only through supported Web API properties' {
        Invoke-InsuranceFoundationReconciliation -Contract $script:contract -Scope All -Confirm:$false

        $systemFormReads = @($script:calls | Where-Object {
            $_.Method -eq 'GET' -and $_.Path -match '^/systemforms\?'
        })
        $systemFormReads.Count | Should -BeGreaterThan 0
        @($systemFormReads.Path | Where-Object { $_ -match '_solutionid_value' }) |
            Should -BeNullOrEmpty
    }

    It 'queries roles only through supported Web API properties' {
        Invoke-InsuranceFoundationReconciliation -Contract $script:contract -Scope All -Confirm:$false

        $roleReads = @($script:calls | Where-Object {
            $_.Method -eq 'GET' -and $_.Path -match '^/roles\?'
        })
        $roleReads.Count | Should -BeGreaterThan 0
        @($roleReads.Path | Where-Object { $_ -match '_solutionid_value' }) |
            Should -BeNullOrEmpty
    }

    It 'verifies saved-query ownership through solution component membership' {
        Mock Invoke-DataverseRequest {
            return [pscustomobject]@{
                value = @([pscustomobject]@{
                    solutionid = [pscustomobject]@{ uniquename = 'crmshow_DataModel' }
                })
            }
        }

        Assert-SolutionOwnership `
            ([pscustomobject]@{ savedqueryid = '11111111-1111-1111-1111-111111111111' }) `
            'crmshow_DataModel' 'existing view'
    }

    It 'verifies role ownership through solution component membership' {
        $script:ownershipPath = $null
        Mock Invoke-DataverseRequest {
            param($Method, $Path)
            $script:ownershipPath = $Path
            return [pscustomobject]@{
                value = @([pscustomobject]@{
                    solutionid = [pscustomobject]@{ uniquename = 'crmshow_DataModel' }
                })
            }
        }

        Assert-SolutionOwnership `
            ([pscustomobject]@{ roleid = '11111111-1111-1111-1111-111111111111' }) `
            'crmshow_DataModel' 'existing role'

        $script:ownershipPath | Should -Match (
            'objectid eq 11111111-1111-1111-1111-111111111111'
        )

        Should -Invoke Invoke-DataverseRequest -Times 1 -Exactly -ParameterFilter {
            $Method -eq 'GET' -and
            $Path -match 'solutioncomponents' -and
            $Path -match 'objectid eq 11111111-1111-1111-1111-111111111111'
        }
    }

    It 'inherits alternate-key ownership from the already-verified parent table' {
        $keyRequest = Get-AlternateKeyRequest `
            -TableLogicalName 'crmshow_accountcontactrole' `
            -Columns @('crmshow_accountid') `
            -SchemaName 'crmshow_testkey'
        $keyRequest.InheritsSolutionOwnership | Should -BeTrue

        Mock Invoke-DataverseRequest {
            return [pscustomobject]@{
                value = @([pscustomobject]@{
                    MetadataId = '22222222-2222-2222-2222-222222222222'
                    SchemaName = 'crmshow_testkey'
                    KeyAttributes = @('crmshow_accountid')
                })
            }
        }

        Invoke-ChildRequestIfMissing -QueryPath '/key-query' `
            -Request $keyRequest -Component 'existing key' `
            -AssertCompatible {
                param($actual)
                @($actual.KeyAttributes) | Should -Be @('crmshow_accountid')
            }

        Should -Invoke Invoke-DataverseRequest -Times 0 -Exactly -ParameterFilter {
            $Method -eq 'GET' -and $Path -match '^/solutioncomponents\?'
        }
    }

    It 'continues after all five choices already exist and creates schema components' {
        $script:choicesExist = $true

        Invoke-InsuranceFoundationReconciliation -Contract $script:contract `
            -Scope All -Confirm:$false | Out-Null

        @($script:calls | Where-Object {
            $_.Method -ne 'GET' -and
            $_.Path -like '/GlobalOptionSetDefinitions*'
        }) | Should -BeNullOrEmpty
        @($script:calls | Where-Object {
            $_.Method -eq 'GET' -and
            $_.Path -match '/Attributes/Microsoft\.Dynamics\.CRM\.PicklistAttributeMetadata\?'
        }).Count | Should -BeGreaterOrEqual 2
        @($script:calls | Where-Object {
            $_.Method -eq 'POST' -and
            $_.Path -match "EntityDefinitions\(LogicalName='(?:account|contact)'\)/Attributes$"
        }).Count | Should -Be 2
        @($script:calls | Where-Object {
            $_.Method -eq 'POST' -and $_.Path -eq '/EntityDefinitions'
        }).Count | Should -Be 3
    }

    It 'publishes the Customer table, confirms visibility, and creates the relationship once' {
        $script:choicesExist = $true
        Invoke-InsuranceFoundationReconciliation -Contract $script:contract -Scope DataModel -Confirm:$false
        $tableCreate = @($script:calls | Where-Object {
            $_.Method -eq 'POST' -and
            $_.Path -eq '/EntityDefinitions' -and
            $_.Body.LogicalName -eq 'crmshow_policypartyrole'
        })[0]
        $initialPublish = @($script:calls | Where-Object {
            $_.Method -eq 'POST' -and
            $_.Path -eq '/PublishXml' -and
            $_.Sequence -gt $tableCreate.Sequence
        })[0]
        $customerCreate = @($script:calls | Where-Object {
            $_.Method -eq 'POST' -and $_.Path -eq '/CreateCustomerRelationships'
        })
        $customerVisibilityReads = @($script:calls | Where-Object {
            $_.Method -eq 'SNAPSHOT' -and
            $_.Path -like 'crmshow_policypartyrole*' -and
            $_.Sequence -gt $initialPublish.Sequence -and
            $_.Sequence -lt $customerCreate[0].Sequence
        })
        $finalPublish = @($script:calls | Where-Object {
            $_.Method -eq 'POST' -and
            $_.Path -eq '/PublishXml' -and
            $_.Sequence -gt $customerCreate[0].Sequence
        })[0]

        $initialPublish.Sequence | Should -BeGreaterThan $tableCreate.Sequence
        $customerCreate.Count | Should -Be 1
        $customerVisibilityReads.Count | Should -BeGreaterThan 0
        $customerCreate[0].Sequence |
            Should -BeGreaterThan $customerVisibilityReads[-1].Sequence
        $finalPublish.Sequence |
            Should -BeGreaterThan $customerCreate[0].Sequence
    }

    It 'recovers an interrupted Customer relationship create on rerun' {
        $table = $script:contract.tables[2] |
            ConvertTo-Json -Depth 100 | ConvertFrom-Json
        $table.alternateKeys = @()
        $table.businessRules = @()
        $table.views = @()
        $table.forms = @()
        $script:tableExists = $false
        $script:customerCreateAttempts = 0

        Mock Start-Sleep {}
        Mock Get-TableExistenceSnapshot {
            param($LogicalName)
            if ($LogicalName -ne $table.logicalName -or
                -not $script:tableExists) {
                return $null
            }
            return [pscustomobject]@{
                MetadataId = 'existing-table'
                LogicalName = $LogicalName
                SchemaName = $table.schemaName
            }
        }
        Mock Get-TableMetadataSnapshot {
            param($LogicalName, $RequestedAttributeLogicalNames)
            if ($LogicalName -ne $table.logicalName -or
                -not $script:tableExists) {
                return $null
            }
            return New-TableMetadataSnapshot -Table $table `
                -IncludeCustomerRelationships:(
                    $script:customerCreateAttempts -ge 2
                )
        }
        Mock Wait-TableMetadataSnapshot {
            param($Table, $Component, $Ready, $RequestedAttributeLogicalNames)
            $snapshot = Get-TableMetadataSnapshot $Table.logicalName
            $script:calls.Add([pscustomobject]@{
                Sequence=$script:calls.Count + 1
                Method='SNAPSHOT'; Path=$Component; Body=$snapshot
                Headers=$null
            })
            if ($Ready -and -not (& $Ready $snapshot)) {
                return $null
            }
            return $snapshot
        }
        Mock Invoke-DataverseRequest {
            param($Method, $Path, $Body, $Headers)
            $script:calls.Add([pscustomobject]@{
                Sequence=$script:calls.Count + 1
                Method=$Method; Path=$Path; Body=$Body; Headers=$Headers
            })
            if ($Method -eq 'GET' -and
                $Path -like "/GlobalOptionSetDefinitions(Name='*") {
                return [pscustomobject]@{
                    MetadataId='11111111-1111-1111-1111-111111111111'
                }
            }
            if ($Method -eq 'POST' -and $Path -eq '/EntityDefinitions') {
                $script:tableExists = $true
                return [pscustomobject]@{}
            }
            if ($Method -eq 'POST' -and $Path -eq '/CreateCustomerRelationships') {
                $script:customerCreateAttempts++
                if ($script:customerCreateAttempts -eq 1) {
                    throw 'simulated interruption'
                }
                return [pscustomobject]@{}
            }
            if ($Method -eq 'GET') { throw "Unsupported mocked endpoint: $Path" }
            return [pscustomobject]@{}
        }

        { Invoke-TableReconciliation $table } |
            Should -Throw '*simulated interruption*'
        $beforeRecovery = $script:calls.Count
        { Invoke-TableReconciliation $table } | Should -Not -Throw

        $recoveryMutations = @($script:calls[$beforeRecovery..($script:calls.Count - 1)] |
            Where-Object { $_.Method -in @('POST', 'PATCH', 'PUT') })
        $recoveryMutations[0].Path | Should -Be '/CreateCustomerRelationships'
        $recoveryMutations[1].Path | Should -Be '/PublishXml'
        @($script:calls | Where-Object {
            $_.Method -eq 'POST' -and $_.Path -eq '/EntityDefinitions'
        }).Count | Should -Be 1
        @($script:calls | Where-Object {
            $_.Method -eq 'POST' -and
            $_.Path -eq '/CreateCustomerRelationships'
        }).Count | Should -Be 2
    }

    It 'rejects conflicting partial Customer metadata instead of retrying' {
        $table = $script:contract.tables[2]
        $column = $table.columns | Where-Object logicalName -eq 'crmshow_partyid'
        Mock Invoke-DataverseRequest {
            param($Method, $Path, $Body, $Headers)
            $script:calls.Add([pscustomobject]@{
                Method=$Method; Path=$Path; Body=$Body; Headers=$Headers
            })
            if ($Method -eq 'GET' -and
                $Path -match '/Attributes/Microsoft\.Dynamics\.CRM\.LookupAttributeMetadata') {
                return [pscustomobject]@{ value=@() }
            }
            if ($Method -eq 'GET' -and $Path -match '/ManyToOneRelationships\?') {
                return [pscustomobject]@{ value=@([pscustomobject]@{
                    SchemaName='crmshow_PolicyPartyRole_Party_account'
                    ReferencedEntity='account'
                    ReferencingEntity=$table.logicalName
                    ReferencingAttribute=$column.logicalName
                }) }
            }
            throw "Unsupported mocked endpoint: $Method $Path"
        }

        { Invoke-ExistingCustomerRelationshipReconciliation $table $column } |
            Should -Throw '*Customer lookup conflict*automatic recovery requires no partial metadata*'
        @($script:calls | Where-Object {
            $_.Method -eq 'POST' -and
            $_.Path -eq '/CreateCustomerRelationships'
        }) | Should -BeNullOrEmpty
    }

    It 'reapplies all localized form and view fields on existing components' {
        $table = $script:contract.tables[0]
        $requests = @(
            (New-ViewRequest $table $table.views[0] 10427),
            (New-FormRequest $table $table.forms[0])
        )
        foreach ($request in $requests) {
            $request.InheritsSolutionOwnership | Should -BeTrue
            $script:calls.Clear()
            $id = if ($request.EntityLogicalName -eq 'savedquery') {
                'existing-view'
            } else { 'existing-form' }
            $existing = [pscustomobject]@{
                name=[string]$request.LocalizedFields.name.'1033'
                description=[string]$request.LocalizedFields.description.'1033'
            }
            $existing | Add-Member NoteProperty $request.IdProperty $id
            foreach ($xmlProperty in 'fetchxml', 'layoutxml', 'formxml') {
                if ($request.Body.ContainsKey($xmlProperty)) {
                    $existing | Add-Member NoteProperty $xmlProperty `
                        $request.Body[$xmlProperty]
                }
            }
            Mock Invoke-DataverseRequest {
                param($Method, $Path, $Body, $Headers)
                $script:calls.Add([pscustomobject]@{
                    Method=$Method; Path=$Path; Body=$Body; Headers=$Headers
                })
                if ($Method -eq 'GET') {
                    return [pscustomobject]@{ value=@($existing) }
                }
                return [pscustomobject]@{}
            }

            Invoke-ChildRequestIfMissing -QueryPath '/component-query' `
                -Request $request -Component 'localized component' `
                -AssertCompatible {
                    param($actual)
                    foreach ($xmlProperty in 'fetchxml', 'layoutxml', 'formxml') {
                        if ($request.Body.ContainsKey($xmlProperty)) {
                            Assert-XmlCompatible $actual $request $xmlProperty `
                                'localized component'
                        }
                    }
                } | Out-Null

            $repairs = @($script:calls | Where-Object Path -eq '/SetLocLabels')
            $repairs.Count | Should -Be 2
            foreach ($repair in $repairs) {
                @($repair.Body.Labels.LanguageCode) |
                    Should -Be @(1033, 1031, 1036, 1040)
            }
            @($script:calls | Where-Object {
                $_.Method -eq 'GET' -and $_.Path -match '^/solutioncomponents\?'
            }) | Should -BeNullOrEmpty
        }
    }

    It 'uses the complete deterministic mutation order' {
        Invoke-InsuranceFoundationReconciliation -Contract $script:contract -Scope All -Confirm:$false |
            Out-Null
        $actual = @($script:calls | Where-Object {
            $_.Method -in @('POST', 'PATCH', 'PUT')
        } | ForEach-Object Path)
        $expected = @(
            '/GlobalOptionSetDefinitions','/GlobalOptionSetDefinitions',
            '/GlobalOptionSetDefinitions','/GlobalOptionSetDefinitions',
            '/GlobalOptionSetDefinitions',
            "/EntityDefinitions(LogicalName='account')/Attributes",
            "/EntityDefinitions(LogicalName='contact')/Attributes",
            '/EntityDefinitions','/PublishXml','/PublishXml',
            "/EntityDefinitions(LogicalName='crmshow_accountcontactrole')/Keys",
            '/savedqueries','/SetLocLabels','/SetLocLabels',
            '/savedqueries','/SetLocLabels','/SetLocLabels',
            '/savedqueries','/SetLocLabels','/SetLocLabels',
            '/systemforms','/SetLocLabels','/SetLocLabels',
            '/EntityDefinitions','/PublishXml','/PublishXml',
            "/EntityDefinitions(LogicalName='crmshow_policyprojection')/Keys",
            '/savedqueries','/SetLocLabels','/SetLocLabels',
            '/savedqueries','/SetLocLabels','/SetLocLabels',
            '/systemforms','/SetLocLabels','/SetLocLabels',
            '/EntityDefinitions','/PublishXml','/CreateCustomerRelationships',
            '/PublishXml',
            "/EntityDefinitions(LogicalName='crmshow_policypartyrole')/Keys",
            '/savedqueries','/SetLocLabels','/SetLocLabels',
            '/savedqueries','/SetLocLabels','/SetLocLabels',
            '/savedqueries','/SetLocLabels','/SetLocLabels',
            '/systemforms','/SetLocLabels','/SetLocLabels',
            '/roles','/SetLocLabels','/SetLocLabels',
            '/roles(new-role)/Microsoft.Dynamics.CRM.AddPrivilegesRole',
            '/roles','/SetLocLabels','/SetLocLabels',
            '/roles(new-role)/Microsoft.Dynamics.CRM.AddPrivilegesRole',
            '/PublishAllXml'
        )
        $actual | Should -Be $expected
    }

    It 'reports deferred business rules and never schedules workflow mutation' {
        $script:choicesExist = $true
        $messages = @(Invoke-InsuranceFoundationReconciliation -Contract $script:contract `
            -Scope DataModel -Confirm:$false)
        @($messages | Where-Object { $_ -like '*Deferred: OR-001/#9*' }).Count | Should -Be 3
        @($script:calls | Where-Object {
            $_.Path -match 'workflow' -or $_.Body.xaml -or $_.Body.clientdata
        }) | Should -BeNullOrEmpty
    }

    It 'does not recreate compatible existing choices' {
        $desiredChoice = (New-ChoiceRequest $script:contract.choices[0]).Body
        Mock Invoke-DataverseRequest {
            param($Method, $Path, $Body, $Headers)
            $script:calls.Add([pscustomobject]@{
                Method = $Method; Path = $Path; Body = $Body; Headers = $Headers
            })
            if ($Method -eq 'GET' -and $Path -like "/GlobalOptionSetDefinitions*") {
                return [pscustomobject]@{
                    Name = 'crmshow_accounttype'
                    '@odata.type' = 'Microsoft.Dynamics.CRM.OptionSetMetadata'
                    MetadataId = 'choice-metadata-id'
                    IsGlobal = $true; OptionSetType = 'Picklist'
                    SolutionUniqueName = 'crmshow_Foundation'
                    DisplayName = $desiredChoice.DisplayName
                    Description = $desiredChoice.Description
                    Options = $desiredChoice.Options
                }
            }
            if ($Method -eq 'GET') { throw "Unsupported mocked endpoint: $Path" }
            return [pscustomobject]@{}
        }
        $oneChoice = $script:contract | ConvertTo-Json -Depth 100 | ConvertFrom-Json
        $oneChoice.choices = @($oneChoice.choices[0])
        $oneChoice.nativeExtensions = @()
        $oneChoice.tables = @()
        $oneChoice.roles = @()

        Invoke-InsuranceFoundationReconciliation -Contract $oneChoice -Scope Foundation -Confirm:$false
        $reads = @($script:calls | Where-Object {
            $_.Method -eq 'GET' -and $_.Path -like '/GlobalOptionSetDefinitions*'
        })
        $reads.Count | Should -Be 1
        $reads[0].Path | Should -Be (
            "/GlobalOptionSetDefinitions(Name='crmshow_accounttype')/" +
            'Microsoft.Dynamics.CRM.OptionSetMetadata'
        )
        @($script:calls | Where-Object {
            $_.Method -ne 'GET' -and $_.Path -like '/GlobalOptionSetDefinitions*'
        }) | Should -BeNullOrEmpty
    }

    It 'throws rather than replacing a structural conflict' {
        Mock Invoke-DataverseRequest {
            param($Method, $Path, $Body, $Headers)
            $script:calls.Add([pscustomobject]@{
                Method=$Method; Path=$Path; Body=$Body; Headers=$Headers
            })
            if ($Method -eq 'GET' -and $Path -like "/EntityDefinitions*") {
                return [pscustomobject]@{
                    value = @([pscustomobject]@{
                        LogicalName = 'crmshow_accountcontactrole'
                        OwnershipType = 'OrganizationOwned'
                        IsAuditEnabled = [pscustomobject]@{ Value = $true }
                        SolutionUniqueName = 'crmshow_DataModel'
                        Attributes = @()
                    })
                }
            }
            return [pscustomobject]@{ value = @() }
        }
        $oneTable = $script:contract | ConvertTo-Json -Depth 100 | ConvertFrom-Json
        $oneTable.tables = @($oneTable.tables[0])
        $oneTable.nativeExtensions = @()

        { Invoke-InsuranceFoundationReconciliation -Contract $oneTable -Scope DataModel -Confirm:$false } |
            Should -Throw '*ownership*'
        @($script:calls | Where-Object Method -ne 'GET') |
            Should -BeNullOrEmpty
    }

    It 'does not recreate a compatible existing table or its lookups' {
        $table = $script:contract.tables[0]
        Mock Invoke-DataverseRequest {
            param($Method, $Path, $Body, $Headers)
            $script:calls.Add([pscustomobject]@{
                Method = $Method; Path = $Path; Body = $Body; Headers = $Headers
            })
            if ($Method -eq 'GET' -and $Path -match '^/EntityDefinitions\?') {
                return [pscustomobject]@{ value = @([pscustomobject]@{
                    MetadataId = 'compatible-table'
                    LogicalName = $table.logicalName
                    OwnershipType = 'UserOwned'
                    SolutionUniqueName = 'crmshow_DataModel'
                    DisplayName = ConvertTo-LocalizedLabel $table.metadata.label
                    Description = ConvertTo-LocalizedLabel $table.metadata.description
                    ManyToOneRelationships = @($table.relationships | ForEach-Object {
                        [pscustomobject]@{
                            SchemaName = $_.schemaName
                            ReferencedEntity = [string]$_.referencedTables[0]
                            ReferencingEntity = $table.logicalName
                            ReferencingAttribute = $_.lookupColumn
                            CascadeConfiguration = [pscustomobject]@{
                                Assign='NoCascade'; Delete='Restrict'
                                Merge='Cascade'; Reparent='NoCascade'
                                Share='NoCascade'; Unshare='NoCascade'
                            }
                        }
                    })
                    Attributes = @($table.columns | ForEach-Object {
                        [pscustomobject]@{
                            MetadataId = "compatible-$($_.logicalName)"
                            LogicalName = $_.logicalName
                            SchemaName = $_.schemaName
                            AttributeType = @{
                                Text='String'; Lookup='Lookup'; GlobalChoice='Picklist'
                                DateOnly='DateTime'; DateTime='DateTime'; Customer='Customer'
                            }[$_.type]
                            DisplayName = ConvertTo-LocalizedLabel $_.metadata.label
                            Description = ConvertTo-LocalizedLabel $_.metadata.description
                        }
                    })
                }) }
            }
            if ($Method -eq 'GET' -and $Path -match 'ObjectTypeCode') {
                return [pscustomobject]@{ ObjectTypeCode = 10427 }
            }
            if ($Method -eq 'GET' -and
                $Path -match '/Attributes/Microsoft\.Dynamics\.CRM\.PicklistAttributeMetadata') {
                $column = $table.columns |
                    Where-Object logicalName -eq 'crmshow_roletype'
                return [pscustomobject]@{ value = @([pscustomobject]@{
                    MetadataId = "compatible-$($column.logicalName)"
                    LogicalName = $column.logicalName
                    SchemaName = $column.schemaName
                    AttributeType = 'Picklist'
                    GlobalOptionSet = [pscustomobject]@{ Name = $column.choice }
                    DisplayName = ConvertTo-LocalizedLabel $column.metadata.label
                    Description = ConvertTo-LocalizedLabel $column.metadata.description
                    SolutionUniqueName = $table.solution
                }) }
            }
            if ($Method -eq 'GET' -and
                $Path -match '/Attributes/Microsoft\.Dynamics\.CRM\.(String|DateTime|Lookup)AttributeMetadata') {
                $typeName = $Matches[1]
                $logicalName = [regex]::Match(
                    $Path, "LogicalName eq '([^']+)'"
                ).Groups[1].Value
                $column = $table.columns |
                    Where-Object logicalName -eq $logicalName
                $attributeType = @{
                    String='String'; DateTime='DateTime'; Lookup='Lookup'
                }[$typeName]
                return [pscustomobject]@{ value=@([pscustomobject]@{
                    MetadataId="compatible-$($column.logicalName)"
                    LogicalName=$column.logicalName
                    SchemaName=$column.schemaName
                    AttributeType=$attributeType
                    Targets=@($column.lookup.targets)
                    MaxLength=$column.maxLength
                    DateTimeBehavior=$(if ($column.type -eq 'DateOnly') {
                        @{ Value='DateOnly' }
                    } elseif ($column.type -eq 'DateTime') {
                        @{ Value='TimeZoneIndependent' }
                    })
                    Format=$(if ($column.type -eq 'DateOnly') {
                        'DateOnly'
                    } elseif ($column.type -eq 'DateTime') {
                        'DateAndTime'
                    })
                    DisplayName=ConvertTo-LocalizedLabel $column.metadata.label
                    Description=ConvertTo-LocalizedLabel $column.metadata.description
                }) }
            }
            if ($Method -eq 'GET' -and
                $Path -match '(?:/Keys\?|^/savedqueries\?|^/systemforms\?)') {
                return [pscustomobject]@{ value = @() }
            }
            if ($Method -eq 'GET') { throw "Unsupported mocked endpoint: $Path" }
            return [pscustomobject]@{}
        }
        $oneTable = $script:contract | ConvertTo-Json -Depth 100 | ConvertFrom-Json
        $oneTable.tables = @($table)
        $oneTable.nativeExtensions = @()

        Invoke-InsuranceFoundationReconciliation -Contract $oneTable -Scope DataModel -Confirm:$false
        @($script:calls | Where-Object {
            $_.Method -eq 'POST' -and
            $_.Path -in @('/EntityDefinitions', '/CreateCustomerRelationships')
        }) | Should -BeNullOrEmpty
        @($script:calls | Where-Object {
            $_.Method -eq 'GET' -and
            $_.Path -match '/Attributes/Microsoft\.Dynamics\.CRM\.PicklistAttributeMetadata\?'
        }).Count | Should -Be 1
        @($script:calls | Where-Object {
            $_.Method -eq 'GET' -and
            $_.Path -match '/Attributes/Microsoft\.Dynamics\.CRM\.(?:String|DateTime|Lookup)AttributeMetadata\?'
        }).Count | Should -Be 7
        @($script:calls | Where-Object {
            $_.Method -eq 'GET' -and
            $_.Path -match '\$expand=.*ManyToOneRelationships'
        }).Count | Should -Be 1
        @($script:calls | Where-Object {
            $_.Method -eq 'POST' -and $_.Path -eq '/PublishXml'
        }).Count | Should -Be 1
    }

    It 'rejects destructive cascade behavior on an existing ordinary relationship' {
        $table = $script:contract.tables[0] |
            ConvertTo-Json -Depth 100 | ConvertFrom-Json
        $table.columns = @($table.columns | Where-Object type -eq 'Lookup')
        $table.alternateKeys = @()
        $table.businessRules = @()
        $table.views = @()
        $table.forms = @()

        Mock Invoke-DataverseRequest {
            param($Method, $Path, $Body, $Headers)
            if ($Method -eq 'GET' -and $Path -match '^/EntityDefinitions\?') {
                return [pscustomobject]@{ value=@([pscustomobject]@{
                    MetadataId='existing-table'
                    LogicalName=$table.logicalName
                    OwnershipType=$table.ownership
                    SolutionUniqueName=$table.solution
                    DisplayName=ConvertTo-LocalizedLabel $table.metadata.label
                    Description=ConvertTo-LocalizedLabel $table.metadata.description
                    Attributes=@($table.columns | ForEach-Object {
                        [pscustomobject]@{
                            MetadataId="attribute-$($_.logicalName)"
                            LogicalName=$_.logicalName
                            SchemaName=$_.schemaName
                            AttributeType='Lookup'
                            DisplayName=ConvertTo-LocalizedLabel $_.metadata.label
                            Description=ConvertTo-LocalizedLabel $_.metadata.description
                        }
                    })
                    ManyToOneRelationships=@($table.relationships | ForEach-Object {
                        [pscustomobject]@{
                            SchemaName=$_.schemaName
                            ReferencedEntity=[string]$_.referencedTables[0]
                            ReferencingEntity=$table.logicalName
                            ReferencingAttribute=$_.lookupColumn
                            CascadeConfiguration=[pscustomobject]@{
                                Assign='NoCascade'; Delete='Cascade'
                                Merge='Cascade'; Reparent='NoCascade'
                                Share='NoCascade'; Unshare='NoCascade'
                            }
                        }
                    })
                }) }
            }
            if ($Method -eq 'GET' -and
                $Path -match '/Attributes/Microsoft\.Dynamics\.CRM\.LookupAttributeMetadata') {
                $logicalName = [regex]::Match(
                    $Path, "LogicalName eq '([^']+)'"
                ).Groups[1].Value
                $column = $table.columns |
                    Where-Object logicalName -eq $logicalName
                return [pscustomobject]@{ value=@([pscustomobject]@{
                    MetadataId="attribute-$($column.logicalName)"
                    LogicalName=$column.logicalName
                    SchemaName=$column.schemaName
                    AttributeType='Lookup'
                    Targets=@($column.lookup.targets)
                    DisplayName=ConvertTo-LocalizedLabel $column.metadata.label
                    Description=ConvertTo-LocalizedLabel $column.metadata.description
                }) }
            }
            if ($Method -eq 'GET' -and $Path -match 'ObjectTypeCode') {
                return [pscustomobject]@{ ObjectTypeCode=10427 }
            }
            if ($Method -eq 'GET' -and
                $Path -match '(?:/Keys\?|^/savedqueries\?|^/systemforms\?)') {
                return [pscustomobject]@{ value=@() }
            }
            if ($Method -eq 'GET') { throw "Unsupported mocked endpoint: $Path" }
            return [pscustomobject]@{}
        }

        { Invoke-TableReconciliation $table } |
            Should -Throw '*cascade conflict*Delete*'
    }

    It 'rejects incomplete ordinary relationship endpoint metadata' {
        $table = $script:contract.tables[0] |
            ConvertTo-Json -Depth 100 | ConvertFrom-Json
        $table.columns = @($table.columns | Where-Object type -eq 'Lookup')
        $table.alternateKeys = @()
        $table.businessRules = @()
        $table.views = @()
        $table.forms = @()

        Mock Invoke-DataverseRequest {
            param($Method, $Path, $Body, $Headers)
            if ($Method -eq 'GET' -and $Path -match '^/EntityDefinitions\?') {
                return [pscustomobject]@{ value=@([pscustomobject]@{
                    MetadataId='existing-table'
                    LogicalName=$table.logicalName
                    OwnershipType=$table.ownership
                    SolutionUniqueName=$table.solution
                    DisplayName=ConvertTo-LocalizedLabel $table.metadata.label
                    Description=ConvertTo-LocalizedLabel $table.metadata.description
                    Attributes=@($table.columns | ForEach-Object {
                        [pscustomobject]@{
                            MetadataId="attribute-$($_.logicalName)"
                            LogicalName=$_.logicalName
                            SchemaName=$_.schemaName
                            AttributeType='Lookup'
                        }
                    })
                    ManyToOneRelationships=@($table.relationships | ForEach-Object {
                        [pscustomobject]@{
                            SchemaName=$_.schemaName
                            ReferencedEntity=$null
                            ReferencingEntity=$table.logicalName
                            ReferencingAttribute=$_.lookupColumn
                            CascadeConfiguration=[pscustomobject]@{
                                Assign='NoCascade'; Delete='Restrict'
                                Merge='NoCascade'; Reparent='NoCascade'
                                Share='NoCascade'; Unshare='NoCascade'
                            }
                        }
                    })
                }) }
            }
            if ($Method -eq 'GET' -and
                $Path -match '/Attributes/Microsoft\.Dynamics\.CRM\.LookupAttributeMetadata') {
                $logicalName = [regex]::Match(
                    $Path, "LogicalName eq '([^']+)'"
                ).Groups[1].Value
                $column = $table.columns |
                    Where-Object logicalName -eq $logicalName
                return [pscustomobject]@{ value=@([pscustomobject]@{
                    MetadataId="attribute-$($column.logicalName)"
                    LogicalName=$column.logicalName
                    SchemaName=$column.schemaName
                    AttributeType='Lookup'
                    Targets=@($column.lookup.targets)
                }) }
            }
            if ($Method -eq 'GET' -and $Path -match 'ObjectTypeCode') {
                return [pscustomobject]@{ ObjectTypeCode=10427 }
            }
            if ($Method -eq 'GET' -and
                $Path -match '(?:/Keys\?|^/savedqueries\?|^/systemforms\?)') {
                return [pscustomobject]@{ value=@() }
            }
            if ($Method -eq 'GET') { throw "Unsupported mocked endpoint: $Path" }
            return [pscustomobject]@{}
        }

        { Invoke-TableReconciliation $table } |
            Should -Throw '*target conflict*'
    }

    It 'binds a missing choice column on an existing table by metadata ID' {
        $table = $script:contract.tables[0] |
            ConvertTo-Json -Depth 100 | ConvertFrom-Json
        $choiceColumn = $table.columns |
            Where-Object type -eq 'GlobalChoice' | Select-Object -First 1
        $table.columns = @($choiceColumn)
        $table.relationships = @()
        $table.alternateKeys = @()
        $table.businessRules = @()
        $table.views = @()
        $table.forms = @()
        $metadataId = '22222222-2222-2222-2222-222222222222'
        $script:tableSnapshotReads = 0

        Mock Get-TableExistenceSnapshot {
            param($LogicalName)
            return [pscustomobject]@{
                MetadataId = 'existing-table'
                LogicalName = $LogicalName
                SchemaName = $table.schemaName
            }
        }
        Mock Wait-TableMetadataSnapshot {
            param($Table, $Component, $Ready, $RequestedAttributeLogicalNames)
            $script:tableSnapshotReads++
            $snapshot = switch ($script:tableSnapshotReads) {
                1 {
                    New-TableMetadataSnapshot -Table $table `
                        -OmitColumns @($choiceColumn.logicalName)
                }
                default { New-TableMetadataSnapshot -Table $table }
            }
            $script:calls.Add([pscustomobject]@{
                Method = 'SNAPSHOT'
                Path = $Component
                Body = $snapshot
                Headers = $null
                RequestedAttributeLogicalNames = @(
                    $RequestedAttributeLogicalNames
                )
            })
            if ($Ready -and -not (& $Ready $snapshot)) {
                return $null
            }
            return $snapshot
        }
        Mock Invoke-DataverseRequest {
            param($Method, $Path, $Body, $Headers)
            $script:calls.Add([pscustomobject]@{
                Method=$Method; Path=$Path; Body=$Body; Headers=$Headers
            })
            if ($Method -eq 'GET' -and
                $Path -like "/GlobalOptionSetDefinitions(Name='*") {
                return [pscustomobject]@{ MetadataId=$metadataId }
            }
            if ($Method -eq 'GET') { throw "Unsupported mocked endpoint: $Path" }
            return [pscustomobject]@{}
        }

        Invoke-TableReconciliation $table | Out-Null

        $create = @($script:calls | Where-Object {
            $_.Method -eq 'POST' -and
            $_.Path -eq (
                "/EntityDefinitions(LogicalName='$($table.logicalName)')/Attributes"
            )
        })
        $create.Count | Should -Be 1
        $create[0].Body.'GlobalOptionSet@odata.bind' |
            Should -Be "/GlobalOptionSetDefinitions($metadataId)"
        $script:tableSnapshotReads | Should -Be 2
    }

    It 'throws on lookup target and alternate-key structural conflicts' {
        $column = $script:contract.tables[0].columns |
            Where-Object logicalName -eq 'crmshow_accountid'
        {
            Test-AttributeCompatibility ([pscustomobject]@{
                AttributeType = 'Lookup'; Targets = @('contact')
            }) $column 'crmshow_accountcontactrole'
        } | Should -Throw '*target conflict*'

        Mock Invoke-DataverseRequest {
            param($Method, $Path, $Body, $Headers)
            if ($Method -eq 'GET' -and $Path -match '/Keys\?') {
                return [pscustomobject]@{ value = @([pscustomobject]@{
                    SchemaName = 'crmshow_AccountContactRoleIdentity'
                    KeyAttributes = @('crmshow_sourceid')
                    SolutionUniqueName = 'crmshow_DataModel'
                }) }
            }
            return [pscustomobject]@{ value = @() }
        }
        {
            Invoke-TableChildren $script:contract.tables[0] 10427
        } | Should -Throw '*key conflict*Actual: crmshow_sourceid*Expected:*'
    }

    It 'accepts alternate-key attributes returned in platform order' {
        $table = $script:contract.tables[1] |
            ConvertTo-Json -Depth 100 | ConvertFrom-Json
        $table.businessRules = @()
        $table.views = @()
        $table.forms = @()
        Mock Invoke-DataverseRequest {
            return [pscustomobject]@{ value = @([pscustomobject]@{
                SchemaName = $table.alternateKeys[0].schemaName
                KeyAttributes = @('crmshow_externalid', 'crmshow_externalsystem')
            }) }
        }

        {
            Invoke-TableChildren $table 10427
        } | Should -Not -Throw
    }

    It 'throws on type and global-choice binding conflicts' {
        {
            Test-AttributeCompatibility ([pscustomobject]@{ AttributeType = 'String' }) `
                $script:contract.nativeExtensions[0] 'account'
        } | Should -Throw '*type conflict*'
        {
            Test-AttributeCompatibility ([pscustomobject]@{
                AttributeType = 'Picklist'
                GlobalOptionSet = [pscustomobject]@{ Name = 'crmshow_wrongchoice' }
            }) $script:contract.nativeExtensions[0] 'account'
        } | Should -Throw '*choice-binding conflict*'
    }

    It 'throws when typed native choice metadata has a conflicting binding' {
        $extension = $script:contract.nativeExtensions[0]
        Mock Invoke-DataverseRequest {
            param($Method, $Path, $Body, $Headers)
            $script:calls.Add([pscustomobject]@{
                Method=$Method; Path=$Path; Body=$Body; Headers=$Headers
            })
            if ($Method -eq 'GET' -and
                $Path -match '/Attributes/Microsoft\.Dynamics\.CRM\.PicklistAttributeMetadata\?') {
                return [pscustomobject]@{ value=@([pscustomobject]@{
                    MetadataId='native-choice'
                    LogicalName=$extension.logicalName
                    AttributeType='Picklist'
                    GlobalOptionSet=[pscustomobject]@{ Name='crmshow_wrongchoice' }
                    SolutionUniqueName=$extension.solution
                }) }
            }
            throw "Unsupported mocked endpoint: $Method $Path"
        }

        { Invoke-NativeExtensionReconciliation $extension } |
            Should -Throw '*choice-binding conflict*'
        $script:calls[0].Path | Should -Match (
            '/Attributes/Microsoft\.Dynamics\.CRM\.PicklistAttributeMetadata\?'
        )
    }

    It 'rejects UserLocal date metadata for the UTC contract' {
        $column = $script:contract.tables[1].columns |
            Where-Object type -eq 'DateTime' | Select-Object -First 1
        {
            Test-AttributeCompatibility ([pscustomobject]@{
                AttributeType = 'DateTime'
                DateTimeBehavior = @{ Value = 'UserLocal' }
                Format = 'DateAndTime'
            }) $column 'crmshow_policyprojection'
        } | Should -Throw '*date metadata conflict*TimeZoneIndependent*UserLocal*'
    }

    It 'rejects stale view and form XML rather than overwriting it' {
        $table = $script:contract.tables[0]
        $requests = @(
            @{ Request = New-ViewRequest $table $table.views[0] 10427
               Property = 'fetchxml' },
            @{ Request = New-ViewRequest $table $table.views[0] 10427
               Property = 'layoutxml' },
            @{ Request = New-FormRequest $table $table.forms[0]
               Property = 'formxml' }
        )
        foreach ($case in $requests) {
            $existing = [pscustomobject]@{ $case.Property = '<stale />' }
            {
                Assert-XmlCompatible $existing $case.Request $case.Property 'component'
            } | Should -Throw '*Structural XML conflict*stale*'
        }
    }

    It 'includes comparable XML signatures when existing metadata is stale' {
        $table = $script:contract.tables[0]
        $request = New-ViewRequest $table $table.views[0] 10427
        $existing = [pscustomobject]@{ fetchxml = '<fetch><entity name="stale" /></fetch>' }

        {
            Assert-XmlCompatible $existing $request fetchxml 'component'
        } | Should -Throw '*Actual signature:*name=stale*Wanted signature:*'
    }

    It 'accepts the server-assigned saved-query ID in stored FetchXML' {
        $table = $script:contract.tables[0]
        $request = New-ViewRequest $table $table.views[0] 10427
        $storedFetchXml = $request.Body.fetchxml.Replace(
            '<fetch ',
            '<fetch savedqueryid="fd79983c-bf93-f111-8075-000d3a30c0f4" '
        )

        {
            Assert-XmlCompatible (
                [pscustomobject]@{ fetchxml = $storedFetchXml }
            ) $request fetchxml 'component'
        } | Should -Not -Throw
    }

    It 'accepts platform-normalized form IDs and localized field labels' {
        $request = [pscustomobject]@{
            Body = @{
                formxml = @'
<form><tabs><tab name="general"><labels><label description="English" languagecode="1033" /><label description="Deutsch" languagecode="1031" /></labels><columns><column><sections><section name="general"><labels><label description="English" languagecode="1033" /><label description="Deutsch" languagecode="1031" /></labels><rows><row><cell><control id="crmshow_name" datafieldname="crmshow_name" /></cell></row></rows></section></sections></column></columns></tab></tabs></form>
'@
            }
        }
        $existing = [pscustomobject]@{
            formxml = @'
<form><tabs><tab name="general" id="{11111111-1111-1111-1111-111111111111}"><labels><label description="English" languagecode="1033" /></labels><columns><column><sections><section name="general" id="{22222222-2222-2222-2222-222222222222}"><labels><label description="English" languagecode="1033" /></labels><rows><row><cell><labels><label description="Name" languagecode="1033" /></labels><control id="crmshow_name" datafieldname="crmshow_name" /></cell></row></rows></section></sections></column></columns></tab></tabs></form>
'@
        }

        {
            Assert-XmlCompatible $existing $request formxml 'component'
        } | Should -Not -Throw
    }

    It 'updates an empty existing choice rather than treating it as unchanged' {
        $choice = $script:contract.choices[0]
        Mock Invoke-DataverseRequest {
            param($Method, $Path, $Body, $Headers)
            $script:calls.Add([pscustomobject]@{
                Method=$Method; Path=$Path; Body=$Body; Headers=$Headers
            })
            if ($Method -eq 'GET' -and $Path -like '/GlobalOptionSetDefinitions*') {
                return [pscustomobject]@{
                    '@odata.type'='Microsoft.Dynamics.CRM.OptionSetMetadata'
                    Name=$choice.logicalName; IsGlobal=$true
                    OptionSetType='Picklist'
                    MetadataId='empty-choice'; Options=@()
                    DisplayName=(ConvertTo-LocalizedLabel $choice.metadata.label)
                    Description=(ConvertTo-LocalizedLabel $choice.metadata.description)
                    SolutionUniqueName='crmshow_Foundation'
                }
            }
            if ($Method -eq 'GET') { throw "Unsupported mocked endpoint: $Path" }
            return [pscustomobject]@{}
        }
        $contract = $script:contract | ConvertTo-Json -Depth 100 | ConvertFrom-Json
        $contract.choices = @($contract.choices[0]); $contract.nativeExtensions = @()
        $contract.tables = @(); $contract.roles = @()
        Invoke-InsuranceFoundationReconciliation $contract Foundation -Confirm:$false | Out-Null
        @($script:calls | Where-Object Method -eq 'PUT') | Should -BeNullOrEmpty
        $insertions = @($script:calls | Where-Object Path -eq '/InsertOptionValue')
        @($insertions.Body.Value) | Should -Be @(100000000, 100000001, 100000002)
        foreach ($insertion in $insertions) {
            @($insertion.Body.Label.LocalizedLabels.LanguageCode) |
                Should -Be @(1033, 1031, 1036, 1040)
        }
    }

    It 'updates mutable localized choice metadata' {
        $choice = $script:contract.choices[0]
        $desired = (New-ChoiceRequest $choice).Body
        $wrongDisplay = $desired.DisplayName | ConvertTo-Json -Depth 20 | ConvertFrom-Json
        $wrongDisplay.LocalizedLabels[1].Label = 'Changed'
        Mock Invoke-DataverseRequest {
            param($Method, $Path, $Body, $Headers)
            $script:calls.Add([pscustomobject]@{
                Method=$Method; Path=$Path; Body=$Body; Headers=$Headers
            })
            if ($Method -eq 'GET' -and $Path -like '/GlobalOptionSetDefinitions*') {
                return [pscustomobject]@{
                    '@odata.type'='Microsoft.Dynamics.CRM.OptionSetMetadata'
                    Name=$choice.logicalName; IsGlobal=$true; MetadataId='localized-choice'
                    OptionSetType='Picklist'
                    ParentOptionSetName='read-only-parent'
                    IsCustomOptionSet=$true; IsManaged=$false; HasChanged=$false
                    Options=$desired.Options; DisplayName=$wrongDisplay
                    Description=$desired.Description; SolutionUniqueName='crmshow_Foundation'
                }
            }
            if ($Method -eq 'GET') { throw "Unsupported mocked endpoint: $Path" }
            return [pscustomobject]@{}
        }
        $contract = $script:contract | ConvertTo-Json -Depth 100 | ConvertFrom-Json
        $contract.choices = @($contract.choices[0]); $contract.nativeExtensions = @()
        $contract.tables = @(); $contract.roles = @()
        Invoke-InsuranceFoundationReconciliation $contract Foundation -Confirm:$false | Out-Null
        $update = @($script:calls | Where-Object Method -eq 'PUT')
        $update.Count | Should -Be 1
        $update[0].Path | Should -Be '/GlobalOptionSetDefinitions(localized-choice)'
        @($script:calls | Where-Object {
            $_.Method -eq 'GET' -and
            $_.Path -eq (
                '/GlobalOptionSetDefinitions(localized-choice)/' +
                'Microsoft.Dynamics.CRM.OptionSetMetadata'
            )
        }).Count | Should -Be 1
        $update[0].Headers.'MSCRM.MergeLabels' | Should -Be 'true'
        $update[0].Body.Name | Should -Be $choice.logicalName
        $update[0].Body.IsGlobal | Should -BeTrue
        $update[0].Body.OptionSetType | Should -Be 'Picklist'
        $update[0].Body.Contains('Options') | Should -BeFalse
        $update[0].Body.Contains('ParentOptionSetName') | Should -BeFalse
        $update[0].Body.Contains('IsCustomOptionSet') | Should -BeFalse
        $update[0].Body.Contains('IsManaged') | Should -BeFalse
        $update[0].Body.Contains('HasChanged') | Should -BeFalse
        $update[0].Body.Contains('SolutionUniqueName') | Should -BeFalse
    }

    It 'updates choice localization for missing or incorrect non-English option labels' {
        $choice = $script:contract.choices[0]
        $desired = (New-ChoiceRequest $choice).Body
        foreach ($language in 1031, 1036, 1040) {
            foreach ($mode in 'Missing', 'Incorrect') {
                $script:calls.Clear()
                $actualOptions = $desired.Options | ConvertTo-Json -Depth 20 | ConvertFrom-Json
                if ($mode -eq 'Missing') {
                    $actualOptions[0].Label.LocalizedLabels = @(
                        $actualOptions[0].Label.LocalizedLabels |
                            Where-Object LanguageCode -ne $language
                    )
                } else {
                    ($actualOptions[0].Label.LocalizedLabels |
                        Where-Object LanguageCode -eq $language).Label = 'Incorrect'
                }
                Mock Invoke-DataverseRequest {
                    param($Method, $Path, $Body, $Headers)
                    $script:calls.Add([pscustomobject]@{
                        Method=$Method; Path=$Path; Body=$Body; Headers=$Headers
                    })
                    if ($Method -eq 'GET' -and
                        $Path -like '/GlobalOptionSetDefinitions*') {
                        return [pscustomobject]@{
                            '@odata.type'='Microsoft.Dynamics.CRM.OptionSetMetadata'
                            Name=$choice.logicalName; IsGlobal=$true
                            OptionSetType='Picklist'
                            MetadataId='option-localization'; Options=$actualOptions
                            DisplayName=$desired.DisplayName
                            Description=$desired.Description
                            SolutionUniqueName='crmshow_Foundation'
                        }
                    }
                    if ($Method -eq 'GET') {
                        throw "Unsupported mocked endpoint: $Path"
                    }
                    return [pscustomobject]@{}
                }
                $contract = $script:contract |
                    ConvertTo-Json -Depth 100 | ConvertFrom-Json
                $contract.choices = @($contract.choices[0])
                $contract.nativeExtensions = @()
                $contract.tables = @()
                $contract.roles = @()
                Invoke-InsuranceFoundationReconciliation $contract Foundation `
                    -Confirm:$false | Out-Null
                @($script:calls | Where-Object Method -eq 'PUT') |
                    Should -BeNullOrEmpty
                $optionUpdate = @($script:calls | Where-Object {
                    $_.Method -eq 'POST' -and $_.Path -eq '/UpdateOptionValue'
                })
                $optionUpdate.Count | Should -Be 1
                $optionUpdate[0].Body.OptionSetName | Should -Be $choice.logicalName
                $optionUpdate[0].Body.Value | Should -Be 100000000
                @($optionUpdate[0].Body.Label.LocalizedLabels.LanguageCode) |
                    Should -Be @(1033, 1031, 1036, 1040)
            }
        }
    }

    It 'retrieves and parses role privileges through the documented function' {
        $role = $script:contract.roles[0]
        $roleId = '11111111-1111-1111-1111-111111111111'
        $expectedPath = "/RetrieveRolePrivilegesRole(RoleId=$roleId)"
        $schemaNames = @{
            account = 'Account'
            contact = 'Contact'
        }
        foreach ($table in $script:contract.tables) {
            $schemaNames[$table.logicalName] = $table.schemaName
        }
        $wantedNames = @($role.tablePrivileges | ForEach-Object {
            "prvRead$($schemaNames[$_.table])"
        })
        Mock Invoke-DataverseRequest {
            param($Method, $Path, $Body, $Headers)
            $script:calls.Add([pscustomobject]@{
                Method=$Method; Path=$Path; Body=$Body; Headers=$Headers
            })
            if ($Method -eq 'GET' -and $Path -like '/roles?*') {
                return [pscustomobject]@{ value = @([pscustomobject]@{
                    roleid=$roleId; name=$role.name
                    description=[string]$role.metadata.description.'1033'
                }) }
            }
            if ($Method -eq 'GET' -and $Path -like '/solutioncomponents?*') {
                return [pscustomobject]@{ value = @([pscustomobject]@{
                    solutionid = [pscustomobject]@{ uniquename = $role.solution }
                }) }
            }
            if ($Method -eq 'GET' -and
                $Path -match "^/EntityDefinitions\(LogicalName='([^']+)'\)") {
                $logicalName = $Matches[1]
                $schemaName = $schemaNames[$logicalName]
                return [pscustomobject]@{
                    LogicalName = $logicalName
                    SchemaName = $schemaName
                    Privileges = @([pscustomobject]@{
                        Name = "prvRead$schemaName"
                        PrivilegeId = [guid]::NewGuid().ToString()
                        PrivilegeType = 'Read'
                    })
                }
            }
            if ($Method -eq 'GET' -and $Path -eq $expectedPath) {
                return [pscustomobject]@{ RolePrivileges = @(
                    $wantedNames | ForEach-Object {
                        [pscustomobject]@{
                            PrivilegeId=[guid]::NewGuid().ToString()
                            PrivilegeName=$_
                            Depth='Global'
                        }
                    }
                ) }
            }
            if ($Method -eq 'GET') { throw "Unsupported mocked endpoint: $Path" }
            return [pscustomobject]@{}
        }

        Invoke-RoleReconciliation $role $script:contract | Out-Null

        @($script:calls | Where-Object {
            $_.Method -eq 'GET' -and $_.Path -eq $expectedPath
        }).Count | Should -Be 1
        @($script:calls | Where-Object {
            $_.Path -match '(?:Add|Replace)PrivilegesRole$'
        }) | Should -BeNullOrEmpty
        @($script:calls | Where-Object Path -like '/roleprivileges*') |
            Should -BeNullOrEmpty
        $localizationRepairs = @($script:calls |
            Where-Object Path -eq '/SetLocLabels')
        $localizationRepairs.Count | Should -Be 2
        foreach ($repair in $localizationRepairs) {
            @($repair.Body.Labels.LanguageCode) |
                Should -Be @(1033, 1031, 1036, 1040)
        }
        $wantedNames | Should -Contain 'prvReadcrmshow_PolicyProjection'
        ($wantedNames -ccontains 'prvReadcrmshow_policyprojection') |
            Should -BeFalse
    }

    It 'uses exact schema-cased privilege metadata in role mutation requests' {
        $role = $script:contract.roles[0] |
            ConvertTo-Json -Depth 100 | ConvertFrom-Json
        $role.tablePrivileges = @($role.tablePrivileges |
            Where-Object table -in @('account', 'crmshow_policyprojection'))
        $roleId = '22222222-2222-2222-2222-222222222222'
        $accountPrivilegeId = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'
        $policyPrivilegeId = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'

        Mock Invoke-DataverseRequest {
            param($Method, $Path, $Body, $Headers)
            $script:calls.Add([pscustomobject]@{
                Method=$Method; Path=$Path; Body=$Body; Headers=$Headers
            })
            if ($Method -eq 'GET' -and $Path -like '/roles?*') {
                return [pscustomobject]@{ value = @([pscustomobject]@{
                    roleid=$roleId; name=$role.name
                    description=[string]$role.metadata.description.'1033'
                }) }
            }
            if ($Method -eq 'GET' -and $Path -like '/solutioncomponents?*') {
                return [pscustomobject]@{ value = @([pscustomobject]@{
                    solutionid = [pscustomobject]@{ uniquename = $role.solution }
                }) }
            }
            if ($Method -eq 'GET' -and
                $Path -like "/EntityDefinitions(LogicalName='account')?*") {
                return [pscustomobject]@{
                    LogicalName='account'; SchemaName='Account'
                    Privileges=@([pscustomobject]@{
                        Name='prvReadAccount'; PrivilegeId=$accountPrivilegeId
                        PrivilegeType='Read'
                    })
                }
            }
            if ($Method -eq 'GET' -and
                $Path -like "/EntityDefinitions(LogicalName='crmshow_policyprojection')?*") {
                return [pscustomobject]@{
                    LogicalName='crmshow_policyprojection'
                    SchemaName='crmshow_PolicyProjection'
                    Privileges=@([pscustomobject]@{
                        Name='prvReadcrmshow_PolicyProjection'
                        PrivilegeId=$policyPrivilegeId; PrivilegeType='Read'
                    })
                }
            }
            if ($Method -eq 'GET' -and
                $Path -eq "/RetrieveRolePrivilegesRole(RoleId=$roleId)") {
                return [pscustomobject]@{ RolePrivileges=@() }
            }
            if ($Method -eq 'GET') { throw "Unsupported mocked endpoint: $Path" }
            return [pscustomobject]@{}
        }

        Invoke-RoleReconciliation $role $script:contract | Out-Null

        $request = @($script:calls | Where-Object {
            $_.Method -eq 'POST' -and
            $_.Path -like '*/Microsoft.Dynamics.CRM.AddPrivilegesRole'
        })
        $request.Count | Should -Be 1
        @($request[0].Body.Privileges.PrivilegeId) |
            Should -Be @($accountPrivilegeId, $policyPrivilegeId)
        @($script:calls | Where-Object Path -like '/privileges?*') |
            Should -BeNullOrEmpty
    }

    It 'validates referential integrity before transport' {
        $invalid = $script:contract | ConvertTo-Json -Depth 100 | ConvertFrom-Json
        $invalid.tables[0].relationships[0].lookupColumn = 'crmshow_missing'
        {
            Invoke-InsuranceFoundationReconciliation $invalid DataModel -Confirm:$false
        } | Should -Throw '*referentially invalid*'
        $script:calls.Count | Should -Be 0
    }
}

Describe 'Insurance Foundation table metadata convergence' {
    BeforeEach {
        $script:calls = [System.Collections.Generic.List[object]]::new()
        Mock Get-TableExistenceSnapshot { $null }
    }

    It 'waits for a newly created table snapshot before reconciling keys, views, and forms' {
        $table = $script:contract.tables[0] |
            ConvertTo-Json -Depth 100 | ConvertFrom-Json
        $table.columns = @($table.columns | Where-Object {
            $_.logicalName -in @('crmshow_name', 'crmshow_accountid')
        })
        $table.relationships = @($table.relationships | Where-Object {
            $_.lookupColumn -eq 'crmshow_accountid'
        })
        $table.alternateKeys = @($table.alternateKeys[0])
        $table.businessRules = @()
        $table.views = @($table.views[0])
        $table.forms = @($table.forms[0])
        $script:tableSnapshotReads = 0
        $script:visibleSnapshotSequence = $null

        Mock Start-Sleep {}
        Mock Get-TableMetadataSnapshot {
            param($LogicalName, $RequestedAttributeLogicalNames)
            $script:tableSnapshotReads++
            $snapshot = if ($script:tableSnapshotReads -lt 3) {
                $null
            } else {
                New-TableMetadataSnapshot -Table $table
            }
            $script:calls.Add([pscustomobject]@{
                Sequence = $script:calls.Count + 1
                Method = 'SNAPSHOT'
                Path = $LogicalName
                Body = $snapshot
                Headers = $null
            })
            if ($null -ne $snapshot) {
                $script:visibleSnapshotSequence = $script:calls[-1].Sequence
            }
            return $snapshot
        }
        Mock Invoke-DataverseRequest {
            param($Method, $Path, $Body, $Headers)
            $script:calls.Add([pscustomobject]@{
                Sequence = $script:calls.Count + 1
                Method = $Method; Path = $Path; Body = $Body; Headers = $Headers
            })
            if ($Method -eq 'GET' -and
                $Path -match '(?:/Keys\?|^/savedqueries\?|^/systemforms\?)') {
                return [pscustomobject]@{ value = @() }
            }
            if ($Method -eq 'POST' -and $Path -eq '/savedqueries') {
                return [pscustomobject]@{ savedqueryid = 'new-view' }
            }
            if ($Method -eq 'POST' -and $Path -eq '/systemforms') {
                return [pscustomobject]@{ formid = 'new-form' }
            }
            if ($Method -eq 'GET') { throw "Unsupported mocked endpoint: $Method $Path" }
            return [pscustomobject]@{}
        }

        Invoke-TableReconciliation $table | Out-Null

        $script:tableSnapshotReads | Should -BeGreaterThan 2
        $script:visibleSnapshotSequence | Should -Not -BeNullOrEmpty
        @($script:calls | Where-Object {
            $_.Method -eq 'POST' -and $_.Path -eq '/PublishXml'
        }).Count | Should -Be 2

        $keyCreate = @($script:calls | Where-Object {
            $_.Method -eq 'POST' -and
            $_.Path -eq "/EntityDefinitions(LogicalName='$($table.logicalName)')/Keys"
        })[0]
        $viewCreate = @($script:calls | Where-Object {
            $_.Method -eq 'POST' -and $_.Path -eq '/savedqueries'
        })[0]
        $formCreate = @($script:calls | Where-Object {
            $_.Method -eq 'POST' -and $_.Path -eq '/systemforms'
        })[0]

        $keyCreate.Sequence |
            Should -BeGreaterThan $script:visibleSnapshotSequence
        $viewCreate.Sequence |
            Should -BeGreaterThan $script:visibleSnapshotSequence
        $formCreate.Sequence |
            Should -BeGreaterThan $script:visibleSnapshotSequence
    }

    It 'awaits typed metadata for an already existing table before reconciling it' {
        $table = $script:contract.tables[0] |
            ConvertTo-Json -Depth 100 | ConvertFrom-Json
        $table.columns = @($table.columns | Where-Object {
            $_.logicalName -eq 'crmshow_name'
        })
        $table.relationships = @()
        $table.alternateKeys = @()
        $table.businessRules = @()
        $table.views = @()
        $table.forms = @()
        $script:expandedReads = 0
        $script:typedReads = 0

        Mock Start-Sleep {}
        Mock Get-TableExistenceSnapshot {
            param($LogicalName)
            $script:calls.Add([pscustomobject]@{
                Sequence = $script:calls.Count + 1
                Method = 'EXISTS'
                Path = $LogicalName
                Body = $null
                Headers = $null
            })
            return [pscustomobject]@{
                MetadataId = 'existing-table'
                LogicalName = $LogicalName
                SchemaName = $table.schemaName
            }
        }
        Mock Invoke-DataverseRequest {
            param($Method, $Path, $Body, $Headers)
            $script:calls.Add([pscustomobject]@{
                Sequence = $script:calls.Count + 1
                Method = $Method
                Path = $Path
                Body = $Body
                Headers = $Headers
            })
            if ($Method -eq 'GET' -and $Path -like '/EntityDefinitions?*' -and
                $Path -match '\$expand=Attributes') {
                $script:expandedReads++
                return [pscustomobject]@{
                    value = @(
                        New-TableMetadataSnapshot -Table $table
                    )
                }
            }
            if ($Method -eq 'GET' -and
                $Path -match '/Attributes/Microsoft\.Dynamics\.CRM\.StringAttributeMetadata') {
                $script:typedReads++
                if ($script:typedReads -eq 1) {
                    return [pscustomobject]@{ value = @() }
                }
                return New-TableTypedAttributeCollectionResponse `
                    -Table $table -TypeName 'StringAttributeMetadata' `
                    -AttributeLogicalName 'crmshow_name'
            }
            if ($Method -eq 'GET' -and
                $Path -match '(?:/Keys\?|^/savedqueries\?|^/systemforms\?)') {
                return [pscustomobject]@{ value = @() }
            }
            if ($Method -eq 'GET') {
                throw "Unsupported mocked endpoint: $Method $Path"
            }
            return [pscustomobject]@{}
        }

        Invoke-TableReconciliation $table | Out-Null

        @($script:calls | Where-Object Method -eq 'EXISTS').Count | Should -Be 1
        $script:calls[0].Method | Should -Be 'EXISTS'
        $script:expandedReads | Should -Be 2
        $script:typedReads | Should -Be 2
        @($script:calls | Where-Object {
            $_.Method -eq 'POST' -and $_.Path -eq '/EntityDefinitions'
        }) | Should -BeNullOrEmpty
        @($script:calls | Where-Object {
            $_.Method -eq 'POST' -and
            $_.Path -eq "/EntityDefinitions(LogicalName='$($table.logicalName)')/Attributes"
        }) | Should -BeNullOrEmpty
        @($script:calls | Where-Object {
            $_.Method -eq 'POST' -and $_.Path -eq '/PublishXml'
        }).Count | Should -Be 1
    }

    It 'waits for a newly created scalar attribute on an existing table before publishing and posting children' {
        $table = $script:contract.tables[0] |
            ConvertTo-Json -Depth 100 | ConvertFrom-Json
        $table.columns = @($table.columns | Where-Object {
            $_.logicalName -in @(
                'crmshow_name',
                'crmshow_accountid',
                'crmshow_contactid',
                'crmshow_roletype',
                'crmshow_validfrom'
            )
        })
        $table.relationships = @($table.relationships | Where-Object {
            $_.lookupColumn -in @('crmshow_accountid', 'crmshow_contactid')
        })
        $table.alternateKeys = @($table.alternateKeys[0])
        $table.businessRules = @()
        $table.views = @($table.views[0] |
            ConvertTo-Json -Depth 20 | ConvertFrom-Json)
        $table.views[0].columns = @(
            'crmshow_name',
            'crmshow_accountid',
            'crmshow_contactid',
            'crmshow_roletype',
            'crmshow_validfrom'
        )
        $table.forms = @($table.forms[0] |
            ConvertTo-Json -Depth 20 | ConvertFrom-Json)
        $table.forms[0].columns = @(
            'crmshow_name',
            'crmshow_accountid',
            'crmshow_contactid',
            'crmshow_roletype',
            'crmshow_validfrom'
        )
        $script:tableSnapshotReads = 0
        $script:firstPostCreateMissingSequence = $null
        $script:visibleValidFromSequence = $null

        Mock Start-Sleep {}
        Mock Get-TableExistenceSnapshot {
            param($LogicalName)
            $script:calls.Add([pscustomobject]@{
                Sequence = $script:calls.Count + 1
                Method = 'EXISTS'
                Path = $LogicalName
                Body = $null
                Headers = $null
            })
            return [pscustomobject]@{
                MetadataId = 'existing-table'
                LogicalName = $LogicalName
                SchemaName = $table.schemaName
            }
        }
        Mock Get-TableMetadataSnapshot {
            param($LogicalName, $RequestedAttributeLogicalNames)
            $script:tableSnapshotReads++
            $snapshot = switch ($script:tableSnapshotReads) {
                1 {
                    New-TableMetadataSnapshot -Table $table `
                        -OmitColumns @('crmshow_validfrom')
                }
                2 {
                    New-TableMetadataSnapshot -Table $table `
                        -OmitColumns @('crmshow_validfrom')
                }
                default { New-TableMetadataSnapshot -Table $table }
            }
            $script:calls.Add([pscustomobject]@{
                Sequence = $script:calls.Count + 1
                Method = 'SNAPSHOT'
                Path = $LogicalName
                Body = $snapshot
                Headers = $null
                RequestedAttributeLogicalNames = @(
                    $RequestedAttributeLogicalNames
                )
            })
            $hasValidFrom = $null -ne $snapshot -and
                @($snapshot.Attributes | Where-Object {
                    $_.LogicalName -eq 'crmshow_validfrom'
                }).Count -eq 1
            if ($script:tableSnapshotReads -eq 2 -and -not $hasValidFrom) {
                $script:firstPostCreateMissingSequence = `
                    $script:calls[-1].Sequence
            }
            if ($hasValidFrom -and
                $null -eq $script:visibleValidFromSequence) {
                $script:visibleValidFromSequence = `
                    $script:calls[-1].Sequence
            }
            return $snapshot
        }
        Mock Invoke-DataverseRequest {
            param($Method, $Path, $Body, $Headers)
            $script:calls.Add([pscustomobject]@{
                Sequence = $script:calls.Count + 1
                Method = $Method
                Path = $Path
                Body = $Body
                Headers = $Headers
            })
            if ($Method -eq 'GET' -and
                $Path -like "/GlobalOptionSetDefinitions(Name='*") {
                return [pscustomobject]@{
                    MetadataId = '11111111-1111-1111-1111-111111111111'
                }
            }
            if ($Method -eq 'GET' -and
                $Path -match '(?:/Keys\?|^/savedqueries\?|^/systemforms\?)') {
                return [pscustomobject]@{ value = @() }
            }
            if ($Method -eq 'POST' -and $Path -eq '/savedqueries') {
                return [pscustomobject]@{ savedqueryid = 'new-view' }
            }
            if ($Method -eq 'POST' -and $Path -eq '/systemforms') {
                return [pscustomobject]@{ formid = 'new-form' }
            }
            if ($Method -eq 'GET') {
                throw "Unsupported mocked endpoint: $Method $Path"
            }
            return [pscustomobject]@{}
        }

        Invoke-TableReconciliation $table | Out-Null

        $attributeCreate = @($script:calls | Where-Object {
            $_.Method -eq 'POST' -and
            $_.Path -eq "/EntityDefinitions(LogicalName='$($table.logicalName)')/Attributes"
        })
        $attributeCreate.Count | Should -Be 1
        $attributeCreate[0].Body.LogicalName | Should -Be 'crmshow_validfrom'
        $script:tableSnapshotReads | Should -Be 3
        $script:firstPostCreateMissingSequence | Should -Not -BeNullOrEmpty
        $script:visibleValidFromSequence | Should -Not -BeNullOrEmpty
        $script:visibleValidFromSequence |
            Should -BeGreaterThan $script:firstPostCreateMissingSequence

        foreach ($snapshotCall in @($script:calls | Where-Object {
            $_.Method -eq 'SNAPSHOT'
        })) {
            @($snapshotCall.RequestedAttributeLogicalNames | Sort-Object) |
                Should -Be @($table.columns.logicalName | Sort-Object)
        }

        $publish = @($script:calls | Where-Object {
            $_.Method -eq 'POST' -and $_.Path -eq '/PublishXml'
        })[0]
        $keyCreate = @($script:calls | Where-Object {
            $_.Method -eq 'POST' -and
            $_.Path -eq "/EntityDefinitions(LogicalName='$($table.logicalName)')/Keys"
        })[0]
        $viewCreate = @($script:calls | Where-Object {
            $_.Method -eq 'POST' -and $_.Path -eq '/savedqueries'
        })[0]
        $formCreate = @($script:calls | Where-Object {
            $_.Method -eq 'POST' -and $_.Path -eq '/systemforms'
        })[0]

        $publish.Sequence |
            Should -BeGreaterThan $script:visibleValidFromSequence
        $keyCreate.Sequence |
            Should -BeGreaterThan $script:visibleValidFromSequence
        $viewCreate.Sequence |
            Should -BeGreaterThan $script:visibleValidFromSequence
        $formCreate.Sequence |
            Should -BeGreaterThan $script:visibleValidFromSequence
    }

    It 'times out scalar attribute visibility on an existing table without duplicating the create or posting children' {
        $table = $script:contract.tables[0] |
            ConvertTo-Json -Depth 100 | ConvertFrom-Json
        $table.columns = @($table.columns | Where-Object {
            $_.logicalName -in @(
                'crmshow_name',
                'crmshow_accountid',
                'crmshow_contactid',
                'crmshow_roletype',
                'crmshow_validfrom'
            )
        })
        $table.relationships = @($table.relationships | Where-Object {
            $_.lookupColumn -in @('crmshow_accountid', 'crmshow_contactid')
        })
        $table.alternateKeys = @($table.alternateKeys[0])
        $table.businessRules = @()
        $table.views = @($table.views[0] |
            ConvertTo-Json -Depth 20 | ConvertFrom-Json)
        $table.views[0].columns = @(
            'crmshow_name',
            'crmshow_accountid',
            'crmshow_contactid',
            'crmshow_roletype',
            'crmshow_validfrom'
        )
        $table.forms = @($table.forms[0] |
            ConvertTo-Json -Depth 20 | ConvertFrom-Json)
        $table.forms[0].columns = @(
            'crmshow_name',
            'crmshow_accountid',
            'crmshow_contactid',
            'crmshow_roletype',
            'crmshow_validfrom'
        )

        $start = [datetime]'2026-08-09T12:00:00Z'
        $script:clock = [System.Collections.Generic.Queue[datetime]]::new()
        foreach ($value in @(
            $start,
            $start,
            $start,
            $start,
            $start.AddSeconds(180)
        )) {
            $script:clock.Enqueue($value)
        }

        Mock Start-Sleep {}
        Mock Get-Date { $script:clock.Dequeue() }
        Mock Get-TableExistenceSnapshot {
            param($LogicalName)
            $script:calls.Add([pscustomobject]@{
                Sequence = $script:calls.Count + 1
                Method = 'EXISTS'
                Path = $LogicalName
                Body = $null
                Headers = $null
            })
            return [pscustomobject]@{
                MetadataId = 'existing-table'
                LogicalName = $LogicalName
                SchemaName = $table.schemaName
            }
        }
        Mock Get-TableMetadataSnapshot {
            param($LogicalName, $RequestedAttributeLogicalNames)
            $snapshot = New-TableMetadataSnapshot -Table $table `
                -OmitColumns @('crmshow_validfrom')
            $script:calls.Add([pscustomobject]@{
                Sequence = $script:calls.Count + 1
                Method = 'SNAPSHOT'
                Path = $LogicalName
                Body = $snapshot
                Headers = $null
                RequestedAttributeLogicalNames = @(
                    $RequestedAttributeLogicalNames
                )
            })
            return $snapshot
        }
        Mock Invoke-DataverseRequest {
            param($Method, $Path, $Body, $Headers)
            $script:calls.Add([pscustomobject]@{
                Sequence = $script:calls.Count + 1
                Method = $Method
                Path = $Path
                Body = $Body
                Headers = $Headers
            })
            if ($Method -eq 'GET' -and
                $Path -like "/GlobalOptionSetDefinitions(Name='*") {
                return [pscustomobject]@{
                    MetadataId = '11111111-1111-1111-1111-111111111111'
                }
            }
            if ($Method -eq 'GET') {
                throw "Unsupported mocked endpoint: $Method $Path"
            }
            return [pscustomobject]@{}
        }

        {
            Invoke-TableReconciliation $table
        } | Should -Throw (
            '*EventualConsistencyTimeout*' +
            "$($table.logicalName)/crmshow_validfrom*180*"
        )
        @($script:calls | Where-Object {
            $_.Method -eq 'POST' -and
            $_.Path -eq "/EntityDefinitions(LogicalName='$($table.logicalName)')/Attributes"
        }).Count | Should -Be 1
        @($script:calls | Where-Object {
            $_.Method -eq 'POST' -and
            $_.Path -in @(
                '/PublishXml',
                "/EntityDefinitions(LogicalName='$($table.logicalName)')/Keys",
                '/savedqueries',
                '/systemforms'
            )
        }) | Should -BeNullOrEmpty
    }

    It 'waits for all deep-inserted initial lookups atomically on a newly created table before posting child keys, views, and forms' {
        $table = $script:contract.tables[0] |
            ConvertTo-Json -Depth 100 | ConvertFrom-Json
        $table.columns = @($table.columns | Where-Object {
            $_.logicalName -in @(
                'crmshow_name',
                'crmshow_accountid',
                'crmshow_contactid'
            )
        })
        $table.alternateKeys = @($table.alternateKeys[0])
        $table.businessRules = @()
        $table.views = @($table.views[0])
        $table.forms = @($table.forms[0])
        $script:tableSnapshotReads = 0
        $script:firstVisibleTableSequence = $null
        $script:accountLookupOnlySequence = $null
        $script:contactLookupOnlySequence = $null
        $script:initialLookupReadySequence = $null

        Mock Start-Sleep {}
        Mock Get-TableMetadataSnapshot {
            param($LogicalName, $RequestedAttributeLogicalNames)
            $script:tableSnapshotReads++
            $snapshot = switch ($script:tableSnapshotReads) {
                1 { $null }
                2 {
                    New-TableMetadataSnapshot -Table $table `
                        -OmitColumns @(
                            'crmshow_accountid',
                            'crmshow_contactid'
                        ) `
                        -OmitRelationshipSchemas @(
                            'crmshow_Account_AccountContactRoles',
                            'crmshow_Contact_AccountContactRoles'
                        )
                }
                3 {
                    New-TableMetadataSnapshot -Table $table `
                        -OmitColumns @('crmshow_contactid') `
                        -OmitRelationshipSchemas @(
                            'crmshow_Contact_AccountContactRoles'
                        )
                }
                4 {
                    New-TableMetadataSnapshot -Table $table `
                        -OmitColumns @('crmshow_accountid') `
                        -OmitRelationshipSchemas @(
                            'crmshow_Account_AccountContactRoles'
                        )
                }
                default { New-TableMetadataSnapshot -Table $table }
            }
            $script:calls.Add([pscustomobject]@{
                Sequence = $script:calls.Count + 1
                Method = 'SNAPSHOT'
                Path = $LogicalName
                Body = $snapshot
                Headers = $null
                RequestedAttributeLogicalNames = @(
                    $RequestedAttributeLogicalNames
                )
            })
            if ($null -ne $snapshot -and
                $null -eq $script:firstVisibleTableSequence) {
                $script:firstVisibleTableSequence = $script:calls[-1].Sequence
            }
            if ($null -ne $snapshot) {
                $accountLookupMatches = @($snapshot.Attributes | Where-Object {
                    $_.LogicalName -eq 'crmshow_accountid'
                })
                $accountRelationshipMatches = @(
                    $snapshot.ManyToOneRelationships | Where-Object {
                        $_.SchemaName -eq 'crmshow_Account_AccountContactRoles'
                    }
                )
                $contactLookupMatches = @($snapshot.Attributes | Where-Object {
                    $_.LogicalName -eq 'crmshow_contactid'
                })
                $contactRelationshipMatches = @(
                    $snapshot.ManyToOneRelationships | Where-Object {
                        $_.SchemaName -eq 'crmshow_Contact_AccountContactRoles'
                    }
                )
                $hasAccountLookup = $accountLookupMatches.Count -eq 1 -and
                    $accountRelationshipMatches.Count -eq 1
                $hasContactLookup = $contactLookupMatches.Count -eq 1 -and
                    $contactRelationshipMatches.Count -eq 1
                if ($hasAccountLookup -and -not $hasContactLookup -and
                    $null -eq $script:accountLookupOnlySequence) {
                    $script:accountLookupOnlySequence = `
                        $script:calls[-1].Sequence
                }
                if ($hasContactLookup -and -not $hasAccountLookup -and
                    $null -eq $script:contactLookupOnlySequence) {
                    $script:contactLookupOnlySequence = `
                        $script:calls[-1].Sequence
                }
                if ($hasAccountLookup -and $hasContactLookup) {
                    $script:initialLookupReadySequence = `
                        $script:calls[-1].Sequence
                }
            }
            return $snapshot
        }
        Mock Invoke-DataverseRequest {
            param($Method, $Path, $Body, $Headers)
            $script:calls.Add([pscustomobject]@{
                Sequence = $script:calls.Count + 1
                Method = $Method; Path = $Path; Body = $Body; Headers = $Headers
            })
            if ($Method -eq 'GET' -and
                $Path -match '(?:/Keys\?|^/savedqueries\?|^/systemforms\?)') {
                return [pscustomobject]@{ value = @() }
            }
            if ($Method -eq 'POST' -and $Path -eq '/savedqueries') {
                return [pscustomobject]@{ savedqueryid = 'new-view' }
            }
            if ($Method -eq 'POST' -and $Path -eq '/systemforms') {
                return [pscustomobject]@{ formid = 'new-form' }
            }
            if ($Method -eq 'GET') { throw "Unsupported mocked endpoint: $Method $Path" }
            return [pscustomobject]@{}
        }

        Invoke-TableReconciliation $table | Out-Null

        @($script:calls | Where-Object {
            $_.Method -eq 'POST' -and $_.Path -eq '/EntityDefinitions'
        }).Count | Should -Be 1
        @($script:calls | Where-Object {
            $_.Method -eq 'POST' -and $_.Path -eq '/RelationshipDefinitions'
        }).Count | Should -Be 0
        $script:firstVisibleTableSequence | Should -Not -BeNullOrEmpty
        $script:accountLookupOnlySequence | Should -Not -BeNullOrEmpty
        $script:contactLookupOnlySequence | Should -Not -BeNullOrEmpty
        $script:initialLookupReadySequence | Should -Not -BeNullOrEmpty
        $script:firstVisibleTableSequence |
            Should -BeLessThan $script:accountLookupOnlySequence
        $script:accountLookupOnlySequence |
            Should -BeLessThan $script:initialLookupReadySequence
        $script:contactLookupOnlySequence |
            Should -BeLessThan $script:initialLookupReadySequence
        @($script:calls | Where-Object {
            $_.Method -eq 'POST' -and
            $_.Path -eq "/EntityDefinitions(LogicalName='$($table.logicalName)')/Keys"
        })[0].Sequence | Should -BeGreaterThan $script:initialLookupReadySequence
        @($script:calls | Where-Object {
            $_.Method -eq 'POST' -and $_.Path -eq '/savedqueries'
        })[0].Sequence | Should -BeGreaterThan $script:initialLookupReadySequence
        @($script:calls | Where-Object {
            $_.Method -eq 'POST' -and $_.Path -eq '/systemforms'
        })[0].Sequence | Should -BeGreaterThan $script:initialLookupReadySequence
    }

    It 'waits for all initial scalar table-create attributes before posting children and never recreates them' {
        $table = $script:contract.tables[0] |
            ConvertTo-Json -Depth 100 | ConvertFrom-Json
        $table.columns = @($table.columns | Where-Object {
            $_.logicalName -in @(
                'crmshow_name',
                'crmshow_accountid',
                'crmshow_contactid',
                'crmshow_roletype',
                'crmshow_validfrom'
            )
        })
        $table.alternateKeys = @($table.alternateKeys[0])
        $table.businessRules = @()
        $table.views = @($table.views[0] |
            ConvertTo-Json -Depth 20 | ConvertFrom-Json)
        $table.views[0].columns = @(
            'crmshow_name',
            'crmshow_accountid',
            'crmshow_contactid',
            'crmshow_roletype',
            'crmshow_validfrom'
        )
        $table.forms = @($table.forms[0] |
            ConvertTo-Json -Depth 20 | ConvertFrom-Json)
        $table.forms[0].columns = @(
            'crmshow_name',
            'crmshow_accountid',
            'crmshow_contactid',
            'crmshow_roletype',
            'crmshow_validfrom'
        )
        $script:tableSnapshotReads = 0
        $script:partialScalarSequence = $null
        $script:fullReadySequence = $null

        Mock Start-Sleep {}
        Mock Get-TableMetadataSnapshot {
            param($LogicalName, $RequestedAttributeLogicalNames)
            $script:tableSnapshotReads++
            $snapshot = switch ($script:tableSnapshotReads) {
                1 { $null }
                2 {
                    New-TableMetadataSnapshot -Table $table `
                        -OmitColumns @(
                            'crmshow_roletype',
                            'crmshow_validfrom'
                        )
                }
                default { New-TableMetadataSnapshot -Table $table }
            }
            $script:calls.Add([pscustomobject]@{
                Sequence = $script:calls.Count + 1
                Method = 'SNAPSHOT'
                Path = $LogicalName
                Body = $snapshot
                Headers = $null
                RequestedAttributeLogicalNames = @(
                    $RequestedAttributeLogicalNames
                )
            })
            if ($null -ne $snapshot) {
                $hasRoleType = @($snapshot.Attributes | Where-Object {
                    $_.LogicalName -eq 'crmshow_roletype'
                }).Count -eq 1
                $hasValidFrom = @($snapshot.Attributes | Where-Object {
                    $_.LogicalName -eq 'crmshow_validfrom'
                }).Count -eq 1
                if (-not $hasRoleType -and -not $hasValidFrom) {
                    $script:partialScalarSequence = $script:calls[-1].Sequence
                }
                if ($hasRoleType -and $hasValidFrom) {
                    $script:fullReadySequence = $script:calls[-1].Sequence
                }
            }
            return $snapshot
        }
        Mock Invoke-DataverseRequest {
            param($Method, $Path, $Body, $Headers)
            $script:calls.Add([pscustomobject]@{
                Sequence = $script:calls.Count + 1
                Method = $Method
                Path = $Path
                Body = $Body
                Headers = $Headers
            })
            if ($Method -eq 'GET' -and
                $Path -like "/GlobalOptionSetDefinitions(Name='*") {
                return [pscustomobject]@{
                    MetadataId = '11111111-1111-1111-1111-111111111111'
                }
            }
            if ($Method -eq 'GET' -and
                $Path -match '(?:/Keys\?|^/savedqueries\?|^/systemforms\?)') {
                return [pscustomobject]@{ value = @() }
            }
            if ($Method -eq 'POST' -and $Path -eq '/savedqueries') {
                return [pscustomobject]@{ savedqueryid = 'new-view' }
            }
            if ($Method -eq 'POST' -and $Path -eq '/systemforms') {
                return [pscustomobject]@{ formid = 'new-form' }
            }
            if ($Method -eq 'GET') {
                throw "Unsupported mocked endpoint: $Method $Path"
            }
            return [pscustomobject]@{}
        }

        Invoke-TableReconciliation $table | Out-Null

        $script:partialScalarSequence | Should -Not -BeNullOrEmpty
        $script:fullReadySequence | Should -Not -BeNullOrEmpty
        $script:fullReadySequence |
            Should -BeGreaterThan $script:partialScalarSequence
        @($script:calls | Where-Object {
            $_.Method -eq 'POST' -and
            $_.Path -eq "/EntityDefinitions(LogicalName='$($table.logicalName)')/Attributes"
        }) | Should -BeNullOrEmpty
        foreach ($snapshotCall in @($script:calls | Where-Object {
            $_.Method -eq 'SNAPSHOT'
        })) {
            @($snapshotCall.RequestedAttributeLogicalNames | Sort-Object) |
                Should -Be @($table.columns.logicalName | Sort-Object)
        }
        @($script:calls | Where-Object {
            $_.Method -eq 'POST' -and
            $_.Path -eq "/EntityDefinitions(LogicalName='$($table.logicalName)')/Keys"
        })[0].Sequence | Should -BeGreaterThan $script:fullReadySequence
        @($script:calls | Where-Object {
            $_.Method -eq 'POST' -and $_.Path -eq '/savedqueries'
        })[0].Sequence | Should -BeGreaterThan $script:fullReadySequence
        @($script:calls | Where-Object {
            $_.Method -eq 'POST' -and $_.Path -eq '/systemforms'
        })[0].Sequence | Should -BeGreaterThan $script:fullReadySequence
    }

    It 'fails closed instead of recreating an InitialTableCreate relationship after a current-run table already passed atomic readiness' {
        $table = $script:contract.tables[2] |
            ConvertTo-Json -Depth 100 | ConvertFrom-Json
        $table.columns = @($table.columns | Where-Object {
            $_.logicalName -in @(
                'crmshow_name',
                'crmshow_policyid',
                'crmshow_partyid'
            )
        })
        $table.alternateKeys = @()
        $table.businessRules = @()
        $table.views = @()
        $table.forms = @()
        $script:tableSnapshotReads = 0

        Mock Start-Sleep {}
        Mock Get-TableMetadataSnapshot {
            param($LogicalName, $RequestedAttributeLogicalNames)
            $script:tableSnapshotReads++
            $snapshot = switch ($script:tableSnapshotReads) {
                1 { $null }
                2 { New-TableMetadataSnapshot -Table $table }
                default {
                    New-TableMetadataSnapshot -Table $table `
                        -IncludeCustomerRelationships `
                        -OmitColumns @('crmshow_policyid') `
                        -OmitRelationshipSchemas @(
                            'crmshow_PolicyProjection_PartyRoles'
                        )
                }
            }
            $script:calls.Add([pscustomobject]@{
                Sequence = $script:calls.Count + 1
                Method = 'SNAPSHOT'
                Path = $LogicalName
                Body = $snapshot
                Headers = $null
            })
            return $snapshot
        }
        Mock Invoke-DataverseRequest {
            param($Method, $Path, $Body, $Headers)
            $script:calls.Add([pscustomobject]@{
                Sequence = $script:calls.Count + 1
                Method = $Method; Path = $Path; Body = $Body; Headers = $Headers
            })
            if ($Method -eq 'GET' -and
                $Path -match '(?:/Keys\?|^/savedqueries\?|^/systemforms\?)') {
                return [pscustomobject]@{ value = @() }
            }
            if ($Method -eq 'GET') { throw "Unsupported mocked endpoint: $Method $Path" }
            return [pscustomobject]@{}
        }

        {
            Invoke-TableReconciliation $table
        } | Should -Throw '*current-run InitialTableCreate metadata is absent after atomic readiness*'
        @($script:calls | Where-Object {
            $_.Method -eq 'POST' -and $_.Path -eq '/CreateCustomerRelationships'
        }).Count | Should -Be 1
        @($script:calls | Where-Object {
            $_.Method -eq 'POST' -and $_.Path -eq '/RelationshipDefinitions'
        }) | Should -BeNullOrEmpty
    }

    It 'fails closed instead of recreating an InitialTableCreate scalar attribute after a current-run table already passed atomic readiness' {
        $table = $script:contract.tables[2] |
            ConvertTo-Json -Depth 100 | ConvertFrom-Json
        $table.columns = @($table.columns | Where-Object {
            $_.logicalName -in @(
                'crmshow_name',
                'crmshow_policyid',
                'crmshow_partyid',
                'crmshow_roletype',
                'crmshow_validfrom'
            )
        })
        $table.alternateKeys = @()
        $table.businessRules = @()
        $table.views = @()
        $table.forms = @()
        $script:tableSnapshotReads = 0

        Mock Start-Sleep {}
        Mock Get-TableMetadataSnapshot {
            param($LogicalName, $RequestedAttributeLogicalNames)
            $script:tableSnapshotReads++
            $snapshot = switch ($script:tableSnapshotReads) {
                1 { $null }
                2 { New-TableMetadataSnapshot -Table $table }
                default {
                    New-TableMetadataSnapshot -Table $table `
                        -IncludeCustomerRelationships `
                        -OmitColumns @('crmshow_roletype')
                }
            }
            $script:calls.Add([pscustomobject]@{
                Sequence = $script:calls.Count + 1
                Method = 'SNAPSHOT'
                Path = $LogicalName
                Body = $snapshot
                Headers = $null
            })
            return $snapshot
        }
        Mock Invoke-DataverseRequest {
            param($Method, $Path, $Body, $Headers)
            $script:calls.Add([pscustomobject]@{
                Sequence = $script:calls.Count + 1
                Method = $Method
                Path = $Path
                Body = $Body
                Headers = $Headers
            })
            if ($Method -eq 'GET' -and
                $Path -like "/GlobalOptionSetDefinitions(Name='*") {
                return [pscustomobject]@{
                    MetadataId = '11111111-1111-1111-1111-111111111111'
                }
            }
            if ($Method -eq 'GET') {
                throw "Unsupported mocked endpoint: $Method $Path"
            }
            return [pscustomobject]@{}
        }

        {
            Invoke-TableReconciliation $table
        } | Should -Throw '*current-run InitialTableCreate metadata is absent after atomic readiness; recovery POST is forbidden*'
        @($script:calls | Where-Object {
            $_.Method -eq 'POST' -and $_.Path -eq '/CreateCustomerRelationships'
        }).Count | Should -Be 1
        @($script:calls | Where-Object {
            $_.Method -eq 'POST' -and
            $_.Path -eq "/EntityDefinitions(LogicalName='$($table.logicalName)')/Attributes"
        }) | Should -BeNullOrEmpty
    }

    It 'times out initial deep-insert lookup visibility without recreating the relationship or children' {
        $table = $script:contract.tables[0] |
            ConvertTo-Json -Depth 100 | ConvertFrom-Json
        $table.columns = @($table.columns | Where-Object {
            $_.logicalName -in @('crmshow_name', 'crmshow_accountid')
        })
        $table.relationships = @($table.relationships | Where-Object {
            $_.lookupColumn -eq 'crmshow_accountid'
        })
        $table.alternateKeys = @($table.alternateKeys[0])
        $table.businessRules = @()
        $table.views = @($table.views[0])
        $table.forms = @($table.forms[0])

        $start = [datetime]'2026-08-09T12:00:00Z'
        $script:clock = [System.Collections.Generic.Queue[datetime]]::new()
        foreach ($value in @(
            $start,
            $start,
            $start,
            $start,
            $start.AddSeconds(180)
        )) {
            $script:clock.Enqueue($value)
        }

        Mock Start-Sleep {}
        Mock Get-Date { $script:clock.Dequeue() }
        Mock Get-TableMetadataSnapshot {
            param($LogicalName, $RequestedAttributeLogicalNames)
            $snapshot = if ($script:calls.Count -eq 0) {
                $null
            } else {
                New-TableMetadataSnapshot -Table $table `
                    -OmitColumns @('crmshow_accountid') `
                    -OmitRelationshipSchemas @(
                        'crmshow_Account_AccountContactRoles'
                    )
            }
            $script:calls.Add([pscustomobject]@{
                Sequence = $script:calls.Count + 1
                Method = 'SNAPSHOT'
                Path = $LogicalName
                Body = $snapshot
                Headers = $null
            })
            return $snapshot
        }
        Mock Invoke-DataverseRequest {
            param($Method, $Path, $Body, $Headers)
            $script:calls.Add([pscustomobject]@{
                Sequence = $script:calls.Count + 1
                Method = $Method; Path = $Path; Body = $Body; Headers = $Headers
            })
            if ($Method -eq 'GET' -and
                $Path -match '(?:/Keys\?|^/savedqueries\?|^/systemforms\?)') {
                return [pscustomobject]@{ value = @() }
            }
            if ($Method -eq 'GET') { throw "Unsupported mocked endpoint: $Path" }
            return [pscustomobject]@{}
        }

        {
            Invoke-TableReconciliation $table
        } | Should -Throw (
            '*EventualConsistencyTimeout*' +
            "$($table.logicalName)/crmshow_accountid*180*"
        )
        @($script:calls | Where-Object {
            $_.Method -eq 'POST' -and $_.Path -eq '/EntityDefinitions'
        }).Count | Should -Be 1
        @($script:calls | Where-Object {
            $_.Method -eq 'POST' -and
            $_.Path -in @(
                '/RelationshipDefinitions',
                "/EntityDefinitions(LogicalName='$($table.logicalName)')/Keys",
                '/savedqueries',
                '/systemforms'
            )
        }) | Should -BeNullOrEmpty
    }

    It 'times out initial scalar visibility without recreating the attribute or children' {
        $table = $script:contract.tables[0] |
            ConvertTo-Json -Depth 100 | ConvertFrom-Json
        $table.columns = @($table.columns | Where-Object {
            $_.logicalName -in @(
                'crmshow_name',
                'crmshow_accountid',
                'crmshow_contactid',
                'crmshow_roletype',
                'crmshow_validfrom'
            )
        })
        $table.alternateKeys = @($table.alternateKeys[0])
        $table.businessRules = @()
        $table.views = @($table.views[0] |
            ConvertTo-Json -Depth 20 | ConvertFrom-Json)
        $table.views[0].columns = @(
            'crmshow_name',
            'crmshow_accountid',
            'crmshow_contactid',
            'crmshow_roletype',
            'crmshow_validfrom'
        )
        $table.forms = @($table.forms[0] |
            ConvertTo-Json -Depth 20 | ConvertFrom-Json)
        $table.forms[0].columns = @(
            'crmshow_name',
            'crmshow_accountid',
            'crmshow_contactid',
            'crmshow_roletype',
            'crmshow_validfrom'
        )

        $start = [datetime]'2026-08-09T12:00:00Z'
        $script:clock = [System.Collections.Generic.Queue[datetime]]::new()
        foreach ($value in @(
            $start,
            $start,
            $start,
            $start,
            $start.AddSeconds(180)
        )) {
            $script:clock.Enqueue($value)
        }

        Mock Start-Sleep {}
        Mock Get-Date { $script:clock.Dequeue() }
        Mock Get-TableMetadataSnapshot {
            param($LogicalName, $RequestedAttributeLogicalNames)
            $snapshot = if ($script:calls.Count -eq 0) {
                $null
            } else {
                New-TableMetadataSnapshot -Table $table `
                    -OmitColumns @('crmshow_roletype')
            }
            $script:calls.Add([pscustomobject]@{
                Sequence = $script:calls.Count + 1
                Method = 'SNAPSHOT'
                Path = $LogicalName
                Body = $snapshot
                Headers = $null
            })
            return $snapshot
        }
        Mock Invoke-DataverseRequest {
            param($Method, $Path, $Body, $Headers)
            $script:calls.Add([pscustomobject]@{
                Sequence = $script:calls.Count + 1
                Method = $Method
                Path = $Path
                Body = $Body
                Headers = $Headers
            })
            if ($Method -eq 'GET' -and
                $Path -like "/GlobalOptionSetDefinitions(Name='*") {
                return [pscustomobject]@{
                    MetadataId = '11111111-1111-1111-1111-111111111111'
                }
            }
            if ($Method -eq 'GET' -and
                $Path -match '(?:/Keys\?|^/savedqueries\?|^/systemforms\?)') {
                return [pscustomobject]@{ value = @() }
            }
            if ($Method -eq 'GET') { throw "Unsupported mocked endpoint: $Path" }
            return [pscustomobject]@{}
        }

        {
            Invoke-TableReconciliation $table
        } | Should -Throw '*EventualConsistencyTimeout*180*'
        @($script:calls | Where-Object {
            $_.Method -eq 'POST' -and $_.Path -eq '/EntityDefinitions'
        }).Count | Should -Be 1
        @($script:calls | Where-Object {
            $_.Method -eq 'POST' -and
            $_.Path -eq "/EntityDefinitions(LogicalName='$($table.logicalName)')/Attributes"
        }) | Should -BeNullOrEmpty
        @($script:calls | Where-Object {
            $_.Method -eq 'POST' -and
            $_.Path -in @(
                '/RelationshipDefinitions',
                "/EntityDefinitions(LogicalName='$($table.logicalName)')/Keys",
                '/savedqueries',
                '/systemforms'
            )
        }) | Should -BeNullOrEmpty
    }

    It 'times out existing typed metadata visibility without creating the table or duplicate attributes' {
        $table = $script:contract.tables[0] |
            ConvertTo-Json -Depth 100 | ConvertFrom-Json
        $table.columns = @($table.columns | Where-Object {
            $_.logicalName -eq 'crmshow_name'
        })
        $table.relationships = @()
        $table.alternateKeys = @()
        $table.businessRules = @()
        $table.views = @()
        $table.forms = @()
        $start = [datetime]'2026-08-09T12:00:00Z'
        $script:clock = [System.Collections.Generic.Queue[datetime]]::new()
        foreach ($value in @(
            $start,
            $start,
            $start.AddSeconds(180)
        )) {
            $script:clock.Enqueue($value)
        }

        Mock Start-Sleep {}
        Mock Get-Date { $script:clock.Dequeue() }
        Mock Get-TableExistenceSnapshot {
            param($LogicalName)
            $script:calls.Add([pscustomobject]@{
                Sequence = $script:calls.Count + 1
                Method = 'EXISTS'
                Path = $LogicalName
                Body = $null
                Headers = $null
            })
            return [pscustomobject]@{
                MetadataId = 'existing-table'
                LogicalName = $LogicalName
                SchemaName = $table.schemaName
            }
        }
        Mock Invoke-DataverseRequest {
            param($Method, $Path, $Body, $Headers)
            $script:calls.Add([pscustomobject]@{
                Sequence = $script:calls.Count + 1
                Method = $Method
                Path = $Path
                Body = $Body
                Headers = $Headers
            })
            if ($Method -eq 'GET' -and $Path -like '/EntityDefinitions?*' -and
                $Path -match '\$expand=Attributes') {
                return [pscustomobject]@{
                    value = @(
                        New-TableMetadataSnapshot -Table $table
                    )
                }
            }
            if ($Method -eq 'GET' -and
                $Path -match '/Attributes/Microsoft\.Dynamics\.CRM\.StringAttributeMetadata') {
                return [pscustomobject]@{ value = @() }
            }
            if ($Method -eq 'GET') {
                throw "Unsupported mocked endpoint: $Method $Path"
            }
            return [pscustomobject]@{}
        }

        {
            Invoke-TableReconciliation $table
        } | Should -Throw "*EventualConsistencyTimeout*$($table.logicalName)*180*"
        @($script:calls | Where-Object Method -eq 'EXISTS').Count | Should -Be 1
        @($script:calls | Where-Object {
            $_.Method -eq 'POST' -and
            $_.Path -in @(
                '/EntityDefinitions',
                "/EntityDefinitions(LogicalName='$($table.logicalName)')/Attributes",
                '/PublishXml'
            )
        }) | Should -BeNullOrEmpty
    }

    It 'waits for recovered ordinary lookups before posting child keys, views, and forms' {
        $table = $script:contract.tables[0] |
            ConvertTo-Json -Depth 100 | ConvertFrom-Json
        $table.columns = @($table.columns | Where-Object {
            $_.logicalName -in @('crmshow_name', 'crmshow_accountid')
        })
        $table.relationships = @($table.relationships | Where-Object {
            $_.lookupColumn -eq 'crmshow_accountid'
        })
        $table.alternateKeys = @($table.alternateKeys[0])
        $table.businessRules = @()
        $table.views = @($table.views[0])
        $table.forms = @($table.forms[0])
        $script:relationshipCreateSeen = $false
        $script:relationshipVisibilityReads = 0
        $script:visibleLookupSequence = $null

        Mock Start-Sleep {}
        Mock Get-TableExistenceSnapshot {
            param($LogicalName)
            return [pscustomobject]@{
                MetadataId = 'existing-table'
                LogicalName = $LogicalName
                SchemaName = $table.schemaName
            }
        }
        Mock Get-TableMetadataSnapshot {
            param($LogicalName, $RequestedAttributeLogicalNames)
            if ($script:relationshipCreateSeen) {
                $script:relationshipVisibilityReads++
            }
            $isVisible = $script:relationshipVisibilityReads -ge 2
            $snapshot = if ($isVisible) {
                New-TableMetadataSnapshot -Table $table
            } else {
                New-TableMetadataSnapshot -Table $table `
                    -OmitColumns @('crmshow_accountid') `
                    -OmitRelationshipSchemas @(
                        'crmshow_Account_AccountContactRoles'
                    )
            }
            $script:calls.Add([pscustomobject]@{
                Sequence = $script:calls.Count + 1
                Method = 'SNAPSHOT'
                Path = $LogicalName
                Body = $snapshot
                Headers = $null
            })
            if ($isVisible) {
                $script:visibleLookupSequence = $script:calls[-1].Sequence
            }
            return $snapshot
        }
        Mock Invoke-DataverseRequest {
            param($Method, $Path, $Body, $Headers)
            $script:calls.Add([pscustomobject]@{
                Sequence=$script:calls.Count + 1
                Method=$Method; Path=$Path; Body=$Body; Headers=$Headers
            })
            if ($Method -eq 'GET' -and
                $Path -match '(?:/Keys\?|^/savedqueries\?|^/systemforms\?)') {
                return [pscustomobject]@{ value = @() }
            }
            if ($Method -eq 'POST' -and $Path -eq '/RelationshipDefinitions') {
                $script:relationshipCreateSeen = $true
                return [pscustomobject]@{}
            }
            if ($Method -eq 'POST' -and $Path -eq '/savedqueries') {
                return [pscustomobject]@{ savedqueryid = 'new-view' }
            }
            if ($Method -eq 'POST' -and $Path -eq '/systemforms') {
                return [pscustomobject]@{ formid = 'new-form' }
            }
            if ($Method -eq 'GET') { throw "Unsupported mocked endpoint: $Path" }
            return [pscustomobject]@{}
        }

        Invoke-TableReconciliation $table | Out-Null

        @($script:calls | Where-Object {
            $_.Method -eq 'POST' -and $_.Path -eq '/RelationshipDefinitions'
        }).Count | Should -Be 1
        @($script:calls | Where-Object Method -eq 'DELETE') |
            Should -BeNullOrEmpty
        $script:visibleLookupSequence | Should -Not -BeNullOrEmpty
        @($script:calls | Where-Object {
            $_.Method -eq 'POST' -and
            $_.Path -eq "/EntityDefinitions(LogicalName='$($table.logicalName)')/Keys"
        })[0].Sequence | Should -BeGreaterThan $script:visibleLookupSequence
        @($script:calls | Where-Object {
            $_.Method -eq 'POST' -and $_.Path -eq '/savedqueries'
        })[0].Sequence | Should -BeGreaterThan $script:visibleLookupSequence
        @($script:calls | Where-Object {
            $_.Method -eq 'POST' -and $_.Path -eq '/systemforms'
        })[0].Sequence | Should -BeGreaterThan $script:visibleLookupSequence
    }

    It 'blocks child reconciliation and reports the exact component when lookup visibility times out' {
        $table = $script:contract.tables[0] |
            ConvertTo-Json -Depth 100 | ConvertFrom-Json
        $table.columns = @($table.columns | Where-Object {
            $_.logicalName -in @('crmshow_name', 'crmshow_accountid')
        })
        $table.relationships = @($table.relationships | Where-Object {
            $_.lookupColumn -eq 'crmshow_accountid'
        })
        $table.alternateKeys = @($table.alternateKeys[0])
        $table.businessRules = @()
        $table.views = @($table.views[0])
        $table.forms = @($table.forms[0])

        $start = [datetime]'2026-08-09T12:00:00Z'
        $script:clock = [System.Collections.Generic.Queue[datetime]]::new()
        foreach ($value in @(
            $start,
            $start,
            $start,
            $start,
            $start.AddSeconds(180)
        )) {
            $script:clock.Enqueue($value)
        }

        Mock Start-Sleep {}
        Mock Get-Date { $script:clock.Dequeue() }
        Mock Get-TableExistenceSnapshot {
            param($LogicalName)
            return [pscustomobject]@{
                MetadataId = 'existing-table'
                LogicalName = $LogicalName
                SchemaName = $table.schemaName
            }
        }
        Mock Get-TableMetadataSnapshot {
            param($LogicalName, $RequestedAttributeLogicalNames)
            $snapshot = New-TableMetadataSnapshot -Table $table `
                -OmitColumns @('crmshow_accountid') `
                -OmitRelationshipSchemas @(
                    'crmshow_Account_AccountContactRoles'
                )
            $script:calls.Add([pscustomobject]@{
                Sequence = $script:calls.Count + 1
                Method = 'SNAPSHOT'
                Path = $LogicalName
                Body = $snapshot
                Headers = $null
            })
            return $snapshot
        }
        Mock Invoke-DataverseRequest {
            param($Method, $Path, $Body, $Headers)
            $script:calls.Add([pscustomobject]@{
                Sequence=$script:calls.Count + 1
                Method=$Method; Path=$Path; Body=$Body; Headers=$Headers
            })
            if ($Method -eq 'POST' -and $Path -eq '/RelationshipDefinitions') {
                return [pscustomobject]@{}
            }
            if ($Method -eq 'GET' -and
                $Path -match '(?:/Keys\?|^/savedqueries\?|^/systemforms\?)') {
                return [pscustomobject]@{ value = @() }
            }
            if ($Method -eq 'GET') { throw "Unsupported mocked endpoint: $Path" }
            return [pscustomobject]@{}
        }

        {
            Invoke-TableReconciliation $table
        } | Should -Throw (
            '*EventualConsistencyTimeout*' +
            "$($table.logicalName)/crmshow_accountid*180*"
        )
        @($script:calls | Where-Object {
            $_.Method -eq 'POST' -and
            $_.Path -in @(
                "/EntityDefinitions(LogicalName='$($table.logicalName)')/Keys",
                '/savedqueries',
                '/systemforms'
            )
        }) | Should -BeNullOrEmpty
        @($script:calls | Where-Object {
            $_.Method -eq 'POST' -and $_.Path -eq '/RelationshipDefinitions'
        }).Count | Should -Be 1
    }
}

Describe 'Publisher entry point safety' {
    It 'does not invoke az or pac when dot-sourced' {
        $text = @'
function az { throw 'az was called' }
function pac { throw 'pac was called' }
. '__SCRIPT__' -EnvironmentUrl 'https://unit.crm.dynamics.com' -ContractPath '__CONTRACT__'
'@.Replace('__SCRIPT__', $script:publisherPath.Replace("'", "''")).
    Replace('__CONTRACT__', $script:contractPath.Replace("'", "''"))
        & ([scriptblock]::Create($text))
    }

    It 'runs all offline tests before authentication and language mutation' {
        $workflow = Get-Content (Join-Path $script:repoRoot `
            '.github/workflows/solution-author-dev.yml') -Raw
        $tests = $workflow.IndexOf('- name: Run offline authoring contract tests')
        $auth = $workflow.IndexOf('- name: Authenticate Power Platform CLI')
        $languages = $workflow.IndexOf('- name: Reconcile Dataverse languages')
        $tests | Should -BeGreaterOrEqual 0
        $tests | Should -BeLessThan $auth
        $tests | Should -BeLessThan $languages
    }

    It 'runs the Dataverse language tests before mutating the environment' {
        $workflow = Get-Content (Join-Path $script:repoRoot `
            '.github/workflows/solution-author-dev.yml') -Raw

        $expected = [regex]::Escape(
            "(Join-Path `$root 'infra/scripts/tests/Set-DataverseLanguages.Tests.ps1')")
        $workflow | Should -Match $expected
    }
}
