# =================================================================================
# LINK PRIVATE DNS ZONE TO VNET (MySQL)
# =================================================================================
resource "azurerm_private_dns_zone_virtual_network_link" "mysql_dns_link" {
  name                  = "mysql-dns-link"
  resource_group_name   = azurerm_resource_group.project_rg.name
  private_dns_zone_name = azurerm_private_dns_zone.mysql_private_dns.name
  virtual_network_id    = azurerm_virtual_network.project-vnet.id
}

# =================================================================================
# CREATE RANDOM SUFFIX TO INSURE UNIQUE DNS NAME
# =================================================================================

resource "random_string" "suffix" {
  length  = 4
  upper   = false
  special = false
}

# =================================================================================
# CREATE PRIVATE DNS ZONE FOR MYSQL FLEXIBLE SERVER
# =================================================================================
resource "azurerm_private_dns_zone" "mysql_private_dns" {
  name                = "privatelink.mysql.database.azure.com"
  resource_group_name = azurerm_resource_group.project_rg.name
}

# =================================================================================
# CREATE PRIVATE MYSQL FLEXIBLE SERVER
# =================================================================================
resource "azurerm_mysql_flexible_server" "mysql_instance" {
  name                          = "mysql-instance-${random_string.suffix.result}"
  resource_group_name           = azurerm_resource_group.project_rg.name
  location                      = azurerm_resource_group.project_rg.location
  version                       = "8.0.21"
  administrator_login           = "mysqladmin"
  administrator_password        = random_password.mysql_password.result
  storage_mb                    = 32768
  sku_name                      = "B_Standard_B1ms"
  backup_retention_days         = 7
  geo_redundant_backup_enabled  = false
  zone                          = "1"
  public_network_access_enabled = false

  # Ensure MySQL is deployed into a delegated subnet
  delegated_subnet_id = azurerm_subnet.mysql-subnet.id

  # Link to the private DNS zone
  private_dns_zone_id = azurerm_private_dns_zone.mysql_private_dns.id
}
