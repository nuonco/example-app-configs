{{ $region := .nuon.cloud_account.aws.region }}

<center>
  <img src="https://mintlify.s3-us-west-1.amazonaws.com/nuoninc/logo/dark.svg"/>
  <h1>Datadog Operator</h1>
  <small>
{{ if .nuon.install_stack.outputs }}
AWS | {{ dig "account_id" "000000000000" .nuon.install_stack.outputs }} | {{ dig "region" "xx-vvvv-00" .nuon.install_stack.outputs }} | {{ dig "vpc_id" "vpc-000000" .nuon.install_stack.outputs }}
{{ else }}
AWS | 000000000000 | xx-vvvv-00 | vpc-000000
{{ end }}
  </small>
</center>

AWS EKS Cluster with Datadog Operator and Agent

{{ if and .nuon.install_stack.populated }}

## Installation

{{ if .nuon.install_stack.quick_link_url }}

- [AWS CloudFormation QuickLink URL]({{ .nuon.install_stack.quick_link_url }}) {{ else }}
- Generating Quick Link

{{ end }}

{{ if .nuon.install_stack.template_url }}

- [AWS CloudFormation Template URL]({{ .nuon.install_stack.template_url }})
- [Compose
  Preview](https://{{ $region }}.console.aws.amazon.com/composer/canvas?region={{ $region }}&templateURL={{ .nuon.install_stack.template_url}}&srcConsole=cloudformation)
  {{ else }}
- Generating CloudFormation Template URL

{{ end }}

{{ else }} No install stack configured. {{ end }}

## Getting Started

1. Determine your datadog site. This will become an input.
1. Create a datadog API Key. This will be a secret input in the cloudformation stack.
1. Create a datadog APP Key. This will be a secret input in the cloudformation stack.

## Datadog

We deploy the datadog operator and create a datadog agent to monitor the cluster and send logs.

{{ if ne .nuon.inputs.inputs.datadog_site "" }}

<!-- prettier-ignore-start -->
|        |                                                                                                                                     |
| ------ | ----------------------------------------------------------------------------------------------------------------------------------- |
| Events | [https://{{ .nuon.inputs.inputs.datadog_site }}/event/explorer?query=kube_cluster%3A{{ .nuon.install.sandbox.outputs.cluster.name }}](https://{{ .nuon.inputs.inputs.datadog_site }}/event/explorer?query=kube_cluster%3A{{ .nuon.install.sandbox.outputs.cluster.name }}) |
| Logs | [https://{{ .nuon.inputs.inputs.datadog_site }}/logs?=cluster_name%3A{{ .nuon.install.sandbox.outputs.cluster.name }}](https://{{ .nuon.inputs.inputs.datadog_site }}/logs?query=cluster_name%3A{{ .nuon.install.sandbox.outputs.cluster.name }}) |N
<!-- prettier-ignore-end -->

{{ else }}

Datadog is not enabled. If you'd like to enable datadog:

1. set a value for the inpugt `datadog_site`
2. ensure the provided values for the following secrets are correct:
   - datadog_api_key
   - datadog_app_key
3. If the secrets have been updated manually in AWS, click "Manage > Sync Secrets" and redeploy the operator and agent.

{{ end }}

## Accessing the EKS Cluster

In a BYOC context, access to the cluster is limited. For clusters you control, you can do the follwoing:

1. Add an access entry for the relevant role.
2. Grant the following perms: AWSEKSAdmin, AWSClusterAdmin.
3. Add the cluster kubeconfig w/ the following command.

<pre>
aws --region {{ .nuon.install_stack.outputs.region }} \
    --profile your.Profile eks update-kubeconfig      \
    --name {{ dig "outputs" "cluster" "name" "$cluster_name" .nuon.sandbox }} \
    --alias {{ dig "outputs" "cluster" "name" "$cluster_name" .nuon.sandbox }}
</pre>

## State

In the top right of this page, click "Manage" > "View State" to view this install's state.
