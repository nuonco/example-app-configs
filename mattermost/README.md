<center>

<img src="https://upload.wikimedia.org/wikipedia/commons/8/84/Mattermost_logo_horizontal.svg"
     alt="Mattermost" width="160" />

<h1>Mattermost App Config</h1>

Mattermost Access URL: [https://{{.nuon.install.sandbox.outputs.nuon_dns.public_domain.name}}](https://{{.nuon.install.sandbox.outputs.nuon_dns.public_domain.name}})

Nuon Install Id: {{ .nuon.install.id }}

AWS Region: {{ .nuon.install_stack.outputs.region }}

## What is Mattermost?

Mattermost is an open-source, self-hostable collaboration platform designed as an alternative to proprietary services like Slack and Microsoft Teams, with a strong focus on security, customization, and integration. Its functionality includes secure messaging, file sharing, and threaded conversations in public and private channels, as well as features for project management (Boards) and workflow automation (Playbooks). [Example customers](https://mattermost.com/customers/), many of whom are in regulated industries, include U.S. Air Force, Blue Origin, Nasdaq, Qualcomm, BOSCH, HASA, AIG and Samsung.

## Mattermost architecture

The architecture of Mattermost is built with a modular, scalable approach. The core is a single-compiled Go binary that serves as a RESTful JSON web service. This server communicates with web, desktop, and mobile clients and connects to a backend infrastructure that includes a database (PostgreSQL or MySQL) and file storage (local, network, or object storage like Amazon S3). This design allows for on-premise deployment, providing organizations with complete control over their data, and supports high-availability clusters for large-scale, enterprise-level use. See the [Mattermost architecture diagram](https://docs.mattermost.com/deployment-guide/application-architecture.html) for more details. Review the Mattermost docs for how it deploys on [Kubernetes](https://docs.mattermost.com/deployment-guide/server/deploy-kubernetes.html) and visit the [Mattermost OSS repository](https://github.com/mattermost/mattermost) for more information.

</center>

## Full State

<details>
<summary>Full Install State</summary>
<pre>{{ toPrettyJson .nuon }}</pre>
</details>

## Mattermost Resources

[Mattermost Operator Environment Variable docs](https://github.com/mattermost/mattermost-helm/blob/master/charts/mattermost-operator/values.yaml)

[Example Mattermost Custom Resource](https://github.com/mattermost/mattermost-operator/blob/master/docs/examples/mattermost_full.yaml)

[Mattermost Releases](https://github.com/mattermost/mattermost/releases)

[Mattermost Operator Releases](https://github.com/mattermost/mattermost-operator/releases)

[Mattermost Operator Helm Chart](https://github.com/mattermost/mattermost-helm/tree/master/charts/mattermost-operator)

[Mattermost Kubernetes install guide](https://docs.mattermost.com/deployment-guide/server/deploy-kubernetes.html)

[Mattermost community](https://community.mattermost.com/)

[AWS Instance Types](https://aws.amazon.com/ec2/instance-types/)

[AWS T3 and T3a Instances](https://aws.amazon.com/ec2/instance-types/t3/)
