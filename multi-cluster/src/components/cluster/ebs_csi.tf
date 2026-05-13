# EKS Auto Mode has built-in EBS CSI support (ebs.csi.eks.amazonaws.com).
# We just create a StorageClass that uses the Auto Mode provisioner.
resource "kubectl_manifest" "ebs_storage_class" {
  count    = local.enable_ebs_storage_class ? 1 : 0
  provider = kubectl.main

  yaml_body = yamlencode(merge(
    {
      apiVersion = "storage.k8s.io/v1"
      kind       = "StorageClass"
      metadata = {
        name = var.ebs_storage_class.name
        annotations = var.ebs_storage_class.is_default_class ? {
          "storageclass.kubernetes.io/is-default-class" = "true"
        } : {}
      }
      provisioner          = var.ebs_storage_class.provisioner
      volumeBindingMode    = var.ebs_storage_class.volume_binding_mode
      reclaimPolicy        = var.ebs_storage_class.reclaim_policy
      allowVolumeExpansion = var.ebs_storage_class.allow_volume_expansion
      parameters           = var.ebs_storage_class.parameters
    },
    var.ebs_storage_class.restrict_to_auto_mode_nodes ? {
      allowedTopologies = [{
        matchLabelExpressions = [{
          key    = "eks.amazonaws.com/compute-type"
          values = ["auto"]
        }]
      }]
    } : {},
  ))

  depends_on = [
    module.eks,
    aws_security_group_rule.runner_cluster_access_primary,
    aws_security_group_rule.runner_cluster_access_additional,
  ]
}
