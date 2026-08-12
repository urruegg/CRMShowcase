BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
    $script:contractPath = Join-Path $script:repoRoot 'solution/schema/insurance-foundation.json'
    $script:schemaPath = Join-Path $script:repoRoot 'solution/schema/insurance-foundation.schema.json'
    $script:languages = @('1033', '1031', '1036', '1040')
    $script:forbiddenPrivileges = @(
        'Delete', 'Assign', 'Share', 'Customize', 'SecurityAdministration',
        'BulkDelete', 'AuditAdministration'
    )

    function Get-Contract {
        Get-Content -LiteralPath $script:contractPath -Raw -Encoding UTF8 |
            ConvertFrom-Json
    }

    function Assert-LocalizedMetadata {
        param(
            [Parameter(Mandatory)] $Metadata,
            [Parameter(Mandatory)] [string] $Component
        )

        foreach ($property in 'label', 'description') {
            $localized = $Metadata.$property
            @($localized.PSObject.Properties.Name) |
                Should -Be $script:languages -Because "$Component needs exactly four $property translations"
            foreach ($language in $script:languages) {
                $text = [string]$localized.$language
                $text | Should -Not -BeNullOrEmpty -Because "$Component needs a $language $property"
                $text.Trim() | Should -Be $text -Because "$Component metadata must not contain padding"
                $text | Should -Not -Match '(?i)\b(TBD|TODO|placeholder)\b'
                if ($property -eq 'description') {
                    $text | Should -Not -Be $Component -Because "$Component description must be semantic, not its identifier"
                    $text | Should -Not -Be ([string]$Metadata.label.$language) `
                        -Because "$Component description must explain more than its label"
                }
            }
        }
    }

    function Test-JsonInstanceSchema {
        param([Parameter(Mandatory)] [string] $Json)

        if (Get-Command Test-Json -ErrorAction SilentlyContinue) {
            try {
                return Test-Json -Json $Json -SchemaFile $script:schemaPath -ErrorAction Stop
            } catch {
                return $false
            }
        }

        $python = @'
import json, sys
from jsonschema import Draft202012Validator
instance = json.load(sys.stdin)
with open(sys.argv[1], encoding='utf-8-sig') as stream:
    schema = json.load(stream)
Draft202012Validator.check_schema(schema)
errors = sorted(Draft202012Validator(schema).iter_errors(instance), key=lambda e: list(e.path))
for error in errors:
    print('{}: {}'.format('/'.join(map(str, error.path)), error.message))
sys.exit(1 if errors else 0)
'@
        $validationOutput = $Json | & python -c $python $script:schemaPath
        return $LASTEXITCODE -eq 0
    }

    function Test-ContractSchema {
        Test-JsonInstanceSchema -Json (Get-Content $script:contractPath -Raw)
    }

    function Get-UndeclaredChoiceReferences {
        param([Parameter(Mandatory)] $Contract)

        $declared = @($Contract.choices.logicalName)
        $findings = [System.Collections.Generic.List[string]]::new()
        foreach ($extension in $Contract.nativeExtensions) {
            if ($extension.choice -notin $declared) {
                $findings.Add(
                    "nativeExtensions/$($extension.table)/$($extension.logicalName): $($extension.choice)"
                )
            }
        }
        foreach ($table in $Contract.tables) {
            foreach ($column in @($table.columns | Where-Object {
                $_.PSObject.Properties.Name -contains 'choice'
            })) {
                if ($column.choice -notin $declared) {
                    $findings.Add(
                        "tables/$($table.logicalName)/$($column.logicalName): $($column.choice)"
                    )
                }
            }
        }
        return @($findings)
    }

    function Get-ProhibitedContractFindings {
        param([Parameter(Mandatory)] [string] $Json)

        $findings = [System.Collections.Generic.List[string]]::new()

        # Absolute JSON Schema identifiers are metadata, not environment endpoints.
        $withoutSchemaUrls = $Json -replace 'https?://json-schema\.org/draft/[0-9-]+/schema', ''
        if ($withoutSchemaUrls -match '(?i)https?://[^"\\\s]*(?:\.crm\d*\.dynamics\.com|\.powerapps\.com|\.api\.powerplatform\.com)(?:[/:"\\\s]|$)') {
            $findings.Add('environment URL')
        }
        if ($Json -match '(?i)(?<![0-9a-f])[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}(?![0-9a-f])') {
            $findings.Add('GUID')
        }
        if ($Json -match '(?i)(?<![a-z0-9._%+-])[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}(?![a-z0-9.-])') {
            $findings.Add('email address')
        }

        $phoneCandidates = [regex]::Matches(
            $Json,
            '(?<![\w])(?:\+\d{1,3}[\s()./-]*)?(?:\d[\s()./-]*){7,15}(?![\w])'
        )
        foreach ($candidate in $phoneCandidates) {
            $value = $candidate.Value.Trim()
            $digitCount = ([regex]::Matches($value, '\d')).Count
            $hasPhoneShape = $value.StartsWith('+') -or
                $value -match '\(\d{2,4}\)' -or
                $value -match '\d[\s./-]\d'
            $isGuid = $value -match '(?i)^[0-9a-f]{8}-[0-9a-f-]{27}$'
            if ($digitCount -ge 7 -and $hasPhoneShape -and -not $isGuid) {
                $findings.Add('phone-like value')
                break
            }
        }

        if ($Json -match '(?i)\b(?:Mobiliar|Mobilière|Mobiliare|Mobi24)\b|(?i)\bMOBI(?:LIAR)?[-_:][A-Z0-9-]+\b') {
            $findings.Add('Mobiliar identifier or customer data')
        }
        # "Draft" is a legitimate Policy Status. Only explicit work markers are banned.
        if ($Json -match '(?i)\b(?:TBD|TODO|FIXME|XXX|placeholder|WIP)\b|\[(?:draft|work in progress)\]|"(?:_?draft|status)"\s*:\s*"draft"') {
            $findings.Add('draft marker')
        }
        return @($findings)
    }
}

Describe 'Insurance Foundation JSON contract' {
    It 'exists with its JSON Schema' {
        $script:contractPath | Should -Exist
        $script:schemaPath | Should -Exist
    }

    It 'validates against its draft 2020-12 schema' {
        Test-ContractSchema | Should -BeTrue
    }

    It 'uses closed reusable object definitions at every schema boundary' {
        $schema = Get-Content $script:schemaPath -Raw | ConvertFrom-Json
        @($schema.'$defs'.PSObject.Properties.Name) | Should -Contain 'localizedText'
        foreach ($definition in 'semanticMetadata','choiceOption','choice','nativeExtension',
            'table','column','lookup','alternateKey','relationship','businessRule',
            'surfaceComponent','view','form','role','tablePrivilege') {
            @($schema.'$defs'.PSObject.Properties.Name) | Should -Contain $definition
        }

        function Assert-ClosedObjectSchema($node, [string]$path) {
            if ($null -eq $node) { return }
            if ($node -is [System.Collections.IEnumerable] -and $node -isnot [string]) {
                $index = 0
                foreach ($item in $node) {
                    Assert-ClosedObjectSchema $item "$path/$index"
                    $index++
                }
                return
            }
            if ($node.PSObject) {
                if ($node.type -eq 'object') {
                    $node.additionalProperties |
                        Should -BeFalse -Because "object schema $path must reject undeclared properties"
                }
                foreach ($property in $node.PSObject.Properties) {
                    Assert-ClosedObjectSchema $property.Value "$path/$($property.Name)"
                }
            }
        }
        Assert-ClosedObjectSchema $schema '#'
    }

    It 'contains the exact language and owning-solution sets' {
        $contract = Get-Contract
        @($contract.languages) | Should -Be $script:languages
        @($contract.solutions) | Should -Be @('crmshow_Foundation', 'crmshow_DataModel')
    }

    It 'contains exactly the required custom tables in stable order' {
        $contract = Get-Contract
        @($contract.tables.logicalName) | Should -Be @(
            'crmshow_accountcontactrole',
            'crmshow_policyprojection',
            'crmshow_policypartyrole'
        )
    }

    It 'contains the exact required global choices in Foundation' {
        $contract = Get-Contract
        @($contract.choices.logicalName) | Should -Be @(
            'crmshow_accounttype',
            'crmshow_contactlifecyclestage',
            'crmshow_accountcontactroletype',
            'crmshow_policypartyroletype',
            'crmshow_policystatus',
            'crmshow_nbastatus',
            'crmshow_nbachannel',
            'crmshow_productline',
            'crmshow_region',
            'crmshow_metrictype'
        )
        @($contract.choices | Select-Object -ExpandProperty solution -Unique) |
            Should -Be @('crmshow_Foundation')
        $expectedOptions = @{
            crmshow_accounttype = @('Household','Business','Broker')
            crmshow_contactlifecyclestage = @('Prospect','InterestedParty','Customer')
            crmshow_accountcontactroletype = @(
                'HouseholdMember','BusinessContact','BrokerContact','DecisionMaker',
                'AuthorizedRepresentative','BeneficialOwner'
            )
            crmshow_policypartyroletype = @(
                'Policyholder','Insured','Payer','Owner','Driver','Beneficiary',
                'AuthorizedRepresentative'
            )
            crmshow_policystatus = @('Draft','Active','Suspended','Expired','Cancelled')
            crmshow_nbastatus = @('Active','Planned','Accepted','Dismissed')
            crmshow_nbachannel = @('Call','PhoneAppointment','Email','Teams','OnSite','ClickToCall')
            crmshow_productline = @('MotorVehicle','HouseholdContents','CommercialProperty','Pension3a','LegalProtection')
            crmshow_region = @('Mittelland','Zurich','Romandie','Ticino')
            crmshow_metrictype = @('GoalAttainment','GrowthYoY','NPS','Automation','Forecast','Conversion','Efficiency','Satisfaction','Quality')
        }
        foreach ($choice in $contract.choices) {
            @($choice.options.code) | Should -Be $expectedOptions[$choice.logicalName]
        }
        ($contract.choices.options | Where-Object { $_.PSObject.Properties.Name -contains 'value' }) |
            Should -BeNullOrEmpty
    }

    It 'contains the exact native extensions' {
        $contract = Get-Contract
        @($contract.nativeExtensions.logicalName) |
            Should -Be @('crmshow_accounttype', 'crmshow_lifecyclestage')
        ($contract.nativeExtensions | Where-Object logicalName -eq 'crmshow_accounttype').required |
            Should -BeTrue
        ($contract.nativeExtensions | Where-Object logicalName -eq 'crmshow_lifecyclestage').required |
            Should -BeFalse
    }

    It 'resolves every choice reference and locks the exact choice mappings' {
        $contract = Get-Contract
        @(Get-UndeclaredChoiceReferences -Contract $contract) |
            Should -BeNullOrEmpty

        $actual = [System.Collections.Generic.List[string]]::new()
        foreach ($extension in $contract.nativeExtensions) {
            $actual.Add(
                "$($extension.table)|$($extension.logicalName)|$($extension.choice)"
            )
        }
        foreach ($table in $contract.tables) {
            $tableName = $table.logicalName -replace '^crmshow_', ''
            foreach ($column in @($table.columns | Where-Object {
                $_.PSObject.Properties.Name -contains 'choice'
            })) {
                $actual.Add("$tableName|$($column.logicalName)|$($column.choice)")
            }
        }
        @($actual) | Should -Be @(
            'account|crmshow_accounttype|crmshow_accounttype',
            'contact|crmshow_lifecyclestage|crmshow_contactlifecyclestage',
            'accountcontactrole|crmshow_roletype|crmshow_accountcontactroletype',
            'policyprojection|crmshow_status|crmshow_policystatus',
            'policypartyrole|crmshow_roletype|crmshow_policypartyroletype'
        )
    }

    It 'detects an undeclared global choice reference through the referential check' {
        $contract = Get-Contract | ConvertTo-Json -Depth 100 | ConvertFrom-Json
        $contract.nativeExtensions[0].choice = 'crmshow_nonexistentchoice'

        @(Get-UndeclaredChoiceReferences -Contract $contract) |
            Should -Be @(
                'nativeExtensions/account/crmshow_accounttype: crmshow_nonexistentchoice'
            )
    }

    It 'rejects Text columns carrying lookup metadata' {
        $contract = Get-Contract
        $column = $contract.tables[0].columns |
            Where-Object logicalName -eq 'crmshow_name'
        $column | Add-Member -NotePropertyName lookup -NotePropertyValue ([pscustomobject]@{
            targets = @('account')
            authoring = 'InitialTableCreate'
        })

        Test-JsonInstanceSchema -Json ($contract | ConvertTo-Json -Depth 100) |
            Should -BeFalse
    }

    It 'rejects Lookup columns carrying maxLength and UTC format' {
        $contract = Get-Contract
        $column = $contract.tables[0].columns |
            Where-Object logicalName -eq 'crmshow_accountid'
        $column | Add-Member -NotePropertyName maxLength -NotePropertyValue 100
        $column | Add-Member -NotePropertyName format -NotePropertyValue 'UTC'

        Test-JsonInstanceSchema -Json ($contract | ConvertTo-Json -Depth 100) |
            Should -BeFalse
    }

    It 'defines exact columns and Customer authoring for PolicyPartyRole' {
        $contract = Get-Contract
        $expected = @{
            crmshow_accountcontactrole = @(
                'crmshow_name','crmshow_accountid','crmshow_contactid','crmshow_roletype',
                'crmshow_validfrom','crmshow_validto','crmshow_sourcesystem','crmshow_sourceid'
            )
            crmshow_policyprojection = @(
                'crmshow_name','crmshow_accountid','crmshow_policynumber','crmshow_externalsystem',
                'crmshow_externalid','crmshow_lineofbusinesscode','crmshow_status',
                'crmshow_effectivefrom','crmshow_effectiveto','crmshow_sourcelastmodifiedon',
                'crmshow_retrievedon'
            )
            crmshow_policypartyrole = @(
                'crmshow_name','crmshow_policyid','crmshow_partyid','crmshow_roletype',
                'crmshow_validfrom','crmshow_validto','crmshow_sourcesystem','crmshow_sourceid'
            )
        }
        foreach ($table in $contract.tables) {
            @($table.columns.logicalName) | Should -Be $expected[$table.logicalName]
        }
        $shape = @{
            crmshow_accountcontactrole = @(
                'Text:True','Lookup:True','Lookup:True','GlobalChoice:True',
                'DateOnly:True','DateOnly:False','Text:False','Text:False'
            )
            crmshow_policyprojection = @(
                'Text:True','Lookup:True','Text:True','Text:True','Text:True','Text:True',
                'GlobalChoice:True','DateOnly:True','DateOnly:False','DateTime:True','DateTime:True'
            )
            crmshow_policypartyrole = @(
                'Text:True','Lookup:True','Customer:True','GlobalChoice:True',
                'DateOnly:True','DateOnly:False','Text:True','Text:True'
            )
        }
        foreach ($table in $contract.tables) {
            @($table.columns | ForEach-Object { '{0}:{1}' -f $_.type, $_.required }) |
                Should -Be $shape[$table.logicalName]
        }
        $partyTable = $contract.tables | Where-Object logicalName -eq 'crmshow_policypartyrole'
        $party = $partyTable.columns | Where-Object logicalName -eq 'crmshow_partyid'
        $party.type | Should -Be 'Customer'
        $party.lookup.authoring | Should -Be 'CreateCustomerRelationships'
        @($party.lookup.targets) | Should -Be @('account', 'contact')
    }

    It 'locks mixed mastership and non-evidentiary AccountContactRole semantics' {
        $contract = Get-Contract
        $table = $contract.tables | Where-Object logicalName -eq 'crmshow_accountcontactrole'
        $expectedTableDescriptions = @{
            '1033' = 'Effective-dated relationship between a person and a household, business or broker Account. Roles are either CRM-authored with no source identity or source-projected with a source identity; they grant no authorization and are not customer evidence.'
            '1031' = 'Zeitlich gültige Beziehung einer Person zu einem Haushalts-, Unternehmens- oder Maklerkonto. Rollen sind entweder im CRM ohne Quellidentität erfasst oder mit Quellidentität aus einer Quelle projiziert; sie gewähren keine Berechtigung und sind kein Kundennachweis.'
            '1036' = "Relation datée entre une personne et un compte ménage, entreprise ou courtier. Les rôles sont soit créés dans le CRM sans identité source, soit projetés depuis une source avec une identité source; ils n’accordent aucune autorisation et ne constituent pas une preuve client."
            '1040' = 'Relazione con validità temporale tra una persona e un account familiare, aziendale o di brokeraggio assicurativo. I ruoli sono creati nel CRM senza identità della fonte oppure proiettati da una fonte con identità della fonte; non concedono autorizzazioni e non costituiscono prova per il cliente.'
        }
        foreach ($language in $script:languages) {
            $table.metadata.description.$language | Should -Be $expectedTableDescriptions[$language]
        }

        foreach ($columnName in 'crmshow_accountid','crmshow_contactid') {
            ($table.columns | Where-Object logicalName -eq $columnName).metadata.mastership |
                Should -Be 'Mixed'
        }

        $choice = $contract.choices | Where-Object logicalName -eq 'crmshow_accountcontactroletype'
        $expectedChoiceDescriptions = @{
            '1033' = 'Canonical CRM classification of how a person participates in an Account relationship during an effective interval on both CRM-authored and source-projected records; it grants no access or authority.'
            '1031' = 'Kanonische CRM-Klassifikation der Rolle einer Person in einer Kontobeziehung während eines Gültigkeitsintervalls für im CRM erfasste und aus einer Quelle projizierte Datensätze; sie gewährt weder Zugriff noch Befugnis.'
            '1036' = "Classification CRM canonique de la participation d’une personne à une relation de compte pendant une période, pour les enregistrements créés dans le CRM comme pour ceux projetés depuis une source; elle n’accorde ni accès ni pouvoir."
            '1040' = 'Classificazione CRM canonica della partecipazione di una persona alla relazione con un account durante un intervallo, sia per i record creati nel CRM sia per quelli proiettati da una fonte; non concede accesso né autorità.'
        }
        foreach ($language in $script:languages) {
            $choice.metadata.description.$language | Should -Be $expectedChoiceDescriptions[$language]
        }

        $schema = Get-Content $script:schemaPath -Raw | ConvertFrom-Json
        @($schema.'$defs'.semanticMetadata.properties.mastership.enum) | Should -Contain 'Mixed'
    }

    It 'locks PolicyPartyRole party relationship wording without a Customer label' {
        $contract = Get-Contract
        $table = $contract.tables | Where-Object logicalName -eq 'crmshow_policypartyrole'
        $relationship = $table.relationships |
            Where-Object name -eq 'crmshow_customer_policypartyroles'
        $relationship.role |
            Should -Be 'Policy party is an Account or Contact holding the projected role.'
        $expectedLabels = @{
            '1033' = 'Policy Party Roles by Party'
            '1031' = 'Policenparteienrollen nach Partei'
            '1036' = 'Rôles de partie à la police par partie'
            '1040' = 'Ruoli delle parti di polizza per parte'
        }
        $expectedDescriptions = @{
            '1033' = 'Many PolicyPartyRole records reference one Account or Contact as the policy party; that party may differ from the portfolio Account.'
            '1031' = 'Viele Policenparteienrollen verweisen auf ein Konto oder einen Kontakt als Policenpartei; diese Partei kann vom Portfoliokonto abweichen.'
            '1036' = 'Plusieurs enregistrements PolicyPartyRole référencent un compte ou un contact comme partie à la police; cette partie peut différer du compte de portefeuille.'
            '1040' = "Più record PolicyPartyRole fanno riferimento a un account o contatto come parte della polizza; tale parte può differire dall’account di portafoglio."
        }
        foreach ($language in $script:languages) {
            $relationship.metadata.label.$language | Should -Be $expectedLabels[$language]
            $relationship.metadata.description.$language | Should -Be $expectedDescriptions[$language]
        }
        @($relationship.role, $relationship.metadata.label.'1033',
            $relationship.metadata.description.'1033') -join ' ' |
            Should -Not -Match '\bCustomer\b'
    }

    It 'locks authoritative-source correction and insurance exclusions on projection forms' {
        $contract = Get-Contract
        $expected = @{
            crmshow_policyprojection = @{
                '1033' = 'Form for authorized inspection and reconciliation of projected policy context. Correct business facts in the authoritative source, then refresh CRM; this form performs no premium or rate calculation, underwriting or risk acceptance, putting coverage into force, cancellation or termination, payment administration, or source-policy alteration.'
                '1031' = 'Formular zur berechtigten Prüfung und Abstimmung des projizierten Policenkontexts. Fachliche Sachverhalte sind in der massgebenden Quelle zu korrigieren und danach im CRM zu aktualisieren; dieses Formular führt keine Prämien- oder Tarifberechnung, kein Underwriting oder keine Risikoannahme und keine Stornierung, Beendigung, Zahlungsverwaltung oder Änderung der Quellpolice durch und kann keinen Versicherungsschutz in Kraft setzen.'
                '1036' = "Formulaire d’inspection autorisée et de rapprochement du contexte de police projeté. Les faits métier sont corrigés dans la source faisant autorité, puis le CRM est actualisé; ce formulaire n’effectue aucun calcul de prime ou de tarif, aucune souscription ou acceptation du risque, ne peut mettre les garanties en vigueur, résilier ou mettre fin à la police, administrer les paiements ni modifier la police source."
                '1040' = "Modulo per l’ispezione autorizzata e la riconciliazione del contesto di polizza proiettato. I fatti aziendali vengono corretti nella fonte autorevole e poi il CRM viene aggiornato; il modulo non esegue calcoli di premio o tariffa, assunzione o accettazione del rischio, non può mettere in vigore la copertura, annullare o cessare la polizza, amministrare pagamenti né modificare la polizza fonte."
            }
            crmshow_policypartyrole = @{
                '1033' = 'Form for authorized inspection and reconciliation of projected policy-party roles. Correct business facts in the authoritative source, then refresh CRM; this form performs no premium or rate calculation, underwriting or risk acceptance, putting coverage into force, cancellation or termination, payment administration, or source-policy alteration.'
                '1031' = 'Formular zur berechtigten Prüfung und Abstimmung projizierter Policenparteienrollen. Fachliche Sachverhalte sind in der massgebenden Quelle zu korrigieren und danach im CRM zu aktualisieren; dieses Formular führt keine Prämien- oder Tarifberechnung, kein Underwriting oder keine Risikoannahme und keine Stornierung, Beendigung, Zahlungsverwaltung oder Änderung der Quellpolice durch und kann keinen Versicherungsschutz in Kraft setzen.'
                '1036' = "Formulaire d’inspection autorisée et de rapprochement des rôles projetés de partie à la police. Les faits métier sont corrigés dans la source faisant autorité, puis le CRM est actualisé; ce formulaire n’effectue aucun calcul de prime ou de tarif, aucune souscription ou acceptation du risque, ne peut mettre les garanties en vigueur, résilier ou mettre fin à la police, administrer les paiements ni modifier la police source."
                '1040' = "Modulo per l’ispezione autorizzata e la riconciliazione dei ruoli proiettati delle parti di polizza. I fatti aziendali vengono corretti nella fonte autorevole e poi il CRM viene aggiornato; il modulo non esegue calcoli di premio o tariffa, assunzione o accettazione del rischio, non può mettere in vigore la copertura, annullare o cessare la polizza, amministrare pagamenti né modificare la polizza fonte."
            }
        }
        foreach ($tableName in $expected.Keys) {
            $form = ($contract.tables | Where-Object logicalName -eq $tableName).forms[0]
            foreach ($language in $script:languages) {
                $form.metadata.description.$language |
                    Should -Be $expected[$tableName][$language]
            }
        }
    }

    It 'locks high-risk multilingual insurance terms' {
        $contract = Get-Contract
        $accountRoles = $contract.choices |
            Where-Object logicalName -eq 'crmshow_accountcontactroletype'
        $policyRoles = $contract.choices |
            Where-Object logicalName -eq 'crmshow_policypartyroletype'
        $accountAuthorized = $accountRoles.options |
            Where-Object code -eq 'AuthorizedRepresentative'
        $policyAuthorized = $policyRoles.options |
            Where-Object code -eq 'AuthorizedRepresentative'
        $accountAuthorized.metadata.label.'1031' | Should -Be 'Bevollmächtigte Person'
        $accountAuthorized.metadata.description.'1031' |
            Should -Be 'Als bevollmächtigte Person in der Kontobeziehung erfasst; die aktuelle Befugnis ist anhand massgebender Nachweise zu prüfen.'
        $policyAuthorized.metadata.label.'1031' | Should -Be 'Bevollmächtigte Partei'
        $policyAuthorized.metadata.description.'1031' |
            Should -Be 'Im Policenkontext als bevollmächtigte Partei abgebildet; die aktuelle Befugnis muss anhand der massgebenden Quelle geprüft werden.'

        $status = $contract.choices | Where-Object logicalName -eq 'crmshow_policystatus'
        $draft = $status.options | Where-Object code -eq 'Draft'
        $cancelled = $status.options | Where-Object code -eq 'Cancelled'
        @($cancelled.metadata.label.'1033', $cancelled.metadata.label.'1031',
            $cancelled.metadata.label.'1036', $cancelled.metadata.label.'1040') |
            Should -Be @('Cancelled / Terminated','Storniert / beendet',
                'Annulée / résiliée','Annullata / cessata')
        $expectedCancelledDescriptions = @{
            '1033' = 'Broad mapped status for a policy ended in the authoritative source. CRM does not infer the legal mode, effective date or coverage consequence and cannot cancel, reinstate or determine coverage.'
            '1031' = 'Breit abgebildeter Status für eine in der massgebenden Quelle beendete Police. Das CRM leitet weder Rechtsform, Wirksamkeitsdatum noch Deckungsfolge ab und kann weder stornieren, reaktivieren noch Deckung bestimmen.'
            '1036' = "Statut mappé large pour une police terminée dans la source faisant autorité. Le CRM ne déduit ni le mode juridique, ni la date d’effet, ni les conséquences sur les garanties et ne peut ni résilier, ni rétablir, ni déterminer la couverture."
            '1040' = 'Stato mappato ampio per una polizza cessata nella fonte autorevole. Il CRM non deduce la modalità giuridica, la data di efficacia o le conseguenze sulla copertura e non può annullare, riattivare o determinare la copertura.'
        }
        foreach ($language in $script:languages) {
            $cancelled.metadata.description.$language |
                Should -Be $expectedCancelledDescriptions[$language]
        }
        @($draft.metadata.description.'1033', $draft.metadata.description.'1031',
            $draft.metadata.description.'1036', $draft.metadata.description.'1040') |
            Should -Be @(
                'Mapped state for a policy not yet active in its source lifecycle; CRM users cannot put coverage into force.',
                'Abgebildeter Zustand einer im Quelllebenszyklus noch nicht aktiven Police; CRM-Benutzende können keinen Versicherungsschutz in Kraft setzen.',
                "État mappé d’une police non encore active dans son cycle source; les utilisateurs CRM ne peuvent pas mettre les garanties en vigueur.",
                'Stato mappato di una polizza non ancora attiva nel ciclo fonte; gli utenti CRM non possono mettere in vigore la copertura.'
            )

        $raw = Get-Content -LiteralPath $script:contractPath -Raw -Encoding UTF8
        $raw | Should -Not -Match '(?i)Intermediario'
        $raw | Should -Not -Match '(?i)\b(bind|binden|lier|vincolare)\b'
    }

    It 'defines exact alternate keys' {
        $contract = Get-Contract
        $keys = @{}
        foreach ($table in $contract.tables) {
            $keys[$table.logicalName] = @($table.alternateKeys[0].columns)
            @($table.alternateKeys) | Should -HaveCount 1
        }
        $keys.crmshow_accountcontactrole |
            Should -Be @('crmshow_accountid','crmshow_contactid','crmshow_roletype','crmshow_validfrom')
        $keys.crmshow_policyprojection |
            Should -Be @('crmshow_externalsystem','crmshow_externalid')
        $keys.crmshow_policypartyrole |
            Should -Be @('crmshow_sourcesystem','crmshow_sourceid')
    }

    It 'uses UserOwned audited non-activity tables' {
        $contract = Get-Contract
        foreach ($table in $contract.tables) {
            $table.ownership | Should -Be 'UserOwned'
            $table.auditing | Should -BeTrue
            $table.isActivity | Should -BeFalse
            $table.solution | Should -Be 'crmshow_DataModel'
        }
    }

    It 'declares the thin policy projection exclusions' {
        $contract = Get-Contract
        $policy = $contract.tables | Where-Object logicalName -eq 'crmshow_policyprojection'
        @($policy.excludedConcepts) |
            Should -Be @('premium','tariff','underwriting','coverageLimit','paymentBalance')
    }

    It 'defines the exact lookup relationships and authoring modes' {
        $contract = Get-Contract
        $expected = @{
            crmshow_accountcontactrole = @(
                'crmshow_account_accountcontactroles|crmshow_accountid|crmshow_accountcontactrole|account|ManyToOne|Account contains the relationship context; role records reference it.|InitialTableCreate',
                'crmshow_contact_accountcontactroles|crmshow_contactid|crmshow_accountcontactrole|contact|ManyToOne|Contact is the person holding the role; role records reference it.|InitialTableCreate'
            )
            crmshow_policyprojection = @(
                'crmshow_account_policyprojections|crmshow_accountid|crmshow_policyprojection|account|ManyToOne|Account owns portfolio context; PolicyProjection references that Account.|InitialTableCreate'
            )
            crmshow_policypartyrole = @(
                'crmshow_policyprojection_partyroles|crmshow_policyid|crmshow_policypartyrole|crmshow_policyprojection|ManyToOne|PolicyProjection provides policy context; party-role records reference it.|InitialTableCreate',
                'crmshow_customer_policypartyroles|crmshow_partyid|crmshow_policypartyrole|account,contact|ManyToOne|Policy party is an Account or Contact holding the projected role.|CreateCustomerRelationships'
            )
        }
        foreach ($table in $contract.tables) {
            $actual = @($table.relationships | ForEach-Object {
                @($_.name, $_.lookupColumn, $_.referencingTable,
                    ($_.referencedTables -join ','), $_.direction, $_.role, $_.authoring) -join '|'
            })
            $wanted = @($expected[$table.logicalName])
            $actual | Should -Be $wanted

            foreach ($relationship in $table.relationships) {
                $column = $table.columns | Where-Object logicalName -eq $relationship.lookupColumn
                @($column.lookup.targets) | Should -Be @($relationship.referencedTables)
                $column.lookup.authoring | Should -Be $relationship.authoring
            }
        }
    }

    It 'defines the exact table-scoped date-order business rules' {
        $contract = Get-Contract
        $expected = @{
            crmshow_accountcontactrole = @('crmshow_accountcontactrolevaliddateorder','Table','crmshow_validto is blank or crmshow_validto >= crmshow_validfrom')
            crmshow_policyprojection = @('crmshow_policyprojectioneffectivedateorder','Table','crmshow_effectiveto is blank or crmshow_effectiveto >= crmshow_effectivefrom')
            crmshow_policypartyrole = @('crmshow_policypartyrolevaliddateorder','Table','crmshow_validto is blank or crmshow_validto >= crmshow_validfrom')
        }
        foreach ($table in $contract.tables) {
            @($table.businessRules | ForEach-Object { @($_.name,$_.scope,$_.condition) -join '|' }) |
                Should -Be @($expected[$table.logicalName] -join '|')
        }
    }

    It 'defines the exact minimal administration forms' {
        $contract = Get-Contract
        $expected = @{
            crmshow_accountcontactrole = @('crmshow_accountcontactroleadminform','Administration','crmshow_name,crmshow_accountid,crmshow_contactid,crmshow_roletype,crmshow_validfrom,crmshow_validto,crmshow_sourcesystem,crmshow_sourceid')
            crmshow_policyprojection = @('crmshow_policyprojectionadminform','Administration','crmshow_name,crmshow_accountid,crmshow_policynumber,crmshow_externalsystem,crmshow_externalid,crmshow_lineofbusinesscode,crmshow_status,crmshow_effectivefrom,crmshow_effectiveto,crmshow_sourcelastmodifiedon,crmshow_retrievedon')
            crmshow_policypartyrole = @('crmshow_policypartyroleadminform','Administration','crmshow_name,crmshow_policyid,crmshow_partyid,crmshow_roletype,crmshow_validfrom,crmshow_validto,crmshow_sourcesystem,crmshow_sourceid')
        }
        foreach ($table in $contract.tables) {
            @($table.forms | ForEach-Object { @($_.name,$_.purpose,($_.columns -join ',')) -join '|' }) |
                Should -Be @($expected[$table.logicalName] -join '|')
        }
    }

    It 'defines exact administration and overlap-reporting views' {
        $contract = Get-Contract
        $expected = @{
            crmshow_accountcontactrole = @(
                'crmshow_accountcontactroleadminview|Administration|crmshow_name,crmshow_accountid,crmshow_contactid,crmshow_roletype,crmshow_validfrom,crmshow_validto|All AccountContactRole records; no additional record filter.',
                'crmshow_accountcontactroleoverlapview|OverlapReporting|crmshow_accountid,crmshow_contactid,crmshow_roletype,crmshow_validfrom,crmshow_validto|Report distinct AccountContactRole pairs with the same Account, Contact and Role Type where A.Valid From <= coalesce(B.Valid To, open-ended) and B.Valid From <= coalesce(A.Valid To, open-ended).'
            )
            crmshow_policyprojection = @(
                'crmshow_policyprojectionadminview|Administration|crmshow_name,crmshow_accountid,crmshow_policynumber,crmshow_lineofbusinesscode,crmshow_status,crmshow_effectivefrom,crmshow_effectiveto,crmshow_retrievedon|All PolicyProjection records; no additional record filter.'
            )
            crmshow_policypartyrole = @(
                'crmshow_policypartyroleadminview|Administration|crmshow_name,crmshow_policyid,crmshow_partyid,crmshow_roletype,crmshow_validfrom,crmshow_validto|All PolicyPartyRole records; no additional record filter.',
                'crmshow_policypartyroleoverlapview|OverlapReporting|crmshow_policyid,crmshow_partyid,crmshow_roletype,crmshow_validfrom,crmshow_validto|Report distinct PolicyPartyRole pairs with the same Policy Projection, Party and Role Type where A.Valid From <= coalesce(B.Valid To, open-ended) and B.Valid From <= coalesce(A.Valid To, open-ended).'
            )
        }
        foreach ($table in $contract.tables) {
            $actual = @($table.views | ForEach-Object {
                @($_.name,$_.purpose,($_.columns -join ','),$_.filterIntent) -join '|'
            })
            $wanted = @($expected[$table.logicalName])
            $actual | Should -Be $wanted
        }
    }

    It 'provides complete semantic metadata in all four languages' {
        $contract = Get-Contract
        foreach ($choice in $contract.choices) {
            Assert-LocalizedMetadata $choice.metadata $choice.logicalName
            foreach ($option in $choice.options) {
                Assert-LocalizedMetadata $option.metadata "$($choice.logicalName)/$($option.code)"
            }
        }
        foreach ($extension in $contract.nativeExtensions) {
            Assert-LocalizedMetadata $extension.metadata $extension.logicalName
        }
        foreach ($table in $contract.tables) {
            Assert-LocalizedMetadata $table.metadata $table.logicalName
            foreach ($collection in 'columns','alternateKeys','relationships','businessRules','views','forms') {
                foreach ($component in $table.$collection) {
                    $name = if ($component.logicalName) { $component.logicalName } else { $component.name }
                    Assert-LocalizedMetadata $component.metadata "$($table.logicalName)/$name"
                }
            }
        }
        foreach ($role in $contract.roles) {
            Assert-LocalizedMetadata $role.metadata $role.name
        }
    }

    It 'contains no environment or customer content anywhere in the serialized contract' {
        $raw = Get-Content -LiteralPath $script:contractPath -Raw -Encoding UTF8
        @(Get-ProhibitedContractFindings -Json $raw) | Should -BeNullOrEmpty
    }

    It 'targets prohibited content without rejecting schema URLs, versions, LCIDs, or Draft policy status' {
        Get-ProhibitedContractFindings -Json '{"$schema":"https://json-schema.org/draft/2020-12/schema","version":"1.0.0","languages":["1033"],"code":"Draft"}' |
            Should -BeNullOrEmpty
        @(
            'https://showcase.crm4.dynamics.com',
            '8b4e705d-1f2a-4e93-8ad0-72901f1d671b',
            'person@example.com',
            '+41 79 123 45 67',
            'MOBI-POLICY-4711',
            '[DRAFT]'
        ) | ForEach-Object {
            @(Get-ProhibitedContractFindings -Json ('{"value":"' + $_ + '"}')) |
                Should -Not -BeNullOrEmpty -Because "'$_' must be detected"
        }
    }

    It 'implements the exact least-privilege role matrix' {
        $contract = Get-Contract
        @($contract.roles.name) | Should -Be @(
            'CRM Showcase Insurance Reader',
            'CRM Showcase Insurance Data Steward'
        )
        foreach ($role in $contract.roles) {
            $role.solution | Should -Be 'crmshow_Foundation'
            @($role.tablePrivileges) | Should -HaveCount 5
            foreach ($table in 'account','contact') {
                $entry = $role.tablePrivileges | Where-Object table -eq $table
                $entry.depth | Should -Be 'Organization'
                @($entry.privileges) | Should -Be @('Read')
            }
            foreach ($table in 'crmshow_accountcontactrole','crmshow_policyprojection','crmshow_policypartyrole') {
                $entry = $role.tablePrivileges | Where-Object table -eq $table
                $expected = if ($role.name -like '*Reader') {
                    @('Read')
                } else {
                    @('Create','Read','Write','Append','AppendTo')
                }
                $entry.depth | Should -Be 'Organization'
                @($entry.privileges) | Should -Be $expected
            }
            foreach ($entry in $role.tablePrivileges) {
                @($entry.privileges | Where-Object { $_ -in $script:forbiddenPrivileges }) |
                    Should -BeNullOrEmpty
            }
            @($role.deniedPrivileges) | Should -Be $script:forbiddenPrivileges
        }
    }
}
