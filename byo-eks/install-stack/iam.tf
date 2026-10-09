###############################################################################
# Runner instance role + instance profile
###############################################################################

data "aws_iam_policy_document" "ec2_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "runner" {
  name               = "${local.prefix}-runner"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
  tags               = local.tags
}

resource "aws_iam_instance_profile" "runner" {
  name = "${local.prefix}-runner"
  role = aws_iam_role.runner.name
  tags = local.tags
}

data "aws_iam_policy_document" "runner_inline" {
  statement {
    sid     = "AssumeInstallScopedRoles"
    actions = ["sts:AssumeRole", "sts:TagSession"]
    resources = [
      "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:role/${local.prefix}-*",
    ]
  }

  statement {
    sid = "WriteOwnLogGroup"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams",
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:runner-${var.runner_id}",
      "arn:${data.aws_partition.current.partition}:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:runner-${var.runner_id}:*",
    ]
  }

  statement {
    sid    = "DenyLogDeletion"
    effect = "Deny"
    actions = [
      "logs:DeleteLogGroup",
      "logs:DeleteLogStream",
      "logs:DeleteRetentionPolicy",
    ]
    resources = ["*"]
  }

  statement {
    sid       = "ReadOwnInstanceTags"
    actions   = ["ec2:DescribeTags"]
    resources = ["*"]
  }

  statement {
    sid = "RefreshOwnAutoScalingGroup"
    actions = [
      "autoscaling:StartInstanceRefresh",
      "autoscaling:DescribeInstanceRefreshes",
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:autoscaling:${var.aws_region}:${data.aws_caller_identity.current.account_id}:autoScalingGroup:*:autoScalingGroupName/${local.prefix}-runner-asg",
    ]
  }

  statement {
    sid = "DescribeAutoScalingState"
    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "runner_inline" {
  name   = "${local.prefix}-runner-inline"
  role   = aws_iam_role.runner.id
  policy = data.aws_iam_policy_document.runner_inline.json
}

resource "aws_iam_role_policy_attachment" "runner_ssm" {
  role       = aws_iam_role.runner.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

###############################################################################
# Trust policy: control-plane accounts assume the operation roles
###############################################################################

data "aws_iam_policy_document" "control_plane_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type = "AWS"
      identifiers = length(var.nuon_support_iam_role_arns) > 0 ? var.nuon_support_iam_role_arns : [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
      ]
    }
  }

  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.runner.arn]
    }
  }
}

###############################################################################
# Provision role
###############################################################################

resource "aws_iam_role" "provision" {
  count              = local.has_provision ? 1 : 0
  name               = "${local.prefix}-provision"
  assume_role_policy = data.aws_iam_policy_document.control_plane_assume.json
  tags               = local.tags
}

resource "aws_iam_role_policy" "provision_inline" {
  count  = local.has_provision && local.provision_inline_policy != "" ? 1 : 0
  name   = "${local.prefix}-provision-inline"
  role   = aws_iam_role.provision[0].id
  policy = local.provision_inline_policy
}

resource "aws_iam_role_policy_attachment" "provision_managed" {
  for_each   = local.has_provision ? toset(var.provision_managed_policy_arns) : toset([])
  role       = aws_iam_role.provision[0].name
  policy_arn = each.value
}

###############################################################################
# Deprovision role
###############################################################################

resource "aws_iam_role" "deprovision" {
  count              = local.has_deprovision ? 1 : 0
  name               = "${local.prefix}-deprovision"
  assume_role_policy = data.aws_iam_policy_document.control_plane_assume.json
  tags               = local.tags
}

resource "aws_iam_role_policy" "deprovision_inline" {
  count  = local.has_deprovision && local.deprovision_inline_policy != "" ? 1 : 0
  name   = "${local.prefix}-deprovision-inline"
  role   = aws_iam_role.deprovision[0].id
  policy = local.deprovision_inline_policy
}

resource "aws_iam_role_policy_attachment" "deprovision_managed" {
  for_each   = local.has_deprovision ? toset(var.deprovision_managed_policy_arns) : toset([])
  role       = aws_iam_role.deprovision[0].name
  policy_arn = each.value
}

###############################################################################
# Break-glass roles (dynamic, one per enabled role)
###############################################################################

# Role names come from the ctl-api renderer with install-id templating already
# applied by the vendor's stack.toml — match CFN's contract (`RoleName: role.Name`)
# and use each.key verbatim. Rewrapping with `${local.prefix}-bg-` here would
# double-prefix and overflow IAM's 64-char role-name limit.
resource "aws_iam_role" "break_glass" {
  for_each           = local.enabled_break_glass_roles
  name               = each.key
  assume_role_policy = data.aws_iam_policy_document.control_plane_assume.json
  tags               = local.tags
}

resource "aws_iam_role_policy" "break_glass_inline" {
  for_each = { for k, v in local.enabled_break_glass_roles : k => v if local.break_glass_inline_policies[k] != "" }
  name     = "${each.key}-inline"
  role     = aws_iam_role.break_glass[each.key].id
  policy   = local.break_glass_inline_policies[each.key]
}

resource "aws_iam_role_policy_attachment" "break_glass_managed" {
  for_each = merge([
    for k, v in local.enabled_break_glass_roles : {
      for arn in v.managed_policy_arns : "${k}__${arn}" => { role = k, arn = arn }
    }
  ]...)
  role       = aws_iam_role.break_glass[each.value.role].name
  policy_arn = each.value.arn
}

###############################################################################
# Custom roles (dynamic, one per enabled role)
###############################################################################

resource "aws_iam_role" "custom" {
  for_each           = local.enabled_custom_roles
  name               = each.key
  assume_role_policy = data.aws_iam_policy_document.control_plane_assume.json
  tags               = local.tags
}

resource "aws_iam_role_policy" "custom_inline" {
  for_each = { for k, v in local.enabled_custom_roles : k => v if local.custom_inline_policies[k] != "" }
  name     = "${each.key}-inline"
  role     = aws_iam_role.custom[each.key].id
  policy   = local.custom_inline_policies[each.key]
}

resource "aws_iam_role_policy_attachment" "custom_managed" {
  for_each = merge([
    for k, v in local.enabled_custom_roles : {
      for arn in v.managed_policy_arns : "${k}__${arn}" => { role = k, arn = arn }
    }
  ]...)
  role       = aws_iam_role.custom[each.value.role].name
  policy_arn = each.value.arn
}
