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

## API Access

Login to the Twenty instance, go to Settings and APIs & Webhooks to create an API key. Enter the key and press Launch to open an API Playground UI to test the API.

Altneratively, use curl or Postman to test the API. Replace YOUR_API_KEY with the key you created in the UI.

### Rest API

**Returns a list of companies with their details**

curl -X GET "https://{{.nuon.install.sandbox.outputs.nuon_dns.public_domain.name}}/rest/companies" \
 -H "Authorization: Bearer YOUR_API_KEY" \
 -H "Content-Type: application/json"

**Create a new company**

curl -X POST "https://{{.nuon.install.sandbox.outputs.nuon_dns.public_domain.name}}/rest/companies" \
 -H "Authorization: Bearer YOUR_API_KEY" \
 -H "Content-Type: application/json" \
 -d '{
"name": "Tesla, Inc.",
"domainName": "tesla.com",
"employees": 125000
}'

**Get contacts**

curl -X GET "https://{{.nuon.install.sandbox.outputs.nuon_dns.public_domain.name}}/rest/people" \
 -H "Authorization: Bearer YOUR_API_KEY" \
 -H "Content-Type: application/json"

### GraphQL API

**Returns a list of companies with their details**

curl -X POST "https://{{.nuon.install.sandbox.outputs.nuon_dns.public_domain.name}}/graphql" \
 -H "Authorization: Bearer YOUR_API_KEY" \
 -H "Content-Type: application/json" \
 -d '{"query": "query { companies { edges { node { id name domainName { primaryLinkUrl primaryLinkLabel } employees createdAt } } } }"}'

## Twenty Resources

[Twenty image tags](https://hub.docker.com/r/twentycrm/twenty/tags)

[API docs](https://twenty.com/developers/section/api-and-webhooks/api)

[User guide](https://twenty.com/user-guide)

[Developer guide](https://twenty.com/developers)

[Releases](https://github.com/twentyhq/twenty/releases)

[Repo](https://github.com/twentyhq/twenty)

[Kubernetes docs](https://github.com/twentyhq/twenty/tree/main/packages/twenty-docker/k8s)

[postgres-spilo image tags](https://hub.docker.com/r/twentycrm/twenty-postgres-spilo/tags)

[Discord community](https://discord.com/channels/1130383047699738754/1146466959676936192)
