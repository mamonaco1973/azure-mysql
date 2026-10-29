
# ==============================================================================
# File: destroy.ps1
# Purpose: Destroy the MySQL Terraform stack and associated Azure resources.
# ==============================================================================

$ErrorActionPreference = "Stop"

# ==============================================================================
# STEP 1: Destroy MySQL infrastructure
# ==============================================================================
Write-Host "NOTE: Initializing Terraform in 01-mysql..."

Push-Location "$PSScriptRoot\01-mysql"

try {
    terraform init

    if ($LASTEXITCODE -ne 0) {
        throw "ERROR: Terraform initialization failed."
    }

    Write-Host "`nWARNING: Destroying MySQL infrastructure in Azure..." `
        -ForegroundColor Yellow

    terraform destroy -auto-approve

    if ($LASTEXITCODE -ne 0) {
        throw "ERROR: Terraform destroy failed."
    }

    Write-Host "`nNOTE: MySQL infrastructure destroyed successfully." `
        -ForegroundColor Green
}
finally {
    Pop-Location
}

# ==============================================================================
# END
# ==============================================================================
