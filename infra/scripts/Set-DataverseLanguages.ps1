<#
.SYNOPSIS
    Reconcile the supported Dataverse languages for an environment.

.DESCRIPTION
    Reads the provisioned-language list and provisions requested missing
    languages through documented Dataverse Web API operations. Authentication
    is delegated to az rest. Languages are never deprovisioned.
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^https://[a-z0-9-]+\.crm(?:\d+)?\.dynamics\.com/?$')]
    [string]$EnvironmentUrl,

    [Parameter(Mandatory)]
    [int[]]$LocaleId
)

. (Join-Path $PSScriptRoot '..\..\scripts\solution\ConvertTo-SafeCliDiagnosticLine.ps1')

$ErrorActionPreference = 'Stop'
$script:SupportedLocaleIds = @(1031, 1033, 1036, 1040)

function Get-NormalizedLocaleIds {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [int[]]$LocaleId
    )

    $unsupported = @($LocaleId | Where-Object { $_ -notin $script:SupportedLocaleIds } | Sort-Object -Unique)
    if ($unsupported.Count -gt 0) {
        throw "Unsupported Dataverse locale ID: $($unsupported -join ', '). Supported locale IDs are 1031, 1033, 1036 and 1040."
    }

    return @($LocaleId | Sort-Object -Unique)
}

function Get-ProvisionedLocaleIds {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$BaseUrl
    )

    $url = "$($BaseUrl.TrimEnd('/'))/api/data/v9.2/RetrieveProvisionedLanguages()"
    $response = Invoke-DataverseRest -Method GET -Url $url
    if ($null -eq $response.RetrieveProvisionedLanguages) {
        throw 'RetrieveProvisionedLanguages returned no language collection.'
    }
    return @($response.RetrieveProvisionedLanguages | ForEach-Object { [int]$_ })
}

function Wait-DataverseLanguage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$BaseUrl,

        [Parameter(Mandatory)]
        [int]$LocaleId,

        [ValidateRange(0, [int]::MaxValue)]
        [int]$TimeoutSeconds = 3600,

        [ValidateRange(1, [int]::MaxValue)]
        [int]$PollSeconds = 30
    )

    $deadline = [DateTimeOffset]::UtcNow.AddSeconds($TimeoutSeconds)
    while ($true) {
        if ($LocaleId -in @(Get-ProvisionedLocaleIds -BaseUrl $BaseUrl)) {
            return
        }

        $remainingSeconds = ($deadline - [DateTimeOffset]::UtcNow).TotalSeconds
        if ($remainingSeconds -le 0) {
            throw "Locale '$LocaleId' did not become active within $TimeoutSeconds seconds."
        }

        $sleepSeconds = [Math]::Min($PollSeconds, [Math]::Ceiling($remainingSeconds))
        Start-Sleep -Seconds $sleepSeconds
    }
}

function Invoke-DataverseRest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('GET', 'POST')]
        [string]$Method,

        [Parameter(Mandatory)]
        [string]$Url,

        [object]$Body
    )

    $resource = $EnvironmentUrl.TrimEnd('/') + '/'
    $arguments = @(
        'rest',
        '--method', $Method,
        '--url', $Url,
        '--resource', $resource,
        '--only-show-errors'
    )
    $tempFile = $null

    try {
        if ($null -ne $Body) {
            $tempFile = New-TemporaryFile
            $Body |
                ConvertTo-Json -Depth 5 |
                Set-Content -LiteralPath $tempFile.FullName -Encoding UTF8
            $arguments += @(
                '--body', "@$($tempFile.FullName)",
                '--headers', 'Content-Type=application/json'
            )
        }

        $result = & az @arguments 2>&1
        if ($LASTEXITCODE -ne 0) {
            $detail = ConvertTo-SafeCliDiagnosticLine -Value $result
            throw "Dataverse request failed: $Method $Url. Output: $detail"
        }
        if ($result) {
            return $result | ConvertFrom-Json
        }
    }
    finally {
        if ($null -ne $tempFile) {
            Remove-Item -LiteralPath $tempFile.FullName -Force -ErrorAction SilentlyContinue
        }
    }
}

function Invoke-DataverseLanguageReconciliation {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$BaseUrl,

        [Parameter(Mandatory)]
        [int[]]$RequiredLocaleId
    )

    $baseUrl = $BaseUrl.TrimEnd('/')
    $provisioned = @(Get-ProvisionedLocaleIds -BaseUrl $baseUrl)
    $missing = @($RequiredLocaleId | Where-Object { $_ -notin $provisioned })
    $submitted = @()
    foreach ($lcid in $missing) {
        $target = "$baseUrl locale $lcid"
        if ($PSCmdlet.ShouldProcess($target, 'Activate Dataverse language')) {
            Invoke-DataverseRest -Method POST `
                -Url "$baseUrl/api/data/v9.2/ProvisionLanguageAsync" `
                -Body @{ Language = [int]$lcid } | Out-Null
            $submitted += $lcid
        }
    }

    foreach ($lcid in $submitted) {
        Wait-DataverseLanguage -BaseUrl $baseUrl -LocaleId $lcid
    }

    foreach ($lcid in $RequiredLocaleId) {
        Write-Output ([pscustomobject]@{
                Environment = $baseUrl
                LocaleId    = $lcid
                State       = if ($lcid -in $provisioned -or
                    $lcid -in $submitted) { 'Active' } else { 'Planned' }
            })
    }
}

if ($MyInvocation.InvocationName -ne '.') {
    try {
        $baseUrl = $EnvironmentUrl.TrimEnd('/')
        $requiredLocaleIds = Get-NormalizedLocaleIds -LocaleId $LocaleId
        Invoke-DataverseLanguageReconciliation -BaseUrl $baseUrl -RequiredLocaleId $requiredLocaleIds
    }
    catch {
        Write-SafeCliErrorLine -ErrorRecord $_
        exit 1
    }
}
