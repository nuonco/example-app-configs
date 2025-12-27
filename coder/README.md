<center>

  <video autoplay loop muted playsinline width="640" height="360">
    <source src="https://coder.together.agency/videos/logo/sections/0/content/9/value/video.mp4" type="video/mp4">
    Your browser does not support the video tag.
  </video>
</center>

Coder Access URL: [https://{{.nuon.install.sandbox.outputs.nuon_dns.public_domain.name}}](https://{{.nuon.install.sandbox.outputs.nuon_dns.public_domain.name}})

Nuon Install Id: {{ .nuon.install.id }}

AWS Region: {{ .nuon.install_stack.outputs.region }}

> This is a development/demo installation of Coder. Do not use in production.

> A CNAME record must be manually created in Route 53 for wildcard subdomains to work. This enables features like web apps e.g., Jupyter and web port fowarding. For example, if your domain is `{{.nuon.install.sandbox.outputs.nuon_dns.public_domain.name}}`, create a CNAME record for `*.{{.nuon.install.sandbox.outputs.nuon_dns.public_domain.name}}` that points to the DNS name of the load balancer created by this Nuon app config. The load balancer DNS name can be found in AWS Console.

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

</center>

## Coder Resources

[Coder Environment Variable docs](https://coder.com/docs/reference/cli/server)

[Coder Releases](https://github.com/coder/coder/releases/)

[AWS Instance Types](https://aws.amazon.com/ec2/instance-types/)

[AWS T3 and T3a Instances](https://aws.amazon.com/ec2/instance-types/t3/)
