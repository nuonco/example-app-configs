{{ $region := .nuon.cloud_account.aws.region }}

<center>
  <img src="https://mintlify.s3-us-west-1.amazonaws.com/nuoninc/logo/dark.svg"/>
  <h1>Data Ops</h1>
  <small>
{{ if .nuon.install_stack.outputs }}
AWS | {{ dig "account_id" "000000000000" .nuon.install_stack.outputs }} | {{ dig "region" "xx-vvvv-00" .nuon.install_stack.outputs }} | {{ dig "vpc_id" "vpc-000000" .nuon.install_stack.outputs }}
{{ else }}
AWS | 000000000000 | xx-vvvv-00 | vpc-000000
{{ end }}
  </small>
</center>

<center>
A sample applicatoin with Cllickhouse Cluster, Temporal Cluster, Tailscale Operator, DataDog Operator, and examplel
Temporal AI Agent.
</center>

![Screenshot](https://github.com/nuonco/demo/blob/main/screenshots/data-ops.png?raw=true)

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

If you would like to use Tailscale to expose your services (recommended), ensure the following:

1. MagicDNS is enabled on your tailnet.
2. HTTPS is enabled on your tailnet.
3. Tags for the operator are set up.
4. An Oauth App has been created and the credentials are available for use in the CloudFormation stack.

See docs here: https://tailscale.com/kb/1236/kubernetes-operator

The tailnet is automatically configured by the operator. We use an action
[`ts_tailnet`](./{{.nuon.install.id}}/actions/{{.nuon.actions.workflows.ts_tailnet.id}}) to retrieve the address to the
tailnet for use in other components.

## Components

### Tailscale

We deploy the tailscale operator and make use of it extensively to expose services via `Ingress`es.

### Services on the Tailnet

{{ if and .nuon.actions.workflows.ts_tailnet .nuon.actions.workflows.ts_tailnet.populated (dig "outputs" "steps" "get" "tailnet" "" .nuon.actions.workflows.ts_tailnet) }}
{{ $tailnet := .nuon.actions.workflows.ts_tailnet.outputs.steps.get.tailnet }}

| Service           | Tailnet Address                                                                                                    |
| ----------------- | ------------------------------------------------------------------------------------------------------------------ |
| ch-ui             | [ch-ui-{{.nuon.install.id}}.{{$tailnet}}](https://ch-ui-{{.nuon.install.id}}.{{$tailnet}})                         |
| clickhouse        | [clickhouse-{{.nuon.install.id}}.{{$tailnet}}](https://clickhouse-{{.nuon.install.id}}.{{$tailnet}})               |
| temporal-frontend | [temporal-frontend-{{.nuon.install.id}}.{{$tailnet}}](https://temporal-frontend-{{.nuon.install.id}}.{{$tailnet}}) |
| temporal-ui       | [temporal-web-{{.nuon.install.id}}.{{$tailnet}}](https://temporal-web-{{.nuon.install.id}}.{{$tailnet}})           |
| agent             | [agent-{{.nuon.install.id}}.{{$tailnet}}](https://agent-{{.nuon.install.id}}.{{$tailnet}})                         |
| agent-api         | [api-{{.nuon.install.id}}.{{$tailnet}}](https://api-{{.nuon.install.id}}.{{$tailnet}})                             |

{{ else }}

... one sec ...

Ensure this action has run: [`ts_tailnet`](./{{.nuon.install.id}}/actions/{{.nuon.actions.workflows.ts_tailnet.id}})

{{ end }}

### Clickhouse

This demo deploys a 2-node replicated clickhouse cluster and a corresponding 3-node keeper cluster to support
replication. The clickhouse cluster is controlled by a ClickHouseInstallation (chi) CRD deployed in the
`clickhouse-installation` namespace. The keepers are controlled by a `ClickHouseKeeper` (chk) CRD deployed in the
`clickhouse-keeper` namespace. The installation and keepers are given their own nodepool to reduce the likelihood of
resource contention.

We also deploy a clickhouse ui which, for the purposes of this demonstration, is made public.

### Temporal

This app config includes a full temporal cluster and an RDS DB for persitence and visibility.

### Temporal AI Agent

We deploy the `temporal-ai-agent` app from the temporal demo modified to run on k8s. This is not a producton ready
application and is not intended to be exposed to the open internet.

### Datadog

We deploy the datadog operator and create a datadog agent to monitor the cluster and send logs.

{{ if ne .nuon.inputs.inputs.datadog_site "" }}

<!-- prettier-ignore-start -->
|        |                                                                                                                                     |
| ------ | ----------------------------------------------------------------------------------------------------------------------------------- |
| Events | [https://{{ .nuon.inputs.inputs.datadog_site }}/event/explorer?query=kube_cluster%3A{{ .nuon.install.sandbox.outputs.cluster.name }}](https://{{ .nuon.inputs.inputs.datadog_site }}/event/explorer?query=kube_cluster%3A{{ .nuon.install.sandbox.outputs.cluster.name }}) |
| Logs | [https://{{ .nuon.inputs.inputs.datadog_site }}/logs?=cluster_name%3A{{ .nuon.install.sandbox.outputs.cluster.name }}](https://{{ .nuon.inputs.inputs.datadog_site }}/logs?query=cluster_name%3A{{ .nuon.install.sandbox.outputs.cluster.name }}) |N
<!-- prettier-ignore-end -->

{{ else }}

Datadog is not enabled. If you'dl ike to enable datadog:

1. set a value for the inpug: `datadog_site`
2. reprovision the install and provide values for the following
   - datadog_api_key
   - datadog_app_key

{{ end }}

## Actions

We have a few examples of actions in this app.

|                             | Trigger   | Description                                                                                |
| --------------------------- | --------- | ------------------------------------------------------------------------------------------ |
| `ch_operator_creds`         | automatic | Copies the autogenerated secrets into the cluster in the shape the operator expects.       |
| `ch_data_dbpedia`           | manual    | Creates a database and a 1ReplicatedMergeTree` table and copies part of a dataset into it. |
| `ch_ui_ingress_healthcheck` | automatic | Checks the status of the tailscale ingress for ch-ui.                                      |
| `ch_ingress_healthcheck`    | automatic | Checks the status of the tailscale ingress for the clickhouse cluster.                     |

If you run the [`ch_data_dbpedia`](./{{.nuon.install.id}}/actions/{{.nuon.actions.workflows.ch_data_dbpedia.id}}), you
can then navigate to the ch-ui and explore the data. We use part of the
[dbpedia dataset](https://clickhouse.com/docs/getting-started/example-datasets/dbpedia-dataset#load-table).

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
