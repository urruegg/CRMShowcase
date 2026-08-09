BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
    $script:exportScriptPath = Join-Path $script:repoRoot 'scripts/solution/Export-InsuranceFoundationPackages.ps1'
    $script:childPowerShellPath = if (Get-Command pwsh -ErrorAction SilentlyContinue) {
        (Get-Command pwsh -ErrorAction Stop).Source
    }
    else {
        (Get-Command powershell -ErrorAction Stop).Source
    }

    . $script:exportScriptPath `
        -EnvironmentUrl 'https://unit.crm.dynamics.com' `
        -OutputDirectory (Join-Path (Get-PSDrive -Name TestDrive).Root 'dot-source')

    function script:New-ExportTestContext {
        [CmdletBinding()]
        param()

        $rootPath = Join-Path (Get-PSDrive -Name TestDrive).Root ([guid]::NewGuid().Guid)
        $null = New-Item -ItemType Directory -Path $rootPath -Force

        return [pscustomobject]@{
            RootPath        = $rootPath
            OutputDirectory = Join-Path $rootPath 'out'
            LogPath         = Join-Path $rootPath 'pac.log'
            PacPath         = Join-Path $rootPath 'pac.ps1'
        }
    }

    function script:New-FakePacCommand {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            [string]$Path
        )

        $scriptContent = @'
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Arguments
)

$ErrorActionPreference = 'Stop'

function Get-ArgumentValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string[]]$InputArguments,

        [Parameter(Mandatory)]
        [string]$Name
    )

    $index = [Array]::IndexOf($InputArguments, $Name)
    if ($index -lt 0 -or $index -ge ($InputArguments.Count - 1)) {
        throw "Missing required argument: $Name"
    }

    return $InputArguments[$index + 1]
}

$path = Get-ArgumentValue -InputArguments $Arguments -Name '--path'
$environment = Get-ArgumentValue -InputArguments $Arguments -Name '--environment'
$name = Get-ArgumentValue -InputArguments $Arguments -Name '--name'
$managed = Get-ArgumentValue -InputArguments $Arguments -Name '--managed'
$fileName = [System.IO.Path]::GetFileName($path)

if (-not [string]::IsNullOrWhiteSpace($env:TEST_EXPORT_PAC_LOG_PATH)) {
    $record = [pscustomobject][ordered]@{
        Arguments   = @($Arguments)
        Environment = $environment
        Name        = $name
        Path        = $path
        Managed     = $managed
        File        = $fileName
        Overwrite   = ([Array]::IndexOf($Arguments, '--overwrite') -ge 0)
    }

    Add-Content -LiteralPath $env:TEST_EXPORT_PAC_LOG_PATH `
        -Value ($record | ConvertTo-Json -Compress -Depth 10) `
        -Encoding UTF8
}

if ($env:TEST_EXPORT_PAC_FAIL_FILE -eq $fileName) {
    Write-Output "simulated export failure for $fileName"
    exit 19
}

$directoryPath = Split-Path -Path $path -Parent
if (-not [string]::IsNullOrWhiteSpace($directoryPath)) {
    New-Item -ItemType Directory -Path $directoryPath -Force | Out-Null
}

if ($env:TEST_EXPORT_PAC_SKIP_FILE -ne $fileName) {
    if ($env:TEST_EXPORT_PAC_ZERO_BYTE_FILE -eq $fileName) {
        [System.IO.File]::WriteAllBytes($path, [byte[]]@())
    }
    else {
        [System.IO.File]::WriteAllText($path, "package:$fileName")
    }
}

