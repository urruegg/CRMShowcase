<#
.SYNOPSIS
    Seeds the Advisor Cockpit demo scenario into a Dataverse environment.
.DESCRIPTION
    Reads the synthetic fixtures under data/scenarios/advisor-cockpit/ and builds
    idempotent upsert requests keyed by alternate key (materialized-projection
    pattern, ADR-0026). Authentication is acquired at runtime by `az rest`
    (OIDC / CI service principal) — no connection strings.

    The script is safe to dot-source for testing: the top-level parameters are
    non-mandatory and the seed action runs only when the script is invoked
    directly with an -EnvironmentUrl.

    Live execution is DEV-gated: the target tables are authored in DEV by Sprint 3
    Phases 1-3. Until they exist, this script still builds and validates the seed
    plan (Get-SeedPlan) and the analytics upsert requests, which the pipeline seed
    step (Phase 5.3) executes once the tables are present.

    Claims (crmshow_claimprojection) are also mapped to concrete columns, since
    that table's contract is settled and its fields (name/accountid/
    externalsystem/externalid/productline/title/channel/status/openeddate/
    slahours) are plain text/choice/date types with no cross-fixture lookup
    resolution beyond the owning Account. Resolving crmshow_accountid requires
    a caller-supplied -AccountKeyMap (seed key -> Account GUID), because no
    stable, script-resolvable alternate key exists yet on `account` itself
    (accounts-contacts.json's own crmshow_seedkey column is not yet part of
    the contract) -- claim upserts are skipped with a warning if the map is
    not supplied or a referenced account key is missing from it.

    Policies (crmshow_policyprojection) are NOT yet mapped: beyond the same
    account-resolution gap, the table also requires crmshow_policynumber,
    crmshow_lineofbusinesscode, crmshow_effectivefrom and
    crmshow_sourcelastmodifiedon (absent from policies.json today) and a
    crmshow_status GlobalChoice whose numeric option value is not derivable
    from the fixture's free-text German status strings without an explicit
    mapping decision. Left for a follow-up once that mapping is agreed.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$EnvironmentUrl,
    [string]$FixtureRoot,
    [System.Collections.IDictionary]$AccountKeyMap
)

$ErrorActionPreference = 'Stop'

if (-not $FixtureRoot) {
    $FixtureRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../data/scenarios/advisor-cockpit')).Path
}
$script:FixtureRoot = $FixtureRoot

# One entry per fixture file. EntitySet + AlternateKey drive the idempotent
# upsert URL. Non-analytics entity/attribute logical names are provisional until
# the DEV tables land (Phases 1-3); only the measure projection is mapped to
# concrete columns here because its contract already exists (Phase 4).
function Get-FixtureManifest {
    @(
        [pscustomobject]@{ File = 'measures.json'; EntitySet = 'crmshow_measuresnapshots'; AlternateKey = @('crmshow_subject', 'crmshow_metric', 'crmshow_asofdate'); Shape = 'measure' }
        [pscustomobject]@{ File = 'accounts-contacts.json'; EntitySet = 'accounts'; AlternateKey = @('crmshow_seedkey'); Shape = 'accountsContacts' }
        [pscustomobject]@{ File = 'leads.json'; EntitySet = 'leads'; AlternateKey = @('crmshow_seedkey'); Shape = 'record' }
        [pscustomobject]@{ File = 'activities.json'; EntitySet = 'activitypointers'; AlternateKey = @('crmshow_seedkey'); Shape = 'activities' }
        [pscustomobject]@{ File = 'nba.json'; EntitySet = 'crmshow_nextbestactions'; AlternateKey = @('crmshow_seedkey'); Shape = 'nba' }
        [pscustomobject]@{ File = 'policies.json'; EntitySet = 'crmshow_policyprojections'; AlternateKey = @('crmshow_externalsystem', 'crmshow_externalid'); Shape = 'record' }
        [pscustomobject]@{ File = 'claims.json'; EntitySet = 'crmshow_claimprojections'; AlternateKey = @('crmshow_externalsystem', 'crmshow_externalid'); Shape = 'record' }
    )
}

