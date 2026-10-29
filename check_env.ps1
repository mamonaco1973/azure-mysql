
# ==============================================================================
# File: check_env.ps1
# Purpose: Validate tools, environment variables, and Azure authentication
# ==============================================================================

Write-Host "NOTE: Validating required commands in PATH."

# Required commands
$commands = @("az", "terraform", "jq")
$allFound = $true

foreach ($cmd in $commands) {
    if (Get-Command $cmd -ErrorAction SilentlyContinue) {
        Write-Host "NOTE: $cmd is found in PATH."
    }
    else {
        Write-Host "ERROR: $cmd is not found in PATH." -ForegroundColor Red
        $allFound = $false
    }
}

if (-not $allFound) {
    Write-Host "ERROR: One or more required commands are missing."
    exit 1
}

Write-Host "NOTE: All required commands are available."
Write-Host "`nNOTE: Validating environment variables."

# Required Azure Service Principal variables
$requiredVars = @(
    "ARM_CLIENT_ID",
    "ARM_CLIENT_SECRET",
    "ARM_SUBSCRIPTION_ID",
    "ARM_TENANT_ID"
)

$allSet = $true

foreach ($var in $requiredVars) {
    $value = [Environment]::GetEnvironmentVariable($var)

    if ([string]::IsNullOrWhiteSpace($value)) {
        Write-Host "ERROR: $var is not set or is empty." -ForegroundColor Red
        $allSet = $false
    }
    else {
        Write-Host "NOTE: $var is set."
    }
}

if (-not $allSet) {
    Write-Host "ERROR: Required environment variables are missing."
    exit 1
}

Write-Host "`nNOTE: Logging in to Azure using Service Principal..."

az login `
    --service-principal `
    --username $env:ARM_CLIENT_ID `
    --password $env:ARM_CLIENT_SECRET `
    --tenant $env:ARM_TENANT_ID `
    --output none

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to log in to Azure." -ForegroundColor Red
    Write-Host "Check Service Principal credentials and permissions."
    exit 1
}

Write-Host "NOTE: Successfully logged into Azure." -ForegroundColor Green

# Set the intended subscription
az account set --subscription $env:ARM_SUBSCRIPTION_ID

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to select Azure subscription."
    exit 1
}

Write-Host "NOTE: Azure subscription selected successfully."