Write-Output "exported $fileName"
exit 0
'@

        Set-Content -LiteralPath $Path -Value $scriptContent -Encoding UTF8
        return $Path
    }

    function script:Get-FakePacInvocations {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            [string]$LogPath
        )

        if (-not (Test-Path -LiteralPath $LogPath -PathType Leaf)) {
            return @()
        }

        return @(
            Get-Content -LiteralPath $LogPath -Encoding UTF8 |
                Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
                ForEach-Object { $_ | ConvertFrom-Json -ErrorAction Stop }
        )
    }

    function script:Invoke-ExportEntryScript {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            $Context,

            [switch]$WhatIf,

            [string]$FailFile,
            [string]$ZeroByteFile,
            [string]$SkipFile
        )

        $previousPacPath = $env:POWERPLATFORMTOOLS_PACPATH
        $previousLogPath = $env:TEST_EXPORT_PAC_LOG_PATH
        $previousFailFile = $env:TEST_EXPORT_PAC_FAIL_FILE
        $previousZeroByteFile = $env:TEST_EXPORT_PAC_ZERO_BYTE_FILE
        $previousSkipFile = $env:TEST_EXPORT_PAC_SKIP_FILE

        try {
            $env:POWERPLATFORMTOOLS_PACPATH = $Context.PacPath
            $env:TEST_EXPORT_PAC_LOG_PATH = $Context.LogPath

            if ([string]::IsNullOrWhiteSpace($FailFile)) {
                Remove-Item Env:TEST_EXPORT_PAC_FAIL_FILE -ErrorAction SilentlyContinue
            }
            else {
                $env:TEST_EXPORT_PAC_FAIL_FILE = $FailFile
            }

            if ([string]::IsNullOrWhiteSpace($ZeroByteFile)) {
                Remove-Item Env:TEST_EXPORT_PAC_ZERO_BYTE_FILE -ErrorAction SilentlyContinue
            }
            else {
                $env:TEST_EXPORT_PAC_ZERO_BYTE_FILE = $ZeroByteFile
            }

            if ([string]::IsNullOrWhiteSpace($SkipFile)) {
                Remove-Item Env:TEST_EXPORT_PAC_SKIP_FILE -ErrorAction SilentlyContinue
            }
            else {
                $env:TEST_EXPORT_PAC_SKIP_FILE = $SkipFile
            }

            $arguments = @(
                '-NoLogo',
                '-NoProfile',
                '-NonInteractive',
                '-File',
                $script:exportScriptPath,
                '-EnvironmentUrl',
                'https://unit.crm.dynamics.com',
                '-OutputDirectory',
                $Context.OutputDirectory
            )
            if ($WhatIf) {
                $arguments += '-WhatIf'
            }

            $output = & $script:childPowerShellPath @arguments 2>&1
            $exitCode = $LASTEXITCODE
        }
        finally {
            if ($null -eq $previousPacPath) {
                Remove-Item Env:POWERPLATFORMTOOLS_PACPATH -ErrorAction SilentlyContinue
            }
            else {
                $env:POWERPLATFORMTOOLS_PACPATH = $previousPacPath
            }

            if ($null -eq $previousLogPath) {
                Remove-Item Env:TEST_EXPORT_PAC_LOG_PATH -ErrorAction SilentlyContinue
            }
            else {
                $env:TEST_EXPORT_PAC_LOG_PATH = $previousLogPath
            }

            if ($null -eq $previousFailFile) {
                Remove-Item Env:TEST_EXPORT_PAC_FAIL_FILE -ErrorAction SilentlyContinue
            }
            else {
                $env:TEST_EXPORT_PAC_FAIL_FILE = $previousFailFile
            }

            if ($null -eq $previousZeroByteFile) {
                Remove-Item Env:TEST_EXPORT_PAC_ZERO_BYTE_FILE -ErrorAction SilentlyContinue
            }
            else {
                $env:TEST_EXPORT_PAC_ZERO_BYTE_FILE = $previousZeroByteFile
            }

            if ($null -eq $previousSkipFile) {
                Remove-Item Env:TEST_EXPORT_PAC_SKIP_FILE -ErrorAction SilentlyContinue
            }
            else {
                $env:TEST_EXPORT_PAC_SKIP_FILE = $previousSkipFile
            }
        }

        return [pscustomobject]@{
            ExitCode        = $exitCode
            Output          = (@($output | ForEach-Object { $_.ToString() }) -join [Environment]::NewLine).Trim()
            OutputDirectory = $Context.OutputDirectory
            LogPath         = $Context.LogPath
            Invocations     = @(script:Get-FakePacInvocations -LogPath $Context.LogPath)
        }
    }
}

Describe 'Get-InsuranceFoundationExports' {
    It 'returns exactly the four reviewed package definitions' {
        $definitions = @(
            Get-InsuranceFoundationExports |
                Sort-Object File |
                ForEach-Object {
                    '{0}|{1}|{2}' -f $_.Name, $_.Managed.ToString().ToLowerInvariant(), $_.File
                }
        )

        $definitions | Should -Be @(
            'crmshow_DataModel|false|crmshow_DataModel.zip',
            'crmshow_DataModel|true|crmshow_DataModel_managed.zip',
            'crmshow_Foundation|false|crmshow_Foundation.zip',
            'crmshow_Foundation|true|crmshow_Foundation_managed.zip'
        )
    }
}

