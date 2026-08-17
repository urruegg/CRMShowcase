<#
.SYNOPSIS
    Resolves the demo presenter identity for a Dataverse environment (Sprint-004).
.DESCRIPTION
    Personalized live demos need seeded records owned by a real, loggable-in
    identity. Rather than committing a personal UPN/e-mail to this (public)
    repository, the presenter is resolved at runtime by role pattern: the
    enabled, interactive (accessmode = 0, i.e. Read-Write) System
    Administrator in the target environment. This deliberately excludes CI
    application users (accessmode = 4, Non-interactive — see ADR-0005) and
    any disabled account.

    When more than one qualifying user is found, resolution is deterministic
    (sorted by fullname, first wins) with a logged warning naming the count,
    so a live-demo operator knows which identity got assigned. An explicit
    -PresenterUserId always wins and skips the Dataverse query entirely.

    Throws when no qualifying user is found, rather than silently seeding
    ownerless demo data or falling back to a non-interactive application
    user — owner assignment is the whole point of this script.

    Live-verified (2026-08-17) against crmshowdev: the sole enabled,
    interactive user is the tenant's own admin@ABSx15847880.onmicrosoft.com
    ("MOD Administrator", accessmode 0, System Administrator + Basic User
    roles); the CI application user "# crm-showcase-ci-dev" is accessmode 4
    and is correctly excluded by this filter.
#>
[CmdletBinding()]
param(
    [string]$EnvironmentUrl,
    [string]$PresenterUserId
)

$ErrorActionPreference = 'Stop'

function Get-DemoPresenterUser {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string]$EnvironmentUrl,
        [string]$PresenterUserId
    )

    if ($PresenterUserId) {
        return $PresenterUserId
    }

    $baseUrl = $EnvironmentUrl.TrimEnd('/')
    $url = "$baseUrl/api/data/v9.2/systemusers?" +
        "`$select=systemuserid,fullname,accessmode&`$filter=isdisabled eq false&" +
        "`$expand=systemuserroles_association(`$select=name)"
    $response = az rest --method GET --url $url --resource "$baseUrl/" --only-show-errors | ConvertFrom-Json

    $admins = @($response.value | Where-Object {
        $_.accessmode -eq 0 -and
        @($_.systemuserroles_association | ForEach-Object { $_.name }) -contains 'System Administrator'
    })

    if ($admins.Count -eq 0) {
        throw "No enabled, interactive System Administrator found in '$EnvironmentUrl'. Refusing to seed ownerless demo data -- pass -PresenterUserId explicitly if this is intentional."
    }
    if ($admins.Count -gt 1) {
        Write-Warning "Get-DemoPresenterUser: $($admins.Count) System Administrators found; using the first alphabetically by fullname."
    }
    $chosen = @($admins | Sort-Object fullname)[0]
    return [string]$chosen.systemuserid
}

if ($MyInvocation.InvocationName -ne '.') {
    if ($EnvironmentUrl) {
        Get-DemoPresenterUser -EnvironmentUrl $EnvironmentUrl -PresenterUserId $PresenterUserId
    }
}
