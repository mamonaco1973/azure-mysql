# =================================================================================
# PHPMyAdmin VM NETWORK INTERFACE
# ---------------------------------------------------------------------------------
# Purpose:
#   Create a Network Interface (NIC) for the PHPMyAdmin VM and attach it to the
#   application/VM subnet.
#
# Notes:
#   - The NIC receives a private IP from the VM subnet
#   - A Public IP is associated to provide inbound access (lab/demo use)
# =================================================================================
resource "azurerm_network_interface" "phpmyadmin-vm-nic" {
  name                = "phpmyadmin-vm-nic"
  location            = var.project_location
  resource_group_name = azurerm_resource_group.project_rg.name

  # -----------------------------------------------------------------------------
  # IP configuration
  # - Dynamic private IP allocation from the VM subnet
  # - Public IP association for external access (demo convenience)
  # -----------------------------------------------------------------------------
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.vm-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.phpmyadmin_vm_public_ip.id
  }
}

# =================================================================================
# PHPMyAdmin LINUX VIRTUAL MACHINE
# ---------------------------------------------------------------------------------
# Purpose:
#   Deploy a small Ubuntu VM that hosts PHPMyAdmin for interacting with the MySQL
#   Flexible Server instance.
#
# Key Characteristics:
#   - Attached to the VM subnet via a dedicated NIC
#   - Bootstrapped via cloud-init (custom_data) using a template script
#   - Uses password authentication for simplicity in lab/demo scenarios
#
# Notes:
#   - For production, prefer SSH keys and disable password authentication
#   - Keep VM size small; this host is intended as a lightweight web client
# =================================================================================
resource "azurerm_linux_virtual_machine" "phpmyadmin-vm" {
  name                = "phpmyadmin-vm"
  location            = var.project_location
  resource_group_name = azurerm_resource_group.project_rg.name

  size           = "Standard_B1s"
  admin_username = "sysadmin"
  admin_password = random_password.vm_password.result

  # -----------------------------------------------------------------------------
  # Authentication
  # - Password auth enabled for lab/demo usability
  # -----------------------------------------------------------------------------
  disable_password_authentication = false

  # -----------------------------------------------------------------------------
  # Networking
  # - Attach the VM to the pre-created NIC
  # -----------------------------------------------------------------------------
  network_interface_ids = [
    azurerm_network_interface.phpmyadmin-vm-nic.id
  ]

  # -----------------------------------------------------------------------------
  # OS disk
  # - Standard_LRS keeps costs low for non-performance workloads
  # -----------------------------------------------------------------------------
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  # -----------------------------------------------------------------------------
  # Base image
  # - Ubuntu 24.04 LTS from the Azure Marketplace
  #
  # Notes:
  #   - "latest" improves convenience but reduces strict repeatability
  #   - For repeatable builds, pin version to a specific image version
  # -----------------------------------------------------------------------------
  source_image_reference {
    publisher = "canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  # -----------------------------------------------------------------------------
  # Cloud-init bootstrap
  # - Provide a rendered script as custom_data (base64 encoded)
  #
  # Inputs passed into the template:
  #   - PASSWORD   : MySQL admin password for PHPMyAdmin login convenience
  #   - MYSQL_HOST : MySQL server FQDN (computed from the unique suffix)
  #   - USER       : MySQL admin username
  # -----------------------------------------------------------------------------
  custom_data = base64encode(templatefile("./scripts/phpmyadmin.sh.template", {
    PASSWORD   = random_password.mysql_password.result
    MYSQL_HOST = "mysql-instance-${random_string.suffix.result}.mysql.database.azure.com"
    USER       = "sysadmin"
  }))

  # -----------------------------------------------------------------------------
  # Ordering
  # - Ensure MySQL exists before bootstrapping the client VM
  # -----------------------------------------------------------------------------
  depends_on = [azurerm_mysql_flexible_server.mysql_instance]
}

# =================================================================================
# PHPMyAdmin PUBLIC IP
# ---------------------------------------------------------------------------------
# Purpose:
#   Provide a static, routable Public IP for the PHPMyAdmin VM.
#
# Notes:
#   - Standard SKU is required for certain features and is recommended
#   - domain_name_label creates a public DNS name under:
#       <label>.<region>.cloudapp.azure.com
# =================================================================================
resource "azurerm_public_ip" "phpmyadmin_vm_public_ip" {
  name                = "phpmyadmin-vm-public-ip"
  location            = var.project_location
  resource_group_name = azurerm_resource_group.project_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = "phpmyadmin-${random_string.suffix.result}"
}