# Returns one upsert group per fixture, each keyed by its alternate key.
function Get-SeedPlan {
    [CmdletBinding()]
    param([string]$FixtureRoot = $script:FixtureRoot)

    $plan = foreach ($m in Get-FixtureManifest) {
        $path = Join-Path $FixtureRoot $m.File
        if (-not (Test-Path -LiteralPath $path)) { throw "Missing fixture: $($m.File)" }
        # WinPS 5.1 ConvertFrom-Json emits a JSON array as a single pipeline object;
        # assign first, then wrap, so a one-element @() does not nest the array.
        $records = (Get-Content -LiteralPath $path -Raw -Encoding UTF8) | ConvertFrom-Json
        $records = @($records)
        if (@($m.AlternateKey).Count -lt 1) { throw "Fixture $($m.File) has no alternate key" }

        [pscustomobject]@{
            Fixture      = $m.File
            EntitySet    = $m.EntitySet
            AlternateKey = $m.AlternateKey
            Shape        = $m.Shape
            Records      = $records
            Count        = @($records).Count
        }
    }
    return @($plan)
}

# Maps one measure-snapshot contract row to its Dataverse column body.
function ConvertTo-MeasureUpsertBody {
    [CmdletBinding()]
    param([Parameter(Mandatory)] $Row)

    $body = [ordered]@{
        crmshow_subject        = [string]$Row.subject
        crmshow_subjecttype    = [string]$Row.subjectType
        crmshow_metric         = [string]$Row.metric
        crmshow_asofdate       = [string]$Row.asOfDate
        crmshow_value          = [double]$Row.value
        crmshow_unit           = [string]$Row.unit
        crmshow_externalsystem = [string]$Row.externalSystem
    }
    if ($null -ne $Row.region) { $body.crmshow_region = [string]$Row.region }
    if ($null -ne $Row.productLine) { $body.crmshow_productline = [string]$Row.productLine }
    return $body
}

# Builds a PATCH-upsert request object against an alternate key. Does not execute.
function New-DataverseUpsertRequest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string]$EntitySet,
        [Parameter(Mandatory)] [System.Collections.IDictionary]$AlternateKey,
        [Parameter(Mandatory)] $Body
    )

    $keySegment = ($AlternateKey.GetEnumerator() | ForEach-Object {
            "{0}='{1}'" -f $_.Key, ([uri]::EscapeDataString([string]$_.Value))
        }) -join ','

    [pscustomobject]@{
        Method = 'PATCH'
        Path   = "/$EntitySet($keySegment)"
        Body   = $Body
    }
}

# Builds the concrete analytics upsert requests (the projection whose contract
# already exists). Other shapes are returned by Get-SeedPlan for execution once
# their DEV tables and field maps land (Phase 5.3).
function Get-MeasureUpsertRequests {
    [CmdletBinding()]
    param([string]$FixtureRoot = $script:FixtureRoot)

    $group = Get-SeedPlan -FixtureRoot $FixtureRoot | Where-Object { $_.Shape -eq 'measure' }
    foreach ($row in $group.Records) {
        $key = [ordered]@{
            crmshow_subject  = [string]$row.subject
            crmshow_metric   = [string]$row.metric
            crmshow_asofdate = [string]$row.asOfDate
        }
        New-DataverseUpsertRequest -EntitySet $group.EntitySet -AlternateKey $key -Body (ConvertTo-MeasureUpsertBody -Row $row)
    }
}

