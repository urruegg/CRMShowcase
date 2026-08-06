<#
.SYNOPSIS
    Add the two CI service principals as Dataverse application users with a security role.

.DESCRIPTION
    Idempotent bootstrap. For each entry, creates a systemuser record with the SP's
    applicationid field (that is how Dataverse recognises app users) and assigns the
    given security role. Skips creation if the app user already exists.

    This is the workaround for the microsoft/power-platform Terraform provider's
    `powerplatform_user` resource which does not support creating service-principal
    application users (returns 404 on first apply). See ADR-0005.

.NOTES
    Prerequisites
      - az login into the target tenant with a Global / Power Platform Admin identity.
      - The service principals must already exist (created by terraform apply).

    Idempotency
      - If a systemuser with the given applicationid already exists in the env,
        creation is skipped. Role assignment is applied idempotently.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet('dev', 'test', 'all')]
    [string]$Slot = 'all'
)

$ErrorActionPreference = 'Stop'

# Map: slot -> (env url, sp display name, role name).
# Role IDs are looked up per-env at run time from the Dataverse Web API.
$assignments = @(
    @{ Slot = 'dev';  EnvUrl = 'https://crmshowdev.crm.dynamics.com';  SpDisplayName = 'crm-showcase-ci-dev';  RoleName = 'System Customizer' }
    @{ Slot = 'test'; EnvUrl = 'https://crmshowtest.crm.dynamics.com'; SpDisplayName = 'crm-showcase-ci-test'; RoleName = 'System Administrator' }
)

if ($Slot -ne 'all') {
    $assignments = $assignments | Where-Object { $_.Slot -eq $Slot }
}

foreach ($a in $assignments) {
    Write-Host "`n=== Slot '$($a.Slot)' -> $($a.EnvUrl) ==="
    $envRes = $a.EnvUrl + '/'

    $sp = az ad sp list --display-name $a.SpDisplayName --output json --only-show-errors | ConvertFrom-Json
    if (-not $sp -or $sp.Count -eq 0) { throw "Service principal '$($a.SpDisplayName)' not found." }
    $appId = $sp[0].appId
    $spObjectId = $sp[0].id
    Write-Host ("  SP appId={0}  objectId={1}" -f $appId, $spObjectId)

    $existing = az rest --method GET --url "$($a.EnvUrl)/api/data/v9.2/systemusers?%24filter=applicationid eq $appId&%24select=systemuserid,fullname" --resource $envRes --only-show-errors | ConvertFrom-Json
    if ($existing.value.Count -gt 0) {
        $userId = $existing.value[0].systemuserid
        Write-Host "  App user already exists: $userId"
    } else {
        $buResp = az rest --method GET --url "$($a.EnvUrl)/api/data/v9.2/businessunits?%24filter=_parentbusinessunitid_value eq null&%24select=businessunitid,name" --resource $envRes --only-show-errors | ConvertFrom-Json
        $rootBuId = $buResp.value[0].businessunitid
        Write-Host ("  Root BU id: {0}" -f $rootBuId)

        $bodyObj = @{
            applicationid                              = $appId
            azureactivedirectoryobjectid               = $spObjectId
            'businessunitid@odata.bind'                = "/businessunits($rootBuId)"
        }
        $bodyFile = New-TemporaryFile
        ($bodyObj | ConvertTo-Json) | Set-Content -Path $bodyFile -Encoding utf8

        Write-Host "  Creating app user..."
        $createResp = az rest --method POST --url "$($a.EnvUrl)/api/data/v9.2/systemusers?%24select=systemuserid" --resource $envRes --body "@$bodyFile" --headers 'Content-Type=application/json' 'Prefer=return=representation' --only-show-errors | ConvertFrom-Json
        Remove-Item $bodyFile -Force
        $userId = $createResp.systemuserid
        Write-Host "  Created systemuser: $userId"
    }

    $rolesResp = az rest --method GET --url "$($a.EnvUrl)/api/data/v9.2/roles?%24filter=name eq '$($a.RoleName)'&%24select=roleid" --resource $envRes --only-show-errors | ConvertFrom-Json
    if ($rolesResp.value.Count -eq 0) { throw "Role '$($a.RoleName)' not found in env $($a.EnvUrl)." }
    $roleId = $rolesResp.value[0].roleid
    Write-Host ("  Role '{0}' id: {1}" -f $a.RoleName, $roleId)

    $existingRolesResp = az rest --method GET --url "$($a.EnvUrl)/api/data/v9.2/systemusers%28$userId%29/systemuserroles_association?%24select=roleid" --resource $envRes --only-show-errors | ConvertFrom-Json
    $hasRole = $existingRolesResp.value | Where-Object { $_.roleid -eq $roleId }
    if ($hasRole) {
        Write-Host "  Role already assigned."
    } else {
        $refBody = @{ '@odata.id' = "$($a.EnvUrl)/api/data/v9.2/roles($roleId)" }
        $refFile = New-TemporaryFile
        ($refBody | ConvertTo-Json) | Set-Content -Path $refFile -Encoding utf8
        Write-Host "  Assigning role..."
        az rest --method POST --url "$($a.EnvUrl)/api/data/v9.2/systemusers%28$userId%29/systemuserroles_association/%24ref" --resource $envRes --body "@$refFile" --headers 'Content-Type=application/json' --only-show-errors | Out-Null
        Remove-Item $refFile -Force
        Write-Host "  Role assigned."
    }
}

Write-Host "`nDone."
