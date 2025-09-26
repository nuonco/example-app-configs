<center>

<img src="https://upload.wikimedia.org/wikipedia/commons/5/57/Baserow_Logo.png"
     alt="Baserow" width="300" />

<h1>Baserow App Config</h1>

Baserow Access URL: [https://{{.nuon.install.sandbox.outputs.nuon_dns.public_domain.name}}](https://{{.nuon.install.sandbox.outputs.nuon_dns.public_domain.name}})

Nuon Install Id: {{ .nuon.install.id }}

AWS Region: {{ .nuon.install_stack.outputs.region }}

## What is Baserow?

Baserow is an open-source no-code database and Airtable alternative that allows users to create and manage databases without any coding knowledge. It provides a user-friendly interface for creating tables, fields, and records, as well as features like collaboration, automation, and integrations with other tools. Baserow is designed to be flexible and customizable, making it suitable for a wide range of use cases, from project management to inventory tracking.

Baserow's competitors include: Airtable, Smartsheet, monday.com, ClickUp, NocoDB, Appsmith, Budibase.

</center>

## Configuration Details

- consider using 4+ t3a.medium or ts3.large instances to prevent OOMKill and provide pod stability
- set memory and cpu resource requests and limits for frontend and celery pods
- set BASEROW_EXTRA_ALLOWED_HOSTS to \* to allow ALB healthchecks to work
- requires 2 load balancers for frontend and backend api services
- certificate requires subject_alternative_names for backend api domain
- increased readiness and liveness probe settings to account for slow startups and pod stability
- adjusted aws helm chart to add a websocket ws route to the ALB listener rules for backend websocket support
- for file uploading, requires an existing s3 bucket and an existing k8s secret with aws credentials

## Full State

<details>
<summary>Full Install State</summary>
<pre>{{ toPrettyJson .nuon }}</pre>
</details>

## Baserow Resources

[image tags](https://hub.docker.com/r/baserow/baserow/tags)

[standalone image](https://hub.docker.com/r/baserow/baserow)

[web-frontend image](https://hub.docker.com/r/baserow/web-frontend)

[backend image](https://hub.docker.com/r/baserow/backend)

[Technical help](https://community.baserow.io/c/technical-help/)

[Install with Helm](https://baserow.io/docs/installation%2Finstall-with-helm)

[Helm maintainer's guide](https://artifacthub.io/packages/helm/christianhuth/baserow)

[values.yaml](https://github.com/christianhuth/helm-charts/blob/main/charts/baserow/values.yaml)

[Install with K8s docs](https://baserow.io/docs/installation/install-with-k8s)

[Celery repo](https://github.com/celery/celery)

[Docs](https://baserow.io/docs/index)

[AWS Instance Types](https://aws.amazon.com/ec2/instance-types/)

[AWS T3 and T3a Instances](https://aws.amazon.com/ec2/instance-types/t3/)

[GitHub repo](https://github.com/bram2w/baserow)
