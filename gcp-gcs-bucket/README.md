# GCP GCS Bucket (custom stacks)

The GCP parallel of the AWS persistence pattern: a **curated custom stack**
creates a GCS bucket during the customer's install-stack apply — as the
customer's admin credentials, before any component runs — and a pass-through
component reads it back and emits outputs for downstream use.

## How it works

1. `stack.toml` declares a `[[custom_nested_stacks]]` entry pointing at the
   curated `bucket` module in the install-stacks repo:

   ```toml
   [[custom_nested_stacks]]
   name         = "storage"
   template_url = "github.com/nuonco/install-stacks//gcp/modules/bucket"
   index        = 0
   ```

   The install stack creates the bucket as `<install-id>-storage`. Parameters
   map to install inputs (here: `versioning`).

2. Outputs phone home under
   `{{.nuon.install_stack.outputs.custom_nested_stacks.storage.outputs.*}}`.

3. `components/0-bucket.toml` is a pass-through terraform component that reads
   the bucket by its conventional name and re-emits `name`, `url`, and
   `self_link` as component outputs — reference them from any other component
   as `{{.nuon.components.bucket.outputs.name}}`.

## Requirements

Curated GCP custom stacks need nuon#1943 + nuon#1944 (renderer) and
install-stacks#24 (the `bucket` module). Until those land, this config
validates but the bucket is not created.
