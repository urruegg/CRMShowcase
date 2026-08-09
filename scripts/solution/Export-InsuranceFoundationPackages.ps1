<#
.SYNOPSIS
    Exports the exact reviewed Insurance Foundation solution package set.
.DESCRIPTION
    Produces only the four approved Insurance Foundation packages from a
    Dataverse DEV environment. The script refuses to export into a directory
    that already contains files or subdirectories, stages exports into a
    unique sibling directory, resolves PAC via Resolve-PacCommand.ps1, and
    publishes only a fully validated exact package set.
.PARAMETER EnvironmentUrl
    Dataverse environment URL passed to pac solution export.
.PARAMETER OutputDirectory
    Directory that will receive the four package zip files. The directory must
    be empty when it already exists.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [string]$EnvironmentUrl,

    [Parameter(Mandatory)]
    [string]$OutputDirectory
)

$ErrorActionPreference = 'Stop'

function Get-InsuranceFoundationExports {
    [CmdletBinding()]
    param()

    return @(
        [pscustomobject][ordered]@{
            Name    = 'crmshow_Foundation'
            Managed = $false
            File    = 'crmshow_Foundation.zip'
        }
        [pscustomobject][ordered]@{
            Name    = 'crmshow_Foundation'
            Managed = $true
            File    = 'crmshow_Foundation_managed.zip'
        }
        [pscustomobject][ordered]@{
            Name    = 'crmshow_DataModel'
            Managed = $false
            File    = 'crmshow_DataModel.zip'
        }
        [pscustomobject][ordered]@{
            Name    = 'crmshow_DataModel'
            Managed = $true
            File    = 'crmshow_DataModel_managed.zip'
        }
    )
}

function Get-InsuranceFoundationPackageNameCounts {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [object[]]$FileNames
    )

    $counts = New-Object 'System.Collections.Generic.Dictionary[string,int]' (
        [System.StringComparer]::Ordinal
    )

    foreach ($fileName in @($FileNames)) {
        $normalized = if ($null -eq $fileName) {
            '<null>'
        }
        else {
            $text = [string]$fileName
            if ([string]::IsNullOrEmpty($text)) {
                '<empty>'
            }
            else {
                $text
            }
        }

        if ($counts.ContainsKey($normalized)) {
            $counts[$normalized] = $counts[$normalized] + 1
        }
        else {
            $counts.Add($normalized, 1)
        }
    }

    return $counts
}

function Format-InsuranceFoundationPackageList {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [object[]]$FileNames
    )

    $values = @(
        foreach ($fileName in @($FileNames)) {
            if ($null -eq $fileName) {
                '<null>'
                continue
            }

            $text = [string]$fileName
            if ([string]::IsNullOrEmpty($text)) {
                '<empty>'
                continue
            }

            $text
        }
    )

    if ($values.Count -eq 0) {
        return '<none>'
    }

    return (@($values | Sort-Object) -join ', ')
}

