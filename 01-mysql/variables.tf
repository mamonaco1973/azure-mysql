# =================================================================================
# INPUT VARIABLES
# ---------------------------------------------------------------------------------
# Purpose:
#   Centralize configurable inputs for naming and regional deployment. These
#   variables define the baseline Azure resource names and location used across
#   the Terraform configuration.
#
# Notes:
#   - Defaults are provided for convenience in lab/demo deployments
#   - Override via terraform.tfvars or -var to align with your environment
# =================================================================================

# =================================================================================
# RESOURCE GROUP NAME
# ---------------------------------------------------------------------------------
# Purpose:
#   Name of the Azure Resource Group that acts as the top-level container for
#   all resources in this deployment.
# =================================================================================
variable "project_resource_group" {
  description = "Name of the Azure Resource Group"
  type        = string
  default     = "mysql-rg"
}

# =================================================================================
# VIRTUAL NETWORK NAME
# ---------------------------------------------------------------------------------
# Purpose:
#   Name of the Azure Virtual Network (VNet) used as the logical network
#   boundary for all subnets and connected resources.
# =================================================================================
variable "project_vnet" {
  description = "Name of the Azure Virtual Network"
  type        = string
  default     = "mysql-vnet"
}

# =================================================================================
# MYSQL SUBNET NAME
# ---------------------------------------------------------------------------------
# Purpose:
#   Name of the subnet used for the MySQL Flexible Server delegated subnet.
#
# Notes:
#   - This subnet is delegated to Microsoft.DBforMySQL/flexibleServers
# =================================================================================
variable "project_subnet" {
  description = "Name of the Azure Subnet within the Virtual Network"
  type        = string
  default     = "mysql-subnet"
}

# =================================================================================
# DEPLOYMENT LOCATION
# ---------------------------------------------------------------------------------
# Purpose:
#   Azure region where resources will be deployed.
#
# Notes:
#   - The value must be a valid Azure location name
#   - Ensure the region supports all required SKUs/services in this project
# =================================================================================
variable "project_location" {
  description = "Azure region where resources will be deployed (e.g., eastus)"
  type        = string
  default     = "Central US"
}
