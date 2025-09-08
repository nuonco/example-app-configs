<center>

<img src="https://raw.githubusercontent.com/grafana/grafana/main/docs/logo-horizontal.png"
     alt="Grafana" width="160" />

<h1>Grafana App Config</h1>

Grafana Access URL: [https://{{.nuon.install.sandbox.outputs.nuon_dns.public_domain.name}}](https://{{.nuon.install.sandbox.outputs.nuon_dns.public_domain.name}})

Nuon Install Id: {{ .nuon.install.id }}

AWS Region: {{ .nuon.install_stack.outputs.region }}

## What is Grafana?

Grafana is an open-source platform for monitoring and observability that allows users to visualize, analyze, and understand their data through customizable dashboards and alerts. Grafana's user-friendly interface enables users to create interactive visualizations such as graphs, charts, and heatmaps, facilitating real-time insights and decision-making. [Example customers](https://grafana.com/success/) include Uber, NVIDIA, BlackRock, Palantir, Wells Fargo, SAP, and Citi.

## Grafana architecture

</center>

## Full State

<details>
<summary>Full Install State</summary>
<pre>{{ toPrettyJson .nuon }}</pre>
</details>

## Grafana Resources

[Grafana docs](https://github.com/grafana/grafana)

[Deploy Grafana on Kubernetes](https://grafana.com/docs/grafana/latest/setup-grafana/installation/kubernetes/)

[Grafana Releases](https://github.com/grafana/grafana/releases)

[Grafana Helm Charts](https://github.com/grafana/helm-charts)

[Grafana Operator](https://github.com/grafana/grafana-operator)

[Grafana community](https://community.grafana.com/)