function Assert-InsuranceFoundationPackageSet {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string[]]$FileNames
    )

    $expectedFiles = @(
        Get-InsuranceFoundationExports |
            ForEach-Object { [string]$_.File }
    )
    $actualFiles = @($FileNames | ForEach-Object { [string]$_ })

    $expectedCounts = Get-InsuranceFoundationPackageNameCounts -FileNames $expectedFiles
    $actualCounts = Get-InsuranceFoundationPackageNameCounts -FileNames $actualFiles
    $allNames = New-Object 'System.Collections.Generic.HashSet[string]' (
        [System.StringComparer]::Ordinal
    )

    foreach ($name in $expectedCounts.Keys) {
        $null = $allNames.Add($name)
    }
    foreach ($name in $actualCounts.Keys) {
        $null = $allNames.Add($name)
    }

    $missing = New-Object 'System.Collections.Generic.List[string]'
    $extra = New-Object 'System.Collections.Generic.List[string]'
    $duplicates = New-Object 'System.Collections.Generic.List[string]'

    foreach ($name in @($allNames | Sort-Object)) {
        $expectedCount = 0
        if ($expectedCounts.ContainsKey($name)) {
            $expectedCount = $expectedCounts[$name]
        }

        $actualCount = 0
        if ($actualCounts.ContainsKey($name)) {
            $actualCount = $actualCounts[$name]
        }

        if ($actualCount -lt $expectedCount) {
            for ($index = 0; $index -lt ($expectedCount - $actualCount); $index++) {
                $missing.Add($name) | Out-Null
            }
        }

        if ($actualCount -gt $expectedCount) {
            for ($index = 0; $index -lt ($actualCount - $expectedCount); $index++) {
                $extra.Add($name) | Out-Null
            }
        }

        if ($actualCount -gt 1) {
            $duplicates.Add(('{0} x{1}' -f $name, $actualCount)) | Out-Null
        }
    }

    if ($missing.Count -eq 0 -and $extra.Count -eq 0 -and $duplicates.Count -eq 0) {
        return
    }

    $message = @(
        'Unexpected authored package set.'
        'Expected exactly: {0}.' -f (Format-InsuranceFoundationPackageList -FileNames $expectedFiles)
        'Actual: {0}.' -f (Format-InsuranceFoundationPackageList -FileNames $actualFiles)
    )

    if ($missing.Count -gt 0) {
        $message += 'Missing: {0}.' -f (Format-InsuranceFoundationPackageList -FileNames $missing)
    }
    if ($extra.Count -gt 0) {
        $message += 'Extra: {0}.' -f (Format-InsuranceFoundationPackageList -FileNames $extra)
    }
    if ($duplicates.Count -gt 0) {
        $message += 'Duplicates: {0}.' -f (Format-InsuranceFoundationPackageList -FileNames $duplicates)
    }

    $message += 'Keep only the four reviewed .zip files with exact casing.'
    throw ($message -join ' ')
}

function Resolve-InsuranceFoundationPacCommand {
    [CmdletBinding()]
    param()

    . (Join-Path $PSScriptRoot 'Resolve-PacCommand.ps1')
    return Resolve-PacCommand
}

function Assert-InsuranceFoundationExportedPackage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$File
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Export did not produce package '$File' at '$Path'."
    }

    $item = Get-Item -LiteralPath $Path -Force
    if ($item.Length -le 0) {
        throw "Export produced a zero-byte package '$File' at '$Path'."
    }
}

function Get-InsuranceFoundationDirectoryEntries {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        return @()
    }

    return @(
        Get-ChildItem `
            -LiteralPath $Path `
            -Force
    )
}

function Assert-InsuranceFoundationOutputDirectorySafety {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$OutputDirectory
    )

    if (-not (Test-Path -LiteralPath $OutputDirectory)) {
        return
    }

    if (-not (Test-Path -LiteralPath $OutputDirectory -PathType Container)) {
        throw "OutputDirectory is not a directory: $OutputDirectory"
    }

    $existingItems = @(Get-InsuranceFoundationDirectoryEntries -Path $OutputDirectory)
    if ($existingItems.Count -eq 0) {
        return
    }

    throw (
        "Output directory already contains item(s): {0}. " +
        'Use a new empty directory and rerun the export.'
    ) -f (Format-InsuranceFoundationPackageList -FileNames (
            $existingItems | ForEach-Object { $_.Name }
        ))
}

function Get-InsuranceFoundationOutputDirectoryParent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$OutputDirectory
    )

    $parentPath = Split-Path -Path $OutputDirectory -Parent
    if ([string]::IsNullOrWhiteSpace($parentPath)) {
        throw "OutputDirectory must not be a filesystem root: $OutputDirectory"
    }

    return [System.IO.Path]::GetFullPath($parentPath)
}

