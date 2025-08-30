<center>

<img src="https://avatars.githubusercontent.com/u/30179644?s=80&v=4"/>

<h1>Penpot App Config</h1>

Penpot Access URL: [https://{{.nuon.install.sandbox.outputs.nuon_dns.public_domain.name}}](https://{{.nuon.install.sandbox.outputs.nuon_dns.public_domain.name}})

Nuon Install Id: {{ .nuon.install.id }}

AWS Region: {{ .nuon.install_stack.outputs.region }}

## What is Penpot?

Penpot is an open-source design and prototyping platform. It is web-based and works with open web standards (SVG). Being open source, it can be self-hosted and extended. It targets designers and developers, as opposed to other tools that target only designers. Penpot is developed by Kaleidos, a company with over 20 years of experience in design and development for the web.

</center>

## Full State

<details>
<summary>Full Install State</summary>
<pre>{{ toPrettyJson .nuon }}</pre>
</details>

## Mattermost Resources
