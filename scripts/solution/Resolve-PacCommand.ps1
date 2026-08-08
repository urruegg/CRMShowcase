function Resolve-PacCommand {
    [CmdletBinding()]
    param()

    $candidates = @()
    if ($env:POWERPLATFORMTOOLS_PACPATH) {
        $candidates += $env:POWERPLATFORMTOOLS_PACPATH
        $candidates += Join-Path $env:POWERPLATFORMTOOLS_PACPATH 'pac'
        $candidates += Join-Path $env:POWERPLATFORMTOOLS_PACPATH 'pac.exe'
    }
    $candidates += Join-Path $HOME '.dotnet\tools\pac.exe'
    $candidates += Join-Path $HOME '.dotnet/tools/pac'

    foreach ($candidate in $candidates | Select-Object -Unique) {
        if ($candidate -and (Test-Path $candidate -PathType Leaf)) {
            return (Resolve-Path $candidate).Path
        }
    }

    $command = Get-Command pac -ErrorAction SilentlyContinue
    if ($command) {
        return $command.Source
    }

    throw "pac CLI not found. Install Microsoft.PowerApps.CLI.Tool 1.43.6 or run the Power Platform actions installer."
}
