BeforeAll {
    $script:scriptPath = Join-Path $PSScriptRoot '..\Set-DataverseLanguages.ps1'
    $script:childPowerShellPath = if (Get-Command pwsh -ErrorAction SilentlyContinue) {
        (Get-Command pwsh -ErrorAction Stop).Source
    }
    else {
        (Get-Command powershell -ErrorAction Stop).Source
    }
    . $script:scriptPath -EnvironmentUrl 'https://crmshowdev.crm.dynamics.com' -LocaleId 1033

    function script:Assert-SafeDiagnosticLine {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            [string]$Text,

            [int]$MaxLength = 600
        )

        $Text | Should -Not -Match '[\x00-\x1F\x7F-\x9F]'
        $Text | Should -Not -Match '(^|[\r\n])::'
        $Text.Length | Should -BeLessThan ($MaxLength + 1)
    }

    function script:New-LanguageAzShim {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            [string]$RootPath
        )

        $shimScriptPath = Join-Path $RootPath 'az.ps1'
        $shimCommandPath = Join-Path $RootPath 'az'
        $shimScript = @'
#!/usr/bin/env pwsh
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Arguments
)

$ErrorActionPreference = 'Stop'
$escape = [char]27
Write-Error (
    "::warning::language transport`r`nPermission denied`t" +
    "$escape[31mblocked$escape[0m"
) -ErrorAction Continue
exit 23
'@

        $shimScript = $shimScript -replace "`r`n", "`n"
        $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText($shimScriptPath, $shimScript, $utf8NoBom)
        [System.IO.File]::WriteAllText($shimCommandPath, $shimScript, $utf8NoBom)

        if ([System.IO.Path]::DirectorySeparatorChar -eq '/') {
            & chmod +x -- $shimCommandPath
            if ($LASTEXITCODE -ne 0) {
                throw "Failed to make az shim executable: $shimCommandPath"
            }
        }
    }

    function script:Invoke-LanguageEntryScript {
        [CmdletBinding()]
        param()

        $testRoot = Join-Path (Get-PSDrive -Name TestDrive).Root ([guid]::NewGuid().Guid)
        $null = New-Item -ItemType Directory -Path $testRoot -Force
        script:New-LanguageAzShim -RootPath $testRoot

        $previousPath = $env:PATH
        try {
            $pathSeparator = [System.IO.Path]::PathSeparator
            $env:PATH = if ([string]::IsNullOrEmpty($previousPath)) {
                $testRoot
            }
            else {
                "$testRoot$pathSeparator$previousPath"
            }

            $previousErrorActionPreference = $ErrorActionPreference
            $ErrorActionPreference = 'Continue'
            try {
                $output = & $script:childPowerShellPath `
                    -NoLogo `
                    -NoProfile `
                    -NonInteractive `
                    -File $script:scriptPath `
                    -EnvironmentUrl 'https://crmshowdev.crm.dynamics.com' `
                    -LocaleId 1033 2>&1
                $exitCode = $LASTEXITCODE
            }
            finally {
                $ErrorActionPreference = $previousErrorActionPreference
            }
        }
        finally {
            $env:PATH = $previousPath
        }

        return [pscustomobject]@{
            ExitCode = $exitCode
            Output   = (@($output | ForEach-Object { $_.ToString() }) -join [Environment]::NewLine).Trim()
        }
    }
}

Describe 'Get-NormalizedLocaleIds' {
    It 'returns unique supported locale IDs in ascending order' {
        $actual = @(Get-NormalizedLocaleIds -LocaleId @(1040, 1033, 1031, 1036, 1033, 1040))

        $actual | Should -Be @(1031, 1033, 1036, 1040)
    }

    It 'rejects an unsupported locale ID with a clear error' {
        { Get-NormalizedLocaleIds -LocaleId @(1033, 9999) } |
            Should -Throw -ExpectedMessage "*Unsupported Dataverse locale ID: 9999*"
    }
}

Describe 'Wait-DataverseLanguage' {
    BeforeEach {
        $script:readCount = 0
        Mock Start-Sleep
    }

    It 'polls until the language is active' {
        Mock Get-ProvisionedLocaleIds {
            $script:readCount++
            if ($script:readCount -eq 1) {
                return @(1033)
            }
            return @(1031, 1033)
        }

        Wait-DataverseLanguage -BaseUrl 'https://crmshowdev.crm.dynamics.com' `
            -LocaleId 1031 -TimeoutSeconds 5 -PollSeconds 1

        Should -Invoke Get-ProvisionedLocaleIds -Times 2 -Exactly
        Should -Invoke Start-Sleep -Times 1 -Exactly -ParameterFilter { $Seconds -eq 1 }
    }

    It 'throws after its bounded timeout without real sleeping' {
        Mock Get-ProvisionedLocaleIds { return @(1033) }

        {
            Wait-DataverseLanguage -BaseUrl 'https://orgd0d886ca.crm.dynamics.com' `
                -LocaleId 1040 -TimeoutSeconds 0 -PollSeconds 1
        } | Should -Throw -ExpectedMessage "*Locale '1040' did not become active within 0 seconds*"

        Should -Invoke Get-ProvisionedLocaleIds -Times 1 -Exactly
        Should -Invoke Start-Sleep -Times 0 -Exactly
    }
}

