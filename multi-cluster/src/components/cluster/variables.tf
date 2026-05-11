locals {
  enable_ebs_storage_class = var.ebs_storage_class.enabled

  default_tags = merge(var.tags, {
    "install.nuon.co/id"     = var.nuon_id
    "component.nuon.co/name" = "cluster"
  })
  tags = merge(
    var.additional_tags,
    local.default_tags,
  )
}

#
# from cloudformation install stack
#

variable "vpc_id" {
  type        = string
  description = "The ID of the AWS VPC to provision the cluster in."
}

variable "maintenance_iam_role_arn" {
  type        = string
  description = "The maintenance IAM Role ARN."
}

variable "provision_iam_role_arn" {
  type        = string
  description = "The provision IAM Role ARN."
}

variable "deprovision_iam_role_arn" {
  type        = string
  description = "The deprovision IAM Role ARN."
}

variable "break_glass_iam_role_arn" {
  type        = string
  description = "The break glass IAM Role ARN. If provided, an EKS access entry will be created for this role."
  default     = ""
}

#
# kubernetes group / access entry policy associations
#

variable "provision_role_eks_kubernetes_groups" {
  type        = list(any)
  description = "Additional Kubernetes Groups to add the provision role to. The provision role is assigned to a provision group automatically."
  default     = []
}

variable "maintenance_role_eks_kubernetes_groups" {
  type        = list(any)
  description = "Additional Kubernetes Groups to add the maintenance role to. The maintenance role is assigned to a maintenance group automatically."
  default     = []
}

variable "deprovision_role_eks_kubernetes_groups" {
  type        = list(any)
  description = "Additional Kubernetes Groups to add the deprovision role to. The deprovision role is assigned to a deprovision group automatically."
  default     = []
}

variable "break_glass_role_eks_kubernetes_groups" {
  type        = list(any)
  description = "Additional Kubernetes Groups to add the break glass role to. The break glass role is assigned to a break_glass group automatically."
  default     = []
}

variable "eks_compute_config" {
  type = object({
    enabled       = optional(bool, false)
    node_pools    = optional(list(string))
    node_role_arn = optional(string)
  })
  description = "Configuration block for the cluster compute configuration."
  default = {
    enabled    = true
    node_pools = ["general-purpose"]
  }
}

variable "provision_role_eks_access_entry_policy_associations" {
  type        = map(any)
  description = "EKS Cluster Access Entry Policy Associations for provision role."
  default = {
    cluster_admin = {
      policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
      access_scope = {
        type = "cluster"
      }
    }
    eks_admin = {
      policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy"
      access_scope = {
        type = "cluster"
      }
    }
  }
}

variable "maintenance_role_eks_access_entry_policy_associations" {
  type        = map(any)
  description = "EKS Cluster Access Entry Policy Associations for maintenance role. Defaults to none meaning permissions are governed by eponymous RBAC group."
  default     = {}
}

variable "deprovision_role_eks_access_entry_policy_associations" {
  type        = map(any)
  description = "EKS Cluster Access Entry Policy Associations for deprovision role."
  default = {
    cluster_admin = {
      policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
      access_scope = {
        type = "cluster"
      }
    }
    eks_admin = {
      policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy"
      access_scope = {
        type = "cluster"
      }
    }
  }
}

variable "break_glass_role_eks_access_entry_policy_associations" {
  type        = map(any)
  description = "EKS Cluster Access Entry Policy Associations for break glass role."
  default = {
    cluster_admin = {
      policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
      access_scope = {
        type = "cluster"
      }
    }
    eks_admin = {
      policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy"
      access_scope = {
        type = "cluster"
      }
    }
  }
}

variable "additional_access_entry" {
  type        = map(any)
  description = "Additional access entries. Useful when providing access to extra roles."
  default     = {}
}

variable "maintenance_cluster_role_rules_override" {
  type = list(object({
    apiGroups     = list(string),
    resources     = list(string),
    verbs         = list(string),
    resourceNames = optional(list(string)),
  }))
  description = "A list of rules for the ClusterRole definition for the maintenance group. If this value is provided, these rules will be used instead."
  default     = []
}

#
# install inputs
#

variable "cluster_version" {
  type        = string
  description = "The Kubernetes version to use for the EKS cluster."
  default     = "1.34"
}

variable "cluster_name" {
  type        = string
  description = "The name of the EKS cluster. If not provided, the install ID will be used by default."
  default     = ""
}

variable "cluster_endpoint_public_access" {
  type        = bool
  description = "Whether the EKS cluster API server endpoint is publicly accessible."
  default     = false
}

variable "additional_tags" {
  type        = map(any)
  description = "Extra tags to append to the default tags that will be added to install resources."
  default     = {}
}

variable "additional_namespaces" {
  type        = list(string)
  description = "A list of namespaces that should be created on the cluster. The `{{.nuon.install.id}}` namespace is created by default."
  default     = []
}

variable "helm_driver" {
  type        = string
  description = "One of 'configmap' or 'secret'."
  default     = "secret"
}

variable "ebs_storage_class" {
  type = object({
    enabled                = optional(bool, false)
    name                   = optional(string, "ebs-auto")
    is_default_class       = optional(bool, true)
    provisioner            = optional(string, "ebs.csi.eks.amazonaws.com")
    volume_binding_mode    = optional(string, "WaitForFirstConsumer")
    reclaim_policy         = optional(string, "Delete")
    allow_volume_expansion = optional(bool, true)
    parameters = optional(map(string), {
      type      = "gp3"
      encrypted = "true"
    })
    restrict_to_auto_mode_nodes = optional(bool, true)
  })
  default = {
    enabled = true
  }
  description = "Configuration for the EBS StorageClass using the EKS Auto Mode provisioner."
}

#
# set by nuon
#

variable "nuon_id" {
  type        = string
  description = "The nuon id for this install. Used for naming purposes."
}

variable "region" {
  type        = string
  description = "The region to launch the cluster in."
}

variable "tags" {
  type        = map(any)
  description = "List of custom tags to add to the install resources. Used for taxonomic purposes."
  default     = {}
}

locals {
  roles = {
    provision_iam_role_name   = split("/", var.provision_iam_role_arn)[length(split("/", var.provision_iam_role_arn)) - 1]
    deprovision_iam_role_name = split("/", var.deprovision_iam_role_arn)[length(split("/", var.deprovision_iam_role_arn)) - 1]
    maintenance_iam_role_name = split("/", var.maintenance_iam_role_arn)[length(split("/", var.maintenance_iam_role_arn)) - 1]
    break_glass_iam_role_name = var.break_glass_iam_role_arn != "" ? split("/", var.break_glass_iam_role_arn)[length(split("/", var.break_glass_iam_role_arn)) - 1] : ""
  }
}
