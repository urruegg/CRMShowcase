BeforeAll {
    . "$PSScriptRoot/../Remove-SprintWorktree.ps1"
}

Describe "Remove-SprintWorktree" {
    It "refuses when the worktree has uncommitted changes and -Force is absent" {
        { Remove-SprintWorktree -WorktreePath 'C:\wt\s-a' -RepoRoot 'C:\repo' `
            -StatusText ' M some/file.ps1' -DryRun } | Should -Throw
    }

    It "plans a worktree remove when clean" {
        $r = Remove-SprintWorktree -WorktreePath 'C:\wt\s-a' -RepoRoot 'C:\repo' `
            -StatusText '' -DryRun
        $r.GitCommand | Should -Match 'worktree remove'
    }
}
