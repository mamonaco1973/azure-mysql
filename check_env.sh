#!/bin/bash
# ==============================================================================
# File: check_env.sh
# ==============================================================================
# Purpose:
#   Validate that all required command-line tools and environment variables
#   are present before running Terraform against Azure.
#
# Validation Steps:
#   1) Verify required commands exist in PATH
#   2) Verify required Azure authentication variables are set
#   3) Authenticate to Azure using a Service Principal
#
# Behavior:
#   - Fail-fast: exits immediately if any validation step fails
#   - Designed for non-interactive, CI/CD-safe execution
#
# Requirements:
#   - Azure CLI installed
#   - Terraform installed
#   - jq installed
#   - Service Principal credentials exported as environment variables
# ==============================================================================

echo "NOTE: Validating that required commands are found in your PATH."

# ==============================================================================
# REQUIRED COMMANDS
# ------------------------------------------------------------------------------
# List of CLI tools required for provisioning and validation
# ==============================================================================
commands=("az" "terraform" "jq")

# Track overall command availability
all_found=true

# ------------------------------------------------------------------------------
# Verify each required command is available
# ------------------------------------------------------------------------------
for cmd in "${commands[@]}"; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "ERROR: $cmd is not found in the current PATH."
    all_found=false
  else
    echo "NOTE: $cmd is found in the current PATH."
  fi
done

# ------------------------------------------------------------------------------
# Fail if any required command is missing
# ------------------------------------------------------------------------------
if [ "$all_found" = true ]; then
  echo "NOTE: All required commands are available."
else
  echo "ERROR: One or more required commands are missing."
  exit 1
fi

echo "NOTE: Validating that required environment variables are set."

# ==============================================================================
# REQUIRED ENVIRONMENT VARIABLES
# ------------------------------------------------------------------------------
# These variables are required for Azure Service Principal authentication
# ==============================================================================
required_vars=(
  "ARM_CLIENT_ID"
  "ARM_CLIENT_SECRET"
  "ARM_SUBSCRIPTION_ID"
  "ARM_TENANT_ID"
)

# Track overall variable availability
all_set=true

# ------------------------------------------------------------------------------
# Verify each required environment variable is set and non-empty
# ------------------------------------------------------------------------------
for var in "${required_vars[@]}"; do
  if [ -z "${!var}" ]; then
    echo "ERROR: $var is not set or is empty."
    all_set=false
  else
    echo "NOTE: $var is set."
  fi
done

# ------------------------------------------------------------------------------
# Fail if any required variable is missing
# ------------------------------------------------------------------------------
if [ "$all_set" = true ]; then
  echo "NOTE: All required environment variables are set."
else
  echo "ERROR: One or more required environment variables are missing or empty."
  exit 1
fi

# ==============================================================================
# AZURE AUTHENTICATION
# ------------------------------------------------------------------------------
# Authenticate to Azure using the provided Service Principal credentials
# ==============================================================================
echo "NOTE: Logging in to Azure using Service Principal..."

az login \
  --service-principal \
  --username "$ARM_CLIENT_ID" \
  --password "$ARM_CLIENT_SECRET" \
  --tenant "$ARM_TENANT_ID" \
  >/dev/null 2>&1

# ------------------------------------------------------------------------------
# Verify login succeeded
# ------------------------------------------------------------------------------
if [ $? -ne 0 ]; then
  echo "ERROR: Failed to log into Azure."
  echo "ERROR: Verify Service Principal credentials and environment variables."
  exit 1
else
  echo "NOTE: Successfully logged into Azure."
fi