Describe 'Assert-InsuranceFoundationPackageSet' {
    It 'accepts the exact four files regardless of order' {
        {
            Assert-InsuranceFoundationPackageSet -FileNames @(
                'crmshow_Foundation_managed.zip',
                'crmshow_DataModel.zip',
                'crmshow_DataModel_managed.zip',
                'crmshow_Foundation.zip'
            )
        } | Should -Not -Throw
    }

    It 'rejects a missing package' {
        {
            Assert-InsuranceFoundationPackageSet -FileNames @(
                'crmshow_Foundation.zip',
                'crmshow_Foundation_managed.zip',
                'crmshow_DataModel.zip'
            )
        } | Should -Throw '*Unexpected authored package set*crmshow_DataModel_managed.zip*'
    }

    It 'rejects an additional package' {
        {
            Assert-InsuranceFoundationPackageSet -FileNames @(
                (Get-InsuranceFoundationExports).File + 'unexpected.zip'
            )
        } | Should -Throw '*Unexpected authored package set*unexpected.zip*'
    }

    It 'rejects a duplicate package' {
        {
            Assert-InsuranceFoundationPackageSet -FileNames @(
                'crmshow_Foundation.zip',
                'crmshow_Foundation.zip',
                'crmshow_Foundation_managed.zip',
                'crmshow_DataModel.zip',
                'crmshow_DataModel_managed.zip'
            )
        } | Should -Throw '*Unexpected authored package set*crmshow_Foundation.zip*'
    }

    It 'rejects a case mismatch' {
        {
            Assert-InsuranceFoundationPackageSet -FileNames @(
                'crmshow_foundation.zip',
                'crmshow_Foundation_managed.zip',
                'crmshow_DataModel.zip',
                'crmshow_DataModel_managed.zip'
            )
        } | Should -Throw '*Unexpected authored package set*crmshow_foundation.zip*crmshow_Foundation.zip*'
    }

    It 'rejects a wrong extension' {
        {
            Assert-InsuranceFoundationPackageSet -FileNames @(
                'crmshow_Foundation.zip',
                'crmshow_Foundation_managed.zip',
                'crmshow_DataModel.zip',
                'crmshow_DataModel_managed.pak'
            )
        } | Should -Throw '*Unexpected authored package set*crmshow_DataModel_managed.pak*crmshow_DataModel_managed.zip*'
    }
}

