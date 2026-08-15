<#
.SYNOPSIS
    Authors the Advisor Cockpit Model-Driven App into a Dataverse environment.
.DESCRIPTION
    Reads solution/schema/advisor-cockpit-app.json and idempotently reconciles
    the sitemap, app module, component attachments and security-role
    association via the Dataverse Web API (az rest). Authentication is
    acquired at runtime by `az rest` -- no connection strings.

    The two custom pages this app hosts (crmshow_advisorcockpitpage,
    crmshow_salesleaderdashboardpage) must already exist -- their canvas
    content has no Web API/CLI authoring path (Maker Portal only, confirmed
    Sprint 3). This script resolves them by uniquename via a live query
    (Get-CustomPageIdMap), the same idiom already used for account
    resolution in seed-advisor-cockpit.ps1.

    Safe to dot-source for testing: the top-level parameters are
    non-mandatory and the publish action runs only when the script is
    invoked directly with an -EnvironmentUrl.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$EnvironmentUrl,
    [string]$ContractPath
)

$ErrorActionPreference = 'Stop'

if (-not $ContractPath) {
    $ContractPath = (Resolve-Path (Join-Path $PSScriptRoot '../../solution/schema/advisor-cockpit-app.json')).Path
}
$script:ContractPath = $ContractPath

# Loads the contract and throws a clear error naming the missing key, rather
# than a generic PowerShell null-reference failure deeper in the script.
function Get-AdvisorCockpitAppContract {
    [CmdletBinding()]
    param([Parameter(Mandatory)] [string]$Path)

    $contract = (Get-Content -LiteralPath $Path -Raw -Encoding UTF8) | ConvertFrom-Json
    foreach ($required in @('sitemap', 'appModule', 'components', 'securityRoles')) {
        if (-not $contract.PSObject.Properties.Name.Contains($required)) {
            throw "Advisor Cockpit app contract is missing required key '$required'."
        }
    }
    return $contract
}

# Maps the contract's sitemap section to a sitemap upsert body, generating
# the raw Site Map XML from the structured areas/groups/subAreas -- so the
# XML itself is never hand-maintained as a giant string in the contract.
function ConvertTo-SitemapUpsertBody {
    [CmdletBinding()]
    param([Parameter(Mandatory)] $Sitemap)

    $areasXml = foreach ($area in @($Sitemap.areas)) {
        $groupsXml = foreach ($group in @($area.groups)) {
            $subAreasXml = foreach ($sub in @($group.subAreas)) {
                $subId = [System.Security.SecurityElement]::Escape([string]$sub.id)
                $subTitle = [System.Security.SecurityElement]::Escape([string]$sub.title)
                $subPageUniqueName = [System.Security.SecurityElement]::Escape([string]$sub.pageUniqueName)
                "<SubArea Id=`"$subId`" Title=`"$subTitle`" Url=`"/main.aspx?pagetype=custom&amp;name=$subPageUniqueName`" />"
            }
            $groupId = [System.Security.SecurityElement]::Escape([string]$group.id)
            $groupTitle = [System.Security.SecurityElement]::Escape([string]$group.title)
            "<Group Id=`"$groupId`" Title=`"$groupTitle`">$($subAreasXml -join '')</Group>"
        }
        $areaId = [System.Security.SecurityElement]::Escape([string]$area.id)
        $areaTitle = [System.Security.SecurityElement]::Escape([string]$area.title)
        "<Area Id=`"$areaId`" Title=`"$areaTitle`">$($groupsXml -join '')</Area>"
    }
    $sitemapXml = "<SiteMap>$($areasXml -join '')</SiteMap>"

    [ordered]@{
        sitemapname             = [string]$Sitemap.name
        sitemapnameunique       = [string]$Sitemap.uniqueName
        sitemapxml              = $sitemapXml
        isappaware              = [bool]$Sitemap.isAppAware
        showhome                = [bool]$Sitemap.showHome
        showpinned              = [bool]$Sitemap.showPinned
        showrecents             = [bool]$Sitemap.showRecents
        enablecollapsiblegroups = [bool]$Sitemap.enableCollapsibleGroups
    }
}

# Maps the contract's appModule section to an appmodule upsert body.
# PublisherId is resolved by the caller (a live lookup, not part of the
# contract) since the publisher already exists for every other solution
# component in this repo -- see Get-PublisherId.
function ConvertTo-AppModuleUpsertBody {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] $AppModule,
        [Parameter(Mandatory)] [string]$PublisherId
    )

    [ordered]@{
        name                        = [string]$AppModule.name
        uniquename                  = [string]$AppModule.uniqueName
        description                 = [string]$AppModule.description
        clienttype                  = [int]$AppModule.clientType
        formfactor                  = [int]$AppModule.formFactor
        navigationtype              = [int]$AppModule.navigationType
        'publisherid@odata.bind'    = "/publishers($PublisherId)"
    }
}

# Confirmed appmodulecomponent.componenttype values (Microsoft Learn,
# fetched 2026-08-15). CustomPage's value is filled in from Task 1's
# empirical finding -- update the number below once confirmed; every other
# value here is already documentation-confirmed.
$script:ComponentTypeValues = @{
    Entities = 1
    Views    = 26
    Forms    = 60
    Sitemap  = 62
    CustomPage = -1  # <CONFIRM-IN-TASK-1> -- replace -1 with the real value.
}

