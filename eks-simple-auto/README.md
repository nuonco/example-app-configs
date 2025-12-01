{{ $region := .nuon.install_stack.outputs.region }}

<center>
  <img src="https://mintlify.s3-us-west-1.amazonaws.com/nuoninc/logo/dark.svg"/>
  <h1>Whoami on EKS + Auto Mode</h1>
  <small>
{{ if .nuon.install_stack.outputs }}
AWS | {{ dig "account_id" "000000000000" .nuon.install_stack.outputs }} | {{ dig "region" "xx-vvvv-00" .nuon.install_stack.outputs }} | {{ dig "vpc_id" "vpc-000000" .nuon.install_stack.outputs }}
{{ else }}
AWS | 000000000000 | xx-vvvv-00 | vpc-000000
{{ end }}
  </small>
</center>

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

<details>
<summary>Full Template</summary>
{{ $template := .nuon.install_stack.template_json | fromJson }}
<pre>{{ $template | toPrettyJson }}</pre>
</details>
{{ else }}
No install stack configured.
{{ end }}

## Application

{{ if and .nuon.sandbox.populated .nuon.sandbox.outputs }}

| Service | URL                                                                                                                                      |
| ------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| whoami  | [whoami.{{ .nuon.sandbox.outputs.nuon_dns.public_domain.name }}](https://whoami.{{ .nuon.sandbox.outputs.nuon_dns.public_domain.name }}) |

{{ else }} Results will be visible after the sandbox is deployed. {{ end }}

## Accessing the EKS Cluster

1. Add an access entry for the relevant role.
2. Grant the following perms: AWSEKSAdmin, AWSClusterAdmin.gtg
3. Add the cluster kubeconfig w/ the following command.

<pre>
aws --region {{ .nuon.install_stack.outputs.region }} \
    --profile your.Profile eks update-kubeconfig      \
    --name {{ dig "outputs" "cluster" "name" "$cluster_name" .nuon.sandbox }} \
    --alias {{ dig "outputs" "cluster" "name" "$cluster_name" .nuon.sandbox }}
</pre>

## State

### Install Stack

<details>
  <summary>Install Stack</summary>
  <pre>{{ toPrettyJson .nuon.install_stack }}</pre>
</details>

### Sandbox

{{ if .nuon.sandbox.outputs }}

<details>
<summary>Sandbox State</summary>
<pre class="json">{{ toPrettyJson .nuon.sandbox.outputs }}</pre>
</details>

{{ else }}

<pre>Working on it</pre>

{{ end }} 9

### Actions

<details>
<summary>.nuon.actions</summary>
<pre>{{ toPrettyJson .nuon.actions }}</pre>
</details>

### Components

<details>
<summary>.nuon.components</summary>
<pre>{{ toPrettyJson .nuon.components }}</pre>
</details>

### Inputs

<details>
<summary>.nuon.inputs</summary>
<pre>{{ toPrettyJson .nuon.inputs }}</pre>
</details>

### Full State

<details>
<summary>Full Install State</summary>
<pre>{{ toPrettyJson .nuon }}</pre>
</details>
