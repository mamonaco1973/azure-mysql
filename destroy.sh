#!/bin/bash

#-------------------------------------------------------------------------------
# STEP 1: Destroy mysql infrastructure (VNet, Subnet, NICs, NSGs, etc.)
#-------------------------------------------------------------------------------
cd 01-mysql                            # Go to base infra config
terraform init                         # Initialize Terraform plugins/modules
terraform destroy -auto-approve        # Destroy all foundational Azure resources
cd ..                                  # Return to root

#-------------------------------------------------------------------------------
# END OF SCRIPT
#-------------------------------------------------------------------------------
