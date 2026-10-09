##
## Nuon-generated variables (provided via tfvars file)
##

variable "nuon_install_id" {
  type        = string
  description = "The Nuon install ID for this deployment."
}

variable "nuon_org_id" {
  type        = string
  description = "The Nuon organization ID."
}

variable "nuon_app_id" {
  type        = string
  description = "The Nuon application ID."
}

variable "runner_api_url" {
  type        = string
  description = "The URL of the Nuon runner API."
}

variable "runner_id" {
  type        = string
  description = "The Nuon runner ID."
}

variable "phone_home_url" {
  type        = string
  description = "The URL the module calls to report provisioning results back to Nuon."
}

variable "install_inputs" {
  type        = map(string)
  default     = {}
  description = "Customer-provided install inputs. Keys are input names, values are provided at apply time."
}

variable "nuon_support_iam_role_arns" {
  type        = list(string)
  default     = []
  description = "Nuon control-plane IAM role ARNs that may assume the provision/maintenance/deprovision/break-glass/custom roles. Provided in the vendor tfvars; mirrors the CloudFormation stack's `runner_default_support_iam_role_arn` ctl-api config."
}

##
## IAM permissions (provided via tfvars file)
##
## inline_policy_document: full IAM policy document JSON to attach as an inline
##   policy. Preserves Effect / Action / Resource / Condition fidelity. Mirrors
##   what the CloudFormation install stack attaches as `AWS::IAM::Policy`. Takes
##   precedence over `permissions` when set.
## permissions: list of IAM action strings granted via an inline Allow-on-`*`
##   policy. Convenient shorthand; loses Resource/Condition scoping.
## managed_policy_arns: AWS managed (or customer-managed) policy ARNs to attach.
##

variable "provision_permissions" {
  type        = list(string)
  default     = []
  description = "IAM action strings granted to the provision role via an inline policy. Ignored when provision_inline_policy_document is set."
}

variable "provision_inline_policy_document" {
  type        = string
  default     = ""
  description = "JSON IAM policy document attached to the provision role as an inline policy. When non-empty, takes precedence over provision_permissions."
}

variable "provision_managed_policy_arns" {
  type        = list(string)
  default     = []
  description = "Managed policy ARNs to attach to the provision role (e.g. arn:aws:iam::aws:policy/AdministratorAccess)."
}

variable "maintenance_permissions" {
  type        = list(string)
  default     = []
  description = "IAM action strings granted to the maintenance role via an inline policy. Ignored when maintenance_inline_policy_document is set."
}

variable "maintenance_inline_policy_document" {
  type        = string
  default     = ""
  description = "JSON IAM policy document attached to the maintenance role as an inline policy. When non-empty, takes precedence over maintenance_permissions."
}

variable "maintenance_managed_policy_arns" {
  type        = list(string)
  default     = []
  description = "Managed policy ARNs to attach to the maintenance role."
}

variable "deprovision_permissions" {
  type        = list(string)
  default     = []
  description = "IAM action strings granted to the deprovision role via an inline policy. Ignored when deprovision_inline_policy_document is set."
}

variable "deprovision_inline_policy_document" {
  type        = string
  default     = ""
  description = "JSON IAM policy document attached to the deprovision role as an inline policy. When non-empty, takes precedence over deprovision_permissions."
}

variable "deprovision_managed_policy_arns" {
  type        = list(string)
  default     = []
  description = "Managed policy ARNs to attach to the deprovision role."
}

variable "break_glass_roles" {
  type = map(object({
    permissions            = optional(list(string), [])
    inline_policy_document = optional(string, "")
    managed_policy_arns    = optional(list(string), [])
    enabled                = bool
  }))
  default     = {}
  description = "Break-glass roles. Each key is the role name. Disabled by default; only created when enabled=true. inline_policy_document takes precedence over permissions when set."
}

variable "custom_roles" {
  type = map(object({
    permissions            = optional(list(string), [])
    inline_policy_document = optional(string, "")
    managed_policy_arns    = optional(list(string), [])
    enabled                = bool
  }))
  default     = {}
  description = "Custom roles for app operations. Each key is the role name. Enabled when enabled=true. inline_policy_document takes precedence over permissions when set."
}

##
## Secrets (provided via tfvars file)
##

variable "auto_generate_secrets" {
  type        = list(string)
  default     = []
  description = "Names of secrets to auto-generate. Random values are created and stored in AWS Secrets Manager."
}

