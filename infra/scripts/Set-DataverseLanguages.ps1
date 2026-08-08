<#
.SYNOPSIS
    Reconcile the supported Dataverse languages for an environment.

.DESCRIPTION
    Reads LanguageLocale records and activates requested inactive languages.
    Authentication is delegated to az rest, which acquires a runtime token for
    the Dataverse environment. Languages are never deactivated.
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^https://[a-z0-9-]+\.crm(?:\d+)?\.dynamics\.com/?$')]
    [string]$EnvironmentUrl,

    [Parameter(Mandatory)]
    [int[]]$LocaleId
)

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

function Get-LanguageTransition {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [int]$LocaleId,

        [Parameter(Mandatory)]
        [int]$StateCode
    )

    if ($StateCode -eq 0) {
        return 'Unchanged'
    }
    if ($StateCode -eq 1) {
        return 'Activate'
    }

    throw "Unexpected statecode '$StateCode' for locale '$LocaleId'."
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
        $url = "$($BaseUrl.TrimEnd('/'))/api/data/v9.2/languagelocale?`$select=localeid,statecode&`$filter=localeid eq $LocaleId"
        $response = Invoke-DataverseRest -Method GET -Url $url
        if ($response.value.Count -eq 1 -and [int]$response.value[0].statecode -eq 0) {
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
        [ValidateSet('GET', 'PATCH')]
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

        $result = & az @arguments
        if ($LASTEXITCODE -ne 0) {
            throw "Dataverse request failed: $Method $Url."
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

if ($MyInvocation.InvocationName -ne '.') {
    $baseUrl = $EnvironmentUrl.TrimEnd('/')
    $requiredLocaleIds = Get-NormalizedLocaleIds -LocaleId $LocaleId

    foreach ($lcid in $requiredLocaleIds) {
        $queryUrl = "$baseUrl/api/data/v9.2/languagelocale?`$select=languagelocaleid,localeid,statecode,statuscode&`$filter=localeid eq $lcid"
        $response = Invoke-DataverseRest -Method GET -Url $queryUrl
        if ($response.value.Count -ne 1) {
            throw "Locale '$lcid' is unavailable in '$baseUrl'; expected exactly one LanguageLocale record."
        }

        $language = $response.value[0]
        $transition = Get-LanguageTransition -LocaleId $lcid -StateCode ([int]$language.statecode)
        $shouldVerify = $true
        if ($transition -eq 'Activate') {
            $target = "$baseUrl locale $lcid"
            if ($PSCmdlet.ShouldProcess($target, 'Activate Dataverse language')) {
                $patchUrl = "$baseUrl/api/data/v9.2/languagelocale($($language.languagelocaleid))"
                Invoke-DataverseRest -Method PATCH -Url $patchUrl -Body @{
                    statecode  = 0
                    statuscode = 1
                } | Out-Null
            }
            else {
                $shouldVerify = $false
            }
        }

        if ($shouldVerify) {
            Wait-DataverseLanguage -BaseUrl $baseUrl -LocaleId $lcid
            Write-Output ([pscustomobject]@{
                    Environment = $baseUrl
                    LocaleId    = $lcid
                    State       = 'Active'
                })
        }
    }
}
