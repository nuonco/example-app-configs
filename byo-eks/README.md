{{ $region := .nuon.cloud_account.aws.region }}

<center>

<h1>BYO EKS</h1>

{{ if .nuon.install_stack.outputs }}

AWS | {{ dig "account_id" "000000000000" .nuon.install_stack.outputs }} | {{ $region }} |
{{ dig "vpc_id" "vpc-000000" .nuon.install_stack.outputs }}

{{ else }}

AWS | 000000000000 | xx-vvvv-00 | vpc-000000

{{ end }}

<small>An example application of an app deployed into an existing AWS EKS cluster.</small>

</center>

### Stack

This application uses a custom vpc cloudformation stack that accepts a vpc id, public subnets, private subnets, and a
runner subnet.
