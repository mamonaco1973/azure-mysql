#!/bin/bash
# ===============================================================================
# FILE: validate.sh
# ===============================================================================
# Resolves and prints the phpMyAdmin endpoint and the MySQL Flexible Server
# endpoint. Also waits for phpMyAdmin to become reachable before returning
# success.
#
# OUTPUT (SUMMARY):
#   - phpMyAdmin URL
#   - MySQL Flexible Server hostname
# ===============================================================================

# Enable strict shell behavior:
#   -e  Exit immediately on error
#   -u  Treat unset variables as errors
#   -o pipefail  Fail pipelines if any command fails
set -euo pipefail


# ===============================================================================
# CONFIGURATION
# ===============================================================================
RESOURCE_GROUP_NAME="mysql-rg"
PHPMYADMIN_PUBLIC_IP_NAME="phpmyadmin-vm-public-ip"
PHPMYADMIN_PATH="/"
MYSQL_NAME_PREFIX="mysql-instance"

MAX_ATTEMPTS=30
SLEEP_SECONDS=30


# ===============================================================================
# RESOLVE PHPMYADMIN PUBLIC DNS
# ===============================================================================
PHPMYADMIN_FQDN="$(az network public-ip show \
  --resource-group "${RESOURCE_GROUP_NAME}" \
  --name "${PHPMYADMIN_PUBLIC_IP_NAME}" \
  --query "dnsSettings.fqdn" \
  --output tsv)"

if [ -z "${PHPMYADMIN_FQDN}" ] || [ "${PHPMYADMIN_FQDN}" = "None" ]; then
  echo "ERROR: Could not resolve phpMyAdmin public FQDN."
  echo "ERROR: Ensure Public IP '${PHPMYADMIN_PUBLIC_IP_NAME}' exists."
  exit 1
fi

PHPMYADMIN_URL="http://${PHPMYADMIN_FQDN}${PHPMYADMIN_PATH}"


# ===============================================================================
# WAIT FOR PHPMYADMIN TO BECOME REACHABLE
# ===============================================================================
echo "NOTE: Waiting for phpMyAdmin to become available:"
echo "NOTE:   ${PHPMYADMIN_URL}"

attempt=1
until curl -sS --head --fail "${PHPMYADMIN_URL}" >/dev/null 2>&1; do
  if [ "${attempt}" -ge "${MAX_ATTEMPTS}" ]; then
    echo "ERROR: phpMyAdmin did not become available after ${MAX_ATTEMPTS} attempts."
    echo "ERROR: Last checked URL: ${PHPMYADMIN_URL}"
    exit 1
  fi

  echo "NOTE: phpMyAdmin not reachable yet. Retry ${attempt}/${MAX_ATTEMPTS}."
  sleep "${SLEEP_SECONDS}"
  attempt=$((attempt + 1))
done


# ===============================================================================
# RESOLVE MYSQL FLEXIBLE SERVER ENDPOINT
# ===============================================================================
MYSQL_FQDN="$(az mysql flexible-server list \
  --resource-group "${RESOURCE_GROUP_NAME}" \
  --query "[?starts_with(name, '${MYSQL_NAME_PREFIX}')].fullyQualifiedDomainName" \
  --output tsv)"

if [ -z "${MYSQL_FQDN}" ] || [ "${MYSQL_FQDN}" = "None" ]; then
  echo "ERROR: Could not resolve MySQL Flexible Server endpoint."
  echo "ERROR: No server found with prefix '${MYSQL_NAME_PREFIX}'."
  exit 1
fi


# ===============================================================================
# OUTPUT SUMMARY
# ===============================================================================
echo "==============================================================================="
echo "BUILD VALIDATION RESULTS"
echo "==============================================================================="
echo "phpMyAdmin URL:"
echo "  ${PHPMYADMIN_URL}"
echo
echo "MySQL Flexible Server Endpoint:"
echo "  ${MYSQL_FQDN}"
echo "==============================================================================="
