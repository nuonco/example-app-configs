# =============================================================================
# POLICY: Require RDS Encryption
# =============================================================================
#
# This OPA policy ensures that all RDS database instances have storage
# encryption enabled to protect data at rest.
#
# Policy Rules:
#   - DENY if storage_encrypted is false or missing
#   - WARN if encrypted but not using a custom KMS key
#   - ALLOW if storage_encrypted is true
#
# =============================================================================

package terraform

import rego.v1

# -----------------------------------------------------------------------------
# DENY: RDS instance without encryption
# -----------------------------------------------------------------------------

deny contains msg if {
    # Find RDS instances in the Terraform plan
    some resource in input.resource_changes
    resource.type == "aws_db_instance"
    resource.change.actions[_] in ["create", "update"]
    
    # Check if storage_encrypted is false or missing
    not resource.change.after.storage_encrypted
    
    msg := sprintf(
        "RDS instance '%s' must have storage encryption enabled. Set storage_encrypted = true",
        [resource.address]
    )
}

deny contains msg if {
    # Find RDS instances in the Terraform plan
    some resource in input.resource_changes
    resource.type == "aws_db_instance"
    resource.change.actions[_] in ["create", "update"]
    
    # Check if storage_encrypted is explicitly set to false
    resource.change.after.storage_encrypted == false
    
    msg := sprintf(
        "RDS instance '%s' has encryption disabled. Set storage_encrypted = true",
        [resource.address]
    )
}

# -----------------------------------------------------------------------------
# WARN: Encrypted but not using custom KMS key
# -----------------------------------------------------------------------------

warn contains msg if {
    # Find RDS instances in the Terraform plan
    some resource in input.resource_changes
    resource.type == "aws_db_instance"
    resource.change.actions[_] in ["create", "update"]
    
    # Encryption is enabled
    resource.change.after.storage_encrypted == true
    
    # But no custom KMS key is specified
    not resource.change.after.kms_key_id
    
    msg := sprintf(
        "RDS instance '%s' is encrypted but not using a custom KMS key. Consider setting kms_key_id for better key management",
        [resource.address]
    )
}