function Resolve-InsuranceFoundationPackageExportTarget {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$EnvironmentUrl,

        [Parameter(Mandatory)]
        [string]$OutputDirectory
    )

    if ([string]::IsNullOrWhiteSpace($EnvironmentUrl)) {
        throw 'EnvironmentUrl is required.'
    }
    if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
        throw 'OutputDirectory is required.'
    }

    $resolvedOutputDirectory = [System.IO.Path]::GetFullPath($OutputDirectory)
    Assert-InsuranceFoundationOutputDirectorySafety `
        -OutputDirectory $resolvedOutputDirectory

    $outputDirectoryParent = Get-InsuranceFoundationOutputDirectoryParent `
        -OutputDirectory $resolvedOutputDirectory
    if (Test-Path -LiteralPath $outputDirectoryParent) {
        if (-not (Test-Path -LiteralPath $outputDirectoryParent -PathType Container)) {
            throw "OutputDirectory parent is not a directory: $outputDirectoryParent"
        }
    }

    return [pscustomobject][ordered]@{
        EnvironmentUrl        = $EnvironmentUrl
        OutputDirectory       = $resolvedOutputDirectory
        OutputDirectoryParent = $outputDirectoryParent
    }
}

function New-InsuranceFoundationDirectoryCreationContext {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    $resolvedPath = [System.IO.Path]::GetFullPath($Path)
    $firstPreExistingAncestor = $null
    $missingDirectories = New-Object 'System.Collections.Generic.List[string]'
    $currentPath = $resolvedPath

    while ($true) {
        if (Test-Path -LiteralPath $currentPath) {
            if (-not (Test-Path -LiteralPath $currentPath -PathType Container)) {
                throw "OutputDirectory parent is not a directory: $currentPath"
            }

            $firstPreExistingAncestor = $currentPath
            break
        }

        $missingDirectories.Add($currentPath) | Out-Null

        $nextPath = Split-Path -Path $currentPath -Parent
        if ([string]::IsNullOrWhiteSpace($nextPath)) {
            throw "OutputDirectory parent must be below an existing filesystem root: $resolvedPath"
        }

        $resolvedNextPath = [System.IO.Path]::GetFullPath($nextPath)
        if ($resolvedNextPath -ceq $currentPath) {
            throw "OutputDirectory parent must be below an existing filesystem root: $resolvedPath"
        }

        $currentPath = $resolvedNextPath
    }

    $createdDirectories = @()
    $directoriesToCreate = @($missingDirectories)
    [array]::Reverse($directoriesToCreate)

    try {
        foreach ($directoryPath in $directoriesToCreate) {
            if (Test-Path -LiteralPath $directoryPath) {
                if (-not (Test-Path -LiteralPath $directoryPath -PathType Container)) {
                    throw "OutputDirectory parent is not a directory: $directoryPath"
                }

                continue
            }

            try {
                New-Item -ItemType Directory -Path $directoryPath -ErrorAction Stop | Out-Null
            }
            catch {
                if (Test-Path -LiteralPath $directoryPath -PathType Container) {
                    continue
                }

                throw
            }

            $createdDirectories += $directoryPath
        }

        return [pscustomobject][ordered]@{
            Path                     = $resolvedPath
            FirstPreExistingAncestor = $firstPreExistingAncestor
            CreatedDirectories       = @($createdDirectories)
        }
    }
    catch {
        Remove-InsuranceFoundationCreatedDirectories `
            -FirstPreExistingAncestor $firstPreExistingAncestor `
            -CreatedDirectories $createdDirectories
        throw
    }
}

function Remove-InsuranceFoundationCreatedDirectories {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [string]$FirstPreExistingAncestor,

        [AllowNull()]
        [string[]]$CreatedDirectories
    )

    if (-not $CreatedDirectories) {
        return
    }

    $resolvedFirstPreExistingAncestor = $null
    if (-not [string]::IsNullOrWhiteSpace($FirstPreExistingAncestor)) {
        $resolvedFirstPreExistingAncestor = [System.IO.Path]::GetFullPath($FirstPreExistingAncestor)
    }

    $pathsToCheck = @(
        @($CreatedDirectories | ForEach-Object {
            if (-not [string]::IsNullOrWhiteSpace($_)) {
                [System.IO.Path]::GetFullPath($_)
            }
        }) | Where-Object { $_ }
    )

    for ($index = ($pathsToCheck.Count - 1); $index -ge 0; $index--) {
        $candidatePath = $pathsToCheck[$index]
        if ($resolvedFirstPreExistingAncestor -and $candidatePath -ceq $resolvedFirstPreExistingAncestor) {
            continue
        }
        if (-not (Test-Path -LiteralPath $candidatePath -PathType Container)) {
            if (Test-Path -LiteralPath $candidatePath) {
                break
            }

            continue
        }

        $entries = @(Get-InsuranceFoundationDirectoryEntries -Path $candidatePath)
        if ($entries.Count -gt 0) {
            break
        }

        Remove-Item -LiteralPath $candidatePath -Force
    }
}

