BeforeAll {
    . "$PSScriptRoot/../Get-SprintStatus.ps1"
}

Describe "Get-SprintStatus" {
    It "maps porcelain worktree output under the worktree root to streams" {
        $porcelain = @(
            'worktree C:/Users/urruegg/source/urruegg/wt/sprint-001-stream-A'
            'HEAD abc123'
            'branch refs/heads/feat/sprint-001-stream-A'
            ''
            'worktree C:/Users/urruegg/source/urruegg/CRMShowcase'
            'HEAD def456'
            'branch refs/heads/main'
            ''
        ) -join "`n"

        $rows = Get-SprintStatus -WorktreeRoot 'C:/Users/urruegg/source/urruegg/wt' -WorktreeListText $porcelain
        $rows.Count      | Should -Be 1
        $rows[0].Stream  | Should -Be 'sprint-001-stream-A'
        $rows[0].Branch  | Should -Be 'feat/sprint-001-stream-A'
    }
}
