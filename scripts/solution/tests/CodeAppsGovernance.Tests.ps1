BeforeAll {
    $root = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
    $adr = Join-Path $root 'docs/adr/ADR-0041-code-apps-primary-for-bespoke-full-page-crm-ux.md'
    $pattern = Join-Path $root 'docs/superpowers/patterns/code-app-local-first-polish-loop.md'
    $instructions = Join-Path $root '.github/instructions/code-apps.instructions.md'
}

Describe 'Code Apps governance foundation' {
    It 'records the primary-build decision' {
        Test-Path $adr | Should -BeTrue
        Get-Content $adr -Raw | Should -Match 'Code Apps are primary for bespoke full-page CRM experiences'
    }

    It 'anchors the attended local-first loop' {
        Test-Path $pattern | Should -BeTrue
        $text = Get-Content $pattern -Raw
        $text | Should -Match 'npm run dev'
        $text | Should -Match 'pa app run'
        $text | Should -Match 'Visual Studio Code'
        $text | Should -Match 'DEV and TEST'
    }

    It 'scopes Code App source instructions' {
        Test-Path $instructions | Should -BeTrue
        $text = Get-Content $instructions -Raw
        $text | Should -Match 'power.config.json'
        $text | Should -Match 'generated Dataverse services'
        $text | Should -Match 'no fixture fallback'
    }
}