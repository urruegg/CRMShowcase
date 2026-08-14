BeforeAll {
    . "$PSScriptRoot/../Complete-StreamIntake.ps1"
}

Describe "Complete-StreamIntake" {
    It "plans a branch push and a PR against main, never a merge" {
        $r = Complete-StreamIntake -WorktreePath 'C:\wt\sprint-001-stream-A' `
            -Branch 'feat/sprint-001-stream-A' -IssueNumber 42 `
            -Title 'stream-A: smoke' -DryRun

        $r.PushCommand | Should -Match 'push -u origin feat/sprint-001-stream-A'
        $r.PrCommand   | Should -Match 'gh pr create --base main'
        $r.PrCommand   | Should -Match '--head feat/sprint-001-stream-A'
        $r.Commands -join ' ' | Should -Not -Match 'pr merge'
    }
}
