BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
    $script:githubModuleVariables = Get-Content (Join-Path $script:repoRoot `
        'infra/terraform/modules/github/variables.tf') -Raw
    $script:githubModuleMain = Get-Content (Join-Path $script:repoRoot `
        'infra/terraform/modules/github/main.tf') -Raw
    $script:terraformRoot = Get-Content (Join-Path $script:repoRoot `
        'infra/terraform/main.tf') -Raw
    $script:terraformReadme = Get-Content (Join-Path $script:repoRoot `
        'infra/terraform/README.md') -Raw
    $script:adr0004 = Get-Content (Join-Path $script:repoRoot `
        'docs/adr/ADR-0004-ci-plane-app-registrations-and-github-environments.md') -Raw
    $script:solutionCiWorkflow = Get-Content (Join-Path $script:repoRoot `
        '.github/workflows/solution-ci.yml') -Raw
}

Describe 'GitHub environment reviewed-ref policies' {
    It 'defaults allowed deployment branches to main in the GitHub module input contract' {
        $script:githubModuleVariables | Should -Match (
            'allowed_branch_patterns\s*=\s*optional\(\s*set\(string\)\s*,\s*\[\s*"main"\s*\]\s*\)'
        )
    }

    It 'enables custom deployment branch policies on every repository environment' {
        $script:githubModuleMain | Should -Match (
            '(?ms)resource\s+"github_repository_environment"\s+"envs"\s*\{.*?' +
            'deployment_branch_policy\s*\{\s*' +
            'protected_branches\s*=\s*false\s*' +
            'custom_branch_policies\s*=\s*true\s*' +
            '\}'
        )
    }

    It 'creates explicit deployment policies from allowed branch patterns' {
        $script:githubModuleMain | Should -Match (
            'resource\s+"github_repository_environment_deployment_policy"\s+"allowed_branches"'
        )
        $script:githubModuleMain | Should -Match 'branch_pattern\s*=\s*each\.value\.branch_pattern'
    }

    It 'supports optional reviewer user and team IDs in the module input contract' {
        $script:githubModuleVariables | Should -Match (
            'reviewer_user_ids\s*=\s*optional\(\s*set\(number\)\s*,\s*\[\s*\]\s*\)'
        )
        $script:githubModuleVariables | Should -Match (
            'reviewer_team_ids\s*=\s*optional\(\s*set\(number\)\s*,\s*\[\s*\]\s*\)'
        )
    }

    It 'emits a reviewers block only when reviewer IDs are configured' {
        $script:githubModuleMain | Should -Match (
            '(?ms)dynamic\s+"reviewers"\s*\{\s*' +
            'for_each\s*=\s*length\(each\.value\.reviewer_user_ids\)\s*\+\s*' +
            'length\(each\.value\.reviewer_team_ids\)\s*>\s*0\s*\?\s*\[each\.value\]\s*:\s*\[\]'
        )
        $script:githubModuleMain | Should -Match (
            'users\s*=\s*length\(reviewers\.value\.reviewer_user_ids\)\s*==\s*0\s*\?\s*null\s*:\s*reviewers\.value\.reviewer_user_ids'
        )
        $script:githubModuleMain | Should -Match (
            'teams\s*=\s*length\(reviewers\.value\.reviewer_team_ids\)\s*==\s*0\s*\?\s*null\s*:\s*reviewers\.value\.reviewer_team_ids'
        )
    }

    It 'pins the demo dev and test environments to main only' {
        $script:terraformRoot | Should -Match (
            '(?ms)dev\s*=\s*\{.*?allowed_branch_patterns\s*=\s*\[\s*"main"\s*\]'
        )
        $script:terraformRoot | Should -Match (
            '(?ms)test\s*=\s*\{.*?allowed_branch_patterns\s*=\s*\[\s*"main"\s*\]'
        )
    }

    It 'retains the demo TEST reviewer while leaving DEV without reviewers' {
        $script:terraformRoot | Should -Match (
            '(?ms)test\s*=\s*\{.*?reviewer_user_ids\s*=\s*\[\s*data\.github_user\.owner\.id\s*\].*?' +
            'prevent_self_review\s*=\s*false'
        )
        ([regex]::Matches($script:terraformRoot, 'reviewer_user_ids\s*=')).Count |
            Should -Be 1
    }
}

