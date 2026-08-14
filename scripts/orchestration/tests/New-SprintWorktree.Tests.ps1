BeforeAll {
    . "$PSScriptRoot/../New-SprintWorktree.ps1"
}

Describe "New-SprintWorktree" {
    BeforeEach {
        $script:repo = Join-Path $TestDrive 'repo'
        $script:tmpl = Join-Path $script:repo 'docs/superpowers/contracts'
        New-Item -ItemType Directory -Force -Path $script:tmpl | Out-Null
        '- **Autonomy class:** {{CLASS}}' + "`n" + '- **GitHub issue:** #{{ISSUE}}' + "`n" + '- **Worktree:** {{WORKTREE}}' + "`n" + '- **Branch:** {{BRANCH}}' |
            Set-Content -LiteralPath (Join-Path $script:tmpl 'handover-packet.template.md')
        $script:wtRoot = Join-Path $TestDrive 'wt'
    }

    It "plans a git worktree add and scaffolds the packet" {
        $r = New-SprintWorktree -SprintId 'sprint-001' -StreamId 'stream-A' `
            -IssueNumber 42 -AutonomyClass 'EXECUTION-ONLY' `
            -RepoRoot $script:repo -WorktreeRoot $script:wtRoot -DryRun

        $r.Branch       | Should -Be 'feat/sprint-001-stream-A'
        $r.WorktreePath | Should -Be (Join-Path $script:wtRoot 'sprint-001-stream-A')
        $r.GitCommand   | Should -Match 'worktree add -b feat/sprint-001-stream-A'
        Test-Path -LiteralPath $r.PacketPath | Should -BeTrue
        (Get-Content -Raw -LiteralPath $r.PacketPath) | Should -Match 'EXECUTION-ONLY'
        (Get-Content -Raw -LiteralPath $r.PacketPath) | Should -Match '#42'
    }

    It "rejects an invalid autonomy class" {
        { New-SprintWorktree -SprintId 's' -StreamId 'a' -IssueNumber 1 `
            -AutonomyClass 'BOGUS' -RepoRoot $script:repo -WorktreeRoot $script:wtRoot -DryRun } |
            Should -Throw
    }
}
