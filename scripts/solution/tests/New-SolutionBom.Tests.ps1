BeforeAll {
    . "$PSScriptRoot/../New-SolutionBom.ps1"
}

Describe "New-SolutionBom" {
    BeforeEach {
        $script:fixture = Join-Path $TestDrive 'solution'
        New-Item -ItemType Directory -Force -Path (Join-Path $script:fixture 'Other') | Out-Null
        New-Item -ItemType Directory -Force -Path (Join-Path $script:fixture 'Entities\sample_account\FormXml\main') | Out-Null
        New-Item -ItemType Directory -Force -Path (Join-Path $script:fixture 'Entities\sample_account\SavedQueries') | Out-Null
        Set-Content -Path (Join-Path $script:fixture 'Other\Solution.xml') -Value @'
<ImportExportXml><SolutionManifest><RootComponents>
<RootComponent type="1" schemaName="sample_account" />
</RootComponents><MissingDependencies><MissingDependency>
<Required type="1" schemaName="external_policy" displayName="External policy" solution="External (1.0)" />
<Dependent type="1" schemaName="sample_account" displayName="Sample account" />
</MissingDependency></MissingDependencies></SolutionManifest></ImportExportXml>
'@
        Set-Content -Path (Join-Path $script:fixture 'Other\Relationships.xml') -Value @'
<EntityRelationships><EntityRelationship Name="sample_account_contact" /></EntityRelationships>
'@
        Set-Content -Path (Join-Path $script:fixture 'Entities\sample_account\Entity.xml') -Value @'
<Entity><Name LocalizedName="Sample account">sample_account</Name><EntityInfo>
<entity Name="sample_account"><attributes><attribute PhysicalName="sample_Name">
<Type>nvarchar</Type><Name>sample_name</Name><LogicalName>sample_name</LogicalName>
<RequiredLevel>none</RequiredLevel><displaynames><displayname description="Name" languagecode="1033" /></displaynames>
</attribute></attributes></entity></EntityInfo></Entity>
'@
        Set-Content -Path (Join-Path $script:fixture 'Entities\sample_account\FormXml\main\form-id.xml') -Value '<forms />'
        Set-Content -Path (Join-Path $script:fixture 'Entities\sample_account\SavedQueries\view-id.xml') -Value '<savedquery><LocalizedNames><LocalizedName description="Active samples" languagecode="1033" /></LocalizedNames></savedquery>'
        $script:model = Join-Path $TestDrive 'model'
        New-Item -ItemType Directory -Force -Path $script:model | Out-Null
        Set-Content -Path (Join-Path $script:model 'sample_account.cs') -Value @'
[Microsoft.Xrm.Sdk.Client.EntityLogicalNameAttribute("sample_account")]
public partial class SampleAccount {
[Microsoft.Xrm.Sdk.AttributeLogicalNameAttribute("sample_enriched")]
public virtual string SampleEnriched { get; set; }
[Microsoft.Xrm.Sdk.RelationshipSchemaNameAttribute("sample_enriched_relationship")]
public virtual object SampleRelationship { get; set; }
}
'@
    }

    It "inventories entity children and relationships" {
        $items = New-SolutionBom -SourceFolder $script:fixture
        $items.componentType | Should -Contain 'Entity'
        $items.componentType | Should -Contain 'Attribute'
        $items.componentType | Should -Contain 'Form'
        $items.componentType | Should -Contain 'View'
        $items.componentType | Should -Contain 'Relationship'
        $items.componentType | Should -Contain 'MissingDependency'
        ($items | Where-Object logicalName -eq 'sample_name').parent | Should -Be 'sample_account'
    }

    It "marks matching root components" {
        $entity = New-SolutionBom -SourceFolder $script:fixture |
            Where-Object logicalName -eq 'sample_account'
        $entity.rootComponent | Should -BeTrue
    }

    It "returns deterministic ordering" {
        $first = New-SolutionBom -SourceFolder $script:fixture | ConvertTo-Json -Depth 8
        $second = New-SolutionBom -SourceFolder $script:fixture | ConvertTo-Json -Depth 8
        $first | Should -BeExactly $second
    }

    It "enriches omitted metadata from model builder output" {
        $items = New-SolutionBom -SourceFolder $script:fixture -MetadataModelFolder $script:model
        ($items | Where-Object logicalName -eq 'sample_enriched').parent | Should -Be 'sample_account'
        $items.logicalName | Should -Contain 'sample_enriched_relationship'
    }

    It "rejects an incomplete domain mapping" {
        $mapping = Join-Path $TestDrive 'mapping.csv'
        @'
"componentType","logicalName","parent","domain","targetSolution","disposition","rationale","licenceReview","maturityReview"
"Entity","sample_account","","Party","crmshow_DataModel","Refactor","Native party table","Not required","Not required"
'@ | Set-Content $mapping
        {
            & "$PSScriptRoot/../New-SolutionBom.ps1" `
                -SourceFolder $script:fixture `
                -MappingPath $mapping `
                -JsonPath (Join-Path $TestDrive 'bom.json')
        } | Should -Throw '*Domain mapping missing BOM item*'
    }
}
