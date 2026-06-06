package nuon

# Warn when ECS task uses minimal CPU/memory (suitable for demos, not production)
warn contains msg if {
    some resource in input.plan.resource_changes
    resource.type == "aws_ecs_task_definition"
    resource.change.actions[_] in ["create", "update"]
    
    cpu := resource.change.after.cpu
    memory := resource.change.after.memory
    
    # Check if CPU is minimal (256 = 0.25 vCPU)
    cpu == "256"
    
    msg := sprintf(
        "ECS task '%s' uses minimal CPU (%s) - suitable for demos but consider increasing for production workloads",
        [resource.address, cpu],
    )
}

warn contains msg if {
    some resource in input.plan.resource_changes
    resource.type == "aws_ecs_task_definition"
    resource.change.actions[_] in ["create", "update"]
    
    memory := resource.change.after.memory
    
    # Check if memory is minimal (512 MB)
    memory == "512"
    
    msg := sprintf(
        "ECS task '%s' uses minimal memory (%s MB) - suitable for demos but consider increasing for production workloads",
        [resource.address, memory],
    )
}
