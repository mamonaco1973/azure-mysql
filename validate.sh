#!/bin/bash

#-------------------------------------------------------------------------------
# Output pgweb URL and postgres DNS name
#-------------------------------------------------------------------------------

PGWEB_DNS_NAME=$(az network public-ip show \
  --name pgweb-vm-public-ip \
  --resource-group postgres-rg \
  --query "dnsSettings.fqdn" \
  --output tsv)

echo "NOTE: pgweb running at http://$PGWEB_DNS_NAME"

PG_DNS=$(az postgres flexible-server list \
  --resource-group postgres-rg \
  --query "[?starts_with(name, 'postgres-instance')].fullyQualifiedDomainName" \
  --output tsv)

echo "NOTE: Hostname for postgres server is \"$PG_DNS\""

#-------------------------------------------------------------------------------
# END OF SCRIPT
#-------------------------------------------------------------------------------
