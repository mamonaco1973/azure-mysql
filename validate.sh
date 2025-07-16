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

MYSQL_DNS=$(az mysql flexible-server list \
   --resource-group mysql-rg \
   --query "[?starts_with(name, 'mysql-instance')].fullyQualifiedDomainName" \
   --output tsv)

echo "NOTE: Hostname for mysql server is \"$MYSQL_DNS\""

#-------------------------------------------------------------------------------
# END OF SCRIPT
#-------------------------------------------------------------------------------