Describe 'Main branch protection contract' {
    It 'protects main with enforced admins, linear history, gate1, and conversation resolution' {
        $script:githubModuleMain | Should -Match (
            '(?ms)resource\s+"github_branch_protection"\s+"main"\s*\{.*?' +
            'pattern\s*=\s*"main".*?' +
            'enforce_admins\s*=\s*true.*?' +
            'required_linear_history\s*=\s*true.*?' +
            'require_conversation_resolution\s*=\s*true.*?' +
            'required_status_checks\s*\{.*?' +
            'strict\s*=\s*true.*?' +
            'contexts\s*=\s*\[\s*"gate1"\s*\].*?' +
            '\}'
        )
    }

    It 'requires pull requests on main without a mandatory independent approver in the demo repo' {
        $script:githubModuleMain | Should -Match (
            '(?ms)required_pull_request_reviews\s*\{.*?' +
            'dismiss_stale_reviews\s*=\s*true.*?' +
            'required_approving_review_count\s*=\s*0.*?' +
            'pull_request_bypassers\s*=\s*\[\s*\].*?' +
            '\}'
        )
    }

    It 'disables force-push and deletion bypasses on main' {
        $script:githubModuleMain | Should -Match 'allows_force_pushes\s*=\s*false'
        $script:githubModuleMain | Should -Match 'force_push_bypassers\s*=\s*\[\s*\]'
        $script:githubModuleMain | Should -Match 'allows_deletions\s*=\s*false'
    }
}

Describe 'Solution CI gate1 contract' {
    It 'runs on every pull request without path filters' {
        $script:solutionCiWorkflow | Should -Match (
            '(?ms)^on:\r?\n\s+pull_request:\s*\{\}\s*\r?\n(?:\s*#.*\r?\n)*\s+push:'
        )
    }

    It 'does not allow a user-skippable gate1 bypass label' {
        $script:solutionCiWorkflow | Should -Not -Match 'skip-solution-ci'
    }

    It 'does not put a job-level if guard in front of gate1' {
        $script:solutionCiWorkflow | Should -Match (
            '(?ms)^jobs:\r?\n\s+gate1:\r?\n\s+runs-on:\s+ubuntu-latest\r?\n\s+steps:'
        )
    }
}

Describe 'Terraform bootstrap/import runbook' {
    It 'documents GitHub auth prerequisites and imports all live reviewed-ref controls before first apply' {
        $script:terraformReadme | Should -Match 'GH_TOKEN'
        $script:terraformReadme | Should -Match 'GITHUB_TOKEN'
        $script:terraformReadme | Should -Match (
            'module\.github\.github_repository_environment\.envs\["dev"\]'
        )
        $script:terraformReadme | Should -Match (
            'module\.github\.github_repository_environment\.envs\["test"\]'
        )
        $script:terraformReadme | Should -Match (
            'module\.github\.github_repository_environment_deployment_policy\.allowed_branches\["dev:main"\]'
        )
        $script:terraformReadme | Should -Match '56913774'
        $script:terraformReadme | Should -Match (
            'module\.github\.github_repository_environment_deployment_policy\.allowed_branches\["test:main"\]'
        )
        $script:terraformReadme | Should -Match '56680080'
        $script:terraformReadme | Should -Match (
            'module\.github\.github_branch_protection\.main'
        )
        $script:terraformReadme | Should -Match 'CRMShowcase:main'
    }

    It 'records the live import evidence and plan checks operators must preserve before apply' {
        $script:terraformReadme | Should -Match 'no reviewer removal'
        $script:terraformReadme | Should -Match 'live evidence on 2026-08-10'
        $script:terraformReadme | Should -Match (
            'recreated,\s*re-check the\s*current live policy ID'
        )
        $script:terraformReadme | Should -Match 'required_linear_history = true'
        $script:terraformReadme | Should -Match 'dismiss_stale_reviews = true'
        $script:terraformReadme | Should -Not -Match 'is a create, because DEV currently has no live deployment branch policy'
        $script:terraformReadme | Should -Not -Match 'is a create unless the live repo'
        $script:terraformReadme | Should -Not -Match 'not scaffolded yet'
    }
}

Describe 'ADR-0004 reviewed-ref narrative' {
    It 'records the live reviewed-ref evidence and preserves the demo exceptions' {
        $script:adr0004 | Should -Match '2026-08-10'
        $script:adr0004 | Should -Match '56913774'
        $script:adr0004 | Should -Match '56680080'
        $script:adr0004 | Should -Match 'urruegg'
        $script:adr0004 | Should -Match '46865858'
        $script:adr0004 | Should -Match 'prevent_self_review = false'
        $script:adr0004 | Should -Match 'required_linear_history = true'
        $script:adr0004 | Should -Match 'dismiss_stale_reviews = true'
        $script:adr0004 | Should -Match 'required_approving_review_count = 0'
        $script:adr0004 | Should -Match 'independent required reviewers'
    }

    It 'no longer describes main branch protection as desired-only' {
        $script:adr0004 | Should -Not -Match 'desired IaC'
        $script:adr0004 | Should -Not -Match 'not live evidence'
        $script:adr0004 | Should -Not -Match 'Terraform controller / maintainer session'
    }
}
