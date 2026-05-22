# Certificate

Component to provision an AWS Certificate Manager SSL Certificate.

## Inputs/Variables

| Variable      | Description                                          | Example                                                   |
| ------------- | ---------------------------------------------------- | --------------------------------------------------------- |
| `zone_id`     | The ID of the zone. Can be sourced from the sandbox. | `{{.nuon.install.sandbox.outputs.public_domain.zone_id}}` |
| `domain_name` | The domain name. Usually provided by the sandbox.    | `{{.nuon.install.sandbox.outputs.public_domain.name}}`    |

## Example Configuration

```toml
name = "certificate"
type = "terraform_module"
terraform_version = "1.10.4"

[public_repo]
repo      = "nuonco/components"
directory = "aws/certificate"
branch    = "main"

[vars]
zone_id     = "{{.nuon.install.sandbox.outputs.public_domain.zone_id}}"
domain_name = "{{.nuon.install.sandbox.outputs.public_domain.name}}"
# NOTE: it is also possible to use a subdomain or wildcard here.
# domain_name = "subdomain.{{.nuon.install.sandbox.outputs.public_domain.name}}"
# domain_name = "*.{{.nuon.install.sandbox.outputs.public_domain.name}}"
```
