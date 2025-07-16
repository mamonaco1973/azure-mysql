# =================================================================================
# LINK PRIVATE DNS ZONE TO VNET (MySQL)
# This ensures that the VNet can resolve the MySQL Flexible Server's private endpoint DNS name.
# Required for private access via the name: *.privatelink.mysql.database.azure.com
# =================================================================================
resource "azurerm_private_dns_zone_virtual_network_link" "mysql_dns_link" {
  name                  = "mysql-dns-link"                                # Friendly name for the VNet link
  resource_group_name   = azurerm_resource_group.project_rg.name          # RG where the DNS zone resides
  private_dns_zone_name = azurerm_private_dns_zone.mysql_private_dns.name # DNS zone to be linked
  virtual_network_id    = azurerm_virtual_network.project-vnet.id         # ID of the VNet to associate
}

# =================================================================================
# CREATE RANDOM SUFFIX TO ENSURE UNIQUE DNS NAME
# Azure requires globally unique names for MySQL servers. This avoids name conflicts.
# =================================================================================
resource "random_string" "suffix" {
  length  = 4     # 4-character suffix to append to the server name
  upper   = false # Use lowercase characters only
  special = false # Exclude special characters to keep the name DNS-safe
}

# =================================================================================
# CREATE PRIVATE DNS ZONE FOR MYSQL FLEXIBLE SERVER
# This DNS zone handles name resolution for MySQL private endpoint traffic.
# Without it, VMs in the VNet can’t resolve the MySQL FQDN to a private IP.
# =================================================================================
resource "azurerm_private_dns_zone" "mysql_private_dns" {
  name                = "privatelink.mysql.database.azure.com" # Required name for MySQL private link
  resource_group_name = azurerm_resource_group.project_rg.name # RG to place the DNS zone in
}

# =================================================================================
# CREATE PRIVATE MYSQL FLEXIBLE SERVER
# Fully managed MySQL server deployed into a VNet with private access only.
# No public IP is exposed; traffic flows only inside the private network.
# =================================================================================
resource "azurerm_mysql_flexible_server" "mysql_instance" {
  name                   = "mysql-instance-${random_string.suffix.result}" # Globally unique server name
  resource_group_name    = azurerm_resource_group.project_rg.name          # Target resource group
  location               = azurerm_resource_group.project_rg.location      # Region for deployment
  version                = "8.0.21"                                        # MySQL engine version
  administrator_login    = "sysadmin"                                      # Admin user for DB access
  administrator_password = random_password.mysql_password.result           # Strong, generated password

  # Storage block defines size in GB; adjust based on workload
  storage {
    size_gb = 32 # 32 GB (max 16 TB available depending on SKU)
  }

  sku_name                     = "B_Standard_B1ms" # Basic tier, 1 vCPU, 2 GiB RAM — low-cost entry-level SKU
  backup_retention_days        = 7                 # Retain backups for 7 days
  geo_redundant_backup_enabled = false             # Disable geo-redundant backup to reduce cost
  zone                         = "1"               # Availability zone — helps with high availability

  # Deploy the server into a *delegated* subnet — required for Flexible Server
  delegated_subnet_id = azurerm_subnet.mysql-subnet.id

  # Associate server with private DNS zone for name resolution within the VNet
  private_dns_zone_id = azurerm_private_dns_zone.mysql_private_dns.id

  # Ensure DNS link is created before server deployment to avoid race conditions
  depends_on = [azurerm_private_dns_zone_virtual_network_link.mysql_dns_link]
}
