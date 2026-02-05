# =================================================================================
# MYSQL PRIVATE DNS ZONE -> VNET LINK
# ---------------------------------------------------------------------------------
# Purpose:
#   Link the MySQL Private DNS zone to the project VNet so resources inside the
#   VNet can resolve MySQL Flexible Server private FQDNs.
#
# Why this matters:
#   - Private-only MySQL relies on Private DNS for name resolution
#   - Enables resolution of:
#       *.privatelink.mysql.database.azure.com
#
# Notes:
#   - The DNS zone must exist before the VNet link can be created
# =================================================================================
resource "azurerm_private_dns_zone_virtual_network_link" "mysql_dns_link" {
  name                  = "mysql-dns-link"
  resource_group_name   = azurerm_resource_group.project_rg.name
  private_dns_zone_name = azurerm_private_dns_zone.mysql_private_dns.name
  virtual_network_id    = azurerm_virtual_network.project-vnet.id
}

# =================================================================================
# RANDOM SUFFIX FOR GLOBAL NAME UNIQUENESS
# ---------------------------------------------------------------------------------
# Purpose:
#   Generate a short, DNS-safe suffix to avoid global name collisions for the
#   MySQL Flexible Server resource name.
#
# Notes:
#   - Azure MySQL server names must be globally unique
#   - Keep characters lowercase and alphanumeric for DNS compatibility
# =================================================================================
resource "random_string" "suffix" {
  length  = 4
  upper   = false
  special = false
}

# =================================================================================
# MYSQL PRIVATE DNS ZONE
# ---------------------------------------------------------------------------------
# Purpose:
#   Create the required Private DNS zone used by MySQL Flexible Server private
#   endpoint name resolution inside the VNet.
#
# Notes:
#   - The zone name is fixed for MySQL private link:
#       privatelink.mysql.database.azure.com
#   - Without this zone + VNet link, VMs cannot resolve the MySQL private FQDN
#     to a private IP address
# =================================================================================
resource "azurerm_private_dns_zone" "mysql_private_dns" {
  name                = "privatelink.mysql.database.azure.com"
  resource_group_name = azurerm_resource_group.project_rg.name
}

# =================================================================================
# MYSQL FLEXIBLE SERVER (PRIVATE ACCESS)
# ---------------------------------------------------------------------------------
# Purpose:
#   Deploy a fully managed MySQL Flexible Server with private network access.
#
# Key Characteristics:
#   - No public endpoint exposure (private networking only)
#   - Deployed into a delegated subnet (required by Flexible Server)
#   - Integrated with a Private DNS zone for VNet name resolution
#
# Notes:
#   - Ensure the VNet <-> DNS zone link exists before creating the server to
#     avoid DNS integration race conditions
# =================================================================================
resource "azurerm_mysql_flexible_server" "mysql_instance" {
  name                = "mysql-instance-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.project_rg.name
  location            = azurerm_resource_group.project_rg.location
  version                = "8.4"
  administrator_login    = "sysadmin"
  administrator_password = random_password.mysql_password.result

  # -----------------------------------------------------------------------------
  # Storage
  # - size_gb: Allocated storage capacity for the server
  # -----------------------------------------------------------------------------
  storage {
    size_gb = 32
  }

  # -----------------------------------------------------------------------------
  # Sizing and resiliency
  # -----------------------------------------------------------------------------
  sku_name                     = "B_Standard_B1ms"
  backup_retention_days        = 7
  geo_redundant_backup_enabled = false
  zone                         = "1"

  # -----------------------------------------------------------------------------
  # Networking
  # - delegated_subnet_id: Subnet delegated to MySQL Flexible Server
  # - private_dns_zone_id: Private DNS zone used for private endpoint resolution
  # -----------------------------------------------------------------------------
  delegated_subnet_id = azurerm_subnet.mysql-subnet.id
  private_dns_zone_id = azurerm_private_dns_zone.mysql_private_dns.id

  # -----------------------------------------------------------------------------
  # Ordering
  # - Ensure DNS zone link exists before server creation
  # -----------------------------------------------------------------------------
  depends_on = [azurerm_private_dns_zone_virtual_network_link.mysql_dns_link]
}
