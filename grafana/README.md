<center>

<img src="https://raw.githubusercontent.com/grafana/grafana/main/docs/logo-horizontal.png"
     alt="Grafana" width="160" />

<h1>Grafana App Config</h1>

Grafana Access URL: [https://{{.nuon.install.sandbox.outputs.nuon_dns.public_domain.name}}](https://{{.nuon.install.sandbox.outputs.nuon_dns.public_domain.name}})

Nuon Install Id: {{ .nuon.install.id }}

AWS Region: {{ .nuon.install_stack.outputs.region }}

## What is Grafana?

Grafana is an open-source platform for monitoring and observability that allows users to visualize, analyze, and understand their data through customizable dashboards and alerts. Grafana's user-friendly interface enables users to create interactive visualizations such as graphs, charts, and heatmaps, facilitating real-time insights and decision-making. [Example customers](https://grafana.com/success/) include Uber, NVIDIA, BlackRock, Palantir, Wells Fargo, SAP, and Citi.

Prometheus is an open-source monitoring and alerting toolkit that collects and stores time-series metrics from systems and applications. Grafana connects to Prometheus as a data source, enabling users to visualize and analyze those metrics through customizable dashboards. Together, they provide powerful observability for infrastructure like PostgreSQL, especially when paired with exporters such as the Postgres exporter.

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

[Prometheus](https://prometheus.io/)

[Prometheus OSS](https://github.com/prometheus/prometheus)

[Prometheus Helm Charts](https://github.com/prometheus-community/helm-charts)

[Postgres Exporter OSS](https://github.com/prometheus-community/postgres_exporter)

## Example Commands

### Prometheus

Within Grafana, go to the "Explore" section and select the Prometheus data source. You can then run the following example queries to visualize PostgreSQL metrics:

```bash
pg_up
up{job="postgresql-exporter"}
{job="postgresql-exporter"}
pg_database_size_bytes
pg_stat_database_numbackends{job="postgresql-exporter"}
{__name__=~"pg_.*"}
```

### Grafana dashboards

Within the Grafana dashboards, make sure to select the host or instance <code>prometheus-postgres-exporter.exampledb.svc.cluster.local</code> to see all of the Prometheus metrics for PostgreSQL.

[Dashboard ID 455 (PostgreSQL Overview)](https://grafana.com/grafana/dashboards/455-postgres-overview/)

[Dashboard ID 9628 (PostgreSQL Database)](https://grafana.com/grafana/dashboards/9628-postgresql-database/)

[Dashboard ID 12273 (PostgreSQL Exporter)](https://grafana.com/grafana/dashboards/12273-postgresql-overview-postgres-exporter/)
