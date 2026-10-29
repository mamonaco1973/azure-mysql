
# ==============================================================================
# File: apply.ps1
# Purpose: Validate prerequisites, deploy MySQL Terraform stack,
#          and run post-deployment validation.
# ==============================================================================

$ErrorActionPreference = "Stop"

# ==============================================================================
# STEP 0: Validate environment prerequisites
# ==============================================================================
Write-Host "STEP 0: Validating environment prerequisites..."

& "$PSScriptRoot\check_env.ps1"

if ($LASTEXITCODE -ne 0) {
    throw "Environment validation failed."
}

# ==============================================================================
# STEP 1: Provision MySQL infrastructure
# ==============================================================================
Write-Host "`nSTEP 1: Provisioning MySQL infrastructure..."

Push-Location "$PSScriptRoot\01-mysql"

try {
    terraform init

    if ($LASTEXITCODE -ne 0) {
        throw "Terraform init failed."
    }

    terraform apply -auto-approve

    if ($LASTEXITCODE -ne 0) {
        throw "Terraform apply failed."
    }
}
finally {
    Pop-Location
}

# ==============================================================================
# STEP 2: Run post-deployment validation
# ==============================================================================
Write-Host "`nSTEP 2: Running post-deployment validation..."

& "$PSScriptRoot\validate.ps1"

if ($LASTEXITCODE -ne 0) {
    throw "Post-deployment validation failed."
}

Write-Host "`nDeployment and validation completed successfully." `
    -ForegroundColor Green

# ==============================================================================
# END
# ==============================================================================
