<#
.SYNOPSIS
    Dispatch a sprint stream to GitHub Copilot CLI according to its autonomy class.
.DESCRIPTION
    EXECUTION-ONLY packets build a headless autopilot command with a
    git push / rm / git reset deny-list. DESIGN-SENSITIVE packets are never
    launched headless; the function returns an attended launch plan instead.
#>
[CmdletBinding()]
param(
    [string]$PacketPath,
    [switch]$Headless,
    [switch]$DryRun
)

function Invoke-StreamDelegation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string]$PacketPath,
        [switch]$Headless,
        [switch]$DryRun
    )

    . "$PSScriptRoot/Read-HandoverPacket.ps1"
    $packet = Read-HandoverPacket -Path $PacketPath

    if ($packet.AutonomyClass -eq 'DESIGN-SENSITIVE') {
        if ($Headless) {
            throw "Refusing to launch DESIGN-SENSITIVE stream '$($packet.Stream)' headless. Design must be human-reviewed."
        }
        $attended = "copilot   # interactive; press Shift+Tab for plan mode, then paste: $($packet.Path)"
        $result = [pscustomobject]@{
            Mode    = 'Attended'
            Command = $attended
            Packet  = $packet
        }
        if (-not $DryRun) { Write-Host $attended }
        return $result
    }

    # EXECUTION-ONLY -> headless autopilot with deny-list
    $denies = @("--deny-tool='shell(git push)'", "--deny-tool='shell(rm)'", "--deny-tool='shell(git reset)'")
    $command = "copilot -p `"@$($packet.Path)`" --allow-all-tools $($denies -join ' ') --add-dir `"$($packet.Worktree)`""
    $result = [pscustomobject]@{
        Mode    = 'Headless'
        Command = $command
        Packet  = $packet
    }
    if (-not $DryRun) {
        Push-Location -LiteralPath $packet.Worktree
        try { Invoke-Expression $command } finally { Pop-Location }
    }
    return $result
}

if ($MyInvocation.InvocationName -ne '.') {
    Invoke-StreamDelegation @PSBoundParameters
}
