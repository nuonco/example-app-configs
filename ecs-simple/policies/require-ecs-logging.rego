# =============================================================================
# POLICY: Require ECS Logging
# =============================================================================
#
# This OPA policy ensures that all ECS task definitions have CloudWatch
# logging configured for observability and debugging.
#
# Policy Rules:
#   - DENY if task definition has no log configuration
#   - WARN if using default log retention (never expires)
#   - ALLOW if CloudWatch logging is properly configured
#
# =============================================================================

package terraform

import rego.v1

# -----------------------------------------------------------------------------
# DENY: ECS task definition without logging configured
# -----------------------------------------------------------------------------

deny contains msg if {
    # Find ECS task definitions in the Terraform plan
    some resource in input.resource_changes
    resource.type == "aws_ecs_task_definition"
    resource.change.actions[_] in ["create", "update"]
    
    # Parse container definitions JSON
    container_defs := json.unmarshal(resource.change.after.container_definitions)
    
    # Check if any container is missing log configuration
    some container in container_defs
    not container.logConfiguration
    
    msg := sprintf(
        "ECS task definition '%s' has container '%s' without logging configured. Add logConfiguration with awslogs driver",
        [resource.address, container.name]
    )
}

# -----------------------------------------------------------------------------
# WARN: CloudWatch log group without retention policy
# -----------------------------------------------------------------------------

warn contains msg if {
    # Find CloudWatch log groups in the Terraform plan
    some resource in input.resource_changes
    resource.type == "aws_cloudwatch_log_group"
    resource.change.actions[_] in ["create", "update"]
    
    # Check if retention_in_days is not set
    not resource.change.after.retention_in_days
    
    msg := sprintf(
        "CloudWatch log group '%s' does not have retention_in_days set. Logs will be retained indefinitely, which may increase costs",
        [resource.address]
    )
}

# -----------------------------------------------------------------------------
# WARN: Short log retention period
# -----------------------------------------------------------------------------

warn contains msg if {
    # Find CloudWatch log groups in the Terraform plan
    some resource in input.resource_changes
    resource.type == "aws_cloudwatch_log_group"
    resource.change.actions[_] in ["create", "update"]
    
    # Check if retention is less than 7 days
    retention := resource.change.after.retention_in_days
    retention > 0
    retention < 7
    
    msg := sprintf(
        "CloudWatch log group '%s' has retention of only %d days. Consider increasing to at least 7 days for adequate debugging history",
        [resource.address, retention]
    )
}