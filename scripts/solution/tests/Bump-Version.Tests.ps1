BeforeAll {
    . "$PSScriptRoot/../Bump-Version.ps1"
}

Describe "Bump-Version" {
    It "bumps PATCH: 1.2.3.42 patch -> 1.2.4.100" {
        Bump-Version -Current '1.2.3.42' -Kind 'patch' -Build 100 | Should -Be '1.2.4.100'
    }
    It "bumps MINOR: 1.2.3.42 minor -> 1.3.0.100" {
        Bump-Version -Current '1.2.3.42' -Kind 'minor' -Build 100 | Should -Be '1.3.0.100'
    }
    It "bumps MAJOR: 1.2.3.42 major -> 2.0.0.100" {
        Bump-Version -Current '1.2.3.42' -Kind 'major' -Build 100 | Should -Be '2.0.0.100'
    }
    It "bumps BUILD only: 1.2.3.42 build -> 1.2.3.100" {
        Bump-Version -Current '1.2.3.42' -Kind 'build' -Build 100 | Should -Be '1.2.3.100'
    }
    It "throws on invalid current" {
        { Bump-Version -Current '1.2.3' -Kind 'patch' -Build 1 } | Should -Throw
    }
    It "throws on invalid kind" {
        { Bump-Version -Current '1.0.0.0' -Kind 'xxxx' -Build 1 } | Should -Throw
    }
    It "throws if Build is negative" {
        { Bump-Version -Current '1.0.0.0' -Kind 'patch' -Build -1 } | Should -Throw
    }
}