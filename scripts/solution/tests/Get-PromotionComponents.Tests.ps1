BeforeAll {
    . "$PSScriptRoot/../Get-PromotionComponents.ps1"

    function New-Schema {
        $p = Join-Path $TestDrive 'schema.json'
        $json = @'
{
  "solutions": ["crmshow_Foundation", "crmshow_DataModel"],
  "tables": [
    {
      "logicalName": "crmshow_accountcontactrole",
      "businessRules": [ { "name": "crmshow_accountcontactrolevaliddateorder" } ],
      "views": [
        { "name": "crmshow_accountcontactroleadminview", "purpose": "Administration" },
        { "name": "crmshow_accountcontactroleoverlapview", "purpose": "OverlapReporting" }
      ]
    }
  ]
}
'@
        Set-Content -LiteralPath $p -Value $json
        return $p
    }
}

Describe "Get-PromotionComponents" {
    It "excludes business rules and reporting views, keeps admin views" {
        $c = Get-PromotionComponents -SchemaPath (New-Schema)
        $c.Tables                | Should -Contain 'crmshow_accountcontactrole'
        $c.InScopeViews          | Should -Contain 'crmshow_accountcontactroleadminview'
        $c.ExcludedViews         | Should -Contain 'crmshow_accountcontactroleoverlapview'
        $c.ExcludedBusinessRules | Should -Contain 'crmshow_accountcontactrolevaliddateorder'
        $c.ExcludedComponents    | Should -Contain 'crmshow_accountcontactroleoverlapview'
        $c.ExcludedComponents    | Should -Contain 'crmshow_accountcontactrolevaliddateorder'
    }

    It "flags a package that contains an excluded component" {
        $c = Get-PromotionComponents -SchemaPath (New-Schema)
        $violations = Test-PromotionPackageComponents `
            -PackageComponentNames @('crmshow_accountcontactrole','crmshow_accountcontactroleoverlapview') `
            -ExcludedComponents $c.ExcludedComponents
        $violations | Should -Contain 'crmshow_accountcontactroleoverlapview'
    }

    It "passes a clean package" {
        $c = Get-PromotionComponents -SchemaPath (New-Schema)
        $violations = Test-PromotionPackageComponents `
            -PackageComponentNames @('crmshow_accountcontactrole','crmshow_accountcontactroleadminview') `
            -ExcludedComponents $c.ExcludedComponents
        @($violations).Count | Should -Be 0
    }

    It "throws when the schema is missing" {
        { Get-PromotionComponents -SchemaPath (Join-Path $TestDrive 'nope.json') } | Should -Throw
    }
}
