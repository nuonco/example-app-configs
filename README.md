# Example Apps on Nuon

[Apps](https://docs.nuon.co/concepts/apps) are versions of a software provider's application that can be deployed on a
customer's cloud infrastructure with Nuon. Apps are a set of .toml files that point to your existing Terraform modules,
Helm charts, Kubernetes manifests, and container images. Nuon provides a set of example apps that can be used as a
starting point for configuring and deploying applications using Nuon.

> These example apps are designed for demonstration and learning purposes and not meant for production.
> [Contact Nuon](https://nuon.co/contact-sales) or join the [Slack community](https://nuon-byoc.slack.com) to discuss
> your app's requirements and our technical staff can advise you on how to configure the Nuon app.

# How to Use

Clone this repo and cd into the app directory you want to use, e.g. `cd example-app-configs/<app directory>`. Then run
the following commands to create and sync the app to the Nuon cloud:

```bash
brew install nuonco/tap/nuon
nuon login
nuon apps create --name <app directory>
nuon apps sync
```

Go to the Nuon dashboard at https://app.nuon.co, select your app, and click "Install". Follow the prompts to complete
your first app install in AWS.

# Example Apps

## httpbin

[httpbin](https://httpbingo.org) is a simple HTTP request and response debugging service. This app deploys an ec2
instance and runs the httpbin service using a docker container. This app does not use Kubernetes, so is quicker to make
installs.

## aws-lambda

Creates an AWS Lambda function based on a Go app image built from a Dockerfile. The app also includes a DynamoDB table,
a certificate and an API Gateway. This app does not use Kubernetes, so is quicker to make installs. See the Nuon docs
for [a step-by-step guide](https://docs.nuon.co/get-started/create-your-first-app) on how to deploy this app.

## eks-simple

Creates an EKS cluster with a `whoami` application deployed on it, an Application Load Balancer and a Certificate. See
the Nuon docs for [a step-by-step guide](https://docs.nuon.co/get-started/create-your-first-app) on how to deploy this
app.

## eks-simple-auto

Identical to eks-simple but makes use of our sandbox for AWS Auto Mode EKS sandbox -
[`aws-eks-auto-sandbox`](https://github.com/nuonco/aws-eks-auto-sandbox).

## grafana

[Grafana](https://grafana.com) is an open-source platform for monitoring and observability. This app deploys Grafana,
Prometheus, and PostgreSQL with Helm in an EKS cluster as well as an ALB and certificate in the VPC for cluster and
Grafana access. Read this blog post about:
[installing Grafana with Nuon](https://nuon.co/blog/installing-grafana-with-nuon/).

## mattermost

[Mattermost](https://mattermost.com) is an open-source, self-hostable collaboration platform. This app deploys the
Mattermost operator and a Mattermost instance in an EKS cluster as well as an ALB and certificate in the VPC for cluster
and Mattermost access. Read this blog post about:
[installing Mattermost with Nuon](https://nuon.co/blog/installing-mattermost-with-nuon/).

## coder

[Coder](https://coder.com) is a self-hosted Cloud Development Environment (CDE) platform This app deploys a Postgres
database container and Coder control plane container in an EKS cluster as well as an ALB and certificate in the VPC for
cluster and Coder access. Read this blog post about:
[installing Coder with Nuon](https://nuon.co/blog/installing-coder-with-nuon/).

## twenty

[Twenty](https://twenty.com) is an open-source CRM platform designed to help businesses manage customer relationships,
sales, and marketing activities. Read this blog post about:
[installing Twenty with Nuon](https://nuon.co/blog/installing-salesforce-alternative-twenty-with-nuon/).

## penpot

[Penpot](https://penpot.app) is an open-source design and prototyping platform comparable to Figma. This app deploys a
Postgres database container and several Penpot control plane containers in an EKS cluster as well as an ALB and
certificate in the VPC for cluster and Penpot access.

## baserow

[Baserow](https://baserow.io) is an open-source no-code database and Airtable alternative. This app deploys a Postgres
database container and several Baserow control plane containers in an EKS cluster as well as an ALB and certificate.
Read this blog post about:
[installing Baserow with Nuon](https://nuon.co/blog/installing-airtable-alternative-baserow-with-nuon/).

## ClickHouse

[ClickHouse](https://clickhouse.com/) is a columnar analytical database. This app deploys ClickHouse to an EKS cluster
using the [Altinity/clickhouse-operator](https://github.com/Altinity/clickhouse-operator/). It also deploys a
[ch-ui](https://github.com/caioricciuti/ch-ui).

## ClickHouse + Tailscale

This demo builds off of the previous one and improves on it through the addition of the tailscale operator. This
operator enables exposing the ClickHouse dbs and the ch-ui's to a [tailscale](https://tailscale.com/) tailnet.

## Datadog Operator

This demo provides an example for deploying the
[datadog operator](https://docs.datadoghq.com/containers/datadog_operator/) and agent to an EKS cluster.

## Data-ops

A fully featured application deploying an RDS Cluster, ClickHouse, datadog,
[temporal](https://github.com/temporalio/helm-charts), and a
[temporal-ai-agent](https://github.com/temporal-community/temporal-ai-agent/).

# Resources

[Nuon docs](https://docs.nuon.co)

[AWS EKS Sandbox](https://github.com/nuonco/aws-eks-sandbox)

[AWS EKS Karpenter Sandbox](https://github.com/nuonco/aws-eks-karpenter-sandbox)

[AWS Min Sandbox](https://github.com/nuonco/aws-min-sandbox)
