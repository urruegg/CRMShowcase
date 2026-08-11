BeforeAll {
    . "$PSScriptRoot/../Invoke-StreamDelegation.ps1"

    function New-Packet($class) {
        $p = Join-Path $script:dir "packet-$class.md"
        @(
            '- **Sprint:** sprint-001'
            '- **Stream:** stream-A'
            '- **GitHub issue:** #42'
            "- **Autonomy class:** $class"
            '- **Branch:** feat/sprint-001-stream-A'
            '- **Worktree:** C:\wt\sprint-001-stream-A'
            '- **Approved design ref:** ADR-0023'
        ) | Set-Content -LiteralPath $p
        return $p
    }
}

Describe "Invoke-StreamDelegation" {
    BeforeEach {
        $script:dir = Join-Path $TestDrive 'streams'
        New-Item -ItemType Directory -Force -Path $script:dir | Out-Null
    }

    It "builds a denied-listed headless command for EXECUTION-ONLY" {
        $r = Invoke-StreamDelegation -PacketPath (New-Packet 'EXECUTION-ONLY') -DryRun
        $r.Mode    | Should -Be 'Headless'
        $r.Command | Should -Match 'copilot -p'
        $r.Command | Should -Match '--allow-all-tools'
        $r.Command | Should -Match "--deny-tool='shell\(git push\)'"
        $r.Command | Should -Match "--deny-tool='shell\(rm\)'"
        $r.Command | Should -Match "--deny-tool='shell\(git reset\)'"
    }

    It "returns an attended plan for DESIGN-SENSITIVE and no allow-all command" {
        $r = Invoke-StreamDelegation -PacketPath (New-Packet 'DESIGN-SENSITIVE') -DryRun
        $r.Mode    | Should -Be 'Attended'
        $r.Command | Should -Not -Match '--allow-all-tools'
    }

    It "refuses to force a DESIGN-SENSITIVE packet headless" {
        { Invoke-StreamDelegation -PacketPath (New-Packet 'DESIGN-SENSITIVE') -Headless -DryRun } |
            Should -Throw
    }
}