function ConvertTo-ComponentTypeValue {
    [CmdletBinding()]
    param([Parameter(Mandatory)] [string]$Type)

    if (-not $script:ComponentTypeValues.ContainsKey($Type)) {
        throw "Unknown component type '$Type'. Known types: $($script:ComponentTypeValues.Keys -join ',')."
    }
    return $script:ComponentTypeValues[$Type]
}

# Resolves each of the given custom-page uniquenames to its live canvasapp
# GUID. Throws immediately naming the missing page rather than silently
# building an incomplete map -- a missing custom page means the Maker
# Portal step (Task 1 Step 3 / design doc) has not happened yet for that
# page, which the caller needs to know about explicitly.
function Get-CustomPageIdMap {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string]$EnvironmentUrl,
        [Parameter(Mandatory)] [string[]]$PageUniqueNames
    )

    $baseUrl = $EnvironmentUrl.TrimEnd('/')
    $filter = ($PageUniqueNames | ForEach-Object { "name eq '$_'" }) -join ' or '
    $url = "$baseUrl/api/data/v9.2/canvasapps?`$select=canvasappid,name&`$filter=$filter"
    $response = az rest --method GET --url $url --resource "$baseUrl/" --only-show-errors | ConvertFrom-Json

    $map = [ordered]@{}
    foreach ($page in @($response.value)) {
        $map[[string]$page.name] = [string]$page.canvasappid
    }
    foreach ($expected in $PageUniqueNames) {
        if (-not $map.Contains($expected)) {
            throw "Custom page '$expected' does not exist yet in $EnvironmentUrl -- create it in the Maker Portal first (see the design doc's Approach A)."
        }
    }
    return $map
}

# Maps a contract component to its @odata.type + id property name, since
# the AddAppComponents payload shape differs per entity type.
function Get-ComponentODataEntity {
    [CmdletBinding()]
    param([Parameter(Mandatory)] [string]$Type)

    switch ($Type) {
        'Sitemap'    { return @{ ODataType = 'Microsoft.Dynamics.CRM.sitemap'; IdProperty = 'sitemapid' } }
        'CustomPage' { return @{ ODataType = 'Microsoft.Dynamics.CRM.canvasapp'; IdProperty = 'canvasappid' } }
        default      { throw "No AddAppComponents entity mapping for component type '$Type'." }
    }
}

# Builds the AddAppComponents request body for every contract component not
# already present in $ExistingObjectIds (idempotent -- re-running this after
# a partial success only adds what's missing). Returns $null when there is
# nothing left to add, so the caller can skip the Web API call entirely.
function Get-AppComponentAddRequests {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] $Components,
        [Parameter(Mandatory)] [System.Collections.IDictionary]$ResolvedIds,
        [string[]]$ExistingObjectIds = @(),
        [Parameter(Mandatory)] [string]$AppId
    )

    $entries = foreach ($component in @($Components)) {
        $resolvedId = $ResolvedIds[[string]$component.reference]
        if (-not $resolvedId) {
            throw "No resolved id for component reference '$($component.reference)' (referenceKind '$($component.referenceKind)')."
        }
        if ($ExistingObjectIds -contains $resolvedId) {
            continue
        }
        $entity = Get-ComponentODataEntity -Type $component.type
        [ordered]@{
            '@odata.type'    = $entity.ODataType
            $entity.IdProperty = $resolvedId
        }
    }

    if (@($entries).Count -eq 0) {
        return $null
    }

    [pscustomobject]@{
        AppId      = $AppId
        Components = @($entries)
    }
}

# Builds one $ref associate request per contract security role not already
# associated with the app. Uses the appmoduleroles_association navigation
# property directly (POST .../$ref), the standard Web API pattern for
# adding one member to an existing many-to-many relationship.
function Get-AppRoleAssociationRequests {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string[]]$SecurityRoles,
        [Parameter(Mandatory)] [System.Collections.IDictionary]$RoleIds,
        [string[]]$ExistingRoleIds = @(),
        [Parameter(Mandatory)] [string]$AppId
    )

    foreach ($roleName in $SecurityRoles) {
        if (-not $RoleIds.Contains($roleName)) {
            throw "No resolved role id for security role '$roleName'."
        }
        $roleId = $RoleIds[$roleName]
        if ($ExistingRoleIds -contains $roleId) {
            continue
        }
        [pscustomobject]@{
            Method = 'POST'
            Path   = "/appmodules($AppId)/appmoduleroles_association/`$ref"
            Body   = @{ '@odata.id' = "roles($roleId)" }
        }
    }
}

if ($MyInvocation.InvocationName -ne '.') {
    if ($EnvironmentUrl) {
        Write-Output 'Dry run scaffold -- publish orchestration lands in a later task.'
    }
    else {
        $contract = Get-AdvisorCockpitAppContract -Path $script:ContractPath
        Write-Output ("Contract loaded: app '{0}', {1} components, {2} security role(s)." -f $contract.appModule.name, @($contract.components).Count, @($contract.securityRoles).Count)
    }
}
