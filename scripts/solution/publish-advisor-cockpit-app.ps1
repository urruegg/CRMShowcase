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

if ($MyInvocation.InvocationName -ne '.') {
    if ($EnvironmentUrl) {
        Write-Output 'Dry run scaffold -- publish orchestration lands in a later task.'
    }
    else {
        $contract = Get-AdvisorCockpitAppContract -Path $script:ContractPath
        Write-Output ("Contract loaded: app '{0}', {1} components, {2} security role(s)." -f $contract.appModule.name, @($contract.components).Count, @($contract.securityRoles).Count)
    }
}
