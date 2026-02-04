# =================================================================================
# KEY VAULT NAME UNIQUENESS SUFFIX
# ---------------------------------------------------------------------------------
# Purpose:
#   Generate a DNS-safe random suffix to ensure the Key Vault name is globally
#   unique across Azure.
#
# Notes:
#   - Key Vault names must be globally unique
#   - Lowercase alphanumeric characters are safest for Azure naming rules
# =================================================================================
resource "random_string" "key_vault_suffix" {
  length  = 8
  special = false
  upper   = false
}

# =================================================================================
# CENTRALIZED KEY VAULT FOR CREDENTIAL MANAGEMENT
# ---------------------------------------------------------------------------------
# Purpose:
#   Deploy an Azure Key Vault to securely store credentials used by the MySQL
#   server and supporting virtual machines.
#
# Design Choices:
#   - RBAC authorization enabled (preferred over legacy access policies)
#   - Standard SKU for general-purpose secret storage
#
# Notes:
#   - Purge protection is disabled to allow clean teardown in lab/demo workflows
# =================================================================================
resource "azurerm_key_vault" "credentials_key_vault" {
  name                       = "creds-kv-${random_string.key_vault_suffix.result}"
  resource_group_name        = azurerm_resource_group.project_rg.name
  location                   = var.project_location
  sku_name                   = "standard"
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  purge_protection_enabled   = false
  rbac_authorization_enabled = true
}

# =================================================================================
# KEY VAULT RBAC ROLE ASSIGNMENT
# ---------------------------------------------------------------------------------
# Purpose:
#   Grant the current user or service principal permission to manage secrets
#   within the Key Vault.
#
# Notes:
#   - Scope is limited to the Key Vault resource
#   - Role grants secret management only (no key or certificate access)
# =================================================================================
resource "azurerm_role_assignment" "kv_role_assignment" {
  scope                = azurerm_key_vault.credentials_key_vault.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

# =================================================================================
# MYSQL CREDENTIAL PASSWORD GENERATION
# ---------------------------------------------------------------------------------
# Purpose:
#   Generate a strong random password for MySQL administrative access.
#
# Notes:
#   - Special characters are excluded to simplify scripting and connection use
# =================================================================================
resource "random_password" "mysql_password" {
  length  = 24
  special = false
}

# =================================================================================
# MYSQL CREDENTIALS SECRET
# ---------------------------------------------------------------------------------
# Purpose:
#   Store MySQL credentials in Key Vault as a JSON-encoded secret.
#
# Notes:
#   - Secret creation depends on RBAC role assignment completion
#   - JSON format keeps username and password logically grouped
# =================================================================================
resource "azurerm_key_vault_secret" "mysql_secret" {
  name         = "mysql-credentials"
  key_vault_id = azurerm_key_vault.credentials_key_vault.id
  content_type = "application/json"

  value = jsonencode({
    username = "sysadmin"
    password = random_password.mysql_password.result
  })

  depends_on = [azurerm_role_assignment.kv_role_assignment]
}

# =================================================================================
# VM CREDENTIAL PASSWORD GENERATION
# ---------------------------------------------------------------------------------
# Purpose:
#   Generate a strong random password for VM administrative access.
#
# Notes:
#   - Password is stored securely in Key Vault and not hard-coded
# =================================================================================
resource "random_password" "vm_password" {
  length  = 24
  special = false
}

# =================================================================================
# VM CREDENTIALS SECRET
# ---------------------------------------------------------------------------------
# Purpose:
#   Store VM credentials in Key Vault as a JSON-encoded secret.
#
# Notes:
#   - Secret creation depends on RBAC role assignment completion
#   - Aligns with centralized secrets management best practices
# =================================================================================
resource "azurerm_key_vault_secret" "vm_secret" {
  name         = "vm-credentials"
  key_vault_id = azurerm_key_vault.credentials_key_vault.id
  content_type = "application/json"

  value = jsonencode({
    username = "sysadmin"
    password = random_password.vm_password.result
  })

  depends_on = [azurerm_role_assignment.kv_role_assignment]
}
