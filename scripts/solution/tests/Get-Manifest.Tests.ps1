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

    It "throws on missing file" {
        { Get-Manifest -Path 'nonexistent.json' } | Should -Throw
    }

    It "throws on invalid JSON" {
        $tmp = New-TemporaryFile
        Set-Content -Path $tmp -Value '{ invalid json'
        try { { Get-Manifest -Path $tmp } | Should -Throw } finally { Remove-Item $tmp -Force }
    }
}