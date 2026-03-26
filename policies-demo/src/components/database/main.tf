module "dynamodb_table" {
  source  = "terraform-aws-modules/dynamodb-table/aws"
  version = "~> 4.0.0"

  name         = var.name
  hash_key     = var.hash_key
  billing_mode = var.billing_mode

  attributes = [
    {
      name = "ID"
      type = "N"
    },
  ]
}
