# =============================================================================
# POLICY: Require RDS Backups
# =============================================================================
#
# This OPA policy ensures that all RDS database instances have automated
# backups enabled with an adequate retention period for disaster recovery.
#
# Policy Rules:
#   - DENY if backup_retention_period is 0 (backups disabled)
#   - WARN if backup_retention_period is less than 7 days
#   - ALLOW if backup_retention_period is 7+ days
#
# =============================================================================

package terraform

import rego.v1

# -----------------------------------------------------------------------------
# DENY: RDS instance without backups enabled
# -----------------------------------------------------------------------------

deny contains msg if {
    # Find RDS instances in the Terraform plan
    some resource in input.resource_changes
    resource.type == "aws_db_instance"
    resource.change.actions[_] in ["create", "update"]
    
    # Check if backup_retention_period is 0 (backups disabled)
    resource.change.after.backup_retention_period == 0
    
    msg := sprintf(
        "RDS instance '%s' has backups disabled (backup_retention_period = 0). Set backup_retention_period to at least 7 days",
        [resource.address]
    )
}

# -----------------------------------------------------------------------------
# WARN: RDS instance with insufficient backup retention
# -----------------------------------------------------------------------------

warn contains msg if {
    # Find RDS instances in the Terraform plan
    some resource in input.resource_changes
    resource.type == "aws_db_instance"
    resource.change.actions[_] in ["create", "update"]
    
    # Backups are enabled but retention is less than 7 days
    retention := resource.change.after.backup_retention_period
    retention > 0
    retention < 7
    
    msg := sprintf(
        "RDS instance '%s' has backup retention of %d days. Consider increasing to at least 7 days for adequate disaster recovery",
        [resource.address, retention]
    )
}

# -----------------------------------------------------------------------------
# WARN: Missing backup window configuration
# -----------------------------------------------------------------------------

warn contains msg if {
    # Find RDS instances in the Terraform plan
    some resource in input.resource_changes
    resource.type == "aws_db_instance"
    resource.change.actions[_] in ["create", "update"]
    
    # Backups are enabled
    resource.change.after.backup_retention_period > 0
    
    # But no preferred backup window is set
    not resource.change.after.preferred_backup_window
    
    msg := sprintf(
        "RDS instance '%s' does not specify a preferred_backup_window. Consider setting this to control when backups occur",
        [resource.address]
    )
}