# whoami-smoke-test

Verifies that the whoami service for install `{{ .nuon.install.id }}` is serving
traffic over HTTPS.

## Target

{{ if and .nuon.sandbox.populated .nuon.sandbox.outputs }}
{{ $sub := "whoami" }}{{ with .nuon.inputs }}{{ with .inputs }}{{ with .subdomain }}{{ $sub = . }}{{ end }}{{ end }}{{ end }}

<nuon-group gap="8" align="center">
  <nuon-badge theme="info" variant="code">GET</nuon-badge>
  <nuon-badge theme="default" variant="code">https://{{ $sub }}.{{ .nuon.sandbox.outputs.nuon_dns.public_domain.name }}/</nuon-badge>
</nuon-group>

{{ else }}

The target URL is available once the sandbox is deployed.

{{ end }}

## Step

- **curl-whoami** — an inline ad-hoc action that `curl`s the URL above, retrying
  up to `MAX_RETRIES` times with a delay between attempts. The step succeeds only
  if the endpoint returns a successful HTTP status (`--fail`).

> [!TIP]
> Run **whoami-smoke-test** after **whoami-upgrade** to confirm the rollout is
> healthy.
