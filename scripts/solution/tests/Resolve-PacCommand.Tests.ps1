BeforeAll {
    . "$PSScriptRoot/../Resolve-PacCommand.ps1"
}

Describe "Resolve-PacCommand" {
    BeforeEach {
        $script:originalPacPath = $env:POWERPLATFORMTOOLS_PACPATH
    }

    AfterEach {
        $env:POWERPLATFORMTOOLS_PACPATH = $script:originalPacPath
    }

    It "uses the Power Platform actions executable path" {
        $fakePac = Join-Path $TestDrive 'pac'
        Set-Content -Path $fakePac -Value 'fake'
        $env:POWERPLATFORMTOOLS_PACPATH = $fakePac

        Resolve-PacCommand | Should -Be (Resolve-Path $fakePac).Path
    }

    It "finds pac inside the Power Platform actions directory" {
        $actionsFolder = Join-Path $TestDrive 'actions'
        New-Item -ItemType Directory -Force -Path $actionsFolder | Out-Null
        $fakePac = Join-Path $actionsFolder 'pac'
        Set-Content -Path $fakePac -Value 'fake'
        $env:POWERPLATFORMTOOLS_PACPATH = $actionsFolder

        Resolve-PacCommand | Should -Be (Resolve-Path $fakePac).Path
    }
}
