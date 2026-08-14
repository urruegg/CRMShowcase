BeforeAll {
    . "$PSScriptRoot/../Read-HandoverPacket.ps1"
}

Describe "Read-HandoverPacket" {
    BeforeEach {
        $script:packet = Join-Path $TestDrive 'stream-A.md'
        @(
            '# Handover Packet - stream-A'
            ''
            '- **Sprint:** sprint-001'
            '- **Stream:** stream-A'
            '- **GitHub issue:** #42'
            '- **Autonomy class:** EXECUTION-ONLY'
            '- **Branch:** feat/sprint-001-stream-A'
            '- **Worktree:** C:\wt\sprint-001-stream-A'
            '- **Approved design ref:** ADR-0023'
        ) | Set-Content -LiteralPath $script:packet
    }

    It "parses the required fields" {
        $p = Read-HandoverPacket -Path $script:packet
        $p.Sprint        | Should -Be 'sprint-001'
        $p.Stream        | Should -Be 'stream-A'
        $p.Issue         | Should -Be 42
        $p.AutonomyClass | Should -Be 'EXECUTION-ONLY'
        $p.Branch        | Should -Be 'feat/sprint-001-stream-A'
        $p.Worktree      | Should -Be 'C:\wt\sprint-001-stream-A'
    }

    It "throws when the packet is missing" {
        { Read-HandoverPacket -Path (Join-Path $TestDrive 'nope.md') } |
            Should -Throw
    }

    It "throws on an unknown autonomy class" {
        (Get-Content -LiteralPath $script:packet) -replace 'EXECUTION-ONLY','BOGUS' |
            Set-Content -LiteralPath $script:packet
        { Read-HandoverPacket -Path $script:packet } | Should -Throw
    }
}
