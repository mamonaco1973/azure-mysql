#!/bin/bash
# ==============================================================================
# File: destroy.sh
# ==============================================================================
# Purpose:
#   Tear down the MySQL Terraform stack and all associated Azure resources.
#
# Behavior:
#   - Fail-fast: exit immediately on any error
#   - Linear execution with explicit directory changes
#   - Destroys all resources defined in the MySQL stack
#
# Requirements:
#   - Terraform must be installed and available in PATH
#   - Azure authentication must already be established
# ==============================================================================
set -euo pipefail

# ==============================================================================
# STEP 1: Destroy MySQL infrastructure
# ==============================================================================
cd 01-mysql

terraform init
terraform destroy -auto-approve

cd ..

# ==============================================================================
# END
# ==============================================================================
