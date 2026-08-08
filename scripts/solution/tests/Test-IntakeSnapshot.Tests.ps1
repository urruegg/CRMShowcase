BeforeAll {
    . "$PSScriptRoot/../Test-IntakeSnapshot.ps1"
}

Describe "Test-IntakeSnapshot" {
    It "passes safe structural metadata" {
        $safe = Join-Path $TestDrive 'safe'
        New-Item -ItemType Directory -Force -Path $safe | Out-Null
        Set-Content -Path (Join-Path $safe 'Solution.xml') -Value '<SolutionManifest><UniqueName>Prototype</UniqueName></SolutionManifest>'
        { Test-IntakeSnapshot -Path $safe -ForbiddenEnvironmentHost 'source.example.test' } | Should -Not -Throw
    }

    It "rejects secret and environment patterns" {
        $unsafe = Join-Path $TestDrive 'unsafe'
        New-Item -ItemType Directory -Force -Path $unsafe | Out-Null
        Set-Content -Path (Join-Path $unsafe 'config.json') -Value '{"value":"AccountKey=secret","url":"https://source.example.test"}'
        { Test-IntakeSnapshot -Path $unsafe -ForbiddenEnvironmentHost 'source.example.test' } | Should -Throw '*Unsafe intake content*'
    }

    It "reports matches without throwing when requested" {
        $unsafe = Join-Path $TestDrive 'report'
        New-Item -ItemType Directory -Force -Path $unsafe | Out-Null
        Set-Content -Path (Join-Path $unsafe 'content.html') -Value 'Contact demo@example.test'
        $result = Test-IntakeSnapshot -Path $unsafe -ReportOnly
        $result.matchCount | Should -Be 1
        $result.matches.category | Should -Contain 'EmailAddress'
    }
}
