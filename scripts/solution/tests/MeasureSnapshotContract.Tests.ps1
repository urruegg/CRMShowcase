# Pester tests for the Advisor Cockpit measure-snapshot consumption contract (ADR-0026).
# Runs under Windows PowerShell 5.1 (structural checks) and validates against the
# JSON Schema when a validator is available (Test-Json -SchemaFile on PowerShell 7).

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
    $script:schemaPath = Join-Path $script:repoRoot 'api/advisor-cockpit/measure-snapshot.schema.json'
    $script:samplePath = Join-Path $script:repoRoot 'api/advisor-cockpit/measure-snapshot.sample.json'

    $script:subjectTypes = @('lead', 'account', 'contact', 'ga', 'region', 'product', 'portfolio')
    $script:metrics = @('GoalAttainment', 'GrowthYoY', 'NPS', 'Automation', 'Forecast', 'Conversion', 'Efficiency', 'Satisfaction', 'Quality')
    $script:regions = @('Mittelland', 'Zurich', 'Romandie', 'Ticino')
    $script:productLines = @('MotorVehicle', 'HouseholdContents', 'CommercialProperty', 'Pension3a', 'LegalProtection')

    function Get-Sample {
        Get-Content -LiteralPath $script:samplePath -Raw -Encoding UTF8 | ConvertFrom-Json
    }

    # Returns $true/$false when a schema validator is available, else $null (skip).
    function Test-SampleAgainstSchema {
        $cmd = Get-Command Test-Json -ErrorAction SilentlyContinue
        if ($null -eq $cmd -or -not $cmd.Parameters.ContainsKey('SchemaFile')) { return $null }
        $json = Get-Content -LiteralPath $script:samplePath -Raw -Encoding UTF8
        try {
            return [bool](Test-Json -Json $json -SchemaFile $script:schemaPath -ErrorAction Stop)
        } catch {
            return $false
        }
    }
}

Describe 'measure-snapshot contract' {
    It 'schema and sample files exist and parse as JSON' {
        Test-Path -LiteralPath $script:schemaPath | Should -BeTrue
        Test-Path -LiteralPath $script:samplePath | Should -BeTrue
        { Get-Content -LiteralPath $script:schemaPath -Raw -Encoding UTF8 | ConvertFrom-Json } | Should -Not -Throw
        { Get-Sample } | Should -Not -Throw
    }

    It 'every sample row satisfies the contract rules' {
        $rows = [object[]]((Get-Content -LiteralPath $script:samplePath -Raw -Encoding UTF8) | ConvertFrom-Json)
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

    It 'sample validates against the JSON Schema when a validator is available' {
        $result = Test-SampleAgainstSchema
        if ($null -eq $result) {
            Set-ItResult -Skipped -Because 'Test-Json -SchemaFile is unavailable in this runtime (Windows PowerShell 5.1)'
        }
        else {
            $result | Should -BeTrue
        }
    }
}
