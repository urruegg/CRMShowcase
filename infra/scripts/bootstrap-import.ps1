<#
.SYNOPSIS
    Import existing Power Platform environments into the local Terraform state.

.DESCRIPTION
    Reads terraform.tfvars for environment IDs and issues one `terraform import`
    per environment slot. Idempotent — if a resource is already in state, the
    import is skipped.

.NOTES
    Prerequisites:
      - Terraform >= 1.9
      - az login into the target tenant
      - terraform.tfvars filled in with real environment IDs
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$TerraformDir = (Join-Path $PSScriptRoot '..\terraform')
)

$ErrorActionPreference = 'Stop'
Push-Location $TerraformDir
try {
    # Parse terraform.tfvars for environment IDs (very small parser — only supports the shape in the .example)
    $tfvarsPath = Join-Path $TerraformDir 'terraform.tfvars'
    if (-not (Test-Path $tfvarsPath)) {
        throw "terraform.tfvars not found. Copy terraform.tfvars.example to terraform.tfvars and fill in real values first."
    }
    $tfvars = Get-Content $tfvarsPath -Raw

    $slots = @('dev','test')
    foreach ($slot in $slots) {
        # Grab the id = "..." line inside the block for this slot
        $rx = [regex]::new("(?ms)$slot\s*=\s*\{[^}]*?id\s*=\s*""([^""]+)""")
        $m = $rx.Match($tfvars)
        if (-not $m.Success) { Write-Warning "No id found for slot '$slot' in terraform.tfvars — skipping."; continue }
        $envId = $m.Groups[1].Value
        if ($envId -eq '' -or $envId -eq '00000000-0000-0000-0000-000000000000') {
            Write-Host "Slot '$slot' has no id set (fresh tenant path) — will be created by apply."
            continue
        }

        $addr = "module.powerplatform.powerplatform_environment.this[""$slot""]"
        # Skip if already in state
        $inState = & terraform state list 2>$null | Select-String -Pattern ([regex]::Escape($addr)) -Quiet
        if ($inState) {
            Write-Host "Already in state: $addr — skipping."
            continue
        }

        Write-Host "Importing $addr -> $envId ..."
        & terraform import $addr $envId
        if ($LASTEXITCODE -ne 0) { throw "terraform import failed for slot '$slot'." }
    }

    Write-Host "`nDone. Now review the drift with: terraform plan"
}
finally {
    Pop-Location
}
