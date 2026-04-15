# ---------------------------------------------------------------
# karpenter-image-cache
#
# Creates a custom AMI with pre-pulled container images.
# Karpenter EC2NodeClass references this AMI so nodes launch
# with images already in containerd's content store — avoiding
# multi-GB pulls on every scale-out.
#
# Flow:
#   1. Launch a temporary EC2 builder instance using the EKS AL2023 AMI
#   2. Pull all specified images into containerd on the root volume
#   3. Instance shuts itself down after pulling
#   4. Create an AMI from the stopped instance
#   5. Output ami_id for use in EC2NodeClass amiSelectorTerms
# ---------------------------------------------------------------

locals {
  images      = jsondecode(var.images)
  name_prefix = "image-cache"
  images_hash = md5(join(",", sort(local.images)))
}

# ---------------------------------------------------------------
# Data sources
# ---------------------------------------------------------------

data "aws_subnet" "selected" {
  id = var.subnet_id
}

data "aws_ssm_parameter" "eks_ami" {
  name = "/aws/service/eks/optimized-ami/${var.kubernetes_version}/amazon-linux-2023/x86_64/standard/recommended/image_id"
}

# ---------------------------------------------------------------
# IAM – builder instance profile with ECR read + SSM access
# ---------------------------------------------------------------

resource "aws_iam_role" "builder" {
  name_prefix = "${local.name_prefix}-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ecr_read" {
  role       = aws_iam_role.builder.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.builder.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "builder" {
  name_prefix = "${local.name_prefix}-"
  role        = aws_iam_role.builder.name
  tags        = var.tags
}

# ---------------------------------------------------------------
# Security group – outbound-only (no inbound / no SSH)
# ---------------------------------------------------------------

resource "aws_security_group" "builder" {
  name_prefix = "${local.name_prefix}-"
  description = "Image cache builder - egress only for pulling container images"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound for image pulls"
  }

  tags = merge(var.tags, { Name = "${local.name_prefix}-builder" })
}

# ---------------------------------------------------------------
# Builder instance
#
# Uses the EKS-optimized AL2023 AMI so the containerd layout
# matches exactly what Karpenter nodes will use. Images are
# pulled into the default containerd on the root volume.
# The instance shuts down when done.
# ---------------------------------------------------------------

resource "aws_instance" "builder" {
  ami                    = data.aws_ssm_parameter.eks_ami.value
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  iam_instance_profile   = aws_iam_instance_profile.builder.name
  vpc_security_group_ids = [aws_security_group.builder.id]

  user_data = templatefile("${path.module}/scripts/pull-images.sh.tftpl", {
    images = local.images
  })

  root_block_device {
    volume_size           = var.volume_size_gb
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = merge(var.tags, {
    Name        = "${local.name_prefix}-builder"
    images_hash = local.images_hash
  })

  lifecycle {
    replace_triggered_by = [null_resource.images_trigger]
  }
}

resource "null_resource" "images_trigger" {
  triggers = {
    images_hash = local.images_hash
  }
}

# ---------------------------------------------------------------
# Wait for the builder to finish (it shuts down when done)
# ---------------------------------------------------------------

resource "null_resource" "wait_for_completion" {
  depends_on = [aws_instance.builder]

  triggers = {
    instance_id = aws_instance.builder.id
    images_hash = local.images_hash
  }

  provisioner "local-exec" {
    command = <<-SCRIPT
      echo "Waiting for image cache builder ${aws_instance.builder.id} to complete..."
      while true; do
        STATE=$(aws ec2 describe-instances \
          --instance-ids ${aws_instance.builder.id} \
          --query 'Reservations[0].Instances[0].State.Name' \
          --output text \
          --region ${var.region} 2>/dev/null)
        echo "  instance state: $STATE"
        case "$STATE" in
          stopped)
            echo "Builder completed successfully."
            break
            ;;
          terminated|shutting-down)
            echo "ERROR: Builder instance terminated unexpectedly."
            exit 1
            ;;
        esac
        sleep 15
      done
    SCRIPT
  }
}

# ---------------------------------------------------------------
# Create AMI from the stopped builder instance
# ---------------------------------------------------------------

resource "aws_ami_from_instance" "cache" {
  name               = "${local.name_prefix}-${local.images_hash}"
  source_instance_id = aws_instance.builder.id
  description        = "EKS AL2023 AMI with ${length(local.images)} pre-cached container images"

  tags = merge(var.tags, {
    Name        = local.name_prefix
    images_hash = local.images_hash
  })

  depends_on = [null_resource.wait_for_completion]
}
