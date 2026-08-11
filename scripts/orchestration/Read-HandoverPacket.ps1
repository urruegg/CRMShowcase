<#
.SYNOPSIS
    Parse a handover packet markdown file into a structured object.
.PARAMETER Path
    Path to the stream handover packet.
#>
[CmdletBinding()]
param([string]$Path)

function Read-HandoverPacket {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Handover packet not found: $Path"
    }

    $lines = Get-Content -LiteralPath $Path
    function Get-Field($name) {
        $pattern = '^\- \*\*' + [regex]::Escape($name) + ':\*\*\s*(.+?)\s*$'
        foreach ($line in $lines) {
            $m = [regex]::Match($line, $pattern)
            if ($m.Success) { return $m.Groups[1].Value }
        }
        return $null
    }

    $class = Get-Field 'Autonomy class'
    $valid = @('EXECUTION-ONLY', 'DESIGN-SENSITIVE')
    if ($valid -notcontains $class) {
        throw "Invalid or missing autonomy class '$class'. Expected one of: $($valid -join ', ')."
    }

    $issueRaw = Get-Field 'GitHub issue'
    $issue = 0
    if ($issueRaw) { [void][int]::TryParse(($issueRaw -replace '[^0-9]', ''), [ref]$issue) }

    [pscustomobject]@{
        Sprint        = Get-Field 'Sprint'
        Stream        = Get-Field 'Stream'
        Issue         = $issue
        AutonomyClass = $class
        Branch        = Get-Field 'Branch'
        Worktree      = Get-Field 'Worktree'
        DesignRef     = Get-Field 'Approved design ref'
        Path          = (Resolve-Path -LiteralPath $Path).Path
    }
}
