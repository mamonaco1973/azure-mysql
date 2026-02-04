# =================================================================================
# AZURE PROVIDER CONFIGURATION
# ---------------------------------------------------------------------------------
# Purpose:
#   Configure the AzureRM provider to enable Terraform interaction with Azure
#   resource management APIs.
#
# Notes:
#   - The `features {}` block is mandatory, even when no features are configured.
#   - Removing this block will cause provider initialization to fail.
# =================================================================================
provider "azurerm" {
  features {}
}

# =================================================================================
# CURRENT AZURE SUBSCRIPTION CONTEXT
# ---------------------------------------------------------------------------------
# Purpose:
#   Retrieve metadata for the currently active Azure subscription.
#
# Exposed Attributes:
#   - subscription_id : Unique identifier for the Azure subscription
#   - display_name    : Human-readable subscription name
#   - tenant_id       : Azure AD tenant associated with the subscription
#
# Usage:
#   - Resource tagging
#   - Tenant- or subscription-scoped logic
#   - Cross-subscription references
# =================================================================================
data "azurerm_subscription" "primary" {}

# =================================================================================
# AUTHENTICATED CLIENT CONTEXT
# ---------------------------------------------------------------------------------
# Purpose:
#   Retrieve identity details for the authenticated Azure CLI user or service
#   principal executing the Terraform workflow.
#
# Exposed Attributes:
#   - client_id : Application (service principal) client ID
#   - object_id : Object ID of the authenticated identity
#   - tenant_id : Azure AD tenant ID
#
# Usage:
#   - Role assignments
#   - Managed identity bindings
#   - Secure resource access configuration
# =================================================================================
data "azurerm_client_config" "current" {}

# =================================================================================
# PRIMARY RESOURCE GROUP
# ---------------------------------------------------------------------------------
# Purpose:
#   Create the top-level Azure resource group used to contain all infrastructure
#   resources deployed by this Terraform project.
#
# Inputs:
#   - project_resource_group : Resource group name
#   - project_location       : Azure region for deployment
#
# Notes:
#   - Acts as a logical boundary for lifecycle management
#   - Simplifies cleanup, access control, and cost tracking
# =================================================================================
resource "azurerm_resource_group" "project_rg" {
  name     = var.project_resource_group
  location = var.project_location
}
