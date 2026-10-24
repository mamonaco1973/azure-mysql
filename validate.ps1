
# ==============================================================================
# FILE: validate.ps1
# Purpose:
#   Resolve and print the phpMyAdmin URL and MySQL Flexible Server endpoint.
#   Wait for phpMyAdmin to become reachable before returning success.
# ==============================================================================

$ErrorActionPreference = "Stop"

# ==============================================================================
# CONFIGURATION
# ==============================================================================
$RESOURCE_GROUP_NAME = "mysql-rg"
$PHPMYADMIN_PUBLIC_IP_NAME = "phpmyadmin-vm-public-ip"
$PHPMYADMIN_PATH = "/"
$MYSQL_NAME_PREFIX = "mysql-instance"

$MAX_ATTEMPTS = 30
$SLEEP_SECONDS = 30

# ==============================================================================
# RESOLVE PHPMYADMIN PUBLIC DNS
# ==============================================================================
Write-Host "NOTE: Resolving phpMyAdmin public FQDN..."

$PHPMYADMIN_FQDN = az network public-ip show `
    --resource-group $RESOURCE_GROUP_NAME `
    --name $PHPMYADMIN_PUBLIC_IP_NAME `
    --query "dnsSettings.fqdn" `
    --output tsv

if ($LASTEXITCODE -ne 0 -or
    [string]::IsNullOrWhiteSpace($PHPMYADMIN_FQDN) -or
    $PHPMYADMIN_FQDN.Trim() -eq "None") {

    Write-Host "ERROR: Could not resolve phpMyAdmin public FQDN."
    Write-Host "ERROR: Ensure Public IP '$PHPMYADMIN_PUBLIC_IP_NAME' exists."
    exit 1
}

$PHPMYADMIN_FQDN = $PHPMYADMIN_FQDN.Trim()
$PHPMYADMIN_URL = "http://${PHPMYADMIN_FQDN}${PHPMYADMIN_PATH}"

# ==============================================================================
# WAIT FOR PHPMYADMIN TO BECOME REACHABLE
# ==============================================================================
Write-Host "`nNOTE: Waiting for phpMyAdmin to become available:"
Write-Host "NOTE:   $PHPMYADMIN_URL"

$attempt = 1
$reachable = $false

while ($attempt -le $MAX_ATTEMPTS) {

    # Invoke-WebRequest can throw on HTTP errors, so catch them and retry.
    try {
        $response = Invoke-WebRequest `
            -Uri $PHPMYADMIN_URL `
            -Method Head `
            -TimeoutSec 15 `
            -UseBasicParsing `
            -ErrorAction Stop

        if ($response.StatusCode -ge 200 -and
            $response.StatusCode -lt 400) {
            $reachable = $true
            break
        }
    }
    catch {
        # Endpoint is not ready yet; retry below.
    }

    if ($attempt -ge $MAX_ATTEMPTS) {
        break
    }

    Write-Host "NOTE: phpMyAdmin not reachable yet. Retry $attempt/$MAX_ATTEMPTS."
    Start-Sleep -Seconds $SLEEP_SECONDS
    $attempt++
}

if (-not $reachable) {
    Write-Host "ERROR: phpMyAdmin did not become available after $MAX_ATTEMPTS attempts."
    Write-Host "ERROR: Last checked URL: $PHPMYADMIN_URL"
    exit 1
}

Write-Host "NOTE: phpMyAdmin is reachable."

# ==============================================================================
# RESOLVE MYSQL FLEXIBLE SERVER ENDPOINT
# ==============================================================================
Write-Host "`nNOTE: Resolving MySQL Flexible Server endpoint..."

$MYSQL_FQDN = az mysql flexible-server list `
    --resource-group $RESOURCE_GROUP_NAME `
    --query "[?starts_with(name, '$MYSQL_NAME_PREFIX')].fullyQualifiedDomainName" `
    --output tsv

if ($LASTEXITCODE -ne 0 -or
    [string]::IsNullOrWhiteSpace($MYSQL_FQDN) -or
    $MYSQL_FQDN.Trim() -eq "None") {

    Write-Host "ERROR: Could not resolve MySQL Flexible Server endpoint."
    Write-Host "ERROR: No server found with prefix '$MYSQL_NAME_PREFIX'."
    exit 1
}

$MYSQL_FQDN = $MYSQL_FQDN.Trim()

# ==============================================================================
# OUTPUT SUMMARY
# ==============================================================================
Write-Host "`n==============================================================================="
Write-Host "BUILD VALIDATION RESULTS"
Write-Host "==============================================================================="
Write-Host "phpMyAdmin URL:"
Write-Host "  $PHPMYADMIN_URL"
Write-Host ""
Write-Host "MySQL Flexible Server Endpoint:"
Write-Host "  $MYSQL_FQDN"
Write-Host "==============================================================================="