Describe 'Invoke-DataverseRest' {
    AfterEach {
        Remove-Item Function:\az -ErrorAction SilentlyContinue
    }

    It 'sanitizes hostile az output on transport failure' {
        $escape = [char]27
        function global:az {
            Write-Error (
                "::warning::language transport`r`nPermission denied`t" +
                "$escape[31mblocked$escape[0m"
            ) -ErrorAction Continue
            $global:LASTEXITCODE = 23
        }

        $message = $null
        try {
            Invoke-DataverseRest `
                -Method GET `
                -Url 'https://crmshowdev.crm.dynamics.com/api/data/v9.2/RetrieveProvisionedLanguages()' |
                Out-Null
            throw 'Expected transport failure.'
        }
        catch {
            $message = $_.Exception.Message
        }

        script:Assert-SafeDiagnosticLine -Text $message -MaxLength 400
        $message | Should -Match 'Dataverse request failed: GET'
        $message | Should -Match 'RetrieveProvisionedLanguages\(\)'
        $message | Should -Match 'Output:'
        $message | Should -Match (
            [regex]::Escape(
                '::warning::language transport Permission denied blocked'
            )
        )
        $message | Should -Not -Match 'At line:|--method|--url|--resource'
    }
}

Describe 'Invoke-DataverseLanguageReconciliation' {
    BeforeEach {
        $script:events = [System.Collections.Generic.List[string]]::new()

        Mock Get-ProvisionedLocaleIds {
            [void]$script:events.Add('GET:PROVISIONED')
            return @(1033)
        }
        Mock Invoke-DataverseRest {
            [void]$script:events.Add("POST:${Url}:$($Body.Language)")
            return @{ AsyncOperationId = '11111111-1111-1111-1111-111111111111' }
        }
        Mock Wait-DataverseLanguage {
            [void]$script:events.Add("WAIT:$LocaleId")
        }
    }

    It 'provisions every missing language before starting the first wait' {
        $evidence = @(
            Invoke-DataverseLanguageReconciliation `
                -BaseUrl 'https://crmshowdev.crm.dynamics.com' `
                -RequiredLocaleId @(1031, 1036)
        )

        $script:events | Should -Be @(
            'GET:PROVISIONED'
            'POST:https://crmshowdev.crm.dynamics.com/api/data/v9.2/ProvisionLanguageAsync:1031'
            'POST:https://crmshowdev.crm.dynamics.com/api/data/v9.2/ProvisionLanguageAsync:1036'
            'WAIT:1031'
            'WAIT:1036'
        )
        $evidence.LocaleId | Should -Be @(1031, 1036)
        $evidence.State | Should -Be @('Active', 'Active')
    }

    It 'does not reprovision languages returned by RetrieveProvisionedLanguages' {
        Mock Get-ProvisionedLocaleIds { return @(1031, 1033, 1036, 1040) }
        Mock Invoke-DataverseRest
        Mock Wait-DataverseLanguage

        Invoke-DataverseLanguageReconciliation `
            -BaseUrl 'https://crmshowdev.crm.dynamics.com' `
            -RequiredLocaleId @(1031, 1033, 1036, 1040) | Out-Null

        Should -Invoke Invoke-DataverseRest -Times 0 -Exactly
        Should -Invoke Wait-DataverseLanguage -Times 0 -Exactly
    }

    It 'does not provision or wait during WhatIf and preserves requested output order' {
        Mock Get-ProvisionedLocaleIds { return @(1033) }
        Mock Invoke-DataverseRest
        Mock Wait-DataverseLanguage

        $evidence = @(
            Invoke-DataverseLanguageReconciliation `
                -BaseUrl 'https://crmshowdev.crm.dynamics.com' `
                -RequiredLocaleId @(1031, 1033) -WhatIf
        )

        Should -Invoke Invoke-DataverseRest -Times 0 -Exactly
        Should -Invoke Wait-DataverseLanguage -Times 0 -Exactly
        $evidence.LocaleId | Should -Be @(1031, 1033)
        $evidence.State | Should -Be @('Planned', 'Active')
    }
}

Describe 'Set-DataverseLanguages entry point' {
    It 'emits a single safe error line when az transport fails' {
        $invocation = script:Invoke-LanguageEntryScript

        $invocation.ExitCode | Should -Be 1
        script:Assert-SafeDiagnosticLine -Text $invocation.Output -MaxLength 450
        $invocation.Output | Should -Match 'Dataverse request failed: GET'
        $invocation.Output | Should -Match 'RetrieveProvisionedLanguages\(\)'
        $invocation.Output | Should -Match 'Output:'
        $invocation.Output | Should -Match (
            [regex]::Escape(
                '::warning::language transport Permission denied blocked'
            )
        )
        $invocation.Output | Should -Not -Match 'At line:|--method|--url|--resource'
    }
}
