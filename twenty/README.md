<center>

<img src="https://raw.githubusercontent.com/twentyhq/twenty/main/packages/twenty-website/public/images/core/logo.svg"
     alt="Twenty" width="160" />

<h1>Twenty App Config</h1>

Twenty Access URL: [https://{{.nuon.install.sandbox.outputs.nuon_dns.public_domain.name}}](https://{{.nuon.install.sandbox.outputs.nuon_dns.public_domain.name}})

Nuon Install Id: {{ .nuon.install.id }}

AWS Region: {{ .nuon.install_stack.outputs.region }}

## What is Twenty?

Twenty is an open-source CRM platform designed to help businesses manage customer relationships, sales, and marketing activities. It offers a range of features including contact management, sales pipeline tracking, email marketing, and reporting tools. Twenty's user-friendly interface and customizable workflows enable teams to streamline their processes and improve customer engagement.

Twenty's competitors include: Odoo, ERPNext, EspoCRM, SuiteCRM, Vtiger, Dolibarr, YetiForce, Krayin and proprietary solutions like Salesforce, HubSpot, Zoho CRM, Microsoft Dynamics 365.

</center>

## Full State

<details>
<summary>Full Install State</summary>
<pre>{{ toPrettyJson .nuon }}</pre>
</details>

## Twenty Resources

[User guide](https://twenty.com/user-guide)

[Developer guide](https://twenty.com/developers)

[Releases](https://github.com/twentyhq/twenty/releases)

[Repo](https://github.com/twentyhq/twenty)

[Kubernetes docs](https://github.com/twentyhq/twenty/tree/main/packages/twenty-docker/k8s)
