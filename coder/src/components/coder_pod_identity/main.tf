# EKS Pod Identity trust policy — used instead of IRSA because the
# aws-eks-auto-sandbox doesn't register an OIDC provider with IAM
# (sts:AssumeRoleWithWebIdentity is rejected for pods here; see
# langfuse/src/components/s3_bucket/main.tf for the same finding).
# Pod Identity is the native auth mechanism for EKS Auto Mode: the
# built-in pod identity agent sees the aws_eks_pod_identity_association
# below, intercepts AWS SDK calls from pods running as the coder
# service account, and provides creds for this role. No OIDC, no SA
# annotation required.
data "aws_iam_policy_document" "coder_trust_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole", "sts:TagSession"]
    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "coder" {
  name               = "${var.install_id}-nuon-coder-role"
  assume_role_policy = data.aws_iam_policy_document.coder_trust_policy.json
  tags               = local.tags
}

# Grants rds-db:connect scoped to the coder RDS instance's stable
# DbiResourceId, mirroring byoc-nuon/components/ctl_api_role/db_access.tf.
# This lets the Coder server (and the runner, via generate-db-auth-token)
# mint a short-lived IAM auth token in place of a stored password.
data "aws_iam_policy_document" "coder_db_access" {
  statement {
    effect = "Allow"
    actions = [
      "rds-db:connect",
    ]
    resources = [
      format("arn:aws:rds-db:%s:%s:dbuser:%s/%s",
        var.region,
        data.aws_caller_identity.current.account_id,
        var.db_instance_resource_id,
        var.db_username,
      ),
    ]
  }
}

resource "aws_iam_role_policy" "coder_db_access" {
  name   = "${var.install_id}-nuon-coder-db-access"
  role   = aws_iam_role.coder.id
  policy = data.aws_iam_policy_document.coder_db_access.json
}

# Binds the coder k8s service account (namespace/coder, sa/coder — the
# Coder helm chart's default) to the IAM role above.
resource "aws_eks_pod_identity_association" "coder" {
  cluster_name    = var.cluster_name
  namespace       = "coder"
  service_account = "coder"
  role_arn        = aws_iam_role.coder.arn
  tags            = local.tags
}
