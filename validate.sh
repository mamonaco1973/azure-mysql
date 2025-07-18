#!/bin/bash

#-------------------------------------------------------------------------------
# Output phpmyadmin URL and mysql DNS name
#-------------------------------------------------------------------------------

PHPMYADMIN_DNS_NAME=$(az network public-ip show \
   --name phpmyadmin-vm-public-ip \
   --resource-group mysql-rg \
   --query "dnsSettings.fqdn" \
   --output tsv)

echo "NOTE: phpmyadmin running at http://$PHPMYADMIN_DNS_NAME"

# Wait until the phpMyAdmin URL is reachable (HTTP 200 or similar)
echo "NOTE: Waiting for phpMyAdmin to become available at http://$PHPMYADMIN_DNS_NAME ..."

# Max attempts (optional)
MAX_ATTEMPTS=30
ATTEMPT=1

until curl -s --head --fail "http://$PHPMYADMIN_DNS_NAME" > /dev/null; do
  if [ "$ATTEMPT" -ge "$MAX_ATTEMPTS" ]; then
    echo "ERROR: phpMyAdmin did not become available after $MAX_ATTEMPTS attempts."
    exit 1
  fi
  echo "WARNING: phpMyAdmin not yet reachable. Retrying in 30 seconds..."
  sleep 30
  ATTEMPT=$((ATTEMPT+1))
done

MYSQL_DNS=$(az mysql flexible-server list \
   --resource-group mysql-rg \
   --query "[?starts_with(name, 'mysql-instance')].fullyQualifiedDomainName" \
   --output tsv)

echo "NOTE: Hostname for mysql server is \"$MYSQL_DNS\""

#-------------------------------------------------------------------------------
# END OF SCRIPT
#-------------------------------------------------------------------------------
