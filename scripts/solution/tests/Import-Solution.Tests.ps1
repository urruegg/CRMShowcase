BeforeAll {
    $script:importSolutionScript = Join-Path $PSScriptRoot '../Import-Solution.ps1'
    . $script:importSolutionScript
}

Describe 'Get-SolutionImportArguments' {
    It 'uses normal import for install or update' {
        Get-SolutionImportArguments -ZipFile 'a.zip' -Mode InstallOrUpdate |
            Should -Be @('solution','import','--path','a.zip')
    }

    It 'uses a holding solution for staged upgrade' {
        Get-SolutionImportArguments -ZipFile 'a.zip' -Mode StageForUpgrade |
            Should -Be @('solution','import','--path','a.zip','--import-as-holding')
    }

    It 'never force-overwrites an imported solution' {
        Get-SolutionImportArguments -ZipFile 'a.zip' -Mode InstallOrUpdate |
            Should -Not -Contain '--force-overwrite'
        Get-SolutionImportArguments -ZipFile 'a.zip' -Mode StageForUpgrade |
            Should -Not -Contain '--force-overwrite'
        Get-Content -LiteralPath $script:importSolutionScript -Raw |
            Should -Not -Match '--force-overwrite'
    }
}

Describe 'Get-SolutionUpgradeArguments' {
    It 'builds apply-upgrade arguments from a unique name' {
        Get-SolutionUpgradeArguments -SolutionName 'crmshow_DataModel' |
            Should -Be @('solution','upgrade','--solution-name','crmshow_DataModel')
    }

    It 'rejects a blank solution name' {
        { Get-SolutionUpgradeArguments -SolutionName '  ' } |
            Should -Throw '*SolutionName is required for ApplyUpgrade*'
    }
}

Describe 'Import-Solution parameter behavior' {
    It 'requires a zip file for import modes' {
        { & $script:importSolutionScript -Mode InstallOrUpdate -WhatIf } |
            Should -Throw '*ZipFile is required*'
    }

    It 'requires a solution name for apply upgrade' {
        { & $script:importSolutionScript -Mode ApplyUpgrade -WhatIf } |
            Should -Throw '*SolutionName is required*'
    }

    It 'rejects import-only options for apply upgrade' {
        { & $script:importSolutionScript -Mode ApplyUpgrade -SolutionName 'crmshow_DataModel' -Async -WhatIf } |
            Should -Throw '*Async and PublishChanges*'
        { & $script:importSolutionScript -Mode ApplyUpgrade -SolutionName 'crmshow_DataModel' -PublishChanges -WhatIf } |
            Should -Throw '*Async and PublishChanges*'
    }

    It 'does not require a zip file for apply upgrade' {
        { & $script:importSolutionScript -Mode ApplyUpgrade -SolutionName 'crmshow_DataModel' -WhatIf } |
            Should -Not -Throw
    }

    It 'validates an import zip before resolving PAC' {
        { & $script:importSolutionScript -ZipFile (Join-Path $TestDrive 'missing.zip') -WhatIf } |
            Should -Throw '*Solution zip file not found*'
    }

    It 'accepts async publishing for import modes' {
        $zipFile = Join-Path $TestDrive 'managed.zip'
        Set-Content -LiteralPath $zipFile -Value 'test'

        { & $script:importSolutionScript -ZipFile $zipFile -Async -PublishChanges -WhatIf } |
            Should -Not -Throw
    }
}