# Maps one claims.json row to its crmshow_claimprojection column body. Requires
# the caller to resolve the row's accountKey to a live Account GUID via
# $AccountKeyMap (seed key -> GUID); throws if the key is missing so a broken
# reference is never silently upserted with a blank required lookup.
function ConvertTo-ClaimUpsertBody {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] $Row,
        [Parameter(Mandatory)] [System.Collections.IDictionary]$AccountKeyMap
    )

    if (-not $AccountKeyMap.Contains([string]$Row.accountKey)) {
        throw "No resolved Account GUID for accountKey '$($Row.accountKey)' (claim '$($Row.externalId)')."
    }
    $accountId = [string]$AccountKeyMap[[string]$Row.accountKey]

    $body = [ordered]@{
        crmshow_name           = [string]$Row.title
        'crmshow_accountid@odata.bind' = "/accounts($accountId)"
        crmshow_externalsystem = [string]$Row.externalSystem
        crmshow_externalid     = [string]$Row.externalId
        crmshow_title          = [string]$Row.title
        crmshow_status         = [string]$Row.status
        crmshow_openeddate     = [string]$Row.openedDate
    }
    if ($null -ne $Row.productLine) { $body.crmshow_productline = [string]$Row.productLine }
    if ($null -ne $Row.channel) { $body.crmshow_channel = [string]$Row.channel }
    if ($null -ne $Row.slaHours) { $body.crmshow_slahours = [int]$Row.slaHours }
    return $body
}

# Builds the concrete claim-projection upsert requests. Returns an empty array
# (with a warning, not a throw) when no AccountKeyMap is supplied, since claim
# seeding is optional until account resolution is wired -- callers that only
# want the analytics projection are unaffected.
function Get-ClaimUpsertRequests {
    [CmdletBinding()]
    param(
        [string]$FixtureRoot = $script:FixtureRoot,
        [System.Collections.IDictionary]$AccountKeyMap
    )

    if (-not $AccountKeyMap -or $AccountKeyMap.Count -eq 0) {
        Write-Warning 'Get-ClaimUpsertRequests: no AccountKeyMap supplied; skipping claim upserts.'
        return @()
    }

    $group = Get-SeedPlan -FixtureRoot $FixtureRoot | Where-Object { $_.Fixture -eq 'claims.json' }
    foreach ($row in $group.Records) {
        $key = [ordered]@{
            crmshow_externalsystem = [string]$row.externalSystem
            crmshow_externalid     = [string]$row.externalId
        }
        New-DataverseUpsertRequest -EntitySet $group.EntitySet -AlternateKey $key -Body (ConvertTo-ClaimUpsertBody -Row $row -AccountKeyMap $AccountKeyMap)
    }
}

function Invoke-AdvisorCockpitSeed {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)] [string]$EnvironmentUrl,
        [System.Collections.IDictionary]$AccountKeyMap
    )

    $baseUrl = $EnvironmentUrl.TrimEnd('/')
    $plan = Get-SeedPlan
    Write-Output ("Seed plan: {0} fixtures, {1} records." -f $plan.Count, (($plan | Measure-Object -Property Count -Sum).Sum))

    $requests = @(Get-MeasureUpsertRequests) + @(Get-ClaimUpsertRequests -AccountKeyMap $AccountKeyMap)
    foreach ($req in $requests) {
        $url = "$baseUrl/api/data/v9.2$($req.Path)"
        if ($PSCmdlet.ShouldProcess($url, $req.Method)) {
            $tmp = [System.IO.Path]::GetTempFileName()
            try {
                ($req.Body | ConvertTo-Json -Depth 6) | Set-Content -LiteralPath $tmp -Encoding UTF8
                az rest --method $req.Method --url $url --resource "$baseUrl/" `
                    --headers 'Content-Type=application/json' 'If-Match=*' `
                    --body "@$tmp" --only-show-errors | Out-Null
            }
            finally {
                Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
            }
        }
    }
    Write-Output ("Upserts issued: {0}." -f $requests.Count)
}

if ($MyInvocation.InvocationName -ne '.') {
    if ($EnvironmentUrl) {
        Invoke-AdvisorCockpitSeed -EnvironmentUrl $EnvironmentUrl -AccountKeyMap $AccountKeyMap
    }
    else {
        $plan = Get-SeedPlan
        $plan | ForEach-Object { Write-Output ("{0,-24} {1,-28} key[{2}] {3} records" -f $_.Fixture, $_.EntitySet, ($_.AlternateKey -join ','), $_.Count) }
        Write-Output 'Dry run — pass -EnvironmentUrl to execute the analytics upserts.'
    }
}
