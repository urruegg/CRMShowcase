<#
.SYNOPSIS
    Topologically sort the manifest.solutions array by dependsOn.
    Returns the list of solution objects in the order they must be imported.
#>

function Get-SolutionOrder {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Manifest
    )

    $byName = @{}
    foreach ($s in $Manifest.solutions) { $byName[$s.uniqueName] = $s }

    foreach ($s in $Manifest.solutions) {
        foreach ($dep in $s.dependsOn) {
            if (-not $byName.ContainsKey($dep)) {
                throw "Solution '$($s.uniqueName)' references unknown dependency '$dep'"
            }
        }
    }

    $result  = New-Object System.Collections.Generic.List[object]
    $visited = @{}
    $visiting = @{}

    function Invoke-Visit {
        param([string]$name)
        if ($visited[$name]) { return }
        if ($visiting[$name]) {
            throw "circular dependency detected involving '$name'"
        }
        $visiting[$name] = $true
        foreach ($dep in $byName[$name].dependsOn) {
            Invoke-Visit -name $dep
        }
        $visiting[$name] = $false
        $visited[$name] = $true
        $result.Add($byName[$name]) | Out-Null
    }

    foreach ($s in $Manifest.solutions) {
        Invoke-Visit -name $s.uniqueName
    }

    return ,$result.ToArray()
}