function New-InsuranceFoundationPackageStagingDirectory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$OutputDirectory,

        [Parameter(Mandatory)]
        [string]$OutputDirectoryParent
    )

    $parentPath = [System.IO.Path]::GetFullPath($OutputDirectoryParent)
    $parentDirectoryContext = $null
    $stagingDirectory = $null

    try {
        $parentDirectoryContext = New-InsuranceFoundationDirectoryCreationContext `
            -Path $parentPath
        $parentPath = [string]$parentDirectoryContext.Path

        $leafName = Split-Path -Path $OutputDirectory -Leaf
        if ([string]::IsNullOrWhiteSpace($leafName)) {
            $leafName = 'insurance-foundation-packages'
        }

        do {
            $stagingDirectory = Join-Path `
                $parentPath `
                ('{0}.staging.{1}' -f $leafName, [guid]::NewGuid().Guid)
        } while (Test-Path -LiteralPath $stagingDirectory)

        New-Item -ItemType Directory -Path $stagingDirectory -Force | Out-Null
        return [pscustomobject][ordered]@{
            StagingDirectory             = $stagingDirectory
            OutputDirectoryParent        = $parentPath
            FirstPreExistingAncestor     = $parentDirectoryContext.FirstPreExistingAncestor
            CreatedDirectories           = @($parentDirectoryContext.CreatedDirectories)
        }
    }
    catch {
        Remove-InsuranceFoundationStagingDirectory -Path $stagingDirectory
        Remove-InsuranceFoundationCreatedDirectories `
            -FirstPreExistingAncestor $parentDirectoryContext.FirstPreExistingAncestor `
            -CreatedDirectories $parentDirectoryContext.CreatedDirectories
        throw
    }
}

function Assert-InsuranceFoundationStagingDirectory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        throw "Export staging directory is missing: $Path"
    }

    $entries = @(Get-InsuranceFoundationDirectoryEntries -Path $Path)
    $directories = @($entries | Where-Object { $_.PSIsContainer })
    if ($directories.Count -gt 0) {
        throw (
            "Export staging directory contains unexpected subdirector(ies): {0}."
        ) -f (Format-InsuranceFoundationPackageList -FileNames (
                $directories | ForEach-Object { $_.Name }
            ))
    }

    foreach ($export in @(Get-InsuranceFoundationExports)) {
        Assert-InsuranceFoundationExportedPackage `
            -Path (Join-Path $Path $export.File) `
            -File $export.File
    }

    Assert-InsuranceFoundationPackageSet -FileNames @(
        $entries |
            Where-Object { -not $_.PSIsContainer } |
            ForEach-Object { $_.Name }
    )
}

function Publish-InsuranceFoundationStagingDirectory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$StagingDirectory,

        [Parameter(Mandatory)]
        [string]$OutputDirectory
    )

    if (-not (Test-Path -LiteralPath $StagingDirectory -PathType Container)) {
        throw "Export staging directory is missing before publish: $StagingDirectory"
    }

    if (Test-Path -LiteralPath $OutputDirectory) {
        if (-not (Test-Path -LiteralPath $OutputDirectory -PathType Container)) {
            throw "OutputDirectory is not a directory: $OutputDirectory"
        }

        $existingItems = @(Get-InsuranceFoundationDirectoryEntries -Path $OutputDirectory)
        if ($existingItems.Count -gt 0) {
            throw (
                "Output directory became non-empty before publish: {0}. " +
                'Refusing to replace an existing path.'
            ) -f (Format-InsuranceFoundationPackageList -FileNames (
                    $existingItems | ForEach-Object { $_.Name }
                ))
        }

        Remove-Item -LiteralPath $OutputDirectory -Force
    }

    [System.IO.Directory]::Move($StagingDirectory, $OutputDirectory)
}

function Remove-InsuranceFoundationStagingDirectory {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [string]$Path
    )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        return
    }

    if (Test-Path -LiteralPath $Path -PathType Container) {
        Remove-Item -LiteralPath $Path -Recurse -Force
    }
}

function Invoke-InsuranceFoundationPackageExport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$EnvironmentUrl,

        [Parameter(Mandatory)]
        [string]$OutputDirectory
    )

    $target = Resolve-InsuranceFoundationPackageExportTarget `
        -EnvironmentUrl $EnvironmentUrl `
        -OutputDirectory $OutputDirectory
    $resolvedOutputDirectory = $target.OutputDirectory
    $outputDirectoryParent = $target.OutputDirectoryParent

    $exports = @(Get-InsuranceFoundationExports)
    $pacCommand = $null
    $stagingDirectory = $null
    $stagingDirectoryInfo = $null

    try {
        $stagingDirectoryInfo = New-InsuranceFoundationPackageStagingDirectory `
            -OutputDirectory $resolvedOutputDirectory `
            -OutputDirectoryParent $outputDirectoryParent
        $stagingDirectory = [string]$stagingDirectoryInfo.StagingDirectory

        foreach ($export in $exports) {
            $packagePath = Join-Path $stagingDirectory $export.File
            $managedValue = if ([bool]$export.Managed) { 'true' } else { 'false' }
            if ($null -eq $pacCommand) {
                $pacCommand = Resolve-InsuranceFoundationPacCommand
            }

            $arguments = @(
                'solution',
                'export',
                '--environment', $EnvironmentUrl,
                '--name', [string]$export.Name,
                '--path', $packagePath,
                '--managed', $managedValue,
                '--overwrite'
            )

            $output = & $pacCommand @arguments 2>&1
            $exitCode = $LASTEXITCODE
            if ($exitCode -ne 0) {
                $detail = ($output | Out-String).Trim()
                if ([string]::IsNullOrWhiteSpace($detail)) {
                    $detail = '<no output>'
                }

                throw (
                    "pac solution export failed for '{0}' (solution '{1}', " +
                    'managed={2}, exit code {3}). Output: {4}'
                ) -f $export.File, $export.Name, $managedValue, $exitCode, $detail
            }

            Assert-InsuranceFoundationExportedPackage `
                -Path $packagePath `
                -File $export.File
        }

        Assert-InsuranceFoundationStagingDirectory -Path $stagingDirectory
        Publish-InsuranceFoundationStagingDirectory `
            -StagingDirectory $stagingDirectory `
            -OutputDirectory $resolvedOutputDirectory
    }
    finally {
        Remove-InsuranceFoundationStagingDirectory -Path $stagingDirectory
        Remove-InsuranceFoundationCreatedDirectories `
            -FirstPreExistingAncestor $stagingDirectoryInfo.FirstPreExistingAncestor `
            -CreatedDirectories $stagingDirectoryInfo.CreatedDirectories
    }
}

function Invoke-InsuranceFoundationPackageExportEntry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$EnvironmentUrl,

        [Parameter(Mandatory)]
        [string]$OutputDirectory,

        [Parameter(Mandatory)]
        [bool]$ApprovalGranted
    )

    if (-not $ApprovalGranted) {
        return
    }

    Invoke-InsuranceFoundationPackageExport `
        -EnvironmentUrl $EnvironmentUrl `
        -OutputDirectory $OutputDirectory
}

if ($MyInvocation.InvocationName -ne '.') {
    $target = Resolve-InsuranceFoundationPackageExportTarget `
        -EnvironmentUrl $EnvironmentUrl `
        -OutputDirectory $OutputDirectory
    $packageSummary = ((
            Get-InsuranceFoundationExports |
                ForEach-Object {
                    '{0} ({1})' -f $_.File, ($(if ([bool]$_.Managed) { 'managed' } else { 'unmanaged' }))
                }
        ) -join ', ')

    Invoke-InsuranceFoundationPackageExportEntry `
        -EnvironmentUrl $target.EnvironmentUrl `
        -OutputDirectory $target.OutputDirectory `
        -ApprovalGranted:$(
            $PSCmdlet.ShouldProcess(
                $target.OutputDirectory,
                "Export four reviewed packages: $packageSummary"
            )
        )
}
