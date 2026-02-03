# Terraform Module

An example terraform module for the aws-ambda install stack.

### Usage

```bash
tf init -upgrade
AWS_REGION="us-xxxx-2" AWS_PROFILE="some.OrgRole" tf plan -var-file terraform.tfvars
AWS_REGION="us-xxxx-2" AWS_PROFILE="some.OrgRole" tf apply -var-file terraform.tfvars
```

### Instructions

1. Create an install
2. During the "Await Install Stack" step, copy the "Install template link" and set it in the tfvars
3. Set the region, install_id, and choose a stack_name
4. Toggle roles as desired
5. Plan and apply

### Notes

- This is not _quite_ specific to the aws-lambda application, but it _is_ specific to the
  [nested vpc stack](../stack.toml#6). If you wish to extend this, ensure all of your input and secret params are
  included.
- We use non-standard `CIDR`s in the `example.tfvars`

### TODO

- [ ] write a script that will populate a tf vars file from a workflow ID for easier tf vars generation
- [ ] [maybe] support for an s3 backend
