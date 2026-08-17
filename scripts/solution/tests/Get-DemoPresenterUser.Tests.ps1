# Pester tests for Get-DemoPresenterUser (Sprint-004, tenant-user-inventory stream).
# Dot-sourced (non-mandatory params, auto-invoke guard) so no live Dataverse
# environment is touched — az rest is mocked throughout.

BeforeAll {
    . "$PSScriptRoot/../Get-DemoPresenterUser.ps1"
}

Describe 'Get-DemoPresenterUser' {
    It 'returns the explicit override without calling az' {
        Mock az {}
        $result = Get-DemoPresenterUser -EnvironmentUrl 'https://crmshowdev.crm.dynamics.com' -PresenterUserId '11111111-1111-1111-1111-111111111111'
        $result | Should -Be '11111111-1111-1111-1111-111111111111'
        Should -Invoke -CommandName az -Times 0 -Exactly
    }

    It 'resolves the single enabled interactive System Administrator' {
        Mock az {
            '{"value":[{"systemuserid":"aaa","fullname":"Rahel Moser","accessmode":0,"systemuserroles_association":[{"name":"System Administrator"}]},{"systemuserid":"bbb","fullname":"CI App User","accessmode":4,"systemuserroles_association":[{"name":"System Administrator"}]}]}'
        }
        $result = Get-DemoPresenterUser -EnvironmentUrl 'https://crmshowdev.crm.dynamics.com'
        $result | Should -Be 'aaa'
    }

    It 'picks the alphabetically-first fullname and warns when multiple admins are found' {
        Mock az {
            '{"value":[{"systemuserid":"zzz","fullname":"Zoe Admin","accessmode":0,"systemuserroles_association":[{"name":"System Administrator"}]},{"systemuserid":"aaa","fullname":"Anna Admin","accessmode":0,"systemuserroles_association":[{"name":"System Administrator"}]}]}'
        }
        $result = Get-DemoPresenterUser -EnvironmentUrl 'https://crmshowdev.crm.dynamics.com' -WarningVariable warnings -WarningAction SilentlyContinue
        $result | Should -Be 'aaa'
        $warnings | Should -Not -BeNullOrEmpty
    }

    It 'throws when no enabled interactive System Administrator is found' {
        Mock az { '{"value":[]}' }
        { Get-DemoPresenterUser -EnvironmentUrl 'https://crmshowdev.crm.dynamics.com' } | Should -Throw
    }

    It 'excludes a disabled or non-interactive System Administrator' {
        Mock az {
            '{"value":[{"systemuserid":"ci","fullname":"CI App User","accessmode":4,"systemuserroles_association":[{"name":"System Administrator"}]}]}'
        }
        { Get-DemoPresenterUser -EnvironmentUrl 'https://crmshowdev.crm.dynamics.com' } | Should -Throw
    }

    It 'excludes a user with no System Administrator role even if interactive' {
        Mock az {
            '{"value":[{"systemuserid":"basic","fullname":"Basic User","accessmode":0,"systemuserroles_association":[{"name":"Basic User"}]}]}'
        }
        { Get-DemoPresenterUser -EnvironmentUrl 'https://crmshowdev.crm.dynamics.com' } | Should -Throw
    }
}
