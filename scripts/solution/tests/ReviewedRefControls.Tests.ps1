BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
    $script:githubModuleVariables = Get-Content (Join-Path $script:repoRoot `
        'infra/terraform/modules/github/variables.tf') -Raw
    $script:githubModuleMain = Get-Content (Join-Path $script:repoRoot `
        'infra/terraform/modules/github/main.tf') -Raw
    $script:terraformRoot = Get-Content (Join-Path $script:repoRoot `
        'infra/terraform/main.tf') -Raw
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

    It 'pins the demo dev and test environments to main only' {
        $script:terraformRoot | Should -Match (
            '(?ms)dev\s*=\s*\{.*?allowed_branch_patterns\s*=\s*\[\s*"main"\s*\]'
        )
        $script:terraformRoot | Should -Match (
            '(?ms)test\s*=\s*\{.*?allowed_branch_patterns\s*=\s*\[\s*"main"\s*\]'
        )
    }
}

Describe 'Main branch protection contract' {
    It 'protects main with enforced admins, gate1, and conversation resolution' {
        $script:githubModuleMain | Should -Match (
            '(?ms)resource\s+"github_branch_protection"\s+"main"\s*\{.*?' +
            'pattern\s*=\s*"main".*?' +
            'enforce_admins\s*=\s*true.*?' +
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
