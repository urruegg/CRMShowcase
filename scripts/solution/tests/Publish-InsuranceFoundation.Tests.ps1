BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
    $script:contractPath = Join-Path $script:repoRoot 'solution/schema/insurance-foundation.json'
    $script:publisherPath = Join-Path $script:repoRoot 'scripts/solution/Publish-InsuranceFoundation.ps1'
    . $script:publisherPath -EnvironmentUrl 'https://unit.crm.dynamics.com' -ContractPath $script:contractPath
    $script:contract = Get-Content $script:contractPath -Raw | ConvertFrom-Json
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

    It 'puts every ordinary lookup in the initial table create' {
        $table = $script:contract.tables[0]
        $request = Get-TableCreateRequest -Table $table
        @($request.Body.Attributes |
            Where-Object { $_.'@odata.type' -eq 'Microsoft.Dynamics.CRM.LookupAttributeMetadata' } |
            ForEach-Object LogicalName) |
            Should -Be @('crmshow_accountid', 'crmshow_contactid')
        @($request.Body.OneToManyRelationships.ReferencingAttribute) |
            Should -Be @('crmshow_accountid', 'crmshow_contactid')
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
            $fetch | Should -Match 'valueof="a\.crmshow_validfrom"'
            $fetch | Should -Match 'valueof="a\.crmshow_validto"'
        }
    }

    It 'uses the resolved custom object type code in layout XML' {
        $request = New-ViewRequest $script:contract.tables[0] `
            $script:contract.tables[0].views[0] 10427
        $request.Body.layoutxml | Should -Match 'object="10427"'
        $request.Body.layoutxml | Should -Not -Match 'object="1"'
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
}

Describe 'Insurance Foundation reconciliation' {
    BeforeEach {
        $script:calls = [System.Collections.Generic.List[object]]::new()
        Mock Invoke-DataverseRequest {
            param($Method, $Path, $Body, $Headers)
            $script:calls.Add([pscustomobject]@{
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
            if ($Method -eq 'GET' -and $Path -like '/privileges*') {
                return [pscustomobject]@{ value = @([pscustomobject]@{
                    privilegeid = 'resolved-privilege'
                }) }
            }
            if ($Method -eq 'GET') { return [pscustomobject]@{ value = @() } }
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
    }

    It 'creates the Customer relationship immediately after its owning table and once' {
        Invoke-InsuranceFoundationReconciliation -Contract $script:contract -Scope DataModel -Confirm:$false
        $mutations = @($script:calls | Where-Object Method -ne 'GET')
        $tableIndex = -1
        for ($i = 0; $i -lt $mutations.Count; $i++) {
            if ($mutations[$i].Path -eq '/EntityDefinitions' -and
                $mutations[$i].Body.LogicalName -eq 'crmshow_policypartyrole') {
                $tableIndex = $i
                break
            }

        }
        $tableIndex | Should -BeGreaterOrEqual 0
        $mutations[$tableIndex + 1].Path | Should -Be '/CreateCustomerRelationships'
        @($mutations | Where-Object Path -eq '/CreateCustomerRelationships').Count | Should -Be 1
    }

    It 'uses the complete deterministic mutation order' {
        Invoke-InsuranceFoundationReconciliation -Contract $script:contract -Scope All -Confirm:$false |
            Out-Null
        $actual = @($script:calls | Where-Object Method -ne 'GET' | ForEach-Object Path)
        $expected = @(
            '/GlobalOptionSetDefinitions','/GlobalOptionSetDefinitions',
            '/GlobalOptionSetDefinitions','/GlobalOptionSetDefinitions',
            '/GlobalOptionSetDefinitions',
            "/EntityDefinitions(LogicalName='account')/Attributes",
            "/EntityDefinitions(LogicalName='contact')/Attributes",
            '/EntityDefinitions',
            "/EntityDefinitions(LogicalName='crmshow_accountcontactrole')/Keys",
            '/savedqueries','/SetLocLabels','/SetLocLabels',
            '/savedqueries','/SetLocLabels','/SetLocLabels',
            '/savedqueries','/SetLocLabels','/SetLocLabels',
            '/systemforms','/SetLocLabels','/SetLocLabels',
            '/EntityDefinitions',
            "/EntityDefinitions(LogicalName='crmshow_policyprojection')/Keys",
            '/savedqueries','/SetLocLabels','/SetLocLabels',
            '/savedqueries','/SetLocLabels','/SetLocLabels',
            '/systemforms','/SetLocLabels','/SetLocLabels',
            '/EntityDefinitions','/CreateCustomerRelationships',
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
                    value = @([pscustomobject]@{
                        Name = 'crmshow_accounttype'
                        '@odata.type' = 'Microsoft.Dynamics.CRM.OptionSetMetadata'
                        MetadataId = 'choice-metadata-id'
                        IsGlobal = $true
                        SolutionUniqueName = 'crmshow_Foundation'
                        DisplayName = $desiredChoice.DisplayName
                        Description = $desiredChoice.Description
                        Options = $desiredChoice.Options
                    })
                }
            }
            if ($Method -eq 'GET') { return [pscustomobject]@{ value = @() } }
            return [pscustomobject]@{}
        }
        $oneChoice = $script:contract | ConvertTo-Json -Depth 100 | ConvertFrom-Json
        $oneChoice.choices = @($oneChoice.choices[0])
        $oneChoice.nativeExtensions = @()
        $oneChoice.tables = @()
        $oneChoice.roles = @()

        Invoke-InsuranceFoundationReconciliation -Contract $oneChoice -Scope Foundation -Confirm:$false
        @($script:calls | Where-Object {
            $_.Method -ne 'GET' -and $_.Path -like '/GlobalOptionSetDefinitions*'
        }) | Should -BeNullOrEmpty
    }

    It 'throws rather than replacing a structural conflict' {
        Mock Invoke-DataverseRequest {
            param($Method, $Path, $Body, $Headers)
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
                    LogicalName = $table.logicalName
                    OwnershipType = 'UserOwned'
                    SolutionUniqueName = 'crmshow_DataModel'
                    OneToManyRelationships = @($table.relationships | ForEach-Object {
                        [pscustomobject]@{
                            SchemaName = $_.schemaName
                            ReferencedEntity = [string]$_.referencedTables[0]
                            ReferencingEntity = $table.logicalName
                            ReferencingAttribute = $_.lookupColumn
                        }
                    })
                    Attributes = @($table.columns | ForEach-Object {
                        [pscustomobject]@{
                            LogicalName = $_.logicalName
                            AttributeType = @{
                                Text='String'; Lookup='Lookup'; GlobalChoice='Picklist'
                                DateOnly='DateTime'; DateTime='DateTime'; Customer='Customer'
                            }[$_.type]
                            Targets = @($_.lookup.targets)
                            MaxLength = $_.maxLength
                        }
                    })
                }) }
            }
            if ($Method -eq 'GET' -and $Path -match 'ObjectTypeCode') {
                return [pscustomobject]@{ ObjectTypeCode = 10427 }
            }
            if ($Method -eq 'GET') { return [pscustomobject]@{ value = @() } }
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
        } | Should -Throw '*key conflict*'
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

    It 'updates an empty existing choice rather than treating it as unchanged' {
        $choice = $script:contract.choices[0]
        Mock Invoke-DataverseRequest {
            param($Method, $Path, $Body, $Headers)
            $script:calls.Add([pscustomobject]@{
                Method=$Method; Path=$Path; Body=$Body; Headers=$Headers
            })
            if ($Method -eq 'GET' -and $Path -like '/GlobalOptionSetDefinitions*') {
                return [pscustomobject]@{ value = @([pscustomobject]@{
                    Name=$choice.logicalName; IsGlobal=$true
                    MetadataId='empty-choice'; Options=@()
                    SolutionUniqueName='crmshow_Foundation'
                }) }
            }
            if ($Method -eq 'GET') { return [pscustomobject]@{ value=@() } }
            return [pscustomobject]@{}
        }
        $contract = $script:contract | ConvertTo-Json -Depth 100 | ConvertFrom-Json
        $contract.choices = @($contract.choices[0]); $contract.nativeExtensions = @()
        $contract.tables = @(); $contract.roles = @()
        Invoke-InsuranceFoundationReconciliation $contract Foundation -Confirm:$false | Out-Null
        @($script:calls | Where-Object {
            $_.Method -eq 'PUT' -and $_.Path -like '/GlobalOptionSetDefinitions(empty-choice)*'
        }).Count | Should -Be 1
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
                return [pscustomobject]@{ value = @([pscustomobject]@{
                    Name=$choice.logicalName; IsGlobal=$true; MetadataId='localized-choice'
                    Options=$desired.Options; DisplayName=$wrongDisplay
                    Description=$desired.Description; SolutionUniqueName='crmshow_Foundation'
                }) }
            }
            if ($Method -eq 'GET') { return [pscustomobject]@{ value=@() } }
            return [pscustomobject]@{}
        }
        $contract = $script:contract | ConvertTo-Json -Depth 100 | ConvertFrom-Json
        $contract.choices = @($contract.choices[0]); $contract.nativeExtensions = @()
        $contract.tables = @(); $contract.roles = @()
        Invoke-InsuranceFoundationReconciliation $contract Foundation -Confirm:$false | Out-Null
        @($script:calls | Where-Object Method -eq 'PUT').Count | Should -Be 1
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
}
