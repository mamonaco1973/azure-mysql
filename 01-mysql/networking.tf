# =================================================================================
# VIRTUAL NETWORK BASELINE
# ---------------------------------------------------------------------------------
# Purpose:
#   Create a single Virtual Network (VNet) to host all project subnets, including
#   the MySQL Flexible Server delegated subnet and an application/VM subnet.
#
# Addressing:
#   - VNet CIDR: 10.0.0.0/23 (512 addresses)
#   - Subnets:
#       * MySQL: 10.0.0.0/25 (128 addresses)
#       * VM:    10.0.1.0/25 (128 addresses)
#
# Notes:
#   - Keep CIDR planning consistent across AWS/Azure/GCP parity repos
# =================================================================================
resource "azurerm_virtual_network" "project-vnet" {
  name                = var.project_vnet
  address_space       = ["10.0.0.0/23"]
  location            = var.project_location
  resource_group_name = azurerm_resource_group.project_rg.name
}

# =================================================================================
# MYSQL FLEXIBLE SERVER SUBNET (DELEGATED)
# ---------------------------------------------------------------------------------
# Purpose:
#   Define the subnet used by MySQL Flexible Server. Azure requires this subnet
#   to be delegated to the MySQL Flexible Server service.
#
# Notes:
#   - Delegation is required for Flexible Server deployments into a VNet
#   - Use a dedicated subnet to keep database traffic isolated and controlled
# =================================================================================
resource "azurerm_subnet" "mysql-subnet" {
  name                 = var.project_subnet
  resource_group_name  = azurerm_resource_group.project_rg.name
  virtual_network_name = azurerm_virtual_network.project-vnet.name
  address_prefixes     = ["10.0.0.0/25"]

  # -----------------------------------------------------------------------------
  # Delegation
  # - Required for MySQL Flexible Server to attach to this subnet
  # -----------------------------------------------------------------------------
  delegation {
    name = "delegation"

    service_delegation {
      name    = "Microsoft.DBforMySQL/flexibleServers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

# =================================================================================
# MYSQL SUBNET NETWORK SECURITY GROUP
# ---------------------------------------------------------------------------------
# Purpose:
#   Apply subnet-level security controls for MySQL traffic.
#
# Notes:
#   - This example allows inbound TCP/3306 from any source, which is appropriate
#     only for lab/demo environments
#   - For production, restrict source_address_prefix to the VM subnet CIDR,
#     a jump host range, or specific private IP ranges
# =================================================================================
resource "azurerm_network_security_group" "mysql-nsg" {
  name                = "mysql-nsg"
  location            = var.project_location
  resource_group_name = azurerm_resource_group.project_rg.name

  # -----------------------------------------------------------------------------
  # Inbound: MySQL
  # -----------------------------------------------------------------------------
  security_rule {
    name                       = "Allow-MySQL"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3306"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# =================================================================================
# MYSQL SUBNET -> NSG ASSOCIATION
# ---------------------------------------------------------------------------------
# Purpose:
#   Bind the MySQL NSG to the MySQL subnet so rules are enforced at the subnet
#   boundary for all resources deployed into that subnet.
# =================================================================================
resource "azurerm_subnet_network_security_group_association" "mysql-nsg-assoc" {
  subnet_id                 = azurerm_subnet.mysql-subnet.id
  network_security_group_id = azurerm_network_security_group.mysql-nsg.id
}

# =================================================================================
# VM / APPLICATION SUBNET
# ---------------------------------------------------------------------------------
# Purpose:
#   Create a general-purpose subnet for virtual machines or application
#   workloads that connect to the MySQL server over the private network.
# =================================================================================
resource "azurerm_subnet" "vm-subnet" {
  name                 = "vm-subnet"
  resource_group_name  = azurerm_resource_group.project_rg.name
  virtual_network_name = azurerm_virtual_network.project-vnet.name
  address_prefixes     = ["10.0.1.0/25"]
}

# =================================================================================
# VM SUBNET NETWORK SECURITY GROUP
# ---------------------------------------------------------------------------------
# Purpose:
#   Apply subnet-level security controls for the VM/application subnet.
#
# Notes:
#   - This example allows inbound HTTP (80) and SSH (22) from any source, which
#     is appropriate only for lab/demo environments
#   - For production, restrict source_address_prefix and consider using Azure
#     Bastion, VPN, or private access patterns
# =================================================================================
resource "azurerm_network_security_group" "vm-nsg" {
  name                = "vm-nsg"
  location            = var.project_location
  resource_group_name = azurerm_resource_group.project_rg.name

  # -----------------------------------------------------------------------------
  # Inbound: HTTP
  # -----------------------------------------------------------------------------
  security_rule {
    name                       = "Allow-HTTP"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # -----------------------------------------------------------------------------
  # Inbound: SSH
  # -----------------------------------------------------------------------------
  security_rule {
    name                       = "Allow-SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# =================================================================================
# VM SUBNET -> NSG ASSOCIATION
# ---------------------------------------------------------------------------------
# Purpose:
#   Bind the VM NSG to the VM subnet so rules are enforced for all workloads
#   deployed into that subnet.
# =================================================================================
resource "azurerm_subnet_network_security_group_association" "vm-nsg-assoc" {
  subnet_id                 = azurerm_subnet.vm-subnet.id
  network_security_group_id = azurerm_network_security_group.vm-nsg.id
}
