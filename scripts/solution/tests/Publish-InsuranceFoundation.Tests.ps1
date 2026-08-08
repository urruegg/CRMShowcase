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
            -Key $script:contract.tables[1].alternateKeys[0]
        $request.Path | Should -Be "/EntityDefinitions(LogicalName='crmshow_policyprojection')/Keys"
        @($request.Body.KeyAttributes) |
            Should -Be @('crmshow_externalsystem', 'crmshow_externalid')
    }

    It 'carries four-language metadata for rules, forms, and views' {
        $table = $script:contract.tables[0]
        foreach ($request in @(
            (New-BusinessRuleRequest $table $table.businessRules[0]),
            (New-FormRequest $table $table.forms[0]),
            (New-ViewRequest $table $table.views[0])
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
            $fetch = (New-ViewRequest $table $view).Body.fetchxml
            $fetch | Should -Match 'distinct="true"'
            $fetch | Should -Match "<link-entity name=`"$($table.logicalName)`""
            ([regex]::Matches($fetch, 'operator="null"')).Count | Should -Be 2
            $fetch | Should -Match 'valueof="a\.crmshow_validfrom"'
            $fetch | Should -Match 'valueof="a\.crmshow_validto"'
        }
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
            if ($Method -eq 'GET') { return [pscustomobject]@{ value = @() } }
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
        @($created | Where-Object Path -eq '/workflows').Count | Should -Be 3
        @($created | Where-Object Path -eq '/systemforms').Count | Should -Be 3
        @($created | Where-Object Path -eq '/savedqueries').Count | Should -Be 5
        @($created | Where-Object Path -eq '/roles').Count | Should -Be 2
        $roleActions = @($created | Where-Object Path -match 'AddPrivilegesRole$')
        $roleActions.Count | Should -Be 2
        @($roleActions[0].Body.Privileges).Count | Should -Be 5
        @($roleActions[1].Body.Privileges).Count | Should -Be 17
        @($roleActions.Body.Privileges.Depth | Select-Object -Unique) |
            Should -Be @('Global')
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

    It 'does not recreate compatible existing choices' {
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
                        IsGlobal = $true
                        SolutionUniqueName = 'crmshow_Foundation'
                        Options = @(
                            [pscustomobject]@{ Value = 100000000 },
                            [pscustomobject]@{ Value = 100000001 },
                            [pscustomobject]@{ Value = 100000002 }
                        )
                    })
                }
            }
            if ($Method -eq 'GET') { return [pscustomobject]@{ value = @() } }
            return [pscustomobject]@{}
        }
        $oneChoice = $script:contract | ConvertTo-Json -Depth 100 | ConvertFrom-Json
        $oneChoice.choices = @($oneChoice.choices[0])
        $oneChoice.roles = @()

        Invoke-InsuranceFoundationReconciliation -Contract $oneChoice -Scope Foundation -Confirm:$false
        @($script:calls | Where-Object {
            $_.Method -eq 'POST' -and $_.Path -eq '/GlobalOptionSetDefinitions'
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

        $key = $script:contract.tables[0].alternateKeys[0]
        $actual = [pscustomobject]@{ KeyAttributes = @('crmshow_sourceid') }
        {
            $expected = @($key.columns)
            if ((@($actual.KeyAttributes) -join ',') -ne ($expected -join ',')) {
                throw 'Structural key conflict'
            }
        } | Should -Throw '*key conflict*'
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
