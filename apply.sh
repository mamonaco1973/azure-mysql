#!/bin/bash
# ==============================================================================
# File: apply.sh
# ==============================================================================
# Purpose:
#   Validate prerequisites, deploy the MySQL Terraform stack, and run
#   post-deployment validation.
#
# Behavior:
#   - Fail-fast: exit immediately on any error
#   - No directory stack manipulation
#   - Linear, easy-to-read execution flow
#
# Requirements:
#   - check_env.sh must exist and be executable
#   - Terraform must be installed and available in PATH
#   - Azure authentication must already be established
# ==============================================================================
set -euo pipefail

# ==============================================================================
# STEP 0: Validate environment prerequisites
# ==============================================================================
./check_env.sh

# ==============================================================================
# STEP 1: Provision MySQL infrastructure
# ==============================================================================
cd 01-mysql

terraform init
terraform apply -auto-approve

cd ..

# ==============================================================================
# STEP 2: Run post-deployment validation
# ==============================================================================
echo ""
./validate.sh

# ==============================================================================
# END
# ==============================================================================
