BeforeAll {
    . "$PSScriptRoot/../Get-SolutionOrder.ps1"
    . "$PSScriptRoot/../Get-Manifest.ps1"
    $script:repoRoot = Resolve-Path "$PSScriptRoot/../../.."
}

Describe "Get-SolutionOrder" {
    BeforeEach {
        $script:m = Get-Manifest -Path (Join-Path $script:repoRoot 'solution/manifest.json')
    }

    It "returns Foundation first" {
        $ordered = Get-SolutionOrder -Manifest $script:m
        $ordered[0].uniqueName | Should -Be 'crmshow_Foundation'
    }

    It "puts DataModel and Integration after Foundation" {
        $ordered = Get-SolutionOrder -Manifest $script:m
        $names = @($ordered | ForEach-Object { $_.uniqueName })
        $indexFoundation = $names.IndexOf('crmshow_Foundation')
        $indexDataModel = $names.IndexOf('crmshow_DataModel')
        $indexIntegration = $names.IndexOf('crmshow_Integration')
        $indexDataModel | Should -BeGreaterThan $indexFoundation
        $indexIntegration | Should -BeGreaterThan $indexFoundation
    }

    It "puts every app after DataModel and Integration" {
        $ordered = Get-SolutionOrder -Manifest $script:m
        $names = @($ordered | ForEach-Object { $_.uniqueName })
        foreach ($app in 'crmshow_Sales','crmshow_Service','crmshow_Marketing') {
            $names.IndexOf($app) | Should -BeGreaterThan $names.IndexOf('crmshow_DataModel')
            $names.IndexOf($app) | Should -BeGreaterThan $names.IndexOf('crmshow_Integration')
        }
    }

    It "returns all 6 solutions" {
        $ordered = Get-SolutionOrder -Manifest $script:m
        $ordered | Should -HaveCount 6
    }

    It "emits one solution object per pipeline iteration" {
        $iterations = 0
        foreach ($solution in Get-SolutionOrder -Manifest $script:m) {
            $iterations++
            $solution.uniqueName | Should -BeOfType [string]
            $solution.path | Should -BeOfType [string]
        }
        $iterations | Should -Be 6
    }

    It "throws on circular dependency" {
        $bad = $script:m | ConvertTo-Json -Depth 10 | ConvertFrom-Json
        $bad.solutions[0].dependsOn = @('crmshow_Sales')  # Foundation now depends on Sales (which depends on Foundation)
        { Get-SolutionOrder -Manifest $bad } | Should -Throw -ExpectedMessage '*circular*'
    }

    It "throws on unknown dependency" {
        $bad = $script:m | ConvertTo-Json -Depth 10 | ConvertFrom-Json
        $bad.solutions[3].dependsOn = @('crmshow_Nonexistent')
        { Get-SolutionOrder -Manifest $bad } | Should -Throw -ExpectedMessage '*unknown*'
    }
}