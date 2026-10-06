# ALB

Component to provision an ingress w/ annotations to make use of an AWS
Certificate Manager SSL Certificate via the
['certificate' component](../certificate).

## Inputs/Variables

| Variable             | Description                                             | Example                                                                  |
| -------------------- | ------------------------------------------------------- | ------------------------------------------------------------------------ |
| `install_name`       | Typically, the install id.                              | `{{.nuon.install.id}}`                                                   |
| `name`               | The name for the ingress.                               | `service-name`, `api`, ``                                                |
| `domain`             | The ID of the zone. Can be sourced from the sandbox.    | `{{.nuon.install.sandbox.outputs.public_domain.name}}`                   |
| `domain_certificate` | AWS Cerficate Manager Certificate ARN.                  | `{{.nuon.components.certificate.outputs.public_domain_certificate_arn}}` |
| `https_port`         | port to use for https.                                  | `443` (default: `443`)                                                   |
| `service_name`       | The name of the service this ingress routes traffic to. | `api`                                                                    |
| `service_port`       | The port of the service this ingress routes traffic to. | `3000` (default: `3000`)                                                 |
| `healthcheck_path`   | healthcheck path                                        | `/livez`, `/readyz`, `/health` (default: `/livez`)                       |

Notes

- if no `name` is provided, `{install_name}-pubulic` will be used.
- if no `healtcheck_path` is provided the default `/livez` will be used.

## Example Configuration

```toml
name       = "application_load_balancer"
type       = "helm_chart"
chart_name = "application-load-balancer"

[public_repo]
repo      = "nuonco/components"
directory = "aws/alb"
branch    = "main"

[values]
domain_certificate = "{{.nuon.components.certificate.outputs.public_domain_certificate_arn}}"
domain             = "api.{{.nuon.install.sandbox.outputs.public_domain.name}}"
https_port         = "443"
service_name       = "api"
service_port       = "api"
install_name       = "{{.nuon.install.id}}"
```

## Note

This component depends on outputs of the
[`certificate` component](../certificate). It is important to note, the
`domain_name` of the certificate component should match the `domain` value here.
