BeforeAll {
    $root = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
    $adr = Join-Path $root 'docs/adr/ADR-0041-code-apps-primary-for-bespoke-full-page-crm-ux.md'
    $almAdr = Join-Path $root 'docs/adr/ADR-0017-alm-everything-through-the-pipeline.md'
    $retainedPcfAdr = Join-Path $root 'docs/adr/ADR-0027-page-level-pcf-and-local-first-polish-loop.md'
    $pattern = Join-Path $root 'docs/superpowers/patterns/code-app-local-first-polish-loop.md'
    $plan = Join-Path $root 'docs/superpowers/plans/2026-08-19-power-apps-code-app-advisor-cockpit-parity.md'
    $instructions = Join-Path $root '.github/instructions/code-apps.instructions.md'
    $uxDesigner = Join-Path $root '.github/agents/ux-designer.agent.md'
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

    It 'uses the exact Code App source applyTo contract' {
        $applyToLines = @(Get-Content $instructions | Where-Object { $_ -match '^applyTo:' })
        $applyToLines | Should -HaveCount 1
        $applyToLines[0] | Should -BeExactly "applyTo: 'solution/apps/**/{code-apps,packages}/**/*.{ts,tsx,js,json,html,css}'"
    }

    It 'requires an explicit solution-targeted DEV push' {
        $text = Get-Content $instructions -Raw
        $text | Should -Match ([regex]::Escape('pa app push --solution-id <crmshow_Sales GUID>'))
    }

    It 'requires publication from a clean reviewed checkout' {
        $text = Get-Content $instructions -Raw
        $text | Should -Match 'clean reviewed checkout'
    }

    It 'requires SHA-256 publication evidence' {
        $text = Get-Content $instructions -Raw
        $text | Should -Match 'SHA-256'
    }

    It 'requires ADR-0017 publication from a clean reviewed checkout' {
        Get-Content $almAdr -Raw | Should -Match 'clean reviewed checkout'
    }

    It 'requires ADR-0017 SHA-256 publication evidence' {
        Get-Content $almAdr -Raw | Should -Match 'SHA-256'
    }

    It 'requires ADR-0017 to use an explicit solution-targeted DEV push' {
        Get-Content $almAdr -Raw | Should -Match ([regex]::Escape('pa app push --solution-id <crmshow_Sales GUID>'))
    }

    It 'requires ADR-0041 publication from a clean reviewed checkout' {
        Get-Content $adr -Raw | Should -Match 'clean reviewed checkout'
    }

    It 'requires ADR-0041 SHA-256 publication evidence' {
        Get-Content $adr -Raw | Should -Match 'SHA-256'
    }

    It 'requires ADR-0041 to use an explicit solution-targeted DEV push' {
        Get-Content $adr -Raw | Should -Match ([regex]::Escape('pa app push --solution-id <crmshow_Sales GUID>'))
    }

    It 'requires the pattern publication from a clean reviewed checkout' {
        Get-Content $pattern -Raw | Should -Match 'clean reviewed checkout'
    }

    It 'requires the pattern SHA-256 publication evidence' {
        Get-Content $pattern -Raw | Should -Match 'SHA-256'
    }

    It 'requires the pattern to use an explicit solution-targeted DEV push' {
        Get-Content $pattern -Raw | Should -Match ([regex]::Escape('pa app push --solution-id <crmshow_Sales GUID>'))
    }

    It 'enforces one deterministic publication contract across all four authorities' {
        $authorities = @(
            @{ Name = 'ADR-0017'; Path = $almAdr }
            @{ Name = 'ADR-0041'; Path = $adr }
            @{ Name = 'Code App instructions'; Path = $instructions }
            @{ Name = 'Code App pattern'; Path = $pattern }
        )
        $requiredConcepts = @(
            @{
                Name = 'clean reviewed checkout at the reviewed commit'
                Pattern = 'clean\s+reviewed\s+checkout\s+at\s+the\s+reviewed(?:\s+Git)?\s+commit'
            }
            @{
                Name = 'build and test immediately before publication'
                Pattern = 'build(?:s)?\s+and\s+test(?:s)?\s+immediately\s+before\s+publication'
            }
            @{
                Name = 'configured environment matches the approved DEV environment ID'
                Pattern = 'verif(?:y|ies)\s+(?:each\s+)?(?:app(?:''s)?\s+)?`?power\.config\.json`?\s+(?:is\s+)?bound\s+to\s+the\s+approved\s+DEV\s+environment\s+ID'
            }
            @{
                Name = 'deterministic sorted per-file SHA-256 manifest'
                Pattern = '(?s)sorted\s+per-file\s+SHA-256\s+manifest.*normalized\s+relative\s+paths'
            }
            @{
                Name = 'BOM-free UTF-8 manifest serialization'
                Pattern = 'BOM-free\s+UTF-8\s+manifest'
            }
            @{
                Name = 'dist remains unchanged between hashing and push'
                Pattern = '(?s)leave\s+`?dist`?\s+unchanged\s+between\s+hashing\s+and\s+push'
            }
            @{
                Name = 'exact solution-targeted push command'
                Pattern = [regex]::Escape('pa app push --solution-id <crmshow_Sales GUID>')
            }
            @{
                Name = 'complete publication evidence fields'
                Pattern = '(?is)publication\s+evidence\s+record(?:s)?\s+the\s+commit\s*,?\s*manifest\s+hash(?:es)?\s*,?\s*successful\s+build\s+and\s+test\s+evidence\s*,?\s*CLI\s+version\s*,?\s*app\s+identity\s*,?\s*solution\s+identity\s*,?\s*approved\s+DEV\s+environment\s+ID\s*,?\s*returned\s+play\s+URL\s*,?\s*runtime\s+environment\s+ID\s*,?\s*operator\s*,?\s*timestamp\s*(?:,?\s*and)?\s*result'
            }
            @{
                Name = 'DEV-only publication'
                Pattern = 'DEV\s+only'
            }
            @{
                Name = 'no introduced or stored client secret'
                Pattern = 'no\s+client\s+secret\s+is\s+introduced\s+or\s+stored'
            }
            @{
                Name = 'exact managed artifact reaches TEST through the existing OIDC pipeline'
                Pattern = 'TEST\s+receives\s+the\s+exact\s+managed\s+artifact\s+through\s+the\s+existing\s+OIDC\s+pipeline'
            }
            @{
                Name = 'direct TEST authoring is prohibited'
                Pattern = 'direct\s+TEST\s+authoring\s+is\s+prohibited'
            }
            @{
                Name = 'runtime environment verification through getContext'
                Pattern = '(?s)getContext\(\)\.app\.environmentId.*approved\s+DEV\s+environment\s+ID'
            }
        )

        $gaps = foreach ($authority in $authorities) {
            $text = Get-Content $authority.Path -Raw
            foreach ($concept in $requiredConcepts) {
                if ($text -notmatch $concept.Pattern) {
                    "$($authority.Name): $($concept.Name)"
                }
            }
        }

        ($gaps -join [Environment]::NewLine) | Should -BeNullOrEmpty -Because 'each authority must state the complete deterministic publication contract'
    }

    It 'separates attended publication from runtime evidence finalization' {
        Test-Path $plan | Should -BeTrue
        $text = Get-Content $plan -Raw
        $text | Should -Match 'Complete-CodeAppsDevEvidence\.ps1'
        $text | Should -Match 'RuntimeVerification\s*=\s*''Pending'''
        $text | Should -Match 'RuntimeVerification\s*=\s*''Verified'''
        $text | Should -Match '(?s)refuse.*runtime environment ID.*approved DEV.*environment ID'
    }

    It 'defines Code App localization ownership in source instructions' {
        $text = Get-Content $instructions -Raw
        $text | Should -Match ([regex]::Escape('Dataverse/MDA metadata labels use native localization'))
        $text | Should -Match ([regex]::Escape('Code App-owned strings use versioned app-local catalogs'))
        $text | Should -Match 'EN/DE/FR/IT'
        $text | Should -Match 'never hard-code user-facing strings'
    }

    It 'defines one deterministic Code App locale resolution contract' {
        $text = Get-Content $instructions -Raw
        $text | Should -Match ([regex]::Escape('navigator.languages'))
        $text | Should -Match ([regex]::Escape('Intl.getCanonicalLocales'))
        $text | Should -Match '(?s)de.*fr.*it.*fallback.*en'
        $text | Should -Match '(?s)getContext.*does\s+not\s+expose\s+a\s+locale'
    }

    It 'separates Dataverse metadata localization from Code App-owned strings' {
        Test-Path $uxDesigner | Should -BeTrue
        $text = Get-Content $uxDesigner -Raw
        $text | Should -Match 'Dataverse(?:/MDA)?\s+metadata\s+labels\s+use\s+native\s+localization'
        $text | Should -Match 'Code App-owned\s+strings\s+use\s+versioned\s+app-local\s+catalogs'
    }

    It 'gives the UX designer valid shell execution access' {
        $toolsLines = @(Get-Content $uxDesigner | Where-Object { $_ -match '^tools:' })
        $toolsLines | Should -HaveCount 1
        $toolsLines[0] | Should -Match "'execute'"
        $toolsLines[0] | Should -Not -Match "'powershell'"
    }

    It 'delegates browser opening to the controlling VS Code chat' {
        $text = Get-Content $uxDesigner -Raw
        $text | Should -Match 'controlling VS Code chat'
    }

    It 'records retained controls as Vitest-tested' {
        Test-Path $retainedPcfAdr | Should -BeTrue
        Get-Content $retainedPcfAdr -Raw | Should -Match 'Vitest-tested'
    }

    It 'does not claim retained controls are Jest-tested' {
        Get-Content $retainedPcfAdr -Raw | Should -Not -Match 'Jest-tested'
    }
}
