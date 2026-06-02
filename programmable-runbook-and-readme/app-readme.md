{{ $region := .nuon.install_stack.outputs.region }}

<center>
  <img src="https://mintlify.s3-us-west-1.amazonaws.com/nuoninc/logo/dark.svg"/>
  <h1>{{ .nuon.app.name }}</h1>
  <small>
{{ if .nuon.install_stack.outputs }}
AWS | {{ dig "account_id" "000000000000" .nuon.install_stack.outputs }} | {{ dig "region" "xx-vvvv-00" .nuon.install_stack.outputs }} | {{ dig "vpc_id" "vpc-000000" .nuon.install_stack.outputs }}
{{ else }}
AWS | 000000000000 | xx-vvvv-00 | vpc-000000
{{ end }}
  </small>
</center>

<nuon-banner theme="info">
This README is rendered per-install. The values below are pulled live for install <code>{{ .nuon.install.id }}</code>, and component statuses update in real time.
</nuon-banner>

## Operations

Run these procedures against this install on demand. Each run is recorded in the
install's workflow history — see the **Runbooks** tab for the full log.

<nuon-run-runbook name="restart-and-verify"></nuon-run-runbook>
<nuon-run-runbook name="whoami-smoke-test"></nuon-run-runbook>

## Application

{{ if and .nuon.sandbox.populated .nuon.sandbox.outputs }}
{{ $sub := "whoami" }}{{ with .nuon.inputs }}{{ with .inputs }}{{ with .subdomain }}{{ $sub = . }}{{ end }}{{ end }}{{ end }}

| Service | URL |
| ------- | --- |
| whoami  | [{{ $sub }}.{{ .nuon.sandbox.outputs.nuon_dns.public_domain.name }}](https://{{ $sub }}.{{ .nuon.sandbox.outputs.nuon_dns.public_domain.name }}) |

{{ else }} Results will be visible after the sandbox is deployed. {{ end }}

## Components

{{ if .nuon.components }}

This install is running the following app components.

| Component | Status |
|-----------|--------|
{{- range $name, $component := .nuon.components }}
| `{{ $name }}` | `{{ $component.status }}` |
{{- end }}

{{ else }}

__No app components are active in this install yet.__

{{ end }}

<nuon-component-card name="whoami"></nuon-component-card>
<nuon-component-card name="application_load_balancer"></nuon-component-card>
<nuon-component-card name="certificate"></nuon-component-card>

## Installation

{{ if .nuon.install_stack.populated }}

{{ if .nuon.install_stack.quick_link_url }}
- [AWS CloudFormation QuickLink URL]({{ .nuon.install_stack.quick_link_url }})
{{ else }}
- Generating Quick Link
{{ end }}

{{ if .nuon.install_stack.template_url }}
- [AWS CloudFormation Template URL]({{ .nuon.install_stack.template_url }})
- [Compose Preview](https://{{ $region }}.console.aws.amazon.com/composer/canvas?region={{ $region }}&templateURL={{ .nuon.install_stack.template_url}}&srcConsole=cloudformation)
{{ else }}
- Generating CloudFormation Template URL
{{ end }}

{{ else }}
No install stack configured.
{{ end }}

## Accessing the EKS cluster

1. Add an access entry for the relevant role.
2. Grant the following permissions: `AmazonEKSAdminPolicy`, `AmazonEKSClusterAdminPolicy`.
3. Add the cluster kubeconfig with the following command:

<pre>
aws --region {{ .nuon.install_stack.outputs.region }} \
    --profile your.Profile eks update-kubeconfig      \
    --name {{ dig "outputs" "cluster" "name" "$cluster_name" .nuon.sandbox }} \
    --alias {{ dig "outputs" "cluster" "name" "$cluster_name" .nuon.sandbox }}
</pre>

## State

<details>
  <summary>Install Stack</summary>
  <pre>{{ toPrettyJson .nuon.install_stack }}</pre>
</details>

{{ if .nuon.sandbox.outputs }}

<details>
<summary>Sandbox State</summary>
<pre class="json">{{ toPrettyJson .nuon.sandbox.outputs }}</pre>
</details>

{{ else }}

<pre>Working on it</pre>

{{ end }}

<details>
<summary>.nuon.components</summary>
<pre>{{ toPrettyJson .nuon.components }}</pre>
</details>
