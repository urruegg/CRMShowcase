BeforeAll {
    . "$PSScriptRoot/../Get-Manifest.ps1"
    $script:repoRoot = Resolve-Path "$PSScriptRoot/../../.."
}

Describe "Get-Manifest" {
    It "returns an object with publisher, versioning, solutions" {
        $m = Get-Manifest -Path (Join-Path $script:repoRoot 'solution/manifest.json')
        $m | Should -Not -BeNullOrEmpty
        $m.publisher | Should -Not -BeNullOrEmpty
        $m.publisher.prefix | Should -Be 'crmshow'
        $m.versioning.scheme | Should -Be 'semver-four-part'
        $m.solutions | Should -HaveCount 6
    }

    It "validates the manifest against manifest.schema.json" {
        { Get-Manifest -Path (Join-Path $script:repoRoot 'solution/manifest.json') -Validate } | Should -Not -Throw
    }

    It "versions the Sprint 3 Foundation solution at 1.1.0.0 and DataModel at 1.2.0.0" {
        $m = Get-Manifest -Path (Join-Path $script:repoRoot 'solution/manifest.json')
        ($m.solutions | Where-Object uniqueName -eq 'crmshow_Foundation').version |
            Should -Be '1.1.0.0'
        ($m.solutions | Where-Object uniqueName -eq 'crmshow_DataModel').version |
            Should -Be '1.2.0.0'
    }

    It "throws on missing file" {
        { Get-Manifest -Path 'nonexistent.json' } | Should -Throw
    }

    It "throws on invalid JSON" {
        $tmp = New-TemporaryFile
        Set-Content -Path $tmp -Value '{ invalid json'
        try { { Get-Manifest -Path $tmp } | Should -Throw } finally { Remove-Item $tmp -Force }
    }
}