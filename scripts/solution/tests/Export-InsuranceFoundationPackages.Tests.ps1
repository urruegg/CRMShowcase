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

if (-not [string]::IsNullOrWhiteSpace($env:TEST_EXPORT_PAC_INTERFERENCE_FILE)) {
    [System.IO.File]::WriteAllText(
        $env:TEST_EXPORT_PAC_INTERFERENCE_FILE,
        'interference'
    )
}

if ($env:TEST_EXPORT_PAC_FAIL_FILE -eq $fileName) {
    if (-not [string]::IsNullOrWhiteSpace($env:TEST_EXPORT_PAC_FAIL_TEXT)) {
        Write-Error $env:TEST_EXPORT_PAC_FAIL_TEXT -ErrorAction Continue
    }
    else {
        Write-Output "simulated export failure for $fileName"
    }
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

    function script:Get-ContextDirectoryPaths {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            $Context
        )

        if (-not (Test-Path -LiteralPath $Context.RootPath -PathType Container)) {
            return @()
        }

        return @(
            Get-ChildItem -LiteralPath $Context.RootPath -Directory -Force |
                ForEach-Object { $_.FullName } |
                Sort-Object
        )
    }

    function script:Get-DirectoryFileNames {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            [string]$Path
        )

        if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
            return @()
        }

        return @(
            Get-ChildItem -LiteralPath $Path -File -Force |
                ForEach-Object { $_.Name } |
                Sort-Object
        )
    }

    function script:Get-StagingDirectoryPaths {
        [CmdletBinding()]
        param(
            [AllowNull()]
            [object[]]$Invocations
        )

        return @(
            @($Invocations) |
                Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_.Path) } |
                ForEach-Object { Split-Path -Path ([string]$_.Path) -Parent } |
                Sort-Object -Unique
        )
    }

    function script:Invoke-ExportEntryScript {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            $Context,

            [switch]$WhatIf,

            [string]$FailFile,
            [string]$FailText,
            [string]$ZeroByteFile,
            [string]$SkipFile,
            [string]$InterferenceFile
        )

        $previousPacPath = $env:POWERPLATFORMTOOLS_PACPATH
        $previousLogPath = $env:TEST_EXPORT_PAC_LOG_PATH
        $previousFailFile = $env:TEST_EXPORT_PAC_FAIL_FILE
        $previousFailText = $env:TEST_EXPORT_PAC_FAIL_TEXT
        $previousZeroByteFile = $env:TEST_EXPORT_PAC_ZERO_BYTE_FILE
        $previousSkipFile = $env:TEST_EXPORT_PAC_SKIP_FILE
        $previousInterferenceFile = $env:TEST_EXPORT_PAC_INTERFERENCE_FILE

        try {
            $env:POWERPLATFORMTOOLS_PACPATH = $Context.PacPath
            $env:TEST_EXPORT_PAC_LOG_PATH = $Context.LogPath

            if ([string]::IsNullOrWhiteSpace($FailFile)) {
                Remove-Item Env:TEST_EXPORT_PAC_FAIL_FILE -ErrorAction SilentlyContinue
            }
            else {
                $env:TEST_EXPORT_PAC_FAIL_FILE = $FailFile
            }

            if ([string]::IsNullOrWhiteSpace($FailText)) {
                Remove-Item Env:TEST_EXPORT_PAC_FAIL_TEXT -ErrorAction SilentlyContinue
            }
            else {
                $env:TEST_EXPORT_PAC_FAIL_TEXT = $FailText
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

            if ([string]::IsNullOrWhiteSpace($InterferenceFile)) {
                Remove-Item Env:TEST_EXPORT_PAC_INTERFERENCE_FILE -ErrorAction SilentlyContinue
            }
            else {
                $env:TEST_EXPORT_PAC_INTERFERENCE_FILE = $InterferenceFile
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

            $previousErrorActionPreference = $ErrorActionPreference
            $ErrorActionPreference = 'Continue'
            try {
                $output = & $script:childPowerShellPath @arguments 2>&1
                $exitCode = $LASTEXITCODE
            }
            finally {
                $ErrorActionPreference = $previousErrorActionPreference
            }
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

            if ($null -eq $previousFailText) {
                Remove-Item Env:TEST_EXPORT_PAC_FAIL_TEXT -ErrorAction SilentlyContinue
            }
            else {
                $env:TEST_EXPORT_PAC_FAIL_TEXT = $previousFailText
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

            if ($null -eq $previousInterferenceFile) {
                Remove-Item Env:TEST_EXPORT_PAC_INTERFERENCE_FILE -ErrorAction SilentlyContinue
            }
            else {
                $env:TEST_EXPORT_PAC_INTERFERENCE_FILE = $previousInterferenceFile
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

Describe 'New-InsuranceFoundationPackageStagingDirectory' {
    It 'tracks the first pre-existing ancestor and every created parent directory' {
        $context = script:New-ExportTestContext
        $ancestor = Join-Path $context.RootPath 'pre-existing-ancestor'
        $mid = Join-Path $ancestor 'created-mid'
        $outputParent = Join-Path $mid 'created-parent'
        $outputDirectory = Join-Path $outputParent 'out'
        $null = New-Item -ItemType Directory -Path $ancestor -Force

        $stagingInfo = $null
        try {
            $stagingInfo = New-InsuranceFoundationPackageStagingDirectory `
                -OutputDirectory $outputDirectory `
                -OutputDirectoryParent $outputParent

            $stagingInfo.FirstPreExistingAncestor | Should -Be $ancestor
            @($stagingInfo.CreatedDirectories) | Should -Be @(
                $mid
                $outputParent
            )
            Test-Path -LiteralPath $stagingInfo.StagingDirectory | Should -BeTrue
            (Split-Path -Path $stagingInfo.StagingDirectory -Parent) |
                Should -Be $outputParent
        }
        finally {
            Remove-InsuranceFoundationStagingDirectory -Path $stagingInfo.StagingDirectory
            Remove-InsuranceFoundationCreatedDirectories `
                -FirstPreExistingAncestor $stagingInfo.FirstPreExistingAncestor `
                -CreatedDirectories $stagingInfo.CreatedDirectories
        }

        Test-Path -LiteralPath $outputParent | Should -BeFalse
        Test-Path -LiteralPath $mid | Should -BeFalse
        Test-Path -LiteralPath $ancestor | Should -BeTrue
        @(Get-ChildItem -LiteralPath $ancestor -Force).Count | Should -Be 0
    }
}

Describe 'Export-InsuranceFoundationPackages entry point' {
    BeforeEach {
        $script:originalPacPath = $env:POWERPLATFORMTOOLS_PACPATH
        $script:originalLogPath = $env:TEST_EXPORT_PAC_LOG_PATH
        $script:originalFailFile = $env:TEST_EXPORT_PAC_FAIL_FILE
        $script:originalZeroByteFile = $env:TEST_EXPORT_PAC_ZERO_BYTE_FILE
        $script:originalSkipFile = $env:TEST_EXPORT_PAC_SKIP_FILE
        $script:originalInterferenceFile = $env:TEST_EXPORT_PAC_INTERFERENCE_FILE
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

        if ($null -eq $script:originalInterferenceFile) {
            Remove-Item Env:TEST_EXPORT_PAC_INTERFERENCE_FILE -ErrorAction SilentlyContinue
        }
        else {
            $env:TEST_EXPORT_PAC_INTERFERENCE_FILE = $script:originalInterferenceFile
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

        $invocations = @(script:Get-FakePacInvocations -LogPath $context.LogPath)
        $stagingDirectories = @(script:Get-StagingDirectoryPaths -Invocations $invocations)

        $stagingDirectories.Count | Should -Be 1
        $stagingDirectory = $stagingDirectories[0]
        $stagingDirectory | Should -Not -Be $context.OutputDirectory
        (Split-Path -Path $stagingDirectory -Parent) |
            Should -Be (Split-Path -Path $context.OutputDirectory -Parent)

        $actual = @(
            $invocations |
                Sort-Object Path |
                ForEach-Object { @($_.Arguments) -join '|' }
        )

        $expected = @(
            (@(
                    'solution', 'export',
                    '--environment', 'https://unit.crm.dynamics.com',
                    '--name', 'crmshow_DataModel',
                    '--path', (Join-Path $stagingDirectory 'crmshow_DataModel.zip'),
                    '--managed', 'false',
                    '--overwrite'
                ) -join '|'),
            (@(
                    'solution', 'export',
                    '--environment', 'https://unit.crm.dynamics.com',
                    '--name', 'crmshow_DataModel',
                    '--path', (Join-Path $stagingDirectory 'crmshow_DataModel_managed.zip'),
                    '--managed', 'true',
                    '--overwrite'
                ) -join '|'),
            (@(
                    'solution', 'export',
                    '--environment', 'https://unit.crm.dynamics.com',
                    '--name', 'crmshow_Foundation',
                    '--path', (Join-Path $stagingDirectory 'crmshow_Foundation.zip'),
                    '--managed', 'false',
                    '--overwrite'
                ) -join '|'),
            (@(
                    'solution', 'export',
                    '--environment', 'https://unit.crm.dynamics.com',
                    '--name', 'crmshow_Foundation',
                    '--path', (Join-Path $stagingDirectory 'crmshow_Foundation_managed.zip'),
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

    It 'rejects a preexisting nonempty target untouched and does not invoke pac' {
        $context = script:New-ExportTestContext
        script:New-FakePacCommand -Path $context.PacPath | Out-Null
        New-Item -ItemType Directory -Path $context.OutputDirectory -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $context.OutputDirectory 'keep.txt') -Value 'x'
        New-Item -ItemType Directory -Path (Join-Path $context.OutputDirectory 'keep-dir') -Force | Out-Null

        $env:POWERPLATFORMTOOLS_PACPATH = $context.PacPath
        $env:TEST_EXPORT_PAC_LOG_PATH = $context.LogPath

        $message = $null
        try {
            Invoke-InsuranceFoundationPackageExport `
                -EnvironmentUrl 'https://unit.crm.dynamics.com' `
                -OutputDirectory $context.OutputDirectory
            throw 'Expected output directory preflight to fail.'
        }
        catch {
            $message = $_.Exception.Message
        }

        $message | Should -Match 'already contains item'
        $message | Should -Match 'keep\.txt'
        $message | Should -Match 'keep-dir'

        @(script:Get-FakePacInvocations -LogPath $context.LogPath).Count | Should -Be 0
        $existingItems = @(
            Get-ChildItem -LiteralPath $context.OutputDirectory -Force |
                ForEach-Object { $_.Name }
        )
        $existingItems.Count | Should -Be 2
        $existingItems | Should -Contain 'keep.txt'
        $existingItems | Should -Contain 'keep-dir'
    }

    It 'fails WhatIf target preflight against a nonempty target and does not invoke pac' {
        $context = script:New-ExportTestContext
        script:New-FakePacCommand -Path $context.PacPath | Out-Null
        New-Item -ItemType Directory -Path $context.OutputDirectory -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $context.OutputDirectory 'keep.txt') -Value 'x'
        New-Item -ItemType Directory -Path (Join-Path $context.OutputDirectory 'keep-dir') -Force | Out-Null

        $invocation = script:Invoke-ExportEntryScript -Context $context -WhatIf

        $invocation.ExitCode | Should -Not -Be 0
        $invocation.Output | Should -Match 'already contains item'
        $invocation.Output | Should -Match 'keep\.txt'
        $invocation.Output | Should -Match 'keep-dir'
        @($invocation.Invocations).Count | Should -Be 0

        $existingItems = @(
            Get-ChildItem -LiteralPath $context.OutputDirectory -Force |
                ForEach-Object { $_.Name } |
                Sort-Object
        )
        $existingItems.Count | Should -Be 2
        $existingItems | Should -Contain 'keep.txt'
        $existingItems | Should -Contain 'keep-dir'
    }

    It 'runs successfully as a standalone entry point with a fake pac command' {
        $context = script:New-ExportTestContext
        script:New-FakePacCommand -Path $context.PacPath | Out-Null

        $invocation = script:Invoke-ExportEntryScript -Context $context

        $invocation.ExitCode | Should -Be 0
        $stagingDirectories = @(script:Get-StagingDirectoryPaths -Invocations $invocation.Invocations)

        $stagingDirectories.Count | Should -Be 1
        $stagingDirectories[0] | Should -Not -Be $invocation.OutputDirectory
        (Split-Path -Path $stagingDirectories[0] -Parent) |
            Should -Be (Split-Path -Path $invocation.OutputDirectory -Parent)
        Test-Path -LiteralPath $stagingDirectories[0] | Should -BeFalse
        @(script:Get-DirectoryFileNames -Path $invocation.OutputDirectory) | Should -Be @(
            'crmshow_DataModel.zip',
            'crmshow_DataModel_managed.zip',
            'crmshow_Foundation.zip',
            'crmshow_Foundation_managed.zip'
        )
        @(script:Get-ContextDirectoryPaths -Context $context) | Should -Be @(
            $invocation.OutputDirectory
        )
        @($invocation.Invocations).Count | Should -Be 4
    }

    It 'fourth export failure leaves zero final files and cleans the staging directory' {
        $context = script:New-ExportTestContext
        script:New-FakePacCommand -Path $context.PacPath | Out-Null

        $invocation = script:Invoke-ExportEntryScript `
            -Context $context `
            -FailFile 'crmshow_DataModel_managed.zip'

        $invocation.ExitCode | Should -Not -Be 0
        $invocation.Output | Should -Match 'crmshow_DataModel_managed.zip'
        $invocation.Output | Should -Match 'simulated export failure'
        @($invocation.Invocations).Count | Should -Be 4

        $stagingDirectories = @(script:Get-StagingDirectoryPaths -Invocations $invocation.Invocations)
        $stagingDirectories.Count | Should -Be 1
        Test-Path -LiteralPath $invocation.OutputDirectory | Should -BeFalse
        Test-Path -LiteralPath $stagingDirectories[0] | Should -BeFalse
        @(script:Get-ContextDirectoryPaths -Context $context).Count | Should -Be 0
    }

    It 'emits a single safe pac export failure without raw command formatting' {
        $context = script:New-ExportTestContext
        script:New-FakePacCommand -Path $context.PacPath | Out-Null
        $escape = [char]27

        $invocation = script:Invoke-ExportEntryScript `
            -Context $context `
            -FailFile 'crmshow_DataModel_managed.zip' `
            -FailText (
                "::warning::export transport`r`nPermission denied`t" +
                "$escape[31mblocked$escape[0m"
            )

        $invocation.ExitCode | Should -Be 1
        script:Assert-SafeDiagnosticLine -Text $invocation.Output -MaxLength 450
        $invocation.Output | Should -Match 'pac solution export failed'
        $invocation.Output | Should -Match 'crmshow_DataModel_managed\.zip'
        $invocation.Output | Should -Match (
            [regex]::Escape(
                "Output: '::warning::export transport Permission denied blocked"
            )
        )
        $invocation.Output | Should -Not -Match 'At line:|--environment|--name|--path'
    }

    It 'zero-byte validation failure leaves zero final files' {
        $context = script:New-ExportTestContext
        script:New-FakePacCommand -Path $context.PacPath | Out-Null

        $invocation = script:Invoke-ExportEntryScript `
            -Context $context `
            -ZeroByteFile 'crmshow_Foundation.zip'

        $invocation.ExitCode | Should -Not -Be 0
        $invocation.Output | Should -Match 'zero-byte package'
        @($invocation.Invocations).Count | Should -Be 1

        $stagingDirectories = @(script:Get-StagingDirectoryPaths -Invocations $invocation.Invocations)
        $stagingDirectories.Count | Should -Be 1
        Test-Path -LiteralPath $invocation.OutputDirectory | Should -BeFalse
        Test-Path -LiteralPath $stagingDirectories[0] | Should -BeFalse
        @(script:Get-ContextDirectoryPaths -Context $context).Count | Should -Be 0
    }

    It 'removes a freshly created output parent after a nested failure' {
        $context = script:New-ExportTestContext
        $outputParent = Join-Path $context.RootPath 'fresh-parent'
        $context.OutputDirectory = Join-Path $outputParent 'out'
        script:New-FakePacCommand -Path $context.PacPath | Out-Null

        $invocation = script:Invoke-ExportEntryScript `
            -Context $context `
            -FailFile 'crmshow_DataModel_managed.zip'

        $invocation.ExitCode | Should -Not -Be 0
        $invocation.Output | Should -Match 'crmshow_DataModel_managed.zip'
        $invocation.Output | Should -Match 'simulated export failure'
        @($invocation.Invocations).Count | Should -Be 4
        Test-Path -LiteralPath $context.OutputDirectory | Should -BeFalse
        Test-Path -LiteralPath $outputParent | Should -BeFalse
        @(script:Get-ContextDirectoryPaths -Context $context).Count | Should -Be 0
    }

    It 'preserves a pre-existing empty output parent after failure' {
        $context = script:New-ExportTestContext
        $outputParent = Join-Path $context.RootPath 'existing-parent'
        $null = New-Item -ItemType Directory -Path $outputParent -Force
        $context.OutputDirectory = Join-Path $outputParent 'out'
        script:New-FakePacCommand -Path $context.PacPath | Out-Null

        $invocation = script:Invoke-ExportEntryScript `
            -Context $context `
            -FailFile 'crmshow_DataModel_managed.zip'

        $invocation.ExitCode | Should -Not -Be 0
        @($invocation.Invocations).Count | Should -Be 4
        Test-Path -LiteralPath $context.OutputDirectory | Should -BeFalse
        Test-Path -LiteralPath $outputParent | Should -BeTrue
        @(Get-ChildItem -LiteralPath $outputParent -Force).Count | Should -Be 0
        @(script:Get-ContextDirectoryPaths -Context $context) | Should -Be @(
            $outputParent
        )
    }

    It 'removes run-created empty ancestors on failure but retains the pre-existing ancestor' {
        $context = script:New-ExportTestContext
        $ancestor = Join-Path $context.RootPath 'pre-existing-ancestor'
        $mid = Join-Path $ancestor 'created-mid'
        $outputParent = Join-Path $mid 'created-parent'
        $null = New-Item -ItemType Directory -Path $ancestor -Force
        $context.OutputDirectory = Join-Path $outputParent 'out'
        script:New-FakePacCommand -Path $context.PacPath | Out-Null

        $invocation = script:Invoke-ExportEntryScript `
            -Context $context `
            -FailFile 'crmshow_DataModel_managed.zip'

        $invocation.ExitCode | Should -Not -Be 0
        @($invocation.Invocations).Count | Should -Be 4
        Test-Path -LiteralPath $context.OutputDirectory | Should -BeFalse
        Test-Path -LiteralPath $outputParent | Should -BeFalse
        Test-Path -LiteralPath $mid | Should -BeFalse
        Test-Path -LiteralPath $ancestor | Should -BeTrue
        @(Get-ChildItem -LiteralPath $ancestor -Force).Count | Should -Be 0
        @(script:Get-ContextDirectoryPaths -Context $context) | Should -Be @(
            $ancestor
        )
    }

    It 'stops cleanup when a created ancestor becomes nonempty' {
        $context = script:New-ExportTestContext
        $ancestor = Join-Path $context.RootPath 'interference-ancestor'
        $mid = Join-Path $ancestor 'created-mid'
        $outputParent = Join-Path $mid 'created-parent'
        $null = New-Item -ItemType Directory -Path $ancestor -Force
        $context.OutputDirectory = Join-Path $outputParent 'out'
        script:New-FakePacCommand -Path $context.PacPath | Out-Null

        $invocation = script:Invoke-ExportEntryScript `
            -Context $context `
            -FailFile 'crmshow_DataModel_managed.zip' `
            -InterferenceFile (Join-Path $mid 'block.txt')

        $invocation.ExitCode | Should -Not -Be 0
        @($invocation.Invocations).Count | Should -Be 4
        Test-Path -LiteralPath $context.OutputDirectory | Should -BeFalse
        Test-Path -LiteralPath $outputParent | Should -BeFalse
        Test-Path -LiteralPath $mid | Should -BeTrue
        Test-Path -LiteralPath $ancestor | Should -BeTrue
        @(Get-ChildItem -LiteralPath $mid -Force | ForEach-Object { $_.Name }) | Should -Be @(
            'block.txt'
        )
        @(script:Get-ContextDirectoryPaths -Context $context) | Should -Be @(
            $ancestor
        )
    }

    It 'does not invoke pac or fail a final package assertion when run with WhatIf' {
        $context = script:New-ExportTestContext
        $outputParent = Join-Path $context.RootPath 'whatif-parent'
        $context.OutputDirectory = Join-Path $outputParent 'out'
        script:New-FakePacCommand -Path $context.PacPath | Out-Null

        $invocation = script:Invoke-ExportEntryScript -Context $context -WhatIf

        $invocation.ExitCode | Should -Be 0
        @($invocation.Invocations).Count | Should -Be 0
        Test-Path -LiteralPath $invocation.OutputDirectory | Should -BeFalse
        Test-Path -LiteralPath $outputParent | Should -BeFalse
        @(script:Get-ContextDirectoryPaths -Context $context).Count | Should -Be 0
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
        @(script:Get-ContextDirectoryPaths -Context $context).Count | Should -Be 0
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

    It 'uses only literal-path Remove-Item calls without wildcard arguments' {
        $tokens = $null
        $errors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseFile(
            $script:exportScriptPath,
            [ref]$tokens,
            [ref]$errors
        )

        @($errors) | Should -BeNullOrEmpty

        $removeItemCalls = @(
            $ast.FindAll({
                    param($node)

                    $node -is [System.Management.Automation.Language.CommandAst] -and
                    $node.GetCommandName() -eq 'Remove-Item'
                }, $true)
        )

        $removeItemCalls.Count | Should -BeGreaterThan 0

        foreach ($call in $removeItemCalls) {
            $parameters = @(
                $call.CommandElements |
                    Where-Object {
                        $_ -is [System.Management.Automation.Language.CommandParameterAst]
                    }
            )

            @($parameters | Where-Object { $_.ParameterName -eq 'Path' }).Count |
                Should -Be 0
            @($parameters | Where-Object { $_.ParameterName -eq 'LiteralPath' }).Count |
                Should -BeGreaterThan 0

            $argumentValues = @(
                $call.CommandElements |
                    Select-Object -Skip 1 |
                    Where-Object {
                        $_ -is [System.Management.Automation.Language.StringConstantExpressionAst] -or
                        $_ -is [System.Management.Automation.Language.ExpandableStringExpressionAst]
                    } |
                    ForEach-Object { $_.Value }
            )

            @($argumentValues | Where-Object { $_ -match '[\*\?]' }) |
                Should -BeNullOrEmpty
        }
    }
}
