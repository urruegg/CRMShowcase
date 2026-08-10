BeforeAll {
    . "$PSScriptRoot/../ConvertTo-SafeCliDiagnosticLine.ps1"

    function script:Assert-SafeDiagnosticLine {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            [string]$Text,

            [int]$MaxLength = 600
        )

        $Text | Should -Not -Match '[\x00-\x1F\x7F-\x9F]'
        $Text | Should -Not -Match '(^|[\r\n])::'
        $Text.Length | Should -BeLessThan ($MaxLength + 1)
    }
}

Describe 'ConvertTo-SafeCliDiagnosticLine' {
    It 'collapses hostile CLI text into one readable safe line' {
        $escape = [char]27
        $input = (
            "::warning::Heads up`r`nSecond`tline" +
            [string][char]0 +
            [string][char]0x1F +
            [string][char]0x9F +
            "$escape[31mRED$escape[0m"
        )

        $actual = ConvertTo-SafeCliDiagnosticLine -Value $input -MaxLength 200

        script:Assert-SafeDiagnosticLine -Text $actual -MaxLength 200
        $actual | Should -Match (
            [regex]::Escape("'::warning::Heads up Second line RED")
        )
        $actual | Should -Not -Match '\[31m|\[0m'
    }

    It 'extracts exception text and preserves prefix, suffix, and the truncation marker' {
        $payload = (
            "::error::prefix " +
            ('a' * 120) +
            ' suffix-tail'
        )
        $exception = New-Object System.Exception($payload)

        $actual = Get-SafeCliErrorMessage -ErrorRecord $exception -MaxLength 80

        script:Assert-SafeDiagnosticLine -Text $actual -MaxLength 80
        $actual | Should -Match ([regex]::Escape("'::error::prefix"))
        $actual | Should -Match '\.\.\.\[truncated\]\.\.\.'
        $actual | Should -Match 'suffix-tail$'
    }

    It 'returns the empty placeholder when output contains only controls and ANSI sequences' {
        $escape = [char]27
        $input = (
            "`r`n`t" +
            "$escape[31m$escape[0m" +
            [string][char]0x07 +
            ([string][char]0x9B + '31m')
        )

        ConvertTo-SafeCliDiagnosticLine -Value $input |
            Should -Be '<no output>'
    }
}
