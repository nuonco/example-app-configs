# Permissions

IAM roles used by the Nuon runner during different phases of the install lifecycle. These roles are created in the customer's AWS account via the CloudFormation stack.

## Lifecycle Phases

| Phase       | Role File          | When Used                                         |
|-------------|--------------------|---------------------------------------------------|
| Provision   | `provision.toml`   | Initial install - creating sandbox and components |
| Maintenance | `maintenance.toml` | Day-to-day operations - deployments, updates      |
| Deprovision | `deprovision.toml` | Teardown - destroying components and sandbox      |

## How It Works

1. When a customer runs the CloudFormation stack, these IAM roles are created in their account
2. The Nuon runner assumes the appropriate role for each operation
3. Permission boundaries limit the maximum permissions each role can have
4. This ensures least-privilege access during each lifecycle phase

## Files in This Directory

| File                        | Description                                    |
|-----------------------------|------------------------------------------------|
| `provision.toml`            | IAM role for provisioning operations           |
| `maintenance.toml`          | IAM role for maintenance operations            |
| `deprovision.toml`          | IAM role for deprovision operations            |
| `provision_boundary.json`   | Permission boundary for provision role         |
| `maintenance_boundary.json` | Permission boundary for maintenance role       |
| `deprovision_boundary.json` | Permission boundary for deprovision role       |

## Configuration Keys

```toml
type                 = "provision"           # Role type: provision, maintenance, deprovision
name                 = "{{.nuon.install.id}}-provision"  # IAM role name (supports templating)
description          = "Role description"    # Shown to customers in installer
display_name         = "Display Name"        # UI display name
permissions_boundary = "./boundary.json"    # Path to boundary policy

[[policies]]
managed_policy_name = "AdministratorAccess"  # AWS managed policy

[[policies]]
name = "custom-policy"                       # Custom inline policy
contents = """
{
  "Version": "2012-10-17",
  "Statement": [...]
}
"""
```

## Best Practices

**Principle of Least Privilege**: While this demo uses `AdministratorAccess` for simplicity, production apps should use scoped policies:

```toml
# Example: Scoped provision role
[[policies]]
name = "provision-eks"
contents = """
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "eks:CreateCluster",
        "eks:DeleteCluster",
        "eks:DescribeCluster",
        "eks:UpdateClusterConfig"
      ],
      "Resource": "arn:aws:eks:*:*:cluster/{{.nuon.install.id}}-*"
    }
  ]
}
"""
```

**Permission Boundaries**: Use boundaries to set maximum allowed permissions:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["eks:*", "ec2:*", "s3:*", "rds:*"],
      "Resource": "*"
    },
    {
      "Effect": "Deny",
      "Action": ["iam:CreateUser", "iam:DeleteUser"],
      "Resource": "*"
    }
  ]
}
```

## Documentation

- [Install Access Permissions](https://docs.nuon.co/guides/install-access-permissions)
- [Permissions Reference](https://docs.nuon.co/config-ref/permissions)
