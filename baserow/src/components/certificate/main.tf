# https://registry.terraform.io/modules/terraform-aws-modules/acm/aws/latest

module "certificate" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 4.0"

  domain_name         = var.domain_name
  subject_alternative_names = var.subject_alternative_names != "" ? split(",", var.subject_alternative_names) : []
  zone_id             = var.zone_id
  validation_method   = "DNS"
  wait_for_validation = false
}
