<#
.SYNOPSIS
    Exports the exact reviewed Insurance Foundation solution package set.
.DESCRIPTION
    Produces only the four approved Insurance Foundation packages from a
    Dataverse DEV environment. The script refuses to export into a directory
    that already contains files, resolves PAC via Resolve-PacCommand.ps1, and
    verifies every exported package before asserting the final exact file set.
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

function Invoke-InsuranceFoundationPackageExport {
    [CmdletBinding(SupportsShouldProcess)]
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

    if (Test-Path -LiteralPath $resolvedOutputDirectory) {
        if (-not (Test-Path -LiteralPath $resolvedOutputDirectory -PathType Container)) {
            throw "OutputDirectory is not a directory: $resolvedOutputDirectory"
        }

        $existingFiles = @(
            Get-ChildItem `
                -LiteralPath $resolvedOutputDirectory `
                -File `
                -Force `
                -Recurse
        )
        if ($existingFiles.Count -gt 0) {
            throw (
                "Output directory already contains file(s): {0}. " +
                'Use a new empty directory and rerun the export.'
            ) -f (Format-InsuranceFoundationPackageList -FileNames (
                    $existingFiles | ForEach-Object { $_.Name }
                ))
        }
    }

    $exports = @(Get-InsuranceFoundationExports)
    $completedExports = 0
    $pacCommand = $null

    foreach ($export in $exports) {
        $packagePath = Join-Path $resolvedOutputDirectory $export.File
        $managedValue = if ([bool]$export.Managed) { 'true' } else { 'false' }
        $action = "Export $($export.Name) managed=$managedValue"

        if ($PSCmdlet.ShouldProcess($packagePath, $action)) {
            if (-not (Test-Path -LiteralPath $resolvedOutputDirectory -PathType Container)) {
                New-Item `
                    -ItemType Directory `
                    -Path $resolvedOutputDirectory `
                    -Force | Out-Null
            }

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
            $completedExports++
        }
    }

    if ($completedExports -eq $exports.Count) {
        Assert-InsuranceFoundationPackageSet -FileNames @(
            Get-ChildItem `
                -LiteralPath $resolvedOutputDirectory `
                -File `
                -Force `
                -Recurse |
                ForEach-Object { $_.Name }
        )
    }
}

if ($MyInvocation.InvocationName -ne '.') {
    Invoke-InsuranceFoundationPackageExport `
        -EnvironmentUrl $EnvironmentUrl `
        -OutputDirectory $OutputDirectory `
        -WhatIf:$WhatIfPreference
}
