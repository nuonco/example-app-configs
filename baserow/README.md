<center>

<img src="https://avatars.githubusercontent.com/u/1261496?v=4"
     alt="Baserow" width="160" />

<h1>Baserow App Config</h1>

Baserow Access URL: [https://{{.nuon.install.sandbox.outputs.nuon_dns.public_domain.name}}](https://{{.nuon.install.sandbox.outputs.nuon_dns.public_domain.name}})

Nuon Install Id: {{ .nuon.install.id }}

AWS Region: {{ .nuon.install_stack.outputs.region }}

## What is Baserow?

Baserow is an open-source no-code database and Airtable alternative that allows users to create and manage databases without any coding knowledge. It provides a user-friendly interface for creating tables, fields, and records, as well as features like collaboration, automation, and integrations with other tools. Baserow is designed to be flexible and customizable, making it suitable for a wide range of use cases, from project management to inventory tracking.

Baserow's competitors include: Airtable, Smartsheet, monday.com, ClickUp, NocoDB, Appsmith, Budibase.

</center>

## Full State

<details>
<summary>Full Install State</summary>
<pre>{{ toPrettyJson .nuon }}</pre>
</details>

## Baserow Resources

[image tags](https://hub.docker.com/r/baserow/baserow/tags)

[Install with Helm](https://baserow.io/docs/installation%2Finstall-with-helm)

[Helm maintainer's guide](https://artifacthub.io/packages/helm/christianhuth/baserow)

[values.yaml](https://github.com/christianhuth/helm-charts/blob/main/charts/baserow/values.yaml)

[Install with K8s docs](https://baserow.io/docs/installation/install-with-k8s)

[Docs](https://baserow.io/docs/index)

[GitHub repo](https://github.com/bram2w/baserow)
