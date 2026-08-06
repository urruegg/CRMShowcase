<#
.SYNOPSIS
    Compute a new Dataverse-format version string (MAJOR.MINOR.PATCH.BUILD).
.DESCRIPTION
    Bumps one component of a four-part Dataverse version string and stamps the build
    number from CI. Semantics:
      major -> MAJOR+1, MINOR=0, PATCH=0
      minor -> MINOR+1, PATCH=0
      patch -> PATCH+1
      build -> unchanged MAJOR.MINOR.PATCH
    The BUILD segment is always replaced by the -Build argument (typically the CI run number).
#>

function Bump-Version {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string]$Current,
        [Parameter(Mandatory)] [ValidateSet('major','minor','patch','build')] [string]$Kind,
        [Parameter(Mandatory)] [int]$Build
    )

    if ($Current -notmatch '^\d+\.\d+\.\d+\.\d+$') {
        throw "Current version '$Current' is not in MAJOR.MINOR.PATCH.BUILD format"
    }
    if ($Build -lt 0) { throw "Build must be >= 0" }

    $parts = $Current.Split('.') | ForEach-Object { [int]$_ }
    $maj, $min, $pat = $parts[0], $parts[1], $parts[2]

    switch ($Kind) {
        'major' { $maj++; $min = 0; $pat = 0 }
        'minor' { $min++; $pat = 0 }
        'patch' { $pat++ }
        'build' { }
    }

    return "$maj.$min.$pat.$Build"
}