<center>

  <video autoplay loop muted playsinline width="640" height="360">
    <source src="https://coder.together.agency/videos/logo/sections/0/content/9/value/video.mp4" type="video/mp4">
    Your browser does not support the video tag.
  </video>
</center>

Coder Access URL: [https://{{.nuon.install.sandbox.outputs.nuon_dns.public_domain.name}}](https://{{.nuon.install.sandbox.outputs.nuon_dns.public_domain.name}})

Nuon Install Id: {{ .nuon.install.id }}

AWS Region: {{ .nuon.install_stack.outputs.region }}

## Full State

<details>
<summary>Full Install State</summary>
<pre>{{ toPrettyJson .nuon }}</pre>
</details>

<center>

## What is Coder?

Coder is a Cloud Development Environment (CDE) platform that enables developers to create, manage, and scale development environments in the cloud. This Nuon app config deploys a light-weight Coder instance on AWS using Amazon EKS, meant for demonstration purposes only. Review the Coder docs for how it deploys on [Kubernetes](https://coder.com/docs/install/kubernetes) and visit the [Coder OSS repository](https://github.com/coder/coder) for more information.

## Coder architecture

Coder consists of a PostgreSQL database, an API server, a web dashboard, and a Terraform provisioner server that runs `terraform plan`, `terraform apply`, and `terraform destroy` commands to build development development environments on any cloud or on-premises infrastructure. See the [Coder architecture diagram](https://coder.com/docs/admin/infrastructure/architecture) for more details.

</center>

### Database Configuration

This Nuon app config uses **AWS RDS PostgreSQL** for the database backend with the following features:

- **Managed Database**: RDS PostgreSQL 15 instance (configurable via `coder_db_instance_type` input, defaults to `db.t4g.micro`)
- **Credential Management**: AWS Secrets Manager automatically manages database passwords (no hardcoded credentials)
- **Security**: VPC-isolated with security groups restricting access to cluster CIDR only
- **Monitoring**: Performance insights and CloudWatch logs enabled
- **Backups**: Automated 7-day backup retention with encrypted storage

Database credentials are automatically synced from AWS Secrets Manager to Kubernetes secrets during deployment.

### Helm Chart Deployment

The Coder application is deployed using the official Coder Helm chart from the Helm repository:

- **Helm Repository**: `https://helm.coder.com/v2`
- **Chart Method**: Uses `[helm_repo]` configuration (standard Helm repository approach)
- **Version**: Tracks latest stable release from repository

This follows Nuon best practices for deploying public Helm charts.

> This is a development/demo installation of Coder. Do not use in production.

> Wildcard DNS for workspace subdomains is automatically configured via external-dns. This enables features like web apps (e.g., Jupyter) and web port forwarding without manual DNS configuration.

### Observability & Monitoring

This app includes comprehensive monitoring and Kubernetes event streaming:

- **Observability Stack**: Prometheus, Grafana, Loki, and Alertmanager deployed in the `coder-observability` namespace for metrics collection, log aggregation, and alerting
- **Kubelogstream**: Streams Kubernetes pod events directly to Coder workspace startup logs for easier troubleshooting

**Accessing Grafana Dashboards**:

1. In the Nuon dashboard, navigate to your Coder installation
2. Go to the **Actions** tab
3. Run the `grafana_password` action (manual trigger)
4. The action output will display:
   - Grafana URL: `https://{{.nuon.install.sandbox.outputs.nuon_dns.public_domain.name}}/grafana`
   - Username: `admin`
   - Password: (randomly generated, stored in AWS Secrets Manager)
5. Open the Grafana URL in your browser and log in with the credentials

Grafana is served from `/grafana` path on the same ALB as Coder, reducing infrastructure cost and complexity.

**Available Dashboards**:
- Coder Status - Overview of Coder health
- Coder Coderd - Control plane metrics
- Workspaces - Workspace utilization and performance
- Workspace Detail - Individual workspace deep-dive
- Provisioner - Terraform provisioner metrics
- Postgres Database - RDS performance
- Infrastructure - Node metrics

The admin password is generated once during initial deployment and persisted in AWS Secrets Manager for the lifetime of the installation.

## Coder Resources

[Coder Environment Variable docs](https://coder.com/docs/reference/cli/server)

[Coder Releases](https://github.com/coder/coder/releases/)

[Coder Monitoring](https://coder.com/docs/admin/monitoring)

[Coder Kubernetes Logs Integration](https://coder.com/docs/admin/integrations/kubernetes-logs)

[Coder Logstream Kube GitHub](https://github.com/coder/coder-logstream-kube)

[Coder Observability GitHub](https://github.com/coder/observability)

[AWS Instance Types](https://aws.amazon.com/ec2/instance-types/)