Describe 'Export-InsuranceFoundationPackages entry point' {
    BeforeEach {
        $script:originalPacPath = $env:POWERPLATFORMTOOLS_PACPATH
        $script:originalLogPath = $env:TEST_EXPORT_PAC_LOG_PATH
        $script:originalFailFile = $env:TEST_EXPORT_PAC_FAIL_FILE
        $script:originalZeroByteFile = $env:TEST_EXPORT_PAC_ZERO_BYTE_FILE
        $script:originalSkipFile = $env:TEST_EXPORT_PAC_SKIP_FILE
    }

    AfterEach {
        if ($null -eq $script:originalPacPath) {
            Remove-Item Env:POWERPLATFORMTOOLS_PACPATH -ErrorAction SilentlyContinue
        }
        else {
            $env:POWERPLATFORMTOOLS_PACPATH = $script:originalPacPath
        }

        if ($null -eq $script:originalLogPath) {
            Remove-Item Env:TEST_EXPORT_PAC_LOG_PATH -ErrorAction SilentlyContinue
        }
        else {
            $env:TEST_EXPORT_PAC_LOG_PATH = $script:originalLogPath
        }

        if ($null -eq $script:originalFailFile) {
            Remove-Item Env:TEST_EXPORT_PAC_FAIL_FILE -ErrorAction SilentlyContinue
        }
        else {
            $env:TEST_EXPORT_PAC_FAIL_FILE = $script:originalFailFile
        }

        if ($null -eq $script:originalZeroByteFile) {
            Remove-Item Env:TEST_EXPORT_PAC_ZERO_BYTE_FILE -ErrorAction SilentlyContinue
        }
        else {
            $env:TEST_EXPORT_PAC_ZERO_BYTE_FILE = $script:originalZeroByteFile
        }

        if ($null -eq $script:originalSkipFile) {
            Remove-Item Env:TEST_EXPORT_PAC_SKIP_FILE -ErrorAction SilentlyContinue
        }
        else {
            $env:TEST_EXPORT_PAC_SKIP_FILE = $script:originalSkipFile
        }
    }

    It 'invokes the resolved pac command with the exact arguments for all four exports' {
        $context = script:New-ExportTestContext
        script:New-FakePacCommand -Path $context.PacPath | Out-Null

        $env:POWERPLATFORMTOOLS_PACPATH = $context.PacPath
        $env:TEST_EXPORT_PAC_LOG_PATH = $context.LogPath

        Invoke-InsuranceFoundationPackageExport `
            -EnvironmentUrl 'https://unit.crm.dynamics.com' `
            -OutputDirectory $context.OutputDirectory

        $actual = @(
            script:Get-FakePacInvocations -LogPath $context.LogPath |
                Sort-Object Path |
                ForEach-Object { @($_.Arguments) -join '|' }
        )

        $expected = @(
            (@(
                    'solution', 'export',
                    '--environment', 'https://unit.crm.dynamics.com',
                    '--name', 'crmshow_DataModel',
                    '--path', (Join-Path $context.OutputDirectory 'crmshow_DataModel.zip'),
                    '--managed', 'false',
                    '--overwrite'
                ) -join '|'),
            (@(
                    'solution', 'export',
                    '--environment', 'https://unit.crm.dynamics.com',
                    '--name', 'crmshow_DataModel',
                    '--path', (Join-Path $context.OutputDirectory 'crmshow_DataModel_managed.zip'),
                    '--managed', 'true',
                    '--overwrite'
                ) -join '|'),
            (@(
                    'solution', 'export',
                    '--environment', 'https://unit.crm.dynamics.com',
                    '--name', 'crmshow_Foundation',
                    '--path', (Join-Path $context.OutputDirectory 'crmshow_Foundation.zip'),
                    '--managed', 'false',
                    '--overwrite'
                ) -join '|'),
            (@(
                    'solution', 'export',
                    '--environment', 'https://unit.crm.dynamics.com',
                    '--name', 'crmshow_Foundation',
                    '--path', (Join-Path $context.OutputDirectory 'crmshow_Foundation_managed.zip'),
                    '--managed', 'true',
                    '--overwrite'
                ) -join '|')
        ) | Sort-Object

        $actual | Should -Be $expected
    }

    It 'calls the export helper only after approval is granted' {
        $outputDirectory = Join-Path (Get-PSDrive -Name TestDrive).Root 'approval-gate'

        Mock Invoke-InsuranceFoundationPackageExport {}

        Invoke-InsuranceFoundationPackageExportEntry `
            -EnvironmentUrl 'https://unit.crm.dynamics.com' `
            -OutputDirectory $outputDirectory `
            -ApprovalGranted:$false

        Should -Invoke Invoke-InsuranceFoundationPackageExport -Times 0 -Exactly

        Invoke-InsuranceFoundationPackageExportEntry `
            -EnvironmentUrl 'https://unit.crm.dynamics.com' `
            -OutputDirectory $outputDirectory `
            -ApprovalGranted:$true

        Should -Invoke Invoke-InsuranceFoundationPackageExport -Times 1 -Exactly -ParameterFilter {
            $EnvironmentUrl -eq 'https://unit.crm.dynamics.com' -and
            $OutputDirectory -eq $outputDirectory
        }
    }

    It 'includes the package file name and CLI output when an export fails' {
        $context = script:New-ExportTestContext
        script:New-FakePacCommand -Path $context.PacPath | Out-Null

        $env:POWERPLATFORMTOOLS_PACPATH = $context.PacPath
        $env:TEST_EXPORT_PAC_LOG_PATH = $context.LogPath
        $env:TEST_EXPORT_PAC_FAIL_FILE = 'crmshow_DataModel_managed.zip'

        {
            Invoke-InsuranceFoundationPackageExport `
                -EnvironmentUrl 'https://unit.crm.dynamics.com' `
                -OutputDirectory $context.OutputDirectory
        } | Should -Throw '*crmshow_DataModel_managed.zip*simulated export failure*'
    }

    It 'rejects a zero-byte exported package' {
        $context = script:New-ExportTestContext
        script:New-FakePacCommand -Path $context.PacPath | Out-Null

        $env:POWERPLATFORMTOOLS_PACPATH = $context.PacPath
        $env:TEST_EXPORT_PAC_LOG_PATH = $context.LogPath
        $env:TEST_EXPORT_PAC_ZERO_BYTE_FILE = 'crmshow_Foundation.zip'

        {
            Invoke-InsuranceFoundationPackageExport `
                -EnvironmentUrl 'https://unit.crm.dynamics.com' `
                -OutputDirectory $context.OutputDirectory
        } | Should -Throw '*zero-byte package*crmshow_Foundation.zip*'
    }

    It 'rejects a missing exported package' {
        $context = script:New-ExportTestContext
        script:New-FakePacCommand -Path $context.PacPath | Out-Null

        $env:POWERPLATFORMTOOLS_PACPATH = $context.PacPath
        $env:TEST_EXPORT_PAC_LOG_PATH = $context.LogPath
        $env:TEST_EXPORT_PAC_SKIP_FILE = 'crmshow_Foundation_managed.zip'

        {
            Invoke-InsuranceFoundationPackageExport `
                -EnvironmentUrl 'https://unit.crm.dynamics.com' `
                -OutputDirectory $context.OutputDirectory
        } | Should -Throw '*did not produce package*crmshow_Foundation_managed.zip*'
    }

    It 'rejects a preexisting unrelated file in the output directory' {
        $context = script:New-ExportTestContext
        script:New-FakePacCommand -Path $context.PacPath | Out-Null
        New-Item -ItemType Directory -Path $context.OutputDirectory -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $context.OutputDirectory 'keep.txt') -Value 'x'

        $env:POWERPLATFORMTOOLS_PACPATH = $context.PacPath
        $env:TEST_EXPORT_PAC_LOG_PATH = $context.LogPath

        {
            Invoke-InsuranceFoundationPackageExport `
                -EnvironmentUrl 'https://unit.crm.dynamics.com' `
                -OutputDirectory $context.OutputDirectory
        } | Should -Throw '*already contains file*keep.txt*'

        @(script:Get-FakePacInvocations -LogPath $context.LogPath).Count | Should -Be 0
    }

    It 'runs successfully as a standalone entry point with a fake pac command' {
        $context = script:New-ExportTestContext
        script:New-FakePacCommand -Path $context.PacPath | Out-Null

        $invocation = script:Invoke-ExportEntryScript -Context $context

        $invocation.ExitCode | Should -Be 0
        @(Get-ChildItem -LiteralPath $invocation.OutputDirectory -File | ForEach-Object Name |
                Sort-Object) | Should -Be @(
            'crmshow_DataModel.zip',
            'crmshow_DataModel_managed.zip',
            'crmshow_Foundation.zip',
            'crmshow_Foundation_managed.zip'
        )
        @($invocation.Invocations).Count | Should -Be 4
    }

    It 'does not invoke pac or fail a final package assertion when run with WhatIf' {
        $context = script:New-ExportTestContext
        script:New-FakePacCommand -Path $context.PacPath | Out-Null

        $invocation = script:Invoke-ExportEntryScript -Context $context -WhatIf

        $invocation.ExitCode | Should -Be 0
        @($invocation.Invocations).Count | Should -Be 0
        Test-Path -LiteralPath $invocation.OutputDirectory | Should -BeFalse
        $invocation.Output | Should -Not -Match 'Unexpected authored package set'
    }

    It 'declined approval performs no exports and leaves the output directory empty' {
        $context = script:New-ExportTestContext
        script:New-FakePacCommand -Path $context.PacPath | Out-Null

        $env:POWERPLATFORMTOOLS_PACPATH = $context.PacPath
        $env:TEST_EXPORT_PAC_LOG_PATH = $context.LogPath

        Invoke-InsuranceFoundationPackageExportEntry `
            -EnvironmentUrl 'https://unit.crm.dynamics.com' `
            -OutputDirectory $context.OutputDirectory `
            -ApprovalGranted:$false

        @(script:Get-FakePacInvocations -LogPath $context.LogPath).Count | Should -Be 0
        Test-Path -LiteralPath $context.OutputDirectory | Should -BeFalse
    }
}

Describe 'Export package script safety' {
    It 'contains exactly one ShouldProcess approval gate' {
        $tokens = $null
        $errors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseFile(
            $script:exportScriptPath,
            [ref]$tokens,
            [ref]$errors
        )

        @($errors) | Should -BeNullOrEmpty

        $shouldProcessCalls = @(
            $ast.FindAll({
                    param($node)

                    $node -is [System.Management.Automation.Language.InvokeMemberExpressionAst] -and
                    $node.Member -is [System.Management.Automation.Language.StringConstantExpressionAst] -and
                    $node.Member.Value -eq 'ShouldProcess'
                }, $true)
        )

        $shouldProcessCalls.Count | Should -Be 1
    }

    It 'does not invoke pac when dot-sourced' {
        $outputDirectory = Join-Path (Get-PSDrive -Name TestDrive).Root 'dot-source-only'
        $text = @'
function pac { throw 'pac was called' }
. '__SCRIPT__' -EnvironmentUrl 'https://unit.crm.dynamics.com' -OutputDirectory '__OUTPUT__'
'@.Replace('__SCRIPT__', $script:exportScriptPath.Replace("'", "''")).
            Replace('__OUTPUT__', $outputDirectory.Replace("'", "''"))

        & ([scriptblock]::Create($text))
    }
}
