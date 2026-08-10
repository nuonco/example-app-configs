# HTTPBin

{{ $accountId := dig "account_id" "000000000000" .nuon.install_stack.outputs }}
{{ $region := .nuon.cloud_account.aws.region }}
{{ $vpcId := dig "vpc_id" "vpc-000000" .nuon.install_stack.outputs }}
{{ $publicIp := dig "public_ip" "" .nuon.components.ec2.outputs }}

A simple service used to test and debug HTTP requests. Built with the [go-httpbin](https://github.com/mccutchen/go-httpbin) implementation.

{{ if $publicIp }}Your httpbin instance: [http://{{ $publicIp }}](http://{{ $publicIp }}){{ else }}Deploying...{{ end }}

<nuon-tabs>

<nuon-tab name="quickstart">

<div style="padding-top:1rem;"></div>

Once deployed, you can test your httpbin instance with any HTTP client:

```bash
# GET request
curl http://{{ $publicIp }}/get

# POST request with JSON
curl -X POST -H "Content-Type: application/json" \
  http://{{ $publicIp }}/post \
  -d '{"foo": "bar"}'

# Test headers
curl http://{{ $publicIp }}/headers

# Test delay
curl http://{{ $publicIp }}/delay/3
```



## About this App Config

This is a sample App Config with a single `terraform_module` component that creates an EC2 instance
and starts a basic web server. The full source code can be referenced [here](https://github.com/nuonco/example-app-configs/tree/main/httpbin).

On average, this app costs around ~$2.50 per day to run.

</nuon-tab>

<nuon-tab name="health">

<div style="padding-top:1rem;"></div>

## Deployment Status

{{ $ec2Component := .nuon.components.ec2 }}
{{ $ec2Status := dig "status" "unknown" $ec2Component }}

<table>
  <thead>
    <tr>
      <th>Component</th>
      <th>Status</th>
      <th>Type</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><strong>ec2</strong></td>
      <td><nuon-status status="{{ $ec2Status }}" variant="badge"></nuon-status></td>
      <td>terraform_module</td>
    </tr>
  </tbody>
</table>



</nuon-tab>

<nuon-tab name="debug">

<div style="padding-top:1rem;"></div>

## Runbooks

<div style="display:flex; flex-wrap:wrap; gap:12px; margin-bottom:1.5rem;">
  <div style="display:flex; flex-direction:column; gap:4px; align-items:flex-start;">
    <nuon-run-runbook name="deploy_and_verify"></nuon-run-runbook>
  </div>
  <div style="display:flex; flex-direction:column; gap:4px; align-items:flex-start;">
    <nuon-run-runbook name="deploy_verify_and_logs"></nuon-run-runbook>
  </div>
  <div style="display:flex; flex-direction:column; gap:4px; align-items:flex-start;">
    <nuon-run-runbook name="verify_status"></nuon-run-runbook>
  </div>
</div>

## Recent Actions

{{ $workflows := dict }}
{{ with .nuon.actions }}{{ $workflows = default dict .workflows }}{{ end }}
{{ if $workflows }}

<table>
  <thead>
    <tr>
      <th>Action</th>
      <th>Status</th>
      <th>Details</th>
    </tr>
  </thead>
  <tbody>
  {{ range $name, $workflow := $workflows }}
    {{ $status := dig "status" "unknown" $workflow }}
    <tr>
      <td><code>{{ $name }}</code></td>
      <td><nuon-status status="{{ $status }}" variant="badge"></nuon-status></td>
      <td>
        <nuon-panel heading="Action: {{ $name }}" trigger="View" size="3/4">
          <table>
            <thead><tr><th>Field</th><th>Value</th></tr></thead>
            <tbody>
              <tr><td>Name</td><td><code>{{ $name }}</code></td></tr>
              <tr><td>Status</td><td><nuon-status status="{{ $status }}" variant="badge"></nuon-status></td></tr>
              <tr><td>ID</td><td><code>{{ dig "id" "—" $workflow }}</code></td></tr>
            </tbody>
          </table>
        </nuon-panel>
      </td>
    </tr>
  {{ end }}
  </tbody>
</table>

{{ else }}

<nuon-banner theme="info">No actions have run yet.</nuon-banner>

{{ end }}

</nuon-tab>

<nuon-tab name="infrastructure">

<div style="padding-top:1rem;"></div>

<div style="display:flex;gap:1.5rem;align-items:flex-start;">
  <div style="flex:1;min-width:0;">

<div style="display:flex;align-items:baseline;gap:0.75rem;"><h3 style="margin:0;">AWS Stack</h3></div>

{{ $stackStatus := dig "status" "" .nuon.install_stack }}
{{ $stackOutputs := default dict .nuon.install_stack.outputs }}

<table>
  <thead>
    <tr><th>Field</th><th>Value</th></tr>
  </thead>
  <tbody>
    <tr><td>Status</td><td>{{ if $stackStatus }}<nuon-status status="{{ $stackStatus }}" variant="badge"></nuon-status>{{ else }}—{{ end }}</td></tr>
    <tr><td>Account</td><td><code>{{ $accountId }}</code></td></tr>
    <tr><td>Region</td><td><code>{{ $region }}</code></td></tr>
    <tr><td>VPC</td><td><code>{{ $vpcId }}</code></td></tr>
  </tbody>
</table>

  </div>
  <div style="flex:1;min-width:0;">

<div style="display:flex;align-items:baseline;gap:0.75rem;"><h3 style="margin:0;">EC2 Instance</h3></div>

{{ $ec2Status := dig "status" "unknown" .nuon.components.ec2 }}

<table style="width:100%;">
  <thead>
    <tr><th style="width:30%;">Field</th><th style="width:70%;">Value</th></tr>
  </thead>
  <tbody>
    <tr><td>Status</td><td><nuon-status status="{{ $ec2Status }}" variant="badge"></nuon-status></td></tr>
    <tr><td>Public IP</td><td>{{ if $publicIp }}<code>{{ $publicIp }}</code>{{ else }}—{{ end }}</td></tr>
    <tr><td>Name</td><td><code>ec2</code></td></tr>
    <tr><td>Type</td><td>terraform_module</td></tr>
  </tbody>
</table>

  </div>
</div>

<div style="margin-top:1.5rem;">

<div style="display:flex;align-items:baseline;gap:0.75rem;"><h3 style="margin:0;">Install Information</h3></div>

<table>
  <thead>
    <tr><th>Field</th><th>Value</th></tr>
  </thead>
  <tbody>
    <tr><td>Install ID</td><td><code>{{ .nuon.install.id }}</code></td></tr>
    <tr><td>Install Name</td><td>{{ dig "name" "—" .nuon.install }}</td></tr>
  </tbody>
</table>

</nuon-tab>

</nuon-tabs>
