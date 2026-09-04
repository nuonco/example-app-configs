# GCP Custom Stacks

This launch-test app declares every curated module supported by the GCP install stack. It focuses on install-stack creation and teardown; it has no application components.

The modules use unique indices for stable config ordering, but Terraform may provision independent GCP module types in parallel:

1. `service_account`
2. `kms`
3. `dns`
4. `bucket`

Common outputs are available at:

```text
{{.nuon.install_stack.outputs.custom_nested_stacks.identity.outputs.email}}
{{.nuon.install_stack.outputs.custom_nested_stacks.identity.outputs.unique_id}}
{{.nuon.install_stack.outputs.custom_nested_stacks.encryption.outputs.id}}
{{.nuon.install_stack.outputs.custom_nested_stacks.encryption.outputs.key_ring}}
{{.nuon.install_stack.outputs.custom_nested_stacks.publicdns.outputs.name_servers}}
{{.nuon.install_stack.outputs.custom_nested_stacks.publicdns.outputs.managed_zone_id}}
{{.nuon.install_stack.outputs.custom_nested_stacks.storage.outputs.name}}
{{.nuon.install_stack.outputs.custom_nested_stacks.storage.outputs.url}}
```

The public managed zone is `<install-id>.example.com.` and is not delegated. Bucket and DNS destructive deletion are disabled. Cloud KMS key material remains in GCP after Terraform destroy.