variable "secrets" {
  type = map(object({
    description = string
    required    = bool
    value       = string
  }))
  default     = {}
  sensitive   = true
  description = "Customer-provided secrets. Keys are secret names, values include the secret value to store in AWS Secrets Manager."
}

variable "runner_enabled" {
  type        = bool
  default     = true
  description = "Whether to provision the runner module (ASG, launch template, log group). Set to false to skip the runner and only create networking, IAM, and secrets."
}

variable "runner_instance_type" {
  type        = string
  default     = "t3.medium"
  description = "EC2 instance type for the Nuon runner instance. Override with a larger type (e.g. t3.large) for installs with heavy build jobs."
}

##
## Customer-supplied variables (prompted at apply time)
##

variable "aws_region" {
  type        = string
  description = "The AWS region where Nuon runner infrastructure will be provisioned. The customer provides this value."

  validation {
    condition = contains([
      "us-east-1",
      "us-east-2",
      "us-west-1",
      "us-west-2",
      "ca-central-1",
      "ca-west-1",
      "eu-north-1",
      "eu-west-1",
      "eu-west-2",
      "eu-west-3",
      "eu-central-1",
      "eu-central-2",
      "eu-south-1",
      "eu-south-2",
      "ap-east-1",
      "ap-northeast-1",
      "ap-northeast-2",
      "ap-northeast-3",
      "ap-south-1",
      "ap-south-2",
      "ap-southeast-1",
      "ap-southeast-2",
      "ap-southeast-3",
      "ap-southeast-4",
      "me-south-1",
      "me-central-1",
      "sa-east-1",
      "af-south-1",
    ], var.aws_region)
    error_message = "The aws_region must be a valid AWS region (e.g. us-east-1, eu-west-1)."
  }
}

variable "vpc_id" {
  type        = string
  description = "Existing VPC to install into. Every subnet below must belong to it. This stack does not create a VPC."

  validation {
    condition     = can(regex("^vpc-[0-9a-f]{8,}$", var.vpc_id))
    error_message = "vpc_id must be a VPC ID, e.g. vpc-0123456789abcdef0."
  }
}

variable "runner_subnet_id" {
  type        = string
  description = "Existing private subnet the runner VM runs in. The runner has no public IP, so the subnet's 0.0.0.0/0 route must reach a NAT gateway, transit gateway, or egress appliance."

  validation {
    condition     = can(regex("^subnet-[0-9a-f]{8,}$", var.runner_subnet_id))
    error_message = "runner_subnet_id must be a subnet ID, e.g. subnet-0123456789abcdef0."
  }
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "Existing public subnet IDs. Reported to Nuon; the runner does not launch here."

  validation {
    condition     = length(var.public_subnet_ids) > 0
    error_message = "public_subnet_ids must list at least one subnet."
  }
  validation {
    condition     = alltrue([for s in var.public_subnet_ids : can(regex("^subnet-[0-9a-f]{8,}$", s))])
    error_message = "Every entry in public_subnet_ids must be a subnet ID."
  }
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Existing private subnet IDs. Reported to Nuon; the runner does not launch here."

  validation {
    condition     = length(var.private_subnet_ids) > 0
    error_message = "private_subnet_ids must list at least one subnet."
  }
  validation {
    condition     = alltrue([for s in var.private_subnet_ids : can(regex("^subnet-[0-9a-f]{8,}$", s))])
    error_message = "Every entry in private_subnet_ids must be a subnet ID."
  }
}

variable "eks_cluster_arn" {
  type        = string
  default     = ""
  description = "ARN of an existing EKS cluster in this VPC. When set, the maintenance role gets an access entry and namespace Roles. When empty, this stack creates no Kubernetes objects."

  validation {
    condition     = var.eks_cluster_arn == "" || can(regex("^arn:aws[a-z-]*:eks:[a-z0-9-]+:[0-9]{12}:cluster/.+$", var.eks_cluster_arn))
    error_message = "eks_cluster_arn must be empty or an EKS cluster ARN."
  }
}

variable "maintenance_namespaces" {
  type        = list(string)
  default     = []
  description = "Namespaces the maintenance role may manage. A Role and RoleBinding are created in each one and nowhere else. The sample BYO VPC app deploys into whoami only; pass the namespaces your install actually uses."

  validation {
    condition     = alltrue([for ns in var.maintenance_namespaces : can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", ns)) && length(ns) <= 63])
    error_message = "Every maintenance namespace must be a DNS label of at most 63 characters."
  }
}

variable "cluster_api_ingress_port" {
  type        = number
  default     = 443
  description = "Port opened on the cluster security group for the runner. 443 is the EKS API server."
}
