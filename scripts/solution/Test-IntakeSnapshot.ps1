<#
.SYNOPSIS
    Detect unsafe content in a prototype intake snapshot or its derivatives.
#>
[CmdletBinding()]
param(
    [string]$Path,
    [string]$ForbiddenEnvironmentHost,
    [switch]$ReportOnly
)

function Test-IntakeSnapshot {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Path,
        [string]$ForbiddenEnvironmentHost,
        [switch]$ReportOnly
    )

    $root = (Resolve-Path $Path).Path
    $patterns = [ordered]@{
        PrivateKey = '-----BEGIN [A-Z ]*PRIVATE KEY-----'
        BearerToken = 'Authorization\s*:\s*Bearer'
        StorageAccountKey = 'AccountKey\s*='
        SharedAccessSignature = 'SharedAccessSignature\s*='
        ClientSecret = 'ClientSecret'
        EnvironmentCurrentValue = '<currentvalue>'
        EmailAddress = '[A-Z0-9._%+\-]+@[A-Z0-9.\-]+\.[A-Z]{2,}'
    }
    if ($ForbiddenEnvironmentHost) {
        $patterns.SourceEnvironment = [regex]::Escape($ForbiddenEnvironmentHost)
    }

    $textExtensions = @('.xml', '.json', '.yml', '.yaml', '.html', '.htm', '.js', '.css', '.txt', '.md', '.csv', '')
    $findings = @()
    $files = @(Get-ChildItem $root -Recurse -File | Where-Object {
        $_.Length -le 10MB -and $textExtensions -contains $_.Extension.ToLowerInvariant()
    })
    foreach ($file in $files) {
        $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
        if ($null -eq $content) { continue }
        foreach ($entry in $patterns.GetEnumerator()) {
            if ($content -match $entry.Value) {
                $relative = $file.FullName.Substring($root.Length).TrimStart('\').Replace('\', '/')
                $findings += [pscustomobject]@{ category = $entry.Key; sourcePath = $relative }
            }
        }
    }

    $summary = [pscustomobject]@{
        scannedFiles = $files.Count
        matchCount = $findings.Count
        matches = @($findings | Sort-Object category, sourcePath)
    }
    if ($findings.Count -gt 0 -and -not $ReportOnly) {
        $details = ($summary.matches | ForEach-Object { "$($_.category):$($_.sourcePath)" }) -join ', '
        throw "Unsafe intake content detected: $details"
    }
    return $summary
}

if ($Path) {
    Test-IntakeSnapshot -Path $Path -ForbiddenEnvironmentHost $ForbiddenEnvironmentHost -ReportOnly:$ReportOnly
}
