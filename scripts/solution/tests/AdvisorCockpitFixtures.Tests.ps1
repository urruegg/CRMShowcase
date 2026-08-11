# Pester tests for the Advisor Cockpit scenario fixtures (Sprint 3, Phase 5).
# Asserts measures.json satisfies the Phase-4 measure-snapshot contract and that
# no fixture leaks a real-looking e-mail or phone number (synthetic-data guard).

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
    $script:fixtureDir = Join-Path $script:repoRoot 'data/scenarios/advisor-cockpit'
    $script:schemaPath = Join-Path $script:repoRoot 'api/advisor-cockpit/measure-snapshot.schema.json'

    $script:subjectTypes = @('lead', 'account', 'contact', 'ga', 'region', 'product', 'portfolio')
    $script:metrics = @('GoalAttainment', 'GrowthYoY', 'NPS', 'Automation', 'Forecast', 'Conversion', 'Efficiency', 'Satisfaction', 'Quality')
    $script:regions = @('Mittelland', 'Zurich', 'Romandie', 'Ticino')
    $script:productLines = @('MotorVehicle', 'HouseholdContents', 'CommercialProperty', 'Pension3a', 'LegalProtection')

    # Domains that can never be a real recipient (RFC 2606 + RFC 6761 reserved).
    $script:allowedEmailDomains = @('example', 'example.com', 'example.org', 'example.net', 'contoso.example', 'fabrikam.example', 'adventure-works.example')

    $script:fixtureFiles = @(Get-ChildItem -LiteralPath $script:fixtureDir -Filter '*.json' | Select-Object -ExpandProperty FullName)
}

Describe 'advisor-cockpit fixtures' {
    It 'contains all seven scenario fixtures' {
        $names = @($script:fixtureFiles | ForEach-Object { Split-Path $_ -Leaf })
        foreach ($expected in @('measures.json', 'accounts-contacts.json', 'leads.json', 'activities.json', 'nba.json', 'policies.json', 'claims.json')) {
            $names | Should -Contain $expected
        }
    }

    It 'every fixture is valid JSON' {
        foreach ($f in $script:fixtureFiles) {
            { Get-Content -LiteralPath $f -Raw -Encoding UTF8 | ConvertFrom-Json } | Should -Not -Throw -Because "$([System.IO.Path]::GetFileName($f)) must parse"
        }
    }

    It 'measures.json satisfies the measure-snapshot contract rules' {
        $measuresPath = Join-Path $script:fixtureDir 'measures.json'
        $rows = [object[]]((Get-Content -LiteralPath $measuresPath -Raw -Encoding UTF8) | ConvertFrom-Json)
        $rows.Count | Should -BeGreaterThan 0
        foreach ($r in $rows) {
            [string]$r.subject | Should -Not -BeNullOrEmpty
            [string]$r.subjectType | Should -BeIn $script:subjectTypes
            [string]$r.metric | Should -BeIn $script:metrics
            if ($null -ne $r.region) { [string]$r.region | Should -BeIn $script:regions }
            if ($null -ne $r.productLine) { [string]$r.productLine | Should -BeIn $script:productLines }
            [string]$r.asOfDate | Should -Match '^\d{4}-\d{2}-\d{2}$'
            { [double]$r.value } | Should -Not -Throw -Because 'value must be numeric'
            [string]$r.unit | Should -Not -BeNullOrEmpty
            [string]$r.externalSystem | Should -Be 'databricks-mock'
        }
    }

    It 'measures.json has no duplicate (subject, metric, asOfDate) alternate keys' {
        $measuresPath = Join-Path $script:fixtureDir 'measures.json'
        $rows = [object[]]((Get-Content -LiteralPath $measuresPath -Raw -Encoding UTF8) | ConvertFrom-Json)
        $keys = @($rows | ForEach-Object { '{0}|{1}|{2}' -f $_.subject, $_.metric, $_.asOfDate })
        ($keys | Sort-Object -Unique).Count | Should -Be $keys.Count
    }

    It 'validates measures.json against the JSON Schema when a validator is available' {
        $cmd = Get-Command Test-Json -ErrorAction SilentlyContinue
        if ($null -eq $cmd -or -not $cmd.Parameters.ContainsKey('SchemaFile')) {
            Set-ItResult -Skipped -Because 'Test-Json -SchemaFile is unavailable in this runtime (Windows PowerShell 5.1)'
            return
        }
        $json = Get-Content -LiteralPath (Join-Path $script:fixtureDir 'measures.json') -Raw -Encoding UTF8
        (Test-Json -Json $json -SchemaFile $script:schemaPath -ErrorAction Stop) | Should -BeTrue
    }

    It 'leaks no real-looking e-mail address' {
        $emailPattern = '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}'
        foreach ($f in $script:fixtureFiles) {
            $text = Get-Content -LiteralPath $f -Raw -Encoding UTF8
            foreach ($m in [regex]::Matches($text, $emailPattern)) {
                $domain = ($m.Value -split '@')[1].ToLowerInvariant()
                $domain | Should -BeIn $script:allowedEmailDomains -Because "e-mail '$($m.Value)' in $([System.IO.Path]::GetFileName($f)) must use a reserved demo domain"
            }
        }
    }

    It 'leaks no real-looking phone number (every phone carries a 555 marker)' {
        $phonePattern = '\+41[\s\d]{7,}'
        foreach ($f in $script:fixtureFiles) {
            $text = Get-Content -LiteralPath $f -Raw -Encoding UTF8
            foreach ($m in [regex]::Matches($text, $phonePattern)) {
                $m.Value | Should -Match '555' -Because "phone '$($m.Value.Trim())' in $([System.IO.Path]::GetFileName($f)) must use the 555 fictional marker"
            }
        }
    }
}
