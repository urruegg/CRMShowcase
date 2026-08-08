<#
.SYNOPSIS
    Classify a solution-component diff as major | minor | patch.
.DESCRIPTION
    Analyses a unified-diff of an unpacked Dataverse solution (typically the output of
    `git diff` over the folder produced by `pac solution unpack`) and returns the
    recommended semver bump kind.

    Rules (evaluated in priority order):
      1. If any diff line removes a structural component
         (entity | attribute | relationship | optionvalue) it is 'major' (breaking).
      2. Otherwise, if any diff line adds a structural component it is 'minor' (additive).
      3. Otherwise it is 'patch' (labels, descriptions, whitespace, ordering).

    The classifier deliberately ignores diff *headers* (`--- a/...`, `+++ b/...`) and
    hunk markers (`@@`) so that additions/removals inside those lines do not skew
    the classification.

    NOTE: This is a coarse first-pass classifier intended to prompt reviewer attention,
    not a definitive Dataverse compatibility check. Reviewers may still override the
    recommendation.
#>

function Test-BreakingChange {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [AllowEmptyString()] [string]$Diff
    )

    # Structural component tokens we consider semantically significant.
    # Matched case-insensitively against the diff line body (after the +/- prefix).
    $structuralPattern = '<(entity|attribute|relationship|optionvalue)\b'

    $hasRemoval = $false
    $hasAddition = $false

    foreach ($line in ($Diff -split "`r?`n")) {
        # Skip diff metadata / hunk headers so their leading -/+ tokens are not mistaken
        # for component changes.
        if ($line -match '^(---|\+\+\+|@@)') { continue }

        if ($line.Length -eq 0) { continue }

        $prefix = $line[0]
        if ($prefix -ne '+' -and $prefix -ne '-') { continue }

        $body = $line.Substring(1)
        if ($body -notmatch $structuralPattern) { continue }

        if ($prefix -eq '-') { $hasRemoval  = $true }
        else                 { $hasAddition = $true }
    }

    if ($hasRemoval)  { return 'major' }
    if ($hasAddition) { return 'minor' }
    return 'patch'
